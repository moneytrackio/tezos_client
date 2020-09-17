# frozen_string_literal: true

RSpec.describe TezosClient::Tools::AnnotsToType do
  subject { described_class.run(typed_annots: typed_annots) }

  context "when typed_annots is valid" do
    context "when typed_annots contains one element" do
      let(:typed_annots) { { spending_ref: "string" } }

      it "returns a valid result" do
        expect(subject.result).to eq({ "prim" => "string" })
      end
    end

    context "when typed_annots contains multiple elements" do
      let(:typed_annots) do
        {
          spending_ref: "string",
          expires_at: "timestamp",
          payload: "bytes",
          id: "string"
        }
      end

      it "returns a valid result" do
        expect(subject.result).to(
          eq(
            { "prim"=>"pair",
               "args"=>
                [
                  {
                    "prim"=>"timestamp",
                    "annots"=>["%expires_at"]
                  },
                  {
                    "prim"=>"pair",
                    "args"=>
                      [
                        {
                          "prim"=>"string",
                          "annots"=>["%id"]
                        },
                        {
                          "prim"=>"pair",
                          "args"=>[
                            {
                              "prim"=>"bytes",
                              "annots"=>["%payload"]
                            },
                            {
                              "prim"=>"string",
                              "annots"=>["%spending_ref"]
                            }
                          ]
                        },
                      ]
                  }
                ]
            }
          )
        )
      end
    end
  end

  context "when typed_annots contains a forbidden type" do
    let(:typed_annots) { { spending_ref: "string", payload: "natural" } }

    it "is invalid" do
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["The allowed types are: int, nat, string, signature, bytes, timestamp, key, address"]
    end
  end
end
