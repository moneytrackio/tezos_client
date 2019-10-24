# frozen_string_literal: true

RSpec.describe TezosClient::Crypto do
  subject { TezosClient.new }

  describe "#generate_key" do
    it "generates keys" do
      key = subject.generate_key
      puts key
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
          expect(key[:address]).to eq "tz1ULB19s3BXyXkYL5M6i7VWXspWuxqQk3Xq"
          key = subject.generate_key(wallet_seed: wallet_seed, path: "m/44'/1729'/0'/0'/1'")
          expect(key[:address]).to eq "tz1UTikevS42TFpT4uhtxkNbeYsG3ea7bsrB"
        end
      end

      context "with mnemonic and path" do
        let(:mnemonic) { "below dove cushion divide future artefact orange congress maple fiscal flower enable" }
        it "generates keys" do
          key = subject.generate_key(mnemonic: mnemonic, path: "m/44'/1729'/0'/0'/0'")
          expect(key[:address]).to eq "tz1TxN95o3i97ZMpTTwfy3vh4Y6eqwUwyLK1"
        end
      end

      context "with mnemonic" do
        let(:mnemonic) { "build sadness song umbrella entire step giraffe muffin embody funny shove use boat eyebrow width" }
        let(:password) { "uzluxros.hxitrvda@tezos.example.orgrghSrg6WJG".encode("utf-8") }
        it "generates keys" do
          key = subject.generate_key(mnemonic: mnemonic, password: password)
          expect(key[:address]).to eq "tz1QfnpcAcKaVs8nQ1YDVGafBRd6WFUvjiX5"
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

  describe "secret_key_to_public_key" do
    let(:secret_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:expected_public_key) { "edpkugJHjEZLNyTuX3wW2dT4P7PY5crLqq3zeDFvXohAs3tnRAaZKR" }

    it "computes the public key" do
      public_key = subject.secret_key_to_public_key(secret_key)
      expect(public_key).to eq expected_public_key
    end
  end

  describe "public_key_to_address" do
    let(:public_key) { "edpkugJHjEZLNyTuX3wW2dT4P7PY5crLqq3zeDFvXohAs3tnRAaZKR" }
    let(:expected_address) { "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }

    it "computes the public key" do
      address = subject.public_key_to_address(public_key)
      expect(address).to eq expected_address
    end
  end

  describe "generate_mnemonic" do
    it "generates a random mnemonic" do
      mnemonic = subject.generate_mnemonic
      expect(mnemonic).to be_a String
    end
  end

  describe "decode_account_wallet" do
    let(:wallet_path) { Pathname.new(File.expand_path("./spec/fixtures/account.json")) }
    let(:wallet_string) { File.read(File.expand_path("./spec/fixtures/account.json")) }

    it "reads a wallet file" do
      key = subject.decode_account_wallet(wallet_path)
      expect(key).to be_a Hash
      expect(key).to have_key :address
      expect(key).to have_key :secret_key
    end

    it "accepts a string" do
      key = subject.decode_account_wallet(wallet_string)
      expect(key).to be_a Hash
      expect(key).to have_key :address
      expect(key).to have_key :secret_key
      expect(key).to have_key :activation_secret
    end
  end

  describe "#edsk2_to_edsk" do
    let(:edsk2_key) { "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN" }
    let(:pubkey) { "edpkugJHjEZLNyTuX3wW2dT4P7PY5crLqq3zeDFvXohAs3tnRAaZKR" }

    it "has the correct pubkey" do
      edsk_key = subject.edsk2_to_edsk(edsk2_key)
      expect(subject.secret_key_to_public_key(edsk_key)).to eq pubkey
    end

    it "has the same public key" do
      edsk_key = subject.edsk2_to_edsk(edsk2_key)
      expect(subject.secret_key_to_public_key(edsk_key)).to eq subject.secret_key_to_public_key(edsk2_key)
    end
  end
end
