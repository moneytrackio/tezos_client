require 'tezos_client/version'
require 'tezos_client/string_utils'
require 'tezos_client/currency_utils'
require 'tezos_client/crypto'
require 'tezos_client/commands'

require 'tezos_client/client_interface'
require 'tezos_client/rpc_interface'

require 'tezos_client/encode_utils'

class TezosClient
  using CurrencyUtils
  using StringUtils

  include Commands
  include Crypto
  include EncodeUtils

  attr_accessor :client_interface
  attr_accessor :rpc_interface

  RANDOM_SIGNATURE = 'edsigu165B7VFf3Dpw2QABVzEtCxJY2gsNBNcE3Ti7rRxtDUjqTFRpg67EdAQmY6YWPE5tKJDMnSTJDFu65gic8uLjbW2YwGvAZ'.freeze

  def initialize
    @client_config_file = ENV['TEZOS_CLIENT_CONFIG_FILE']
    @client_interface = ClientInterface.new(config_file: @client_config_file)
    @rpc_interface = RpcInterface.new
  end

  def adjust_gas(args)
    transaction_args = args.clone

    transaction_args[:signature] = RANDOM_SIGNATURE
    res = rpc_interface.run_transaction(transaction_args)

    operation_result = res['contents'][0]['metadata']['operation_result']
    status = operation_result['status']

    unless status == 'applied'
      raise "failed to simulate the operation with status #{status}: #{res}"
    end

    consumed_gas = (operation_result['consumed_gas']).to_i
    args[:gas_limit] = (consumed_gas + 100).from_satoshi
    args[:storage_limit] = operation_result.fetch('consumed_storage', 0).from_satoshi
  end

  def operation_id(signed_operation_hex)
    hash = RbNaCl::Hash::Blake2b.digest(signed_operation_hex.to_bin, digest_size: 32)
    encode_tz(:o, hash.to_hex)
  end

  def sign_operation(secret_key:, operation_hex:)
    res = nil

    sign(secret_key: secret_key,
         data: operation_hex,
         watermark: :generic) do |edsig, signed_data|
      op_id = operation_id(signed_data)

      yield(edsig, signed_data, op_id) if block_given?

      res = signed_data
    end

    res
  end

  def end_parenthesis_idx(str)
    pl = 0
    str.each_char.with_index do

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

    adjust_gas(transaction_args)

    transaction_hex = rpc_interface.forge_transaction(transaction_args)

    op_id = nil
    sign_operation(secret_key: args[:secret_key],
                   operation_hex: transaction_hex) do |edsig, sdata|

      transaction_args[:signature] = edsig
      transaction_args[:protocol] = protocol

      res = rpc_interface.preapply_transaction(transaction_args)
      status = res['contents'][0]['metadata']['operation_result']['status']
      raise "preapply failed with status #{status}: #{res}" unless status == 'applied'

      op_id = rpc_interface.broadcast_operation(sdata)
    end

    op_id
  end

end
