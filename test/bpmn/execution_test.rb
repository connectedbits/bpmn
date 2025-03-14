# frozen_string_literal: true

require "test_helper"

module BPMN
  describe Execution do
    let(:sources) { fixture_source("execution_test.bpmn") }
    let(:context) { Context.new(sources) }

    describe :definition do
      let(:process) { context.process_by_id("Process") }
      let(:start_event) { process.element_by_id("Start") }
      let(:task) { process.element_by_id("Task") }
      let(:catch_event) { process.element_by_id("Catch") }
      let(:end_event) { process.element_by_id("End") }
      let(:sub_process) { process.element_by_id("SubProcess") }
      let(:sub_start_event) { sub_process.element_by_id("SubStart") }
      let(:sub_task) { sub_process.element_by_id("SubTask") }
      let(:sub_end_event) { sub_process.element_by_id("SubEnd") }

      it "should parse the process" do
        _(process).wont_be_nil
        _(start_event).wont_be_nil
        _(task).wont_be_nil
        _(catch_event).wont_be_nil
        _(end_event).wont_be_nil
        _(sub_process).wont_be_nil
        _(sub_start_event).wont_be_nil
        _(sub_task).wont_be_nil
        _(sub_end_event).wont_be_nil
      end

      it "should have pretty inspect" do
        _(process.inspect).wont_be_nil
      end
    end

    describe :execution do
      before { @execution = context.start }

      let(:execution) { @execution }
      let(:start_event) { execution.child_by_step_id("Start") }
      let(:task) { execution.child_by_step_id("Task") }
      let(:catch_event) { execution.child_by_step_id("Catch") }
      let(:end_event) { execution.child_by_step_id("End") }
      let(:sub_process) { execution.child_by_step_id("SubProcess") }
      let(:sub_start_event) { sub_process.child_by_step_id("SubStart") }
      let(:sub_task) { sub_process.child_by_step_id("SubTask") }
      let(:sub_end_event) { sub_process.child_by_step_id("SubEnd") }

      it "should start the process" do
        _(execution.started?).must_equal true
        _(start_event.ended?).must_equal true
        _(task.waiting?).must_equal true
        _(catch_event.waiting?).must_equal true
      end

      describe :catch_and_bypass do
        before { catch_event.signal }

        it "should end the process" do
          _(execution.completed?).must_equal true
          _(task.terminated?).must_equal true
          _(catch_event.ended?).must_equal true
          _(sub_process).must_be_nil
        end
      end

      describe :execute_sub_process do
        before { task.signal }

        it "should start the sub process" do
          _(sub_process.started?).must_equal true
          _(sub_task.waiting?).must_equal true
          _(catch_event.terminated?).must_equal true
        end

        describe :signal_sub do
          before { sub_task.signal }

          it "should end the process" do
            _(execution.ended?).must_equal true
            _(sub_process.ended?).must_equal true
            _(end_event).wont_be_nil
          end
        end
      end
    end

    describe :serialization do
      before { @execution = context.start(variables: { "foo": "bar" }) }

      let(:execution) { @execution }
      let(:start_event) { execution.child_by_step_id("Start") }
      let(:task) { execution.child_by_step_id("Task") }
      let(:catch_event) { execution.child_by_step_id("Catch") }
      let(:end_event) { execution.child_by_step_id("End") }
      let(:sub_process) { execution.child_by_step_id("SubProcess") }
      let(:sub_start_event) { sub_process.child_by_step_id("SubStart") }
      let(:sub_task) { sub_process.child_by_step_id("SubTask") }
      let(:sub_end_event) { sub_process.child_by_step_id("SubEnd") }

      it "should start the process" do
        _(execution.started?).must_equal true
        _(start_event.ended?).must_equal true
        _(task.waiting?).must_equal true
        _(catch_event.waiting?).must_equal true
      end

      describe :serialize do
        let(:json) { @json }

        before { @json = execution.serialize }

        it "must serialize the execution tree" do
          _(json).wont_be_nil
          parsed_json = JSON.parse(json)
          _(parsed_json["variables"]).must_equal("foo" => "bar")
        end

        describe :deserialize do
          before { @restored_execution = context.restore(json) }

          let(:restored_execution) { @restored_execution }

          it "should deserialize the execution tree" do
            _(restored_execution.id).must_equal execution.id
            _(restored_execution.status).must_equal execution.status
            _(restored_execution.step.id).must_equal execution.step.id
            _(restored_execution.children.length).must_equal execution.children.length
            _(restored_execution.variables).must_equal execution.variables
          end

          it "should be lossless" do
            _(restored_execution.serialize).must_equal execution.serialize
          end
        end
      end
    end
  end
end
