# frozen_string_literal: true

require "test_helper"

module BPMN
  describe Process do
    let(:sources) { [fixture_source("process_test.bpmn"), fixture_source("task_test.bpmn")] }
    let(:context) { BPMN.new(sources) }

    describe :definition do
      let(:process) { context.process_by_id("ProcessTest") }
      let(:start_event) { process.element_by_id("Start") }
      let(:sub_process) { process.element_by_id("SubProcess") }
      let(:sub_start) { sub_process.element_by_id("SubStart") }
      let(:call_activity) { sub_process.element_by_id("CallActivity") }
      let(:sub_end) { sub_process.element_by_id("SubEnd") }
      let(:end_event) { process.element_by_id("End") }

      it "should parse the process" do
        _(process).wont_be_nil
        _(start_event).wont_be_nil
        _(sub_process).wont_be_nil
        _(sub_start).wont_be_nil
        _(sub_end).wont_be_nil
        _(call_activity).wont_be_nil
        _(end_event).wont_be_nil
      end

      it "should have pretty inspect" do
        _(process.inspect).wont_be_nil
      end

      describe :start_process_to_sub_process do
        before { @execution = context.start(process_id: "ProcessTest") }

        let(:execution) { @execution }
        let(:sub_process) { execution.child_by_step_id("SubProcess") }
        let(:call_activity) { sub_process.child_by_step_id("CallActivity") }
        let(:callee_task) { call_activity.child_by_step_id("Task") }

        it "should start the process" do
          _(execution.started?).must_equal true
          _(call_activity.waiting?).must_equal true
        end

        describe :called_process_to_end do
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
