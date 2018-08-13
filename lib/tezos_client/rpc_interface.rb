require 'httparty'
require 'rest-client'

require_relative 'rpc_interface/monitor'
require_relative 'rpc_interface/contracts'
require_relative 'rpc_interface/context'
require_relative 'rpc_interface/helper'

class TezosClient

  class RpcInterface
    include Monitor
    include Contracts
    include Context
    include Helper

    def initialize(host: "127.0.0.1", port: "8732")
      @host = host
      @port = port
    end

    def get(path)
      url = "http://#{@host}:#{@port}/#{path}"
      response = HTTParty.get(url, options: { headers: { 'Content-Type' => 'application/json' } })
      unless response.success?
        raise "#{url} failed with code #{response.code}: #{response.parsed_response}"
      end

      response.parsed_response
    end

    def post(path, content)
      url = "http://#{@host}:#{@port}/#{path}"
      response = HTTParty.post(url,
                               body: content.to_json,
                               :headers => { 'Content-Type' => 'application/json' })
      unless response.success?
        raise "#{url} failed with code #{response.code}: #{response.parsed_response}"
      end

      response.parsed_response
    end


    def monitor(path, &chunk_reader)
      url = "http://#{@host}:#{@port}/#{path}"

      block = proc do |response|
        response.read_body do |chunk|
          chunk_reader.call(JSON.parse(chunk))
        end
      end

      Thread.new do
        RestClient::Request.execute(method: :get,
                                    url: url,
                                    block_response: block,
                                    content_type: :json,
                                    accept: :json)
      end
    end

  end

end
