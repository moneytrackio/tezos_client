# frozen_string_literal: true

require "active_support/concern"

class TezosClient
  module Logger
    extend ActiveSupport::Concern
    @@logger = nil
    @@env_logger = nil

    def log(out)
      return unless self.class.logger
      self.class.logger << out + "\n"
    end

    FILTERED_KEYS = [:code, :contractCode]
    def tezos_contents_log_filter(content)
      if content.is_a? Array
        content.map { |el| tezos_contents_log_filter(el) }
      elsif content.is_a? Hash
        content.reduce({}) do |h, (k, v)|
          value = if FILTERED_KEYS.include? k.to_sym
            "#{v.to_s[0..30]}..."
          else
            tezos_contents_log_filter(v)
          end
          h.merge(k => value)
        end
      else
        content
      end
    end

    def tezos_contents_log(content)
      tezos_contents_log_filter(content).pretty_inspect
    end

    class_methods do
      # Setup the log for TezosClient calls.
      # Value should be a logger but can can be stdout, stderr, or a filename.
      # You can also configure logging by the environment variable TEZOSCLIENT_LOG.
      def logger=(log)
        @@logger = create_logger log
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
        if @@env_logger
          @@env_logger
        elsif ENV["TEZOSCLIENT_LOG"]
          @@env_logger = create_logger ENV["TEZOSCLIENT_LOG"]
        end
      end

      def logger
        @@logger || env_logger
      end
    end
  end
end
