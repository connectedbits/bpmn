# frozen_string_literal: true

require "test_helper"

module BPMN
  describe Element do
    describe :definitions do
      let(:element) { Element.new(id: "id", name: "name") }

      it "should have pretty inspect output" do
        _(element.inspect).wont_be_nil
      end
    end
  end
end
