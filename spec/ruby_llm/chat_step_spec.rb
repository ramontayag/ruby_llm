# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Chat do
  include_context 'with configured RubyLLM'

  let(:tool_call_double) { Struct.new(:id, :name, :arguments).new('tc_1', 'test_tool', {}) }

  def fake_response(tool_call: false, content: 'done')
    tool_calls = tool_call ? { tc_1: tool_call_double } : nil
    RubyLLM::Message.new(role: :assistant, content: content, tool_calls: tool_calls)
  end

  describe '#step' do
    it 'makes exactly one provider call' do
      chat = RubyLLM::Chat.new(model: 'claude-haiku-4-5-20251001', assume_model_exists: true,
                                provider: :anthropic)
      call_count = 0
      allow(chat.instance_variable_get(:@provider)).to receive(:complete) do
        call_count += 1
        fake_response
      end

      chat.step
      expect(call_count).to eq(1)
    end

    it 'does not recurse when tool calls are returned' do
      chat = RubyLLM::Chat.new(model: 'claude-haiku-4-5-20251001', assume_model_exists: true,
                                provider: :anthropic)
      call_count = 0
      allow(chat.instance_variable_get(:@provider)).to receive(:complete) do
        call_count += 1
        fake_response(tool_call: true)
      end

      chat.step
      expect(call_count).to eq(1)
    end
  end

  describe '#complete' do
    it 'calls step repeatedly until no tool calls are returned' do
      chat = RubyLLM::Chat.new(model: 'claude-haiku-4-5-20251001', assume_model_exists: true,
                                provider: :anthropic)
      step_count = 0
      responses = [fake_response(tool_call: true), fake_response(tool_call: false)]

      allow(chat).to receive(:step) do
        step_count += 1
        responses.shift || fake_response
      end

      chat.complete
      expect(step_count).to eq(2)
    end
  end
end
