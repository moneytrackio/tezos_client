# frozen_string_literal: true

require "base58"
require "rbnacl"
require "digest"
require "money-tree"
require "bip_mnemonic"

class TezosClient
  module Crypto
    using StringUtils

    PREFIXES = {
      tz1:    [6, 161, 159],
      tz2:    [6, 161, 161],
      tz3:    [6, 161, 164],
      KT:     [2, 90, 121],
      expr:   [13, 44, 64, 27],
      edpk:   [13, 15, 37, 217],
      edsk2:  [13, 15, 58, 7],
      spsk:   [17, 162, 224, 201],
      p2sk:   [16, 81, 238, 189],
      sppk:   [3, 254, 226, 86],
      p2pk:   [3, 178, 139, 127],
      edsk:   [43, 246, 78, 7],
      edsig:  [9, 245, 205, 134, 18],
      spsig1: [13, 115, 101, 19, 63],
      p2sig:  [54, 240, 44, 52],
      sig:    [4, 130, 43],
      Net:    [87, 82, 0],
      nce:    [69, 220, 169],
      b:      [1, 52],
      o:      [5, 116],
      Lo:     [133, 233],
      LLo:    [29, 159, 109],
      P:      [2, 170],
      Co:     [79, 179],
      id:     [153, 103]
    }.freeze

    WATERMARK = {
      block: "01",
      endorsement: "02",
      generic: "03"
    }.freeze

    def hex_prefix(type)
      PREFIXES[type].pack("C*").to_hex
    end

    def decode_base58(base58_val)
      bin_val = Base58.base58_to_binary(base58_val, :bitcoin)
      bin_val.to_hex
    end

    def encode_base58(hex_val)
      bin_val = hex_val.to_bin
      Base58.binary_to_base58(bin_val, :bitcoin)
    end

    def checksum(hex)
      b = hex.to_bin
      Digest::SHA256.hexdigest(Digest::SHA256.digest(b))[0...8]
    end

    def get_prefix_and_payload(str)
      PREFIXES.keys.each do |prefix|
        if str.start_with? hex_prefix(prefix)
          return prefix, str[(hex_prefix(prefix).size) .. -1]
        end
      end
    end

    def decode_tz(str)
      decoded = decode_base58 str

      unless checksum(decoded[0...-8]) != decoded[0...-8]
        raise "invalid checksum for #{str}"
      end

      prefix, payload = get_prefix_and_payload(decoded[0...-8])

      yield(prefix, payload) if block_given?

      payload
    end

    def encode_tz(prefix, str)
      prefixed = hex_prefix(prefix) + str
      checksum = checksum(prefixed)

      encode_base58(prefixed + checksum)
    end

    def secret_key_to_public_key(secret_key)
      signing_key = signing_key(secret_key)
      verify_key = signing_key.verify_key
      hex_pubkey = verify_key.to_s.to_hex
      encode_tz(:edpk, hex_pubkey)
    end

    def public_key_to_address(public_key)
      hex_public_key = decode_tz(public_key) do |type, _key|
        raise "invalid public key: #{public_key} " unless type == :edpk
      end

      hash = RbNaCl::Hash::Blake2b.digest(hex_public_key.to_bin, digest_size: 20)
      hex_hash = hash.to_hex

      encode_tz(:tz1, hex_hash)
    end

    def generate_key(mnemonic: nil, password: nil, wallet_seed: nil, path: nil)
      signing_key = generate_signing_key(mnemonic: mnemonic, password: password, wallet_seed: wallet_seed, path: path).to_bytes.to_hex

      secret_key = encode_tz(:edsk2, signing_key)
      public_key = secret_key_to_public_key(secret_key)
      address = public_key_to_address(public_key)

      {
        secret_key: secret_key,
        public_key: public_key,
        address: address,
        path: path
      }
    end

    def edsk2_to_edsk(edsk2key)
      signing_key = signing_key(edsk2key)
      keypair_hex = signing_key.keypair_bytes.to_hex
      encode_tz(:edsk, keypair_hex)
    end

    def generate_mnemonic
      BipMnemonic.to_mnemonic(nil)
    end

    def signing_key(secret_key)
      secret_key = decode_tz(secret_key) do |type, _key|
        raise "invalid secret key: #{secret_key} " unless [:edsk, :edsk2].include? type
      end

      RbNaCl::SigningKey.new(secret_key.to_bin[0..31])
    end

    def sign_bytes(secret_key:, data:, watermark: nil)
      watermarked_data = if watermark.nil?
        data
      else
        WATERMARK[watermark] + data
      end

      hash = RbNaCl::Hash::Blake2b.digest(watermarked_data.to_bin, digest_size: 32)

      signing_key = signing_key(secret_key)
      bin_signature = signing_key.sign(hash)

      edsig = encode_tz(:edsig, bin_signature.to_hex)
      signed_data = data + bin_signature.to_hex

      if block_given?
        yield(edsig, signed_data)
      else
        edsig
      end
    end

    def operation_id(signed_operation_hex)
      hash = RbNaCl::Hash::Blake2b.digest(
        signed_operation_hex.to_bin,
        digest_size: 32
      )
      encode_tz(:o, hash.to_hex)
    end


    def sign_operation(secret_key:, operation_hex:)
      sign_bytes(secret_key: secret_key,
                 data: operation_hex,
                 watermark: :generic) do |edsig, signed_data|
        op_id = operation_id(signed_data)

        if block_given?
          yield(edsig, signed_data, op_id)
        else
          edsig
        end
      end
    end

    def decode_account_wallet(wallet)
      wallet_config = JSON.load(wallet).with_indifferent_access

      mnemonic = wallet_config[:mnemonic].join(" ")
      password = "#{wallet_config[:email]}#{wallet_config[:password]}"
      key = generate_key(mnemonic: mnemonic, password: password)
      key.merge(activation_secret: wallet_config[:secret])
    end

    def encode_script_expr(data:, type:)
      packed_key = pack_data(data: data, type: type)
      raw_expr_key = RbNaCl::Hash::Blake2b.digest(packed_key["packed"].to_bin, digest_size: 32).to_hex
      encode_tz(:expr, raw_expr_key)
    end

    private
      def generate_signing_key(mnemonic: nil, password: nil, wallet_seed: nil, path: nil)
        if mnemonic
          # ensure mnemonic validity
          BipMnemonic.to_entropy(mnemonic: mnemonic)
          wallet_seed = BipMnemonic.to_seed(mnemonic: mnemonic, password: password)
        end
        if path && wallet_seed
          master = MoneyTree::Master.new seed_hex: wallet_seed
          node = master.node_for_path path
          node.private_key
        elsif wallet_seed
          RbNaCl::SigningKey.new(wallet_seed.to_bin[0...32])
        else
          RbNaCl::SigningKey.generate
        end
      end
  end
end
