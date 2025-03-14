# frozen_string_literal: true

require "test_helper"

module BPMN
  describe :serialization_test do
    let(:sources) { fixture_source("check_jurisdiction.bpmn") }
    let(:context) { Context.new(sources) }

    describe :definition do
      let(:process) { context.process_by_id("submission") }
      let(:start_event) { process.element_by_id("submission_submitted") }
      let(:check_jurisdiction_task) { process.element_by_id("submission_check_jurisdiction") }
      let(:open_ticket_task) { process.element_by_id("submission_open_ticket") }
      let(:close_ticket_task) { process.element_by_id("submission_close_ticket") }
      let(:end_event) { process.element_by_id("submission_end") }

      it "should parse the process" do
        _(process).wont_be_nil
        _(start_event).wont_be_nil
        _(check_jurisdiction_task).wont_be_nil
        _(open_ticket_task).wont_be_nil
        _(close_ticket_task).wont_be_nil
        _(end_event).wont_be_nil
      end
    end

    describe :execution do
      before do
        @executions = context.start_with_message(message_name: "Submitted", variables: { "submission_id": "123" })
      end

      let(:execution) { @executions.first }
      let(:start_event) { execution.child_by_step_id("submission_submitted") }
      let(:check_jurisdiction_task) { execution.child_by_step_id("submission_check_jurisdiction") }
      let(:open_ticket_task) { execution.child_by_step_id("submission_open_ticket") }
      let(:close_ticket_task) { execution.child_by_step_id("submission_close_ticket") }
      let(:end_event) { execution.child_by_step_id("submission_end") }

      it "should wait at the check jurisdiction step" do
        _(execution.started?).must_equal true
        _(execution.variables).must_equal({ "submission_id"=>"123" })
        _(check_jurisdiction_task.waiting?).must_equal true
      end

      describe :without_serialization do
        describe :signal_waiting_task do
          before do
            check_jurisdiction_task.signal({ "data": { "submission_check_jurisdiction_outcome": "in_jurisdiction" } })
          end

          it "should wait at the open ticket task" do
            _(check_jurisdiction_task.ended?).must_equal true
            _(open_ticket_task.waiting?).must_equal true
          end

          describe :completion do
            before do
              open_ticket_task.signal
            end

            it "should end the execution" do
              _(execution.ended?).must_equal true
            end
          end
        end
      end

      describe :with_serialization do
        before do
          json = execution.serialize
          @restored_execution = context.restore(json)
        end

        let(:restored_execution) { @restored_execution }
        let(:start_event) { restored_execution.child_by_step_id("submission_submitted") }
        let(:check_jurisdiction_task) { restored_execution.child_by_step_id("submission_check_jurisdiction") }
        let(:open_ticket_task) { restored_execution.child_by_step_id("submission_open_ticket") }
        let(:close_ticket_task) { restored_execution.child_by_step_id("submission_close_ticket") }
        let(:end_event) { restored_execution.child_by_step_id("submission_end") }

        it "should wait at the check jurisdiction step" do
          _(restored_execution.started?).must_equal true
          _(restored_execution.variables).must_equal({ "submission_id"=>"123" })
          _(check_jurisdiction_task.waiting?).must_equal true
        end

        describe :serialize do
          before do
            json = execution.serialize
            @execution = context.restore(json)
          end

          let(:restored_execution) { @execution }

          it "should restore the execution to expected state" do
            _(execution.started?).must_equal true
            _(execution.variables).must_equal({ "submission_id"=>"123" })
            _(execution.step).wont_be_nil
            _(check_jurisdiction_task.waiting?).must_equal true
          end

          describe :signal_waiting_task do
            before do
              check_jurisdiction_task.signal({ "data": { "submission_check_jurisdiction_outcome": "in_jurisdiction" } })
            end

            it "should wait at the open ticket task" do
              _(check_jurisdiction_task.ended?).must_equal true
              _(open_ticket_task.waiting?).must_equal true
            end

            describe :completion do
              before do
                open_ticket_task.signal
              end

              it "should end the execution" do
                _(restored_execution.ended?).must_equal true
              end
            end
          end
        end
      end
    end
  end
end
