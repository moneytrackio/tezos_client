
RSpec.describe TezosClient::Logger do

  subject { TezosClient.new }

  describe "#logger=" do
    context "pass logger class" do
      let(:logger) { [] }
      it "updates logger" do
        TezosClient.logger = logger
        expect { subject.log("hello") }.to change { logger }.from([]).to(["hello\n"])
      end
    end
    context "pass file path" do
      let(:logfile) { Tempfile.new("log") }

      after { logfile.close && logfile.unlink }

      it "updates log file" do
        TezosClient.logger = logfile.path
        expect { subject.log("hello") }.to change { logfile.rewind && logfile.read }.from("").to("hello\n")
      end
    end
  end
end