# frozen_string_literal: true

require_relative "smartpy_inteface/smartpy_wrapper"

class TezosClient
  class SmartpyInterface
    include Logger
    include SmartpyWrapper

    attr_reader :options

    def json_scripts(args)
      compile_to_michelson(**args) do |contract_script_filename, init_script_filename|
        micheline_contract = File.read(contract_script_filename)
        micheline_storage = File.read(init_script_filename)

        [JSON.parse(micheline_storage), JSON.parse(micheline_contract)]
      end
    end

    def origination_script(args)
      json_init_script, json_contract_script = json_scripts(args)

      {
        code: json_contract_script,
        storage: json_init_script
      }
    end

    private
    def compile_to_michelson(target: "compile", script:, flags: {}, args: [])
      Tools::TemporaryFile.with_file_copy(script) do |script_copy_path|
        script_basename = script_copy_path.split("/").last.sub(/.py$/, "")
        script_path = "/tmp/#{script_basename}/"
        init_script_filename = "step_000_cont_0_storage.json"
        contract_script_filename = "step_000_cont_0_contract.json"

        cmd_line = [target, script_copy_path, script_path].concat(
          optional_inputs(flags, args)
        )

        call_smartpy cmd_line

        yield(script_path + "default/" + contract_script_filename, script_path + "default/" + init_script_filename)
      end
    end

    def optional_inputs(flags, args)
      inputs = []

      inputs.concat(optional_flags(flags))
      inputs.concat(optional_args(args))

      inputs
    end

    def optional_flags(flags)
      flags.map do |key, value|
        if value.is_a? Boolean
          "--#{key}"
        else
          ["--#{key}", value.to_s]
        end
      end.flatten
    end

    def optional_args(args)
      return [] if args.count.zero?

      ["--"].concat(
        args.map do |arg|
          arg.to_json
        end
      )
    end
  end
end
