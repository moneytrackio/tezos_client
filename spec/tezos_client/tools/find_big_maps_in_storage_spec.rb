# frozen_string_literal: true

RSpec.describe TezosClient::Tools::FindBigMapsInStorage do
  subject { described_class.run!(storage: storage, storage_type: storage_type) }

  context "complexe struct" do
    let(:storage) do
      {
        prim: "Pair",
        args: [
          {
            prim: "Pair",
            args: [
              { int: "70" },
              { string: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq" }
            ]
          },
          { int: "71" }
        ]
      }
    end

    let(:storage_type) do
      {
        prim: "pair",
        args: [
          {
            prim: "pair",
            args: [
              {
                prim: "big_map",
                args: [
                  { prim: "string" },
                  {
                    prim: "pair",
                    args: [
                      { prim: "address", annots: ["%contract_address"] },
                      { prim: "key", annots: ["%contract_owner"] }
                    ]
                  }
                ],
                annots: ["%contracts"]
              },
              { prim: "address", annots: ["%owner"] }
            ]
          },
          {
            prim: "big_map",
            args: [
              { prim: "string" },
              { prim: "address" }
            ],
            annots: ["%spendings"]
          }
        ]
      }
    end

    it "return all big maps" do
      expect(subject).to eq([
        {
          name: :contracts,
          id: "70",
          value_type: {
            prim: "pair",
            args: [
              { prim: "address", annots: ["%contract_address"] },
              { prim: "key", annots: ["%contract_owner"] }
            ]
          },
          key_type: { prim: "string" }
        }.with_indifferent_access,
        {
          name: :spendings,
          id: "71",
          value_type: { prim: "address" },
          key_type: { prim: "string" }
        }.with_indifferent_access
      ])
    end
  end
end
