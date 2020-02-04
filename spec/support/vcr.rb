# frozen_string_literal: true

require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
end


module VcrDisabler
  def disabling_vcr
    WebMock.disable!
      yield
  ensure
    WebMock.enable!
  end

  def reading_vcr_cassette?
    VCR.current_cassette && !VCR.current_cassette&.recording?
  end
end

RSpec.configure do |config|
  config.include VcrDisabler
end
