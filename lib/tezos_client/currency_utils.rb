# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/util"

class TezosClient
  module CurrencyUtils
    TEZOS_SATOSHI = 1000000.0

    refine Numeric do
      def from_satoshi
        self.to_d / TEZOS_SATOSHI
      end

      def to_satoshi
        (self * TEZOS_SATOSHI).to_i
      end
    end
  end
end
