# frozen_string_literal: true

require_relative "liquidity_inteface/liquidity_wrapper"

class TezosClient
  class LiquidityInterface
    include Logger
    include LiquidityWrapper

    attr_reader :options

    def initialize(rpc_node_address: "127.0.0.1", rpc_node_port: 8732, options: {})
      @rpc_node_address = rpc_node_address
      @rpc_node_port = rpc_node_port
      @options = options
    end

    def format_params(params)
      return [] if params.nil?
      return [params] if params.is_a? String

      params.map(&:to_s)
    end

    def initial_storage(args)
      from = args.fetch :from
      script = args.fetch :script
      init_params = args.fetch :init_params
      init_params = format_params(init_params)

      Tools::TemporaryFile.with_tempfile(".json") do |json_file|
        cmd_opt = ["--source", from.to_s,"--json", script.to_s, "-o", json_file.path.to_s, "--init-storage"] + init_params

        call_liquidity cmd_opt, verbose: options[:verbose]
        JSON.parse json_file.read.strip
      end
    end

    def json_scripts(script:)
      Tools::TemporaryFile.with_file_copy(script) do |script_copy_path|
        script_basename = script_copy_path.sub(/.liq$/, "")

        json_init_script_path = "#{script_basename}.initializer.tz.json"
        json_contract_script_path = "#{script_basename}.tz.json"

        call_liquidity ["--json", "#{script_copy_path}"]

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
      _json_init_script, json_contract_script = json_scripts(script: args[:script])

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

      cmd_opt = ["--source", "#{source}"]
      cmd_opt << "--spendable" if spendable
      cmd_opt << "--delegatable" if delegatable
      cmd_opt += ["--amount", "#{amount}tz", "#{script}", "--forge-deploy", init_params]
      res = call_liquidity cmd_opt
      res.strip
    end

    def tezos_node
      "#{@rpc_node_address}:#{@rpc_node_port}"
    end

    def get_storage(script:, contract_address:)
      res = call_liquidity ["#{script}", "--get-storage", "#{contract_address}"]
      res.strip
    end

    def call_parameters(script:, entrypoint:, parameters:)
      params = format_params parameters
      Tools::TemporaryFile.with_tempfile(".json") do |json_file|
        params = [ entrypoint ] + params
        res = call_liquidity ["--json", "-o", "#{json_file.path}", "#{script}", "--data"] + params
        JSON.parse res
      end
    end

    def liquidity_pack_data(data:, type:)
      res = call_liquidity ["--pack", "#{data}", "#{type}"]
      res.strip
    end
  end
end
