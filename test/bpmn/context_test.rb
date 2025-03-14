# frozen_string_literal: true

require "test_helper"

module BPMN
  describe Context do
    describe :listener do
      before { BPMN.config.listener = ->(args) { log << args } }

      let(:sources) { fixture_source("execution_test.bpmn") }
      let(:context) { Context.new(sources) }
      let(:log) { [] }

      it "should pretty print inspect" do
        _(context.inspect).wont_be_nil
      end
    end
  end
end
