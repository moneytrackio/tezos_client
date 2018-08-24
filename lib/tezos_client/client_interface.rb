# frozen_string_literal: true

require_relative "client_interface/client_wrapper"
require_relative "client_interface/misc"
require_relative "client_interface/key"
require_relative "client_interface/contract"
require_relative "client_interface/block_contextual"

class TezosClient
  class ClientInterface
    attr_reader :config_file

    include Logger

    include ClientWrapper
    include Misc
    include Key
    include Contract
    include BlockContextual

    def initialize(config_file: nil)
      @config_file = config_file
    end
  end
end
