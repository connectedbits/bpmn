# frozen_string_literal: true

require "test_helper"

module BPMN
  describe Definitions do
    describe :from_xml do
      describe :hello_world do
        let(:xml) { fixture_source("hello_world.bpmn") }
        let(:definitions) { Definitions.from_xml(xml) }

        it "should initialize the definitions" do
          _(definitions).wont_be_nil
          _(definitions.id).wont_be_nil
          _(definitions.execution_platform).must_equal("Camunda Cloud")
          _(definitions.execution_platform_version).wont_be_nil
          _(definitions.exporter).must_equal("Camunda Modeler")
          _(definitions.exporter_version).wont_be_nil
          _(definitions.target_namespace).must_equal("http://bpmn.io/schema/bpmn")
          _(definitions.messages.count).must_equal(0)
          _(definitions.signals.count).must_equal(0)
          _(definitions.errors.count).must_equal(0)
          _(definitions.processes.count).must_equal(1)
        end

        it "should have pretty inspect output" do
          _(definitions.inspect).wont_be_nil
        end
      end
    end
  end
end
