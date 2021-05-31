# frozen_string_literal: true

RSpec.describe TezosClient::Tools::ConvertToHash do
  subject { described_class.run!(data: data, type: type) }

  before do
    Time.zone = "UTC"
  end
  context "convert timestamp" do
    let(:type) do
      { prim: "timestamp" }
    end

    context "with date data format: timestamp(integer)" do
      let(:data) do
        { int: 1614620399 }
      end

      it "returns the correct value" do
        expect(subject).to eq(Time.zone.at(1614620399))
      end
    end

    context "with date data format: timestamp(integer)" do
      let(:data) do
        { string: "1614620399" }
      end

      it "returns the correct value" do
        expect(subject).to eq(Time.zone.at(1614620399))
      end
    end

    context "with date data format: timestamp(integer)" do
      let(:data) do
        { string: "2021-03-02 11:07:53" }
      end

      it "returns the correct value" do
        expect(subject).to eq(Time.zone.parse("2021-03-02 11:07:53"))
      end
    end
  end

  context "anonymous string" do
    let(:data) do
      { string: "Spending--001" }
    end

    let(:type) do
      { prim: "string" }
    end

    it "returns the correct value" do
      expect(subject).to eq("Spending--001")
    end
  end

  context "anonymous list" do
    let(:data) do
      [
        {
          "prim": "Pair",
          "args": [
            { "string": "MTK-Practitioner-txrsh" },
            { string: "Spending--001" }
          ]
        },
        {
          "prim": "Pair",
          "args": [
            { "string": "MTK-Practitioner-2" },
            { string: "Spending--002" }
          ]
        }
      ]
    end
    let(:type) do
      {
        "prim": "list",
        "args": [
          {
            "prim": "pair",
            "args": [
              { "prim": "string", "annots": ["%practitioner_ref"] },
              { "prim": "string", "annots": ["%spending_ref"] }
            ]
          }
        ]
      }
    end

    it "returns the correct value" do
      expect(subject).to eq(
        [
          { practitioner_ref: "MTK-Practitioner-txrsh", spending_ref: "Spending--001" },
          { practitioner_ref: "MTK-Practitioner-2", spending_ref: "Spending--002" }
        ]
      )
    end
  end

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
                            { "int": "9876543" },
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
        pub_key: "edpkugJHjEZLNyTuX3wW2dT4P7PY5crLqq3zeDFvXohAs3tnRAaZKR",
        spendings: [
          {
            date: Time.zone.parse("1970-04-25 07:29:03.000000000 +0000"),
            practitioner_price: 60,
            practitioner_ref: "MTK-Practitioner-txrsh",
            remainder_amount: 10,
            spending_ref: "Spending--001"
          }
        ]
      )
    end
  end

  context "with big maps" do
    let(:data) do
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

    let(:type) do
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
      expect(subject).to match hash_including(
        contracts: TezosClient::BigMap.new(
          :contracts,
           "70",
           {
             prim: "pair",
             args: [
               { prim: "address", annots: ["%contract_address"] },
               { prim: "key", annots: ["%contract_owner"] }
             ]
           },
           { prim: "string" }
        ),
        spendings: TezosClient::BigMap.new(
          :spendings,
          "71",
          { prim: "address" },
          { prim: "string" }
        )
       )
    end
  end

  context "with big maps" do
    let(:type) do
      {
        prim: "pair",
        args: [
          { prim: "key", annots: ["%pub_key"] },
          {
            prim: "map",
            args: [
              { prim: "string" },
              {
                prim: "pair",
                args: [
                  {
                    prim: "pair",
                    args: [
                      {
                        prim: "pair",
                        args: [
                          { prim: "timestamp", annots: ["%date"] },
                          { prim: "nat", annots: ["%practitioner_price"] }
                        ]
                      },
                      { prim: "string", annots: ["%practitioner_ref"] }
                    ]
                  },
                  { prim: "nat", annots: ["%remainder_amount"] }
                ]
              }
            ],
            annots: ["%spendings"]
          }
        ]
      }
    end

    context "with empty map" do
      let(:data) do
        {
          prim: "Pair",
          args: [
            { string: "edpkvH2XCYHmU2cpJxzQxzaJ9iMfmvkvSixFsEE1KqEmXBQeFq78PT" },
            []
          ]
        }
      end

      it "return maps" do
        expect(subject).to eq(
          pub_key: "edpkvH2XCYHmU2cpJxzQxzaJ9iMfmvkvSixFsEE1KqEmXBQeFq78PT",
          spendings: {}
        )
      end
    end

    context "with element in map" do
      let(:data) do
        {
          "prim": "Pair",
          "args": [
            { "string": "edpkvWLnfNsAKhWEDafxHaTmE8qtK19fSDJYAnLfg7J5Qf5jbkKgTW" },
            [
              {
                "prim": "Elt",
                "args": [
                  { "string": "Spending--001" },
                  {
                    "prim": "Pair",
                    "args": [
                      {
                        "prim": "Pair",
                        "args": [
                          {
                            "prim": "Pair",
                            "args": [
                              { "string": "2020-04-27T13:48:28Z" },
                              { "int": "6000" }
                            ]
                          },
                          { "string": "HEALTH_PRACTITIONER_EG4WA" }
                        ]
                      },
                      { "int": "1000" }
                    ]
                  }
                ]
              }
            ]
          ]
        }
      end

      it "return maps" do
        expect(subject).to eq(
          pub_key: "edpkvWLnfNsAKhWEDafxHaTmE8qtK19fSDJYAnLfg7J5Qf5jbkKgTW",
          spendings: {
            "Spending--001" => {
              date: Time.zone.parse("2020-04-27T13:48:28Z"),
              practitioner_price: 6000,
              practitioner_ref: "HEALTH_PRACTITIONER_EG4WA",
              remainder_amount: 1000
            }
          },
        )
      end
    end
  end

  context "with option" do
    let(:type) do
      {
        prim: "pair",
        args:
          [
            { prim: "option",
             args: [{ prim: "signature" }],
             annots: ["%topup_signature"]
            },
           { prim: "option",
             args: [{ prim: "timestamp" }],
             annots: ["%topup_valid_until"]
            }
          ]
      }
    end

    context "with None value" do
      let(:data) do
        {prim: "Pair", args: [{prim: "None"}, {prim: "None"}]}
      end

      it "returns nil values" do
        expect(subject).to eq(
          topup_signature: nil,
          topup_valid_until: nil
        )
      end
    end
    context "with some value" do
      let(:topup_valid_until) { Time.zone.parse("1970-04-25 07:29:03.000000000 +0000") }

      let(:data) do
        {
          prim: "Pair",
          args: [
            {
              prim: "Some",
              args:[
                {
                  string: "edsigtp4wchrxPLWscwNQKyUssJixap4njeS3keCTwphwhx4MkQaFn8GfXkCJtk8vi5uV2ahrdS5YWc3qeC74awqWTGJfngKGrs"
                }
              ]
            },
            {
              prim: "Some",
              args:[
                {
                  int: topup_valid_until.to_i
                }
              ]
            }
          ]
        }
      end

      it "returns decoded values" do
        expect(subject).to eq(
         topup_signature: "edsigtp4wchrxPLWscwNQKyUssJixap4njeS3keCTwphwhx4MkQaFn8GfXkCJtk8vi5uV2ahrdS5YWc3qeC74awqWTGJfngKGrs",
         topup_valid_until: topup_valid_until
        )
      end
    end
  end
  context "with option with big map" do
    let(:type) do
      {"prim"=>"pair",
       "args"=>
           [{"prim"=>"address", "annots"=>["%bd_sender"]},
            {"prim"=>"pair",
             "args"=>
                 [{"prim"=>"big_map",
                   "args"=>[{"prim"=>"string"}, {"prim"=>"key"}],
                   "annots"=>["%practitioners"]},
                  {"prim"=>"option",
                   "args"=>[{"prim"=>"address"}],
                   "annots"=>["%replace_contract_address"]}]}]}.with_indifferent_access
    end
    let(:data) do
      {"prim"=>"Pair",
       "args"=>
           [{"bytes"=>"0000ad2daa0299eff4bc9406f6b6097ac496ef136871"},
            {"prim"=>"Pair",
             "args"=>
                 [[{"prim"=>"Elt",
                    "args"=>
                        [{"string"=>"HEALTH_PRACTITIONER_8Q2UE"},
                         {"string"=>
                              "0063b95178c0cecf6518d85ca12f7c719d0b82477cb72cddb788f16b9052159ce7"}]},
                   {"prim"=>"Elt",
                    "args"=>
                        [{"string"=>"HEALTH_PRACTITIONER_HMOOK"},
                         {"string"=>
                              "002ee8a37dc654e3e711cc6a44750fcd777905b688c03a64b6f805462cb87623d4"}]}],
                  {"prim"=>"None"}]}]}.with_indifferent_access
    end

    it "returns decoded values" do
      expect(subject).to eq(
                             :bd_sender => "tz1bRiJ6wkVNnSF6AFV5ZDE2kon97ewBiQFG",
                             :practitioners => {
                                 "HEALTH_PRACTITIONER_8Q2UE"=>"edpkuQ9FTSQ27t6ByQuUwqsxv5hmdcAP6dyi9ThQgjAKCxTA5dp7Dn",
                                 "HEALTH_PRACTITIONER_HMOOK"=>"edpktztA78rBSBbfyRQwoeErGMCyGjnZ3NXhu3g8Ag6VSrjUJfiuSP"
                             },
                             :replace_contract_address => nil
                         )
    end
  end
end
