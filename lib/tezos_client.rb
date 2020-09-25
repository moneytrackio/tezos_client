# frozen_string_literal: true

require "pp"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/module/delegation"
require "timeout"
require "benchmark"
require "open3"
require "active_interaction"
require "time"

require "tezos_client/version"
require "tezos_client/string_utils"
require "tezos_client/currency_utils"
require "tezos_client/crypto"
require "tezos_client/commands"
require "tezos_client/logger"
require "tezos_client/exceptions"
require "tezos_client/encode_utils"
require "tezos_client/operation_mgr"
require "tezos_client/operations/operation"
require "tezos_client/operations/origination_operation"
require "tezos_client/operations/transaction_operation"
require "tezos_client/operations/transactions_operation"
require "tezos_client/operations/activate_account_operation"
require "tezos_client/operations/reveal_operation"
require "tezos_client/operations/raw_operation_array"
require "tezos_client/operations/operation_array"

require "tezos_client/tools/system_call"
require "tezos_client/tools/temporary_file"

require "tezos_client/rpc_interface"
require "tezos_client/smartpy_interface"

require "tezos_client/tools/convert_to_hash"
require "tezos_client/tools/find_big_maps_in_storage"
require "tezos_client/tools/hash_to_micheline"
require "tezos_client/tools/annots_to_type"

class TezosClient
  using CurrencyUtils
  using StringUtils

  include Logger

  include Commands
  include Crypto

  attr_accessor :rpc_interface
  attr_accessor :smartpy_interface

  RANDOM_SIGNATURE = "edsigu165B7VFf3Dpw2QABVzEtCxJY2gsNBNcE3Ti7rRxtDUjqTFRpg67EdAQmY6YWPE5tKJDMnSTJDFu65gic8uLjbW2YwGvAZ"

  def initialize(rpc_node_address: "127.0.0.1", rpc_node_port: 8732, liquidity_options: {})
    @rpc_node_address = rpc_node_address
    @rpc_node_port = rpc_node_port

    @client_config_file = ENV["TEZOS_CLIENT_CONFIG_FILE"]

    @rpc_interface = RpcInterface.new(
      host: @rpc_node_address,
      port: @rpc_node_port
    )

    @smartpy_interface = SmartpyInterface.new
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
  def originate_contract(from:, amount:, secret_key: nil, script: nil, init_params: nil, dry_run: false, **args)
    origination_args = {
      rpc_interface: rpc_interface,
      from: from,
      secret_key: secret_key,
      amount: amount,
      **args
    }

    origination_args[:script] = contract_interface(script).origination_script(
      from: from,
      script: script,
      init_params: init_params
    )

    operation = OriginationOperation.new(origination_args)
    res = broadcast_operation(operation: operation, dry_run: dry_run)

    res.merge(
      originated_contract: res[:operation_results][0][:originated_contracts][0]
    )
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
  def transfer(from:, amount:, to:, secret_key:, dry_run: false, **args)
    operation = TransactionOperation.new(
      rpc_interface: rpc_interface,
      from: from,
      to: to,
      secret_key: secret_key,
      amount: amount,
      **args
    )

    broadcast_operation(operation: operation, dry_run: dry_run)
  end

  def activate_account(pkh:, secret:, dry_run: false, **args)
    operation = ActivateAccountOperation.new(
      rpc_interface: rpc_interface,
      pkh: pkh,
      secret: secret,
      **args
    )

    broadcast_operation(operation: operation, dry_run: dry_run)
  end

  def transfer_to_many(from:, amounts:, secret_key:, dry_run: false, **args)
    operation = TransactionsOperation.new(
      rpc_interface: rpc_interface,
      from: from,
      amounts: amounts,
      secret_key: secret_key,
      **args
    )

    broadcast_operation(operation: operation, dry_run: dry_run)
  end

  def reveal_pubkey(secret_key:, dry_run: false, **args)
    public_key = secret_key_to_public_key(secret_key)
    from = public_key_to_address(public_key)

    operation = RevealOperation.new(
      rpc_interface: rpc_interface,
      public_key: public_key,
      from: from,
      secret_key: secret_key,
      **args
    )

    broadcast_operation(operation: operation, dry_run: dry_run)
  end

  def call_contract(dry_run: false, entrypoint:, params:, params_type:, **args)
    _entrypoint = select_entrypoint(
      contract_address: args[:to],
      entrypoint: entrypoint
    )

    json_params = micheline_params(
      params: params,
      entrypoint: _entrypoint,
      params_type: params_type
    )

    transfer_args = args.merge(
      entrypoint: _entrypoint,
      parameters: json_params,
      dry_run: dry_run
    )

    transfer(transfer_args)
  end

  def select_entrypoint(contract_address:, entrypoint:)
    entrypoints = entrypoints(contract_address)["entrypoints"].keys

    if entrypoints.count == 0
      "default"
    elsif entrypoints.include?(entrypoint)
      entrypoint
    else
      raise ::ArgumentError, "entrypoint #{entrypoint} not found in #{entrypoints}"
    end
  end

  def inject_raw_operations(secret_key:, raw_operations:, dry_run: false, **args)
    public_key = secret_key_to_public_key(secret_key)
    from = public_key_to_address(public_key)

    operation = RawOperationArray.new(
      rpc_interface: rpc_interface,
      public_key: public_key,
      from: from,
      secret_key: secret_key,
      raw_operations: raw_operations,
      **args
    )

    broadcast_operation(operation: operation, dry_run: dry_run)
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
    retries ||= 0

    operations = rpc_interface.get("chains/main/blocks/#{block_id}/operation_hashes")
    operations.flatten.include? operation_id
  rescue TezosClient::RpcRequestFailure
    if (retries += 1) < 3
      sleep(2)
      retry
    else
      raise
    end
  end

  def self.root_path
    File.expand_path(File.dirname(__FILE__))
  end

  private
    def broadcast_operation(operation:, dry_run:)
      res = if dry_run
        operation.simulate
      else
        operation.test_and_broadcast
      end

      res.merge(
        rpc_operation_args: operation.rpc_operation_args
      )
    end

    def micheline_params(params:, entrypoint:, params_type:)
      {
        entrypoint: entrypoint,
        value: convert_params(
          params: params,
          params_type: params_type
        )
      }
    end

    def convert_params(params:,  params_type:)
      case params_type.to_sym
      when :micheline
        params
      else
        raise ::ArgumentError, "params type must be equal to [ :micheline ]"
      end
    end


    def contract_interface(script)
      case script.to_s
      when /[A-Za-z_\/\-]*.py/
        smartpy_interface
      when nil
        raise "script var unset"
      else
        raise "unknown contract type"
      end
    end
end
