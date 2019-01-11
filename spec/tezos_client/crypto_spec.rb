# frozen_string_literal: true

RSpec.describe TezosClient::Crypto do
  subject { TezosClient.new }

  describe "#generate_key" do
    it "generates keys" do
      key = subject.generate_key
      expect(key).to be_a Hash
    end

    it "generates correct secret key" do
      key = subject.generate_key
      secret_key = key[:secret_key]

      expect(secret_key).to be_a String
      expect(secret_key).to start_with "edsk"
    end

    it "generates correct public key" do
      key = subject.generate_key
      public_key = key[:public_key]

      expect(public_key).to be_a String
      expect(public_key).to start_with "edpk"
    end

    it "generates correct address" do
      key = subject.generate_key
      address = key[:address]

      expect(address).to be_a String
      expect(address).to start_with "tz1"
    end

    context "from path" do
      context "with seed" do
        let(:wallet_seed) { "000102030405060708090a0b0c0d0e0f" }
        it "generates keys" do
          key = subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/0'")
          expect(key[:address]).to eq "tz1RfnzRopJXH32SSDap2wMYGULBAnmHxdP1"
          key = subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/1'")
          expect(key[:address]).to eq "tz1gxKJCyZ3wnoRsGVcWvEtdu1q4hK4MiQVr"
        end
      end

      context "with mnemonic" do
        let(:mnemonic) { "below dove cushion divide future artefact orange congress maple fiscal flower enable" }
        it "generates keys" do
          key = subject.generate_key(mnemonic: mnemonic, path: "m/44'/1729'/0'/0'/0'")
          expect(key[:address]).to eq "tz1NBk9mG7F4jsf76rjES6WqVo3Ah8aZUYKM"
        end
      end
    end
  end
  # puppy hundred squirrel border crystal then eye immense chat view flock mystery
  describe "#sign_bytes" do
    let(:secret_key) { "edsk3r9ipNNemnVamKsJzggijP9tQUcnu8YLaJhEbdMzV1Jq7kkJWC" }
    let(:expected_signature) { "edsigtp4wchrxPLWscwNQKyUssJixap4njeS3keCTwphwhx4MkQaFn8GfXkCJtk8vi5uV2ahrdS5YWc3qeC74awqWTGJfngKGrs" }
    let(:data) { "1234" }

    it "signs the data" do
      signature = subject.sign_bytes(secret_key: secret_key, data: data)
      expect(signature).to eq expected_signature
    end
  end
end
