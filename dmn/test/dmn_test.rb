# frozen_string_literal: true

require "test_helper"

module DMN

  describe :module do
    it "should have a version number" do
      _(DMN::VERSION).wont_be_nil
    end
  end

  describe :decide do
    it "should evaluate a decision" do
      variables = {
        violation: {
          type: "speed",
          actual_speed: 100,
          speed_limit: 65,
        },
      }
      _(DMN.decide("fine_decision", definitions_xml: fixture_source("fine.dmn"), variables:)).must_equal({ "amount" => 1000, "points" => 7 })
    end
  end
end
