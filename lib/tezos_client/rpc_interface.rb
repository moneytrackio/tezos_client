# frozen_string_literal: true

require "httparty"
require "rest-client"

require_relative "rpc_interface/monitor"
require_relative "rpc_interface/contracts"
require_relative "rpc_interface/context"
require_relative "rpc_interface/helper"
require_relative "rpc_interface/operations"
require_relative "rpc_interface/request_manager"
require_relative "rpc_interface/blocks"

class TezosClient
  class RpcInterface
    include Logger
    include Monitor
    include Contracts
    include Context
    include Helper
    include Operations
    include RequestManager
    include Blocks

    def initialize(host: "127.0.0.1", port: "8732", http_client: ::HTTParty)
      @host = host
      @port = port
      @http_client = http_client
    end
  end
end
