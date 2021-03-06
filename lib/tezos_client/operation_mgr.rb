# frozen_string_literal: true

require "tezos_client/compute_operation_args_counters"

class TezosClient
  class OperationMgr
    include Crypto
    using CurrencyUtils

    attr_accessor :rpc_interface,
                  :rpc_operation_args

    def initialize(rpc_interface:, rpc_operation_args:, **args)
      @rpc_interface = rpc_interface
      @secret_key = args.fetch(:secret_key)
      @multiple_operations = rpc_operation_args.is_a?(Array)
      @rpc_operation_args = @multiple_operations ? rpc_operation_args : [rpc_operation_args]
      @signed_operation_args_h = nil
      @branch = args[:branch]
      @protocol = args[:protocol]
      @ignore_counter_error = args[:ignore_counter_error]
    end

    def multiple_operations?
      @multiple_operations
    end

    def ignore_counter_error?
      !!@ignore_counter_error
    end

    def single_operation?
      !multiple_operations?
    end

    def branch
      @branch ||= rpc_interface.head_hash
    end

    def protocol
      @protocol ||= rpc_interface.protocol
    end

    def chain_id
      @chain_id ||= rpc_interface.chain_id
    end

    def simulate_and_update_limits
      run_result = run

      run_result[:operation_results].zip(rpc_operation_args) do |operation_result, rpc_operation_args|
        if rpc_operation_args.key?(:gas_limit)
          rpc_operation_args[:gas_limit] = (operation_result[:consumed_gas].to_i.from_satoshi + 0.001).to_satoshi.to_s
        end
      end

      run_result
    end

    def to_hex
      rpc_interface.forge_operations(operations: rpc_operation_args, branch: branch)
    end

    def valid_secret_key?
      @secret_key&.match?(/^edsk/)
    end

    def sign
      raise ArgumentError, "Invalid secret key" unless valid_secret_key?

      sign_operation(
        secret_key: @secret_key,
        operation_hex: to_hex
      ) do |base_58_signature, signed_hex, _op_id|
        @signed_operation_args_h = rpc_operation_args.hash
        @base_58_signature = base_58_signature
        @signed_hex = signed_hex
      end
    end

    def signed?
      @signed_operation_args_h == rpc_operation_args.hash
    end

    def base_58_signature
      sign unless signed?
      @base_58_signature
    end

    def signed_hex
      sign unless signed?
      @signed_hex
    end

    def simulate
      # simulate operations and adjust gas limits
      run_result = simulate_and_update_limits
      if valid_secret_key?
        preapply
      else
        run_result
      end
    end

    def test_and_broadcast
      simulate_res = simulate
      op_id = broadcast

      simulate_res.merge(
        operation_id: op_id,
      )
    end

    def run
      rpc_responses = rpc_interface.run_operations(
        operations: rpc_operation_args,
        signature: RANDOM_SIGNATURE,
        branch: branch,
        chain_id: chain_id
      )

      ensure_applied!(rpc_responses)

      convert_rpc_response(rpc_responses)
    end

    def convert_rpc_response(rpc_responses)
      converted_rpc_responce = {
        status: :applied,
        operation_results: operation_results(rpc_responses),
        internal_operation_results: internal_operation_result(rpc_responses)
      }

      converted_rpc_responce.merge(consumed_tez(rpc_responses))
    end

    def operation_results(rpc_responses)
      rpc_responses.map do |rpc_response|
        metadata = rpc_response[:metadata]
        metadata[:operation_result][:consumed_gas] = compute_consumed_gas(metadata) if metadata.key? :operation_result
        metadata[:operation_result]
      end
    end

    def internal_operation_result(rpc_responses)
      rpc_responses.map do |rpc_response|
        rpc_response[:metadata][:internal_operation_results]
      end.compact.flatten
    end

    def consumed_tez(rpc_responses)
      total_consumed_storage = 0
      total_consumed_gas = 0

      rpc_responses.each do |rpc_response|
        metadata = rpc_response[:metadata]
        total_consumed_storage += compute_consumed_storage(metadata)
        total_consumed_gas += compute_consumed_gas(metadata)
      end

      {
        consumed_storage: total_consumed_storage,
        consumed_gas: total_consumed_gas
      }
    end

    def compute_consumed_gas(metadata)
      consumed_gas = (metadata.dig(:operation_result, :consumed_gas) || "0").to_i

      if metadata.key?(:internal_operation_results)
        metadata[:internal_operation_results].each do |internal_operation_result|
          consumed_gas += (internal_operation_result[:result][:consumed_gas] || "0").to_i
        end
      end
      consumed_gas
    end

    def compute_consumed_storage(metadata)
      (metadata.dig(:operation_result, :paid_storage_size_diff) || "0").to_i.from_satoshi
    end

    def preapply
      rpc_responses = rpc_interface.preapply_operations(
        operations: rpc_operation_args,
        signature: base_58_signature,
        protocol: protocol,
        branch: branch
      )

      ensure_applied!(rpc_responses)

      convert_rpc_response(rpc_responses)
    end

    def broadcast
      self.rpc_operation_args = ::TezosClient::ComputeOperationArgsCounters.new(
        pending_operations: rpc_interface.pending_operations,
        operation_args: rpc_operation_args
      ).call if ignore_counter_error?

      rpc_interface.broadcast_operation(signed_hex)
    end

    private
      def ensure_applied!(rpc_responses)
        metadatas = rpc_responses.map { |response| response[:metadata] }
        operation_results = metadatas.map { |metadata| metadata[:operation_result] }
        internal_operations = metadatas.map { |metadata| metadata[:internal_operation_results] }.flatten.compact
        operation_results.concat(internal_operations.map { |internal_operation| internal_operation[:result] })

        failed = operation_results.detect do |operation_result|
          operation_result != nil && operation_result[:status] != "applied"
        end

        return metadatas if failed.nil?

        failed_operation_result = operation_results.detect do |operation_result|
          operation_result[:status] == "failed"
        end

        failed!("failed", failed_operation_result[:errors], operation_results)
      end

      def exception_klass(errors)
        error = errors[0]
        case error[:id]
        when TezBalanceTooLow::FIRST_ERROR_REGEXP
          TezBalanceTooLow
        when ScriptRuntimeError::FIRST_ERROR_REGEXP
          ScriptRuntimeError
        else
          OperationFailure
        end
      end

      def failed!(status, errors, metadata)
        raise exception_klass(errors).new(metadata: metadata, errors: errors, status: status)
      end
  end
end
