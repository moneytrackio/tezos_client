# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module RequestManager
      def get(path)
        url = "http://#{@host}:#{@port}/#{path}"
        response = HTTParty.get(url, options: { headers: { "Content-Type" => "application/json" } })
        formatted_response = format_response(response.parsed_response)

        log("-------")
        log(">>> GET #{url} \n")
        log("<<< code: #{response.code} \n #{formatted_response.pretty_inspect}")
        log("-------")
        unless response.success?
          raise "#{url} failed with code #{response.code}: #{formatted_response.pretty_inspect}"
        end

        formatted_response
      end

      def post(path, content)
        url = "http://#{@host}:#{@port}/#{path}"
        response = HTTParty.post(url,
                                 body: content.to_json,
                                 headers: { "Content-Type" => "application/json" })

        formatted_response = format_response(response.parsed_response)

        log("-------")
        log(">>> POST #{url} \n #{content.pretty_inspect}")
        log("<<< code: #{response.code} \n #{formatted_response.pretty_inspect}")
        log("-------")

        unless response.success?
          raise "#{url} failed with code #{response.code}:\n #{formatted_response.pretty_inspect}"
        end

        formatted_response
      end

      def monitor(path, &event_handler)
        uuid = SecureRandom.uuid

        url = "http://#{@host}:#{@port}/#{path}"

        event_reader = monitor_event_reader(uuid, event_handler)

        Thread.new do
          log("Monitor #{uuid}: Start monitoring GET #{url}")
          RestClient::Request.execute(method: :get,
                                      url: url,
                                      block_response: event_reader,
                                      content_type: :json,
                                      accept: :json)
        end
      end

      private

      def monitor_event_reader(uuid, event_handler)
        proc do |event_response|
          event_response.read_body do |event_json|
            event = format_response(JSON.parse(event_json))
            log("Monitor #{uuid}: received chunk #{event.pretty_inspect}")
            event_handler.call(event)
          end
        end
      end

      def format_response(response)
        if response.is_a? Array
          response.map do |el|
            (el.is_a? Hash) ? el.with_indifferent_access : el
          end
        elsif response.is_a? Hash
          response.with_indifferent_access
        else
          response
        end
      end
    end
  end
end