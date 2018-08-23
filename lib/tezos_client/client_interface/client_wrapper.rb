# frozen_string_literal: true

class TezosClient
  class ClientInterface
    # Wrapper used to call the tezos-client binary
    module ClientWrapper
      def call_client(command)
        cmd = "#{client_cmd} #{command}"
        Open3.popen3(cmd) do |_stdin, stdout, stderr, wait_thr|
          err = stderr.read
          status = wait_thr.value.exitstatus

          if status != 0
            raise "command '#{cmd}' existed with status #{status}: #{err}"
          end

          STDERR.puts err
          output = stdout.read

          if block_given?
            yield(output)
          else
            output
          end
        end
      end

      def client_cmd
        res = "tezos-client -l"
        if config_file
          res = "#{res} -c #{config_file}"
        end
        res
      end
    end
  end
end
