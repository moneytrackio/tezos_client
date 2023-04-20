# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tezos_client/version"

Gem::Specification.new do |spec|
  spec.name          = "tezos_client"
  spec.version       = TezosClient::VERSION
  spec.authors       = ["Pierre Michard", "Sébastien Lauret", "Othmane El Kesri"]
  spec.email         = ["pierre@moneytrack.io", "sebastien@moneytrack.io", "othmane@moneytrack.io"]

  spec.summary       = "Wrapper to the tezos client."
  spec.description   = ""
  spec.homepage      = "https://moneytrack.io"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rails_config"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "vcr", "~> 4.0.0"
  spec.add_development_dependency "pry"

  spec.add_dependency "active_interaction", ">= 3.8"
  spec.add_dependency "base58", "~> 0.2.3"
  spec.add_dependency "httparty", "~> 0.21.0"
  spec.add_dependency "rbnacl", "~> 7.1"
  spec.add_dependency "rest-client", "~> 2.1"
  spec.add_dependency "activesupport", "~> 7.0.4", ">= 7.0.4.3"
  spec.add_dependency "money-tree", "~> 0.11.2"
  spec.add_dependency "bip_mnemonic", "~> 0.0.2"
end
