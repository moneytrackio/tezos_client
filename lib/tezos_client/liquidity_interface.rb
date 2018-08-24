# frozen_string_literal: true

require_relative "liquidity_inteface/liquidity_wrapper"

class TezosClient
  class LiquidityInterface
    include Logger
    include LiquidityWrapper

    def initialize(rpc_node_address: "127.0.0.1", rpc_node_port: 8732)
      @rpc_node_address = rpc_node_address
      @rpc_node_port = rpc_node_port
    end

    def format_params(params)
      params = [params] if params.is_a? String
      params.map { |s| "'#{s}'" }.join(" ")
    end

    def initial_storage(args)
      from = args.fetch :from
      script = args.fetch :script
      init_params = args.fetch :init_params
      init_params = format_params(init_params)

      res = call_liquidity "--source #{from} --json --init-storage #{script} #{init_params}"
      JSON.parse res.strip
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

    def json_scripts(args)
      with_file_copy(args[:script]) do |script_copy_path|
        json_init_script_path = "#{script_copy_path}.initializer.tz.json"
        json_contract_script_path = "#{script_copy_path}.tz.json"

        call_liquidity "--json #{script_copy_path}"

        json_contract_script_file = File.open(json_contract_script_path)
        json_contract_script = JSON.parse(json_contract_script_file.read)
        json_contract_script_file.close

        if File.exists? json_init_script_path
          json_init_script_file = File.open(json_init_script_path)
          json_init_script = JSON.parse(json_init_script_file.read)
          json_init_script_file.close
        end

        if block_given?
          yield(json_init_script, json_contract_script)
        else
          return json_init_script, json_contract_script
        end

      ensure
        [json_init_script_path, json_contract_script_path].each do |file_path|
          File.delete file_path if File.exists? file_path
        end
      end
    end

    def origination_script(args)
      storage = initial_storage(args)
      _json_init_script, json_contract_script = json_scripts(args)

      {
        code: json_contract_script,
        storage: storage
      }
    end

    def forge_deploy(args)
      amount = args.fetch(:amount, 0)
      spendable = args.fetch(:spendable, false)
      delegatable = args.fetch(:delegatable, false)
      source = args.fetch :from
      script = args.fetch :script
      init_params = args.fetch :init_params

      res = call_liquidity "--source #{source} #{spendable ? '--spendable' : ''} #{delegatable ? '--delegatable' : ''} --amount #{amount}tz --forge-deploy #{script} '#{init_params}'"
      res.strip
    end

    def tezos_node
      "#{@rpc_node_address}:#{@rpc_node_port}"
    end

    def get_storage(script:, contract_address:)
      res = call_liquidity "--get-storage #{script} #{contract_address}"
      res.strip
    end

    def call_parameters(script:, parameters:)
      parameters = format_params(parameters)
      res = call_liquidity "--json --data #{script} #{parameters}"
      JSON.parse res.strip
    end
  end
end
