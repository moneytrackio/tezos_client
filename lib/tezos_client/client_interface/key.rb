# frozen_string_literal: true

class TezosClient
  class ClientInterface
    # Commands managing keys and accounts
    module Key
      def gen_keys(name)
        call_client("gen keys #{name}")
      end

      def addresses
        output = call_client("list known addresses")
        output.lines.reduce({}) do |acc, address_output|
          address_format = /([^:]+): (\w+) /
          res = address_format.match(address_output)
          acc.merge(res[1] => res[2])
        end
      end

      def import_public_key(name, public_key, force: false)
        cmd = "import public key #{name} #{public_key}"
        cmd = "#{cmd} --force" if force

        call_client(cmd)
      end

      def import_secret_key(name, secret_key, force: false)
        cmd = "import secret key #{name} #{secret_key}"
        cmd = "#{cmd} --force" if force

        call_client(cmd)
      end
    end
  end
end
