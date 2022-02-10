# TezosClient

[![Maintainability](https://api.codeclimate.com/v1/badges/54ab3bbbdc10c1faf933/maintainability)](https://codeclimate.com/github/moneytrackio/tezos_client/maintainability)

[![Build Status](https://travis-ci.org/moneytrackio/tezos_client.svg?branch=master)](https://travis-ci.org/moneytrackio/tezos_client)

Tezos Client interacts with Tezos nodes using RPC commands. 

## Requirements

Tezos client requires SmartPy to be installed in order to work properly.
To install it on Linux, you can basically follow the steps coded in travis-script folder. 

## Dependency 

### michelson-to-micheline 
```bash
sudo apt-get install nodejs
npm i -g michelson-to-micheline
```

### SmartPy
[SmartPy](https://smartpy.io/releases/20210317-bc925bb73dc885ac2b4dde9689e805d9b0bc6125/)

```bash
sh <(curl -s https://smartpy.io/releases/20210317-bc925bb73dc885ac2b4dde9689e805d9b0bc6125/cli/install.sh)
export PATH=$PATH:$HOME/smartpy-cli/
```

### TypeScript (for dev)
```bash
npm install -g typescript
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tezos_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tezos_client

## Usage

### Generate Tezos key pairs

Generate a perfectly random key pair:

```ruby 
client = TezosClient.new 
key = subject.generate_key
          expect(key[:address]).to eq "tz1RfnzRopJXH32SSDap2wMYGULBAnmHxdP1"
# => {
#       secret_key: "edsk4T2fHv5RLL3VSXHz82SQiyFx7vZ4wwtA2u67AvAaw5yqNEvuU2", 
#       public_key: "edpkuncp7KSVhV57Qg7odwhMFcnAHnNrMppbitBPKBfvdg6fFVeNjr", 
#       address: "tz1a97x7GAvMDyrwwKTLQo131CoidXyUef48"
#    }
```

Generate a key pair from a seed and a BIP 44 Path:

```ruby
key = subject.generate_key(wallet_seed:"000102030405060708090a0b0c0d0e0f", path: "m/44'/1729'/0'/0'/0'")
          expect(key[:address]).to eq "tz1RfnzRopJXH32SSDap2wMYGULBAnmHxdP1"
# => {
#       secret_key: "edsk4T2fHv5RLL3VSXHz82SQiyFx7vZ4wwtA2u67AvAaw5yqNEvuU2", 
#       public_key: "edpkuncp7KSVhV57Qg7odwhMFcnAHnNrMppbitBPKBfvdg6fFVeNjr", 
#       address: "tz1a97x7GAvMDyrwwKTLQo131CoidXyUef48"
#    }
```
Generate a key pair from a BIP-39 mnemonic sentence and a BIP 44 Path:

```ruby
key = subject.generate_key(
          mnemonic: "below dove cushion divide future artefact orange congress maple fiscal flower enable", 
          path: "m/44'/1729'/0'/0'/0'")
          expect(key[:address]).to eq "tz1RfnzRopJXH32SSDap2wMYGULBAnmHxdP1"
# => {
#       secret_key: "edsk4T2fHv5RLL3VSXHz82SQiyFx7vZ4wwtA2u67AvAaw5yqNEvuU2", 
#       public_key: "edpkuncp7KSVhV57Qg7odwhMFcnAHnNrMppbitBPKBfvdg6fFVeNjr", 
#       address: "tz1a97x7GAvMDyrwwKTLQo131CoidXyUef48"
#    }
```


### Transfer funds

```ruby 
client = TezosClient.new 

client.transfer(
    amount: 1,
    from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
    to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
    secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
)
```

### Call a contract

```ruby
client = TezosClient.new  
client.transfer(
    amount: 5,
    from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
    to: "KT1MZTrMDPB42P9yvjf7Cy8Lkjxjj4jetbCt",
    secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
    parameters: '"pro"'
)
```

### Originate a contract written in SmartPy

```ruby
script = File.expand_path("./spec/fixtures/demo.py")
source = "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq"
secret_key = "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
amount =  0
init_params= "MyContract()"
client = TezosClient.new

res = client.originate_contract(
    from: source,
    amount: amount,
    script: script,
    secret_key: secret_key,
    init_params: init_params
)

puts "Origination operation: #{res[:operation_id]}"
puts "Contract address: #{res[:originated_contract]}"
```

### Call a contract written in SmartPy

```ruby
TezosClient.new.call_contract(
  from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
  secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
  to: "KT1STzq9p2tfW3K4RdoM9iYd1htJ4QcJ8Njs",
  amount: 0,
  entrypoint: "myEntryPoint",
  params: { int: 1 },
  params_type: :micheline
)
```


## Options

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tezos_client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TezosClient project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tezos_client/blob/master/CODE_OF_CONDUCT.md).
