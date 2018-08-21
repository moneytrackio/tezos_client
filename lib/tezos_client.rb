# frozen_string_literal: true

require 'tezos_client/version'
require 'tezos_client/string_utils'
require 'tezos_client/currency_utils'
require 'tezos_client/crypto'
require 'tezos_client/commands'
require 'tezos_client/logger'

require 'tezos_client/client_interface'
require 'tezos_client/rpc_interface'
require 'tezos_client/liquidity_interface'

require 'tezos_client/encode_utils'

require 'timeout'

class TezosClient
  using CurrencyUtils
  using StringUtils

  extend Logger

  include Commands
  include Crypto
  include EncodeUtils

  attr_accessor :client_interface
  attr_accessor :rpc_interface
  attr_accessor :liquidity_interface

  RANDOM_SIGNATURE = 'edsigu165B7VFf3Dpw2QABVzEtCxJY2gsNBNcE3Ti7rRxtDUjqTFRpg67EdAQmY6YWPE5tKJDMnSTJDFu65gic8uLjbW2YwGvAZ'

  def initialize(rpc_node_address: '127.0.0.1', rpc_node_port: 8732)
    @rpc_node_address = rpc_node_address
    @rpc_node_port = rpc_node_port

    @client_config_file = ENV['TEZOS_CLIENT_CONFIG_FILE']
    @client_interface = ClientInterface.new(
      config_file: @client_config_file
    )

    @rpc_interface = RpcInterface.new(
      host: @rpc_node_address,
      port: @rpc_node_port
    )

    @liquidity_interface = LiquidityInterface.new(
      rpc_node_address: @rpc_node_address,
      rpc_node_port: @rpc_node_port
    )
  end

  def run_transaction(args)
    transaction_args = args.merge(signature: RANDOM_SIGNATURE)

    res = rpc_interface.run_transaction(transaction_args)

    operation_result = res['metadata']['operation_result']
    status = operation_result['status']

    unless status == 'applied'
      raise "failed to simulate the operation with status #{status}: #{res}"
    end

    consumed_storage = operation_result.fetch('consumed_storage', '0').to_i.from_satoshi
    consumed_gas = (operation_result['paid_storage_size_diff']).to_i.from_satoshi

    {
      status: :applied,
      consumed_gas: consumed_gas,
      consumed_storage: consumed_storage
    }
  end

  def run_origination(args)
    transaction_args = args.merge(signature: RANDOM_SIGNATURE)

    res = rpc_interface.run_origination(transaction_args)
    operation_result = res['metadata']['operation_result']

    unless operation_result['status'] == 'applied'
      raise "failed to simulate the operation with status #{operation_result['status']}: #{res}"
    end

    consumed_storage = operation_result.fetch('paid_storage_size_diff', '0').to_i.from_satoshi
    consumed_gas = (operation_result['consumed_gas']).to_i.from_satoshi
    originated_contract = operation_result['originated_contracts'][0]

    {
        status: :applied,
        consumed_gas: consumed_gas,
        consumed_storage: consumed_storage,
        originated_contract: originated_contract
    }
  end

  def operation_id(signed_operation_hex)
    hash = RbNaCl::Hash::Blake2b.digest(signed_operation_hex.to_bin, digest_size: 32)
    encode_tz(:o, hash.to_hex)
  end

  def sign_operation(secret_key:, operation_hex:)
    sign(secret_key: secret_key,
         data: operation_hex,
         watermark: :generic) do |edsig, signed_data|
      op_id = operation_id(signed_data)

      if block_given?
        yield(edsig, signed_data, op_id)
      else
        edsig
      end
    end
  end

  def transfer(args)
    default_args = {
      gas_limit: 0.04,
      storage_limit: 0.006,
      fee: 0.05,
      parameters: nil
    }
    args = default_args.merge args

    raise ArgumentError, 'must pass :amount' unless args.include? :amount
    raise ArgumentError, 'must pass :from' unless args.include? :from
    raise ArgumentError, 'must pass :to' unless args.include? :to
    raise ArgumentError, 'must pass :secret_key' unless args.include? :secret_key

    branch  = rpc_interface.head_hash
    counter = rpc_interface.contract_counter(args[:from]) + 1
    protocol = rpc_interface.protocols[0]

    transaction_args = {
      branch: branch,
      counter: counter,
      from: args[:from],
      to: args[:to],
      amount: args[:amount],
      gas_limit: args[:gas_limit],
      storage_limit: args[:storage_limit],
      fee: args[:fee]
    }

    if args[:parameters]
      transaction_args[:parameters] = encode_args(args[:parameters])
    end

    # simulate operation and adjust gas limits
    run_result = run_transaction(transaction_args)
    transaction_args[:gas_limit] = run_result[:consumed_gas] + 0.01
    transaction_args[:storage_limit] = run_result[:consumed_storage]

    # forge transaction hex
    transaction_hex = rpc_interface.forge_transaction(transaction_args)

    op_id = nil
    sign_operation(
      secret_key: args[:secret_key],
      operation_hex: transaction_hex
    ) do |base58_signature, signed_transaction_hex|

      transaction_args[:signature] = base58_signature
      transaction_args[:protocol] = protocol

      # simulate operation apply
      res = rpc_interface.preapply_transaction(transaction_args)
      status = res['metadata']['operation_result']['status']

      unless status == 'applied'
        raise "preapply failed with status #{status}: #{res}"
      end

      op_id = rpc_interface.broadcast_operation(signed_transaction_hex)
    end

    op_id
  end

  def block_include_operation?(operation_id, block_id)
    operations = rpc_interface.get("chains/main/blocks/#{block_id}/operation_hashes")
    operations.flatten.include? operation_id
  end

  def monitor_operation(operation_id, timeout: 60)
    including_block = nil

    monitoring_thread = rpc_interface.monitor_block do |block_header|
      log "recently received block: #{block_header}"
      hash = block_header['hash']
      if block_include_operation?(operation_id, hash)
        log "operation #{operation_id} found in block #{hash}"
        including_block = hash
      end
    end

    Timeout.timeout(timeout) do
      loop do
        sleep(0.1)
        break unless including_block.nil?
      end
    end

    monitoring_thread.terminate

    including_block
  end

  def originate_contract(args)
    amount = args.fetch(:amount, 0)
    spendable = args.fetch(:spendable, false)
    delegatable = args.fetch(:delegatable, false)

    branch  = rpc_interface.head_hash
    counter = rpc_interface.contract_counter(args.fetch(:from)) + 1
    protocol = rpc_interface.protocols[0]



    origination_script = liquidity_interface.origination_script(
      from: args.fetch(:from),
      script: args.fetch(:script),
      init_params: args.fetch(:init_params)
    )

    origination_args = {
      branch: branch,
      amount: amount,
      spendable: spendable,
      delegatable: delegatable,
      from: args.fetch(:from),
      script: origination_script,
      counter: counter,
      manager: args.fetch(:from),
      gas_limit: 0.04,
      storage_limit: 0.006,
      fee: 0.05
    }

    # simulate operation and adjust gas limits
    run_result = run_origination(origination_args)
    origination_args[:gas_limit] = run_result[:consumed_gas] + 0.01
    origination_args[:storage_limit] = run_result[:consumed_storage]

    origination_hex = rpc_interface.forge_origination(origination_args)

    sign_operation(
      secret_key: args.fetch(:secret_key),
      operation_hex: origination_hex
    ) do |base_58_signature, signed_origination_hex|

      res = rpc_interface.preapply_origination(
        origination_args.merge(
          signature: base_58_signature,
          protocol: protocol
        )
      )

      status = res['metadata']['operation_result']['status']

      unless status == 'applied'
        raise "preapply failed with status #{status}: #{res}"
      end

      originated_contract = res['metadata']['operation_result']['originated_contracts'][0]
      op_id = rpc_interface.broadcast_operation(signed_origination_hex)

      {
        operation_id: op_id,
        originated_contract: originated_contract
      }
    end
  end

  def log(out)
    return unless TezosClient.logger
    TezosClient.logger << out + "\n"
  end

end
