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

  def ensure_operation_applied!(rpc_response)
    operation_result = rpc_response['metadata']['operation_result']
    status = operation_result['status']
    raise "Operation status != 'applied': #{status}\n #{rpc_response}" if status != 'applied'
  end

  def run_transaction(args)
    res = rpc_interface.run_transaction(**args, signature: RANDOM_SIGNATURE)

    ensure_operation_applied!(res)

    operation_result = res['metadata']['operation_result']
    consumed_storage = operation_result.fetch('consumed_storage', '0').to_i.from_satoshi
    consumed_gas = (operation_result['paid_storage_size_diff']).to_i.from_satoshi

    {
      status: :applied,
      consumed_gas: consumed_gas,
      consumed_storage: consumed_storage
    }
  end

  def run_origination(args)
    res = rpc_interface.run_origination(**args, signature: RANDOM_SIGNATURE)

    ensure_operation_applied!(res)

    operation_result = res['metadata']['operation_result']
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

  def transfer(args)
    default_args = {
      gas_limit: 0.04,
      storage_limit: 0.006,
      fee: 0.05
    }
    args = default_args.merge args

    raise ArgumentError, 'must pass :amount' unless args.include? :amount
    raise ArgumentError, 'must pass :from' unless args.include? :from
    raise ArgumentError, 'must pass :to' unless args.include? :to
    raise ArgumentError, 'must pass :secret_key' unless args.include? :secret_key

    branch  = rpc_interface.head_hash
    counter = rpc_interface.contract_counter(args[:from]) + 1
    protocol = rpc_interface.protocols[0]

    transaction_args = args.merge(
      branch: branch,
      counter: counter
    )

    if args.key? :parameters
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

      # simulate operation apply
      res = rpc_interface.preapply_transaction(
        **transaction_args,
        signature: base58_signature,
        protocol: protocol
      )

      ensure_operation_applied!(res)

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
    default_args = {
      amount: 0,
      spendable: false,
      delegatable: false,
      gas_limit: 0.04,
      storage_limit: 0.006,
      fee: 0.05
    }

    branch  = rpc_interface.head_hash
    counter = rpc_interface.contract_counter(args.fetch(:from)) + 1
    protocol = rpc_interface.protocols[0]

    origination_script = liquidity_interface.origination_script(
      args.slice(:from, :script, :init_params)
    )

    origination_args = default_args.merge(
      **args,
      branch: branch,
      script: origination_script,
      counter: counter,
      manager: args.fetch(:from)
    )

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
        **origination_args,
        signature: base_58_signature,
        protocol: protocol
      )

      ensure_operation_applied!(res)

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
