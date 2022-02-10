# frozen_string_literal: true

class TezosClient
  class RpcRequestFailure < StandardError
    attr_reader :status_code
    attr_reader :error

    def initialize(error:, url:, status_code:)
      @status_code = status_code
      @error = error

      if @message.nil?
        @message = "#{url} failed with status #{status_code}:\n #{error}"
      end

      super @message
    end
  end

  class SysCallError < RuntimeError
  end

  class SmartPyError < SysCallError
  end

  class BadSignatureError < StandardError
  end

  class InvalidActivation < RpcRequestFailure
    attr_reader :pkh

    def initialize(error:, **_args)
      @pkh = error[:pkh]
      @message = "Invalid activation (pkh: #{pkh})"
      super
    end
  end

  class PreviouslyRevealedKey < RpcRequestFailure
    attr_reader :contract

    def initialize(error:, **_args)
      @contract = error[:contract]

      @message = "Previously revealed key for address #{contract}"

      super
    end
  end

  class OperationFailure < StandardError
    include Logger

    attr_reader :metadata
    attr_reader :errors
    attr_reader :status
    attr_reader :message

    def initialize(metadata:, errors:, status:)
      @metadata = metadata
      @errors = errors
      @status = status

      error = errors[0]

      if @message.nil?
        @message = "failure #{status}: #{tezos_contents_log(error).pretty_inspect}"
      end

      super(message)
    end
  end

  class TezBalanceTooLow < OperationFailure
    FIRST_ERROR_REGEXP = /proto\.[^.]*\.contract\.balance_too_low/

    attr_reader :contract
    attr_reader :balance
    attr_reader :amount

    def initialize(metadata:, errors:, status:)
      error = errors[0]
      @contract = error[:contract]
      @balance = error[:balance]
      @amount = error[:amount]

      @message = "Tezos balance too low for address #{contract} (balance: #{balance}, amount #{amount})"

      super
    end
  end

  class ScriptRuntimeError < OperationFailure
    FIRST_ERROR_REGEXP = /proto.\d*-\w*\.(scriptRejectedRuntimeError|michelson_v\d\.runtime_error)/
    ERROR_REGEXP = /proto.\d*-\w*\.(scriptRejectedRuntimeError|michelson_v\d\.script_rejected)/

    attr_reader :location
    attr_reader :with
    attr_reader :contract

    def initialize(metadata:, errors:, status:)
      first_error = errors[0]
      rejection_error = errors.detect { |error| error[:id].match? ERROR_REGEXP }

      @location = rejection_error[:location]
      @contract = first_error[:contractHandle]
      @with = rejection_error[:with]
      @message = "Script runtime Error when executing #{contract}: #{with} (location: #{location})"
      super
    end
  end
end
