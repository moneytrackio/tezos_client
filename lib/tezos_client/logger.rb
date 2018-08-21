
class TezosClient
  module Logger

    # Setup the log for TezosClient calls.
    # Value should be a logger but can can be stdout, stderr, or a filename.
    # You can also configure logging by the environment variable TEZOSCLIENT_LOG.
    def logger=(log)
      @loger = create_logger log
    end

    # Create a log that respond to << like a logger
    # param can be 'stdout', 'stderr', a string (then we will log to that file) or a logger (then we return it)
    def create_logger(param)
      if param
        if param.is_a? String
          if param == 'stdout'
            stdout_logger = Class.new do
              def <<(obj)
                STDOUT.puts obj
              end
            end
            stdout_logger.new
          elsif param == 'stderr'
            stderr_logger = Class.new do
              def <<(obj)
                STDERR.puts obj
              end
            end
            stderr_logger.new
          else
            file_logger = Class.new do
              attr_writer :target_file

              def <<(obj)
                File.open(@target_file, 'a') { |f| f.puts obj }
              end
            end
            logger = file_logger.new
            logger.target_file = param
            logger
          end
        else
          param
        end
      end
    end

    def env_logger
      if @env_logger
        @env_logger
      elsif ENV['TEZOSCLIENT_LOG']
        @env_logger = create_logger ENV['TEZOSCLIENT_LOG']
      end
    end

    def logger
      @logger || env_logger
    end

  end

end
