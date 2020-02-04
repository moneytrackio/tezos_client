# frozen_string_literal: true

class TezosClient
  class SmartpyInterface
    module MichelineSerializerWrapper
      def convert_michelson_to_micheline(script)
        cmd = ["michelson-to-micheline", script]

        Tools::SystemCall.execute(cmd)
      end

      def actual_project_path
        TezosClient.root_path
      end
    end
  end
end