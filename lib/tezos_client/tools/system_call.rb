module Tools
  module SystemCall
    def self.execute(cmd)
      Open3.popen3(*cmd) do |_stdin, stdout, stderr, wait_thr|
        err = stderr.read
        status = wait_thr.value.exitstatus

        if status != 0
          raise SystemCallError, "command '#{cmd}' existed with status #{status}: #{err}"
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