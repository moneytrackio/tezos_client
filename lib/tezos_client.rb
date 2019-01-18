# frozen_string_literal: true

require "pp"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/string/inflections"
require "timeout"

require "tezos_client/version"
require "tezos_client/string_utils"
require "tezos_client/currency_utils"
require "tezos_client/crypto"
require "tezos_client/commands"
require "tezos_client/logger"
require "tezos_client/encode_utils"
require "tezos_client/operation"
require "tezos_client/operations/origination_operation"
require "tezos_client/operations/transaction_operation"
require "tezos_client/operations/transactions_operation"
require "tezos_client/operations/activate_account_operation"
require "tezos_client/operations/reveal_operation"

require "tezos_client/client_interface"
require "tezos_client/rpc_interface"
require "tezos_client/liquidity_interface"


class TezosClient
  using CurrencyUtils
  using StringUtils

  include Logger

  include Commands
  include Crypto

  attr_accessor :client_interface
  attr_accessor :rpc_interface
  attr_accessor :liquidity_interface

  RANDOM_SIGNATURE = "edsigu165B7VFf3Dpw2QABVzEtCxJY2gsNBNcE3Ti7rRxtDUjqTFRpg67EdAQmY6YWPE5tKJDMnSTJDFu65gic8uLjbW2YwGvAZ"

  def initialize(rpc_node_address: "127.0.0.1", rpc_node_port: 8732)
    @rpc_node_address = rpc_node_address
    @rpc_node_port = rpc_node_port

    @client_config_file = ENV["TEZOS_CLIENT_CONFIG_FILE"]
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

  # Originates a contract on the tezos blockchain
  #
  # @param from [String] Address originating the contract
  # @param amount [Numeric] amount to send to the contract
  # @param secret_key [String] Secret key of the origination address
  # @param args [Hash] keyword options for the origination
  # @option args [String] :script path of the liquidity script
  # @option args [Array, String] :init_params params to pass to the storage initialization process
  # @option args [Boolean] :spendable decide wether the contract is spendable or not
  # @option args [Boolean] :delegatable decide wether the contract is delegatable or not
  #
  # @return [Hash] result of the origination containing :operation_id, :operation_result and :originated_contract
  #
  def originate_contract(from:, amount:, secret_key:, **args)
    res = OriginationOperation.new(
      liquidity_interface: liquidity_interface,
      rpc_interface: rpc_interface,
      from: from,
      secret_key: secret_key,
      amount: amount,
      **args
    ).test_and_broadcast

    res.merge(originated_contract: res[:operation_result][:originated_contracts][0])
  end

  # Transfer funds to an account
  #
  # @param from [String] Address originating the transfer
  # @param to [String] Address receiving the transfer
  # @param amount [Numeric] amount to send to the account
  # @param secret_key [String] Secret key of the origination address
  # @param args [Hash] keyword options for the transfer
  #
  # @return [Hash] result of the transfer containing :operation_id and :operation_result
  #
  def transfer(from:, amount:, to:, secret_key:, **args)
    TransactionOperation.new(
      liquidity_interface: liquidity_interface,
      rpc_interface: rpc_interface,
      from: from,
      to: to,
      secret_key: secret_key,
      amount: amount,
      **args
    ).test_and_broadcast
  end

  def activate_account(pkh:, secret:, **args)
    ActivateAccountOperation.new(
      liquidity_interface: liquidity_interface,
      rpc_interface: rpc_interface,
      pkh: pkh,
      secret: secret,
      **args
    ).test_and_broadcast
  end

  def transfer_to_many(from:, amounts:, secret_key:, **args)
    TransactionsOperation.new(
      liquidity_interface: liquidity_interface,
      rpc_interface: rpc_interface,
      from: from,
      amounts: amounts,
      secret_key: secret_key,
      **args
    ).test_and_broadcast
  end

  def reveal_pubkey(secret_key:, **args)

    public_key = secret_key_to_public_key(secret_key)
    from = public_key_to_address(public_key)

    RevealOperation.new(
      liquidity_interface: liquidity_interface,
      rpc_interface: rpc_interface,
      public_key: public_key,
      from: from,
      secret_key: secret_key,
      **args
    ).test_and_broadcast
  end

  def call_contract(args)
    parameters = args.fetch(:parameters)

    json_params = liquidity_interface.call_parameters(
      script: args.fetch(:script),
      parameters: parameters
    )

    transfer_args = args.merge(parameters: json_params)

    transfer(transfer_args)
  end

  def monitor_operation(operation_id, timeout: 120)
    including_block = nil

    monitoring_thread = rpc_interface.monitor_block do |block_header|
      log "recently received block: #{block_header.pretty_inspect}"
      hash = block_header["hash"]

      if block_include_operation?(operation_id, hash)
        log "operations #{operation_id} found in block #{hash}"
        including_block = hash
      end
    end

    Timeout.timeout(timeout) do
      loop do
        sleep(0.1)
        break unless monitoring_thread.alive?
        break unless including_block.nil?
      end
    end

    if monitoring_thread.status.nil?
      # when thread raise an Exception, reraise it
      log "monitoring thread raised an exception"
      monitoring_thread.value
    else
      monitoring_thread.terminate
    end

    including_block
  end

  def block_include_operation?(operation_id, block_id)
    operations = rpc_interface.get("chains/main/blocks/#{block_id}/operation_hashes")
    operations.flatten.include? operation_id
  end

end
