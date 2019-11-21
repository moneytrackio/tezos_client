# frozen_string_literal: true

require_relative "smartpy_inteface/smartpy_wrapper"
require_relative "smartpy_inteface/entry_point_serializer_wrapper"
require_relative "smartpy_inteface/micheline_serializer_wrapper"

class TezosClient
  class SmartpyInterface
    include Logger
    include SmartpyWrapper
    include MichelineSerializerWrapper
    include EntryPointSerializerWrapper

    attr_reader :options

    def json_scripts(args)
      compile_to_michelson(args) do |contract_script_filename, init_script_filename|
        micheline_contract = convert_michelson_to_micheline(read_file(contract_script_filename))
        micheline_storage = convert_michelson_to_micheline(read_file(init_script_filename))

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
      with_file_copy(args[:script]) do |script_copy_path|
        script_basename = script_copy_path.split("/").last.sub(/.py$/, "")
        script_path = "/tmp/#{script_basename}/"
        init_script_filename = "contractStorage.tz"
        contract_script_filename = "contractCode.tz"
        call_smartpy ["local-compile", script_copy_path, args[:init_params], script_path]

        yield(script_path + contract_script_filename, script_path + init_script_filename)
      end
    end

    def with_tempfile(extension)
      file = Tempfile.new(["script", extension])
      yield(file)

    ensure
      file.unlink
    end

    def with_file_copy(source_file_path)
      source_file = File.open(source_file_path, "r")
      source_extention = File.extname(source_file_path)

      file_copy_path = nil

      res = with_tempfile(source_extention) do |file_copy|
        file_copy.write(source_file.read)
        file_copy_path = file_copy.path
        file_copy.close
        yield(file_copy_path)
      end

      res
    ensure
      File.delete(file_copy_path) if File.exists? file_copy_path
    end

    def read_file(filename)
      file = File.open(filename)
      file_data = file.read
      file.close
      file_data
    end
  end
end
