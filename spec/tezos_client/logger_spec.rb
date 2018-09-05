
RSpec.describe TezosClient::Logger do

  subject { TezosClient.new }

  class FileLogger
    def initialize(path)
      @target_file = path
    end

    def <<(obj)
      File.open(@target_file, "a") { |f| f.puts obj }
    end
  end

  let(:logfile) { Tempfile.new("log") }
  let(:logger) do
    FileLogger.new(logfile.path)
  end
  describe "#logger=" do
    it "writes in log file" do
      TezosClient.logger = logger
      expect { subject.log("hello") }.to change { logfile.rewind && logfile.read }.from("").to("hello\n")
    end
  end
end