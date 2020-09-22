# frozen_string_literal: true

class TezosClient
  module Tools
    module SystemCall
      def self.execute(cmd)
        Open3.popen3(*cmd) do |_stdin, stdout, stderr, wait_thr|
          status = wait_thr.value.exitstatus

          if status != 0
            err  = stdout.read + stderr.read
            raise ::TezosClient::SysCallError, "command '#{cmd}' existed with status #{status}: #{err}"
          end

          output = stdout.read

          if block_given?
            yield(output)
          else
            output
          end
        end
      end
    end
  end
end
