# frozen_string_literal: true

class TezosClient
  class SmartpyInterface
    module EntryPointSerializerWrapper
      def gen_entry_point_args(params_struct, entry_point, params)
        cmd = ["node", "./lib/conseil_lib/gen_entry_point_args.js", params_struct, entry_point] + params

        Open3.popen3(*cmd) do |_stdin, stdout, stderr, wait_thr|
          err = stderr.read
          status = wait_thr.value.exitstatus
          log err

          if status != 0
            raise "command '#{cmd}' existed with status #{status}: #{err}"
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