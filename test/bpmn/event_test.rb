# frozen_string_literal: true

require "test_helper"

module BPMN
  describe StartEvent do
    let(:sources) { fixture_source("start_event_test.bpmn") }
    let(:context) { BPMN.new(sources) }

    describe :definitions do
      let(:process) { context.process_by_id("StartEventTest") }
      let(:start_event) { process.element_by_id("Start") }

      it "should parse start events" do
        _(start_event).wont_be_nil
      end
    end

    describe :execution do
      before { @execution = context.start }

      let(:execution) { @execution }
      let(:start_event) { execution.child_by_step_id("Start") }

      it "should start the process" do
        _(execution.completed?).must_equal true
        _(start_event.completed?).must_equal true
      end
    end
  end

  describe IntermediateCatchEvent do
    let(:sources) { fixture_source("intermediate_catch_event_test.bpmn") }
    let(:context) { BPMN.new(sources) }

    describe :definitions do
      let(:process) { context.process_by_id("IntermediateCatchEventTest") }
      let(:catch_event) { process.element_by_id("Catch") }
    end

    describe :execution do
      before { @execution = context.start }

      let(:execution) { @execution }
      let(:catch_event) { execution.child_by_step_id("Catch") }

      it "should wait at the catch event" do
        _(execution.started?).must_equal true
        _(catch_event.waiting?).must_equal true
      end

      describe :signal do
        before { catch_event.signal }

        it "should end the process" do
          _(execution.completed?).must_equal true
          _(catch_event.completed?).must_equal true
        end
      end
    end
  end

  describe IntermediateThrowEvent do
    let(:sources) { fixture_source("intermediate_throw_event_test.bpmn") }
    let(:context) { BPMN.new(sources) }

    describe :definitions do
      let(:process) { context.process_by_id("IntermediateThrowEventTest") }
      let(:throw_event) { process.element_by_id("Throw") }
    end

    describe :execution do
      before { @execution = context.start }

      let(:execution) { @execution }
      let(:throw_event) { execution.child_by_step_id("Throw") }

      it "should throw then end the process" do
        _(execution.completed?).must_equal true
        _(throw_event.completed?).must_equal true
      end
    end
  end

  describe BoundaryEvent do
    let(:sources) { fixture_source("boundary_event_test.bpmn") }
    let(:context) { BPMN.new(sources) }

    describe :definition do
      let(:process) { context.process_by_id("BoundaryEventTest") }
      let(:start_event) { process.element_by_id("Start") }
      let(:host_task) { process.element_by_id("HostTask") }
      let(:non_interrupting_event) { process.element_by_id("NonInterrupting") }
      let(:interrupting_event) { process.element_by_id("Interrupting") }
      let(:end_event) { process.element_by_id("End") }
      let(:end_interrupted_event) { process.element_by_id("EndInterrupted") }

      it "should attach boundary to host" do
        _(host_task.attachments.present?).must_equal true
        _(host_task.attachments).must_equal [non_interrupting_event, interrupting_event]
      end
    end

    describe :execution do
      before { @execution = context.start }

      let(:execution) { @execution }
      let(:start_event) { execution.child_by_step_id("Start") }
      let(:host_task) { execution.child_by_step_id("HostTask") }
      let(:non_interrupting_event) { execution.child_by_step_id("NonInterrupting") }
      let(:interrupting_event) { execution.child_by_step_id("Interrupting") }
      let(:end_event) { execution.child_by_step_id("End") }
      let(:end_interrupted_event) { execution.child_by_step_id("EndInterrupted") }

      it "should create boundary events" do
        _(execution.started?).must_equal true
        _(host_task.waiting?).must_equal true
        _(non_interrupting_event.waiting?).must_equal true
        _(interrupting_event.waiting?).must_equal true
      end

      describe :happy_path do
        before { host_task.signal }

        it "should complete the process" do
          _(execution.completed?).must_equal true
          _(host_task.completed?).must_equal true
          _(non_interrupting_event.terminated?).must_equal true
          _(interrupting_event.terminated?).must_equal true
        end
      end

      describe :non_interrupting do
        before { non_interrupting_event.signal }

        it "should not terminate host task" do
          _(host_task.waiting?).must_equal true
          _(non_interrupting_event.completed?).must_equal true
          _(interrupting_event.waiting?).must_equal true
        end
      end

      describe :interrupting do
        before { interrupting_event.signal }

        it "should terminate host task" do
          _(execution.ended?).must_equal true
          _(host_task.terminated?).must_equal true
          _(non_interrupting_event.terminated?).must_equal true
          _(interrupting_event.ended?).must_equal true
        end
      end
    end
  end

  describe EndEvent do
    let(:sources) { fixture_source("end_event_test.bpmn") }
    let(:context) { BPMN.new(sources) }

    describe :definitions do
      let(:process) { context.process_by_id("EndEventTest") }
      let(:end_event) { process.element_by_id("End") }

      it "should parse end events" do
        _(end_event).wont_be_nil
      end
    end

    describe :execution do
      before { @execution = context.start }

      let(:execution) { @execution }
      let(:end_event) { execution.child_by_step_id("End") }

      it "should end the process" do
        _(execution.completed?).must_equal true
        _(execution.completed?).must_equal true
      end
    end
  end
end
