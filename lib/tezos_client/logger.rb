# frozen_string_literal: true

class TezosClient
  module Logger
    # Setup the log for TezosClient calls.
    # Value should be a logger but can can be stdout, stderr, or a filename.
    # You can also configure logging by the environment variable TEZOSCLIENT_LOG.
    def logger=(log)
      @logger = create_logger log
    end

    class StdOutLogger
      def <<(obj)
        STDOUT.puts obj
      end
    end

    class StdErrLogger
      def <<(obj)
        STDERR.puts obj
      end
    end

    class FileLogger
      attr_writer :target_file

      def initialize(target_file)
        @target_file = target_file
      end

      def <<(obj)
        File.open(@target_file, "a") { |f| f.puts obj }
      end
    end

    # Create a log that respond to << like a logger
    # param can be 'stdout', 'stderr', a string (then we will log to that file) or a logger (then we return it)
    def create_logger(param)
      return unless param

      if param.is_a? String
        if param == "stdout"
          StdOutLogger.new
        elsif param == "stderr"
          StdErrLogger.new
        else
          FileLogger.new(param)
        end
      else
        param
      end
    end

    def env_logger
      if @env_logger
        @env_logger
      elsif ENV["TEZOSCLIENT_LOG"]
        @env_logger = create_logger ENV["TEZOSCLIENT_LOG"]
      end
    end

    def logger
      @logger || env_logger
    end
  end
end
