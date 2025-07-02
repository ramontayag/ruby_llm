# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Message do
  describe '#initialize' do
    it 'initializes with basic attributes' do
      message = described_class.new(role: :assistant, content: 'Hello world')

      expect(message.role).to eq(:assistant)
      expect(message.content).to eq('Hello world')
      expect(message.usage_limits).to eq({})
    end

    it 'accepts usage_limits parameter' do
      usage_limits = {
        remaining_requests: 100,
        remaining_tokens: 50000,
        reset_requests: '2024-01-01T00:00:00Z',
        reset_tokens: '2024-01-01T00:00:00Z',
        limit_requests: 1000,
        limit_tokens: 100000
      }

      message = described_class.new(
        role: :assistant,
        content: 'Hello',
        usage_limits: usage_limits
      )

      expect(message.usage_limits).to eq(usage_limits)
    end

    it 'defaults usage_limits to empty hash when not provided' do
      message = described_class.new(role: :user, content: 'Test')

      expect(message.usage_limits).to eq({})
    end
  end

  describe '#usage_limits' do
    it 'is readable' do
      usage_limits = { remaining_requests: 50 }
      message = described_class.new(
        role: :assistant,
        content: 'Test',
        usage_limits: usage_limits
      )

      expect(message.usage_limits).to eq(usage_limits)
    end
  end

  describe '#to_h' do
    it 'includes usage_limits in hash representation' do
      usage_limits = {
        remaining_requests: 75,
        remaining_tokens: 25000
      }

      message = described_class.new(
        role: :assistant,
        content: 'Test response',
        input_tokens: 10,
        output_tokens: 5,
        model_id: 'gpt-4',
        usage_limits: usage_limits
      )

      hash = message.to_h

      expect(hash[:usage_limits]).to eq(usage_limits)
      expect(hash[:role]).to eq(:assistant)
      expect(hash[:content]).to eq('Test response')
      expect(hash[:input_tokens]).to eq(10)
      expect(hash[:output_tokens]).to eq(5)
      expect(hash[:model_id]).to eq('gpt-4')
    end

    it 'includes empty usage_limits hash when not provided' do
      message = described_class.new(
        role: :user,
        content: 'Test message'
      )

      hash = message.to_h

      expect(hash[:usage_limits]).to eq({})
    end

    it 'includes usage_limits when not empty' do
      message = described_class.new(
        role: :assistant,
        content: 'Test',
        usage_limits: { remaining_requests: 1 }
      )

      hash = message.to_h

      expect(hash[:usage_limits]).to eq({ remaining_requests: 1 })
    end
  end
end
