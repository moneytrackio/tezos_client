# frozen_string_literal: true

RSpec.describe TezosClient::Tools::ConvertToHash do
  subject { described_class.run!(data: data, type: type) }

  context "complexe struct" do
    let(:data) do
      {
        "prim": "Pair",
        "args": [
          { "bytes": "00886860e486f58c10f8f01d2dac7853f0cc5266deab1e275b287ecae9e4dec586" },
          [
            {
              "prim": "Pair",
              "args": [
                {
                  "prim": "Pair",
                  "args": [
                    {
                      "prim": "Pair",
                      "args": [
                        {
                          "prim": "Pair",
                          "args": [
                            { "int": "1579877725" },
                            { "int": "60" }
                          ]
                        },
                        { "string": "MTK-Practitioner-txrsh" }
                      ]
                    },
                    { "int": "10" }
                  ]
                },
                { string: "Spending--001" }
              ]
            }
          ]
        ]
      }
    end
    let(:type) do
      {
        "prim": "pair",
        "args": [
            {
                "prim": "key",
                "annots": ["%pub_key"]
            },
            {
              "prim": "list",
              "args": [
                {
                  "prim": "pair",
                  "args": [
                    {
                      "prim": "pair",
                      "args": [
                        {
                          "prim": "pair",
                          "args": [
                            {
                              "prim": "pair",
                              "args": [
                                { "prim": "timestamp", "annots": ["%date"] },
                                { "prim": "int", "annots": ["%practitioner_price"] }
                              ]
                            },
                            { "prim": "string", "annots": ["%practitioner_ref"] }
                          ]
                        },
                        { "prim": "int", "annots": ["%remainder_amount"] }
                      ]
                    },
                    { "prim": "string", "annots": ["%spending_ref"] }
                  ]
                }
              ], "annots": ["%spendings"]
          }
        ]
      }
    end


    it "convert data to simple hash" do
      expect(subject).to eq(
        pub_key: "00886860e486f58c10f8f01d2dac7853f0cc5266deab1e275b287ecae9e4dec586",
        spendings: [
          {
            date: Time.zone.parse("2020-01-24 14:55:25 +0000"),
            practitioner_price: 60,
            practitioner_ref: "MTK-Practitioner-txrsh",
            remainder_amount: 10,
            spending_ref: "Spending--001"
          }
        ]
      )
    end
  end
end
