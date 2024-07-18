# frozen_string_literal: true

require "test_helper"

module SpotFlow
  module Bpmn
    describe Process do
      let(:sources) { fixture_source("process_test.bpmn") }
      let(:context) { SpotFlow.new(sources) }

      describe :definition do
        let(:process) { context.process_by_id("ProcessTest") }
        let(:start_event) { process.element_by_id("Start") }
        let(:end_event) { process.element_by_id("End") }

        it "should parse the process" do
          _(process).wont_be_nil
          _(start_event).wont_be_nil
          _(end_event).wont_be_nil
        end

        it "should have pretty inspect" do
          _(process.inspect).wont_be_nil
        end
      end      
    end

    describe CallActivity do
      let(:caller_source) { fixture_source("call_activity_caller_test.bpmn") }
      let(:callee_source) { fixture_source("call_activity_callee_test.bpmn") }
      let(:sources) { [caller_source, callee_source] }
      let(:context) { SpotFlow.new(sources) }    

      describe :definition do
        let(:caller_process) { context.process_by_id("Caller") }
        let(:callee_process) { context.process_by_id("Callee") }
        let(:call_activity) { caller_process.element_by_id("CallActivity") }
        let(:callee_task) { callee_process.element_by_id("Task") }

        it "should parse the process" do
          _(caller_process).wont_be_nil
          _(callee_process).wont_be_nil
          _(call_activity).wont_be_nil
          _(callee_task).wont_be_nil
        end
      end

      describe :execution do
        before do
          @execution = context.start(process_id: "Caller")
        end

        let (:execution) { @execution }
        let (:call_activity) { execution.child_by_step_id("CallActivity") }
        let (:callee_task) { call_activity.child_by_step_id("Task") }

        it "should wait at the call activity and start the child process" do
          _(call_activity.waiting?).must_equal true
          _(callee_task.waiting?).must_equal true
        end

        describe :complete_called_process do
          before { callee_task.signal }

          it "should complete the called process" do
            _(callee_task.parent.completed?).must_equal true
            _(execution.completed?).must_equal true
          end
        end
      end
    end
  end
end
