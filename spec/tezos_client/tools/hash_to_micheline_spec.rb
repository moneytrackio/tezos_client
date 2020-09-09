# frozen_string_literal: true

RSpec.describe TezosClient::Tools::HashToMicheline do
  subject { described_class.run(params) }

  context "when the params are valid" do
    context "when storage_type is provided" do
      context "when there is multiple parameters" do
        let(:params) do
          {
            storage_type: { "prim"=>"pair",
                 "args"=>
                  [{ "prim"=>"pair",
                     "args"=>
                        [{ "prim"=>"pair", "args"=>[
                          { "prim"=>"timestamp", "annots"=>["%expires_at"] }, { "prim"=>"string", "annots"=>["%id"] }
                        ] },
                   { "prim"=>"bytes", "annots"=>["%payload"] }] },
                   { "prim"=>"string", "annots"=>["%spending_ref"] }] },
            params: {
                     payload: "payload",
                     spending_ref: "spending_ref",
                     id: "id",
                     expires_at: Time.current
                   }
          }
        end

        it "returns a valid micheline" do
          expect(subject.result).to eq(
            { prim: "Pair",
             args: [
               { prim: "Pair", args: [
                 { prim: "Pair", args: [{ int: params[:params][:expires_at].to_i.to_s }, { string: "id" }] },
                 { bytes: "payload" }
               ] }, { string: "spending_ref" }] }
          )
        end

        it "doesnt call TezosClient#entrypoint" do
          expect_any_instance_of(TezosClient).not_to receive(:entrypoint)

          subject
        end
      end

      context "when there is only one parameter" do
        let(:params) do
          {
            storage_type: { "prim" => "string" },
            params: {
              payload: "payload"
            }
          }
        end

        it "returns a valid micheline" do
          expect(subject.result).to eq({ string: "payload" })
        end
      end
    end

      context "when storage_type is not provided" do
        let(:params) {
          {
            contract_address: "KT1234567890",
            entrypoint: "my_entrypoint",
            params: {
              payload: "payload"
            }
          }
        }

        before { allow_any_instance_of(TezosClient).to receive(:entrypoint).and_return({ prim: "string" }) }

        context "with many entrypoint" do
          before do
            allow_any_instance_of(TezosClient).to receive(:entrypoints).and_return({
              "entrypoints" => {
                  params[:entrypoint] => { prim: "string" },
                  "other_entrypoint" => { prim: "string" },
              }
            })
          end

          it "calls TezosClient#entrypoint with valid params" do
            expect_any_instance_of(TezosClient).to receive(:entrypoint)
                                                       .with(params[:contract_address], params[:entrypoint])

            subject
          end

          it "returns a valid micheline" do
            expect(subject.result).to eq({ string: params[:params][:payload] })
          end
        end

        context "with one entrypoint" do
          before do
            allow_any_instance_of(TezosClient).to receive(:entrypoints).and_return({
              "entrypoints" => {}
            })
          end

          it "calls TezosClient#entrypoint with valid params" do
            expect_any_instance_of(TezosClient).to receive(:entrypoint)
              .with(params[:contract_address], params[:entrypoint])

            subject
          end

          it "returns a valid micheline" do
            expect(subject.result).to eq({ string: params[:params][:payload] })
          end
        end
      end
    end

    context "when only contract_address and params are provided" do
      let(:params) {
        {
          contract_address: "KT1234567890",
          params: {
            payload: "payload"
          }
        }
      }

      before do
        allow_any_instance_of(TezosClient).to receive(:entrypoint).and_return({ prim: "string" })
        allow_any_instance_of(TezosClient).to receive(:entrypoints).and_return({
          "entrypoints" => {}
        })
      end

      it "calls TezosClient#entrypoint with valid params and default entrypoint" do
        expect_any_instance_of(TezosClient).to receive(:entrypoint)
                                                   .with(params[:contract_address], "default")

        subject
      end

      it "returns a valid micheline" do
        expect(subject.result).to eq({ string: params[:params][:payload] })
      end
    end
  end

  context "when the params are invalid" do
    context "when storage_type, contract_address and entrypoint are provided" do
      let(:params) do
        {
          contract_address: "KT1234567890",
          entrypoint: "my_entrypoint",
          params: {
            payload: "payload"
          },
          storage_type: { "prim" => "string" }
        }
      end

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to eq ["You should provide the contract_address and the entrypoint only if storage_type is not provided"]
      end
    end

    context "when a timestamp parameter is not an instance of Time" do
      let(:params) do
        {
          params: {
            expires_at: 1594386282
          },
          storage_type: { "prim" => "timestamp" }
        }
      end

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to eq ["timestamp input must be an instance of Time"]
      end
    end

    context "when a key in the params is not found in the storage_type" do
      let(:params) do
        {
          params: {
            expires_at: Time.now,
            spending_ref: "spending_ref"
          },
          storage_type: {
            prim: "pair", args: [{ "prim" => "timestamp", annots: ["%expiration_date"] }, { "prim" => "string", annots: ["%spending_ref"] } ]
          }
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error KeyError, /key not found: "expiration_date"/
      end
    end
  end
end
