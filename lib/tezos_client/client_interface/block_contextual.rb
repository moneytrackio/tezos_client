class TezosClient
  class ClientInterface
    # Commands managing keys and accounts
    module BlockContextual
      def transfer(quantity:, from:, to:, dry_run: false, arg: nil)
        cmd = "transfer #{quantity} from #{from} to #{to}"
        cmd = "#{cmd} --dry-run" if dry_run
        cmd = "#{cmd} --arg #{arg}" unless arg.nil?

        res = call_client(cmd)
      end
    end
  end
end