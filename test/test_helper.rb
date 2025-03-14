# frozen_string_literal: true

GEM_ROOT = File.join(File.dirname(__FILE__), "..")

require "minitest/autorun"
require "minitest/reporters"
require "minitest/spec"
require "minitest/focus"
require "active_support"
require "active_support/testing/time_helpers"
require "pry"

require "simplecov"
SimpleCov.start do
  enable_coverage :branch

  add_filter %r{^/test/}

  add_group "Spot Flow",                  ["bpmn/"]
  add_group "Spot Flow Services",         ["bpmn/services/"]
  add_group "Spot Flow BPMN",             ["bpmn/bpmn/"]
  add_group "Spot Flow Zeebe Extensions", ["bpmn/zeebe/"]
end

Time.zone_default = Time.find_zone!("UTC")

Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new(color: true),
    ENV,
    Minitest.backtrace_filter,
)

require_relative "../lib/bpmn"

class Minitest::Spec
  include ActiveSupport::Testing::TimeHelpers

  before :each do
  end

  after :each do
  end

  def file_fixture(filename)
    Pathname.new(File.join(GEM_ROOT, "/test/fixtures/files", filename))
  end

  def fixture_source(filename)
    file_fixture(filename).read
  end
end
