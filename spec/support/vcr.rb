# frozen_string_literal: true

require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
end

module VcrDisabler
  @@disabling_cont = 0
  def disabling_vcr
    if @@disabling_cont.zero?
      WebMock.disable!
    end
    @@disabling_cont += 1
    yield
  ensure
    @@disabling_cont -= 1
    WebMock.enable! if @@disabling_cont == 0
  end

  def reading_vcr_cassette?
    VCR.current_cassette && !VCR.current_cassette&.recording?
  end
end

RSpec.configure do |config|
  config.include VcrDisabler
end

RSpec.shared_context "vcr disabled", shared_context: :metadata do
  around do |example|
    disabling_vcr { example.call }
  end
end

RSpec.configure do |rspec|
  rspec.include_context "vcr disabled", disabling_vcr: true
end
