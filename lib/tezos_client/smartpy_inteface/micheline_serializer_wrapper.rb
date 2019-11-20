# frozen_string_literal: true

class TezosClient
  class SmartpyInterface
    module MichelineSerializerWrapper
      def convert_michelson_to_micheline(script)
        cmd = ["node", actual_project_path + "/lib/conseil_lib/convert_to_micheline.js", script]

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

      def actual_project_path
        path = File.expand_path(File.dirname(__FILE__)).split("/")
        path[0..path.index("tezos_client")].join("/")
      end
    end
  end
end