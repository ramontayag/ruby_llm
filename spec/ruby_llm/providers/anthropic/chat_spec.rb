# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::Anthropic::Chat do

  describe '#parse_usage_limits' do
    context 'with complete headers' do
      let(:headers) do
        {
          'anthropic-ratelimit-requests-remaining' => '500',
          'anthropic-ratelimit-tokens-remaining' => '75000',
          'anthropic-ratelimit-requests-reset' => '2024-01-01T12:00:00Z',
          'anthropic-ratelimit-tokens-reset' => '2024-01-01T13:00:00Z',
          'anthropic-ratelimit-requests-limit' => '1000',
          'anthropic-ratelimit-tokens-limit' => '100000'
        }
      end

      it 'parses all usage limit fields correctly' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result).to eq({
          remaining_requests: 500,
          remaining_tokens: 75000,
          reset_requests: '2024-01-01T12:00:00Z',
          reset_tokens: '2024-01-01T13:00:00Z',
          limit_requests: 1000,
          limit_tokens: 100000
        })
      end
    end

    context 'with partial headers' do
      let(:headers) do
        {
          'anthropic-ratelimit-requests-remaining' => '200',
          'anthropic-ratelimit-tokens-reset' => '2024-01-01T14:00:00Z'
        }
      end

      it 'parses only available fields and excludes nil values' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result).to eq({
          remaining_requests: 200,
          reset_tokens: '2024-01-01T14:00:00Z'
        })
      end
    end

    context 'with no relevant headers' do
      let(:headers) do
        {
          'content-type' => 'application/json',
          'x-custom-header' => 'value'
        }
      end

      it 'returns empty hash' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result).to eq({})
      end
    end

    context 'with nil headers' do
      it 'returns empty hash' do
        result = described_class.send(:parse_usage_limits, nil)

        expect(result).to eq({})
      end
    end

    context 'with string numeric values' do
      let(:headers) do
        {
          'anthropic-ratelimit-requests-remaining' => '999',
          'anthropic-ratelimit-tokens-remaining' => '123456'
        }
      end

      it 'converts string numbers to integers' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result[:remaining_requests]).to eq(999)
        expect(result[:remaining_tokens]).to eq(123456)
      end
    end

    context 'with non-numeric values for numeric fields' do
      let(:headers) do
        {
          'anthropic-ratelimit-requests-remaining' => 'invalid',
          'anthropic-ratelimit-tokens-remaining' => ''
        }
      end

      it 'converts invalid numeric values to zero' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result).to eq({
          remaining_requests: 0,
          remaining_tokens: 0
        })
      end
    end
  end

  describe '#build_message' do
    let(:data) do
      {
        'model' => 'claude-3-5-haiku-20241022',
        'usage' => {
          'input_tokens' => 10,
          'output_tokens' => 25
        }
      }
    end
    let(:content) { 'Hello, world!' }
    let(:tool_use) { nil }
    let(:headers) do
      {
        'anthropic-ratelimit-requests-remaining' => '100',
        'anthropic-ratelimit-tokens-remaining' => '50000'
      }
    end

    it 'builds message with usage limits from headers' do
      message = described_class.send(:build_message, data, content, tool_use, headers)

      expect(message.content).to eq('Hello, world!')
      expect(message.role).to eq(:assistant)
      expect(message.input_tokens).to eq(10)
      expect(message.output_tokens).to eq(25)
      expect(message.model_id).to eq('claude-3-5-haiku-20241022')
      expect(message.usage_limits).to eq({
        remaining_requests: 100,
        remaining_tokens: 50000
      })
    end

    it 'builds message without usage limits when headers are nil' do
      message = described_class.send(:build_message, data, content, tool_use, nil)

      expect(message.content).to eq('Hello, world!')
      expect(message.usage_limits).to eq({})
    end
  end
end