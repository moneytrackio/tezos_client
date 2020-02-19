# frozen_string_literal: true

require_relative "smartpy_inteface/smartpy_wrapper"
require_relative "smartpy_inteface/micheline_serializer_wrapper"

class TezosClient
  class SmartpyInterface
    include Logger
    include SmartpyWrapper
    include MichelineSerializerWrapper

    attr_reader :options

    def json_scripts(args)
      compile_to_michelson(args) do |contract_script_filename, init_script_filename|
        micheline_contract = File.read(contract_script_filename)
        micheline_storage = convert_michelson_to_micheline(File.read(init_script_filename))

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
      def compile_to_michelson(args)
        Tools::TemporaryFile.with_file_copy(args[:script]) do |script_copy_path|
          script_basename = script_copy_path.split("/").last.sub(/.py$/, "")
          script_path = "/tmp/#{script_basename}/"
          init_script_filename = "contractStorage.tz"
          contract_script_filename = "contractCode.tz.json"
          call_smartpy ["local-compile", script_copy_path, args[:init_params], script_path]

          yield(script_path + contract_script_filename, script_path + init_script_filename)
        end
      end
  end
end
