# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module RequestManager
      def get(path, query: {})
        url = "http://#{@host}:#{@port}/#{path}"
        response = nil
        exec_time = Benchmark.realtime do
          response = HTTParty.get(url, headers: { "Content-Type" => "application/json" }, query: query)
        end
        formatted_response = format_response(response.parsed_response)

        log("-------")
        log(">>> GET #{response.request.uri.to_s} \n")
        log("<<< code: #{response.code} \n    exec time: #{exec_time}\n #{tezos_contents_log(formatted_response)}")
        log("-------")
        unless response.success?
          failed!(url: url, code: response.code, responses: formatted_response)
        end

        formatted_response
      end

      def post(path, content)
        url = "http://#{@host}:#{@port}/#{path}"

        response = nil
        exec_time = Benchmark.realtime do
          response = HTTParty.post(url,
                                   body: content.to_json,
                                   headers: { "Content-Type" => "application/json" })
        end

        formatted_response = format_response(response.parsed_response)

        log("-------")
        log(">>> POST #{url} \n #{tezos_contents_log(content)}")
        log("<<< code: #{response.code} \n    exec time: #{exec_time} \n #{tezos_contents_log(formatted_response)}")
        log("-------")

        unless response.success?
          failed!(url: url, code: response.code, responses: formatted_response)
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
                                      read_timeout: 60 * 60 * 24 * 365,
                                      url: url,
                                      block_response: event_reader,
                                      content_type: :json,
                                      accept: :json)
        rescue => e
          log "#{uuid}: failed with error #{e}"
          raise
        end
      end

      private

      def get_error_id(error)
        error[:id]
      rescue TypeError, NoMethodError
        nil
      end

      def exception_klass(error)
        case get_error_id(error)
        when /proto\.[^.]*\.operation\.invalid_activation/
          TezosClient::InvalidActivation
        when /proto\.[^.]*\.contract\.previously_revealed_key/
          TezosClient::PreviouslyRevealedKey
        else
          TezosClient::RpcRequestFailure
        end
      end

      def failed!(url:, code:, responses:)
        error = responses.is_a?(Array) ? responses[0] : responses
        raise exception_klass(error).new(
          error: error,
          url: url,
          status_code: code
        )
      end

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