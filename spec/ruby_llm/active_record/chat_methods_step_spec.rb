# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RubyLLM::ActiveRecord::ChatMethods, '#step' do
  include_context 'with configured RubyLLM'

  let(:model_id) { 'gpt-4.1-nano' }

  def fake_response(tool_call: false)
    tool_calls = tool_call ? { tc_1: Struct.new(:id, :name, :arguments).new('tc_1', 'test_tool', {}) } : nil
    RubyLLM::Message.new(role: :assistant, content: 'done', tool_calls: tool_calls)
  end

  it 'delegates step to the underlying RubyLLM::Chat' do
    chat = Chat.create!(model: model_id)
    chat.messages.create!(role: :user, content: 'hello')

    call_count = 0
    allow_any_instance_of(RubyLLM::Chat).to receive(:step) do # rubocop:disable RSpec/AnyInstance
      call_count += 1
      fake_response
    end

    chat.step
    expect(call_count).to eq(1)
  end

  it 'makes exactly one provider call per step invocation' do
    chat = Chat.create!(model: model_id)
    chat.messages.create!(role: :user, content: 'hello')

    call_count = 0
    allow_any_instance_of(RubyLLM::Chat).to receive(:step).and_wrap_original do |original| # rubocop:disable RSpec/AnyInstance
      call_count += 1
      fake_response
    end

    chat.step rescue nil # rubocop:disable Style/RescueModifier
    expect(call_count).to eq(1)
  end
end
