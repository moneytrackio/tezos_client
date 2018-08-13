class TezosClient
  module StringUtils
    refine String do
      def to_hex
        unpack('H*')[0]
      end

      def to_bin
        [self].pack('H*')
      end

    end
  end
end
