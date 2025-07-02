# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::OpenAI::Chat do

  describe '#parse_usage_limits' do
    context 'with complete headers' do
      let(:headers) do
        {
          'x-ratelimit-remaining-requests' => '800',
          'x-ratelimit-remaining-tokens' => '45000',
          'x-ratelimit-reset-requests' => '2024-01-01T10:30:00Z',
          'x-ratelimit-reset-tokens' => '2024-01-01T11:00:00Z',
          'x-ratelimit-limit-requests' => '1000',
          'x-ratelimit-limit-tokens' => '60000'
        }
      end

      it 'parses all usage limit fields correctly' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result).to eq({
          remaining_requests: 800,
          remaining_tokens: 45000,
          reset_requests: '2024-01-01T10:30:00Z',
          reset_tokens: '2024-01-01T11:00:00Z',
          limit_requests: 1000,
          limit_tokens: 60000
        })
      end
    end

    context 'with partial headers' do
      let(:headers) do
        {
          'x-ratelimit-remaining-requests' => '300',
          'x-ratelimit-reset-tokens' => '2024-01-01T15:30:00Z'
        }
      end

      it 'parses only available fields and excludes nil values' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result).to eq({
          remaining_requests: 300,
          reset_tokens: '2024-01-01T15:30:00Z'
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
          'x-ratelimit-remaining-requests' => '555',
          'x-ratelimit-remaining-tokens' => '789000'
        }
      end

      it 'converts string numbers to integers' do
        result = described_class.send(:parse_usage_limits, headers)

        expect(result[:remaining_requests]).to eq(555)
        expect(result[:remaining_tokens]).to eq(789000)
      end
    end

    context 'with non-numeric values for numeric fields' do
      let(:headers) do
        {
          'x-ratelimit-remaining-requests' => 'invalid',
          'x-ratelimit-remaining-tokens' => ''
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

  describe 'message building with usage limits' do
    let(:data) do
      {
        'model' => 'gpt-4-turbo',
        'choices' => [{
          'message' => {
            'role' => 'assistant',
            'content' => 'Test response'
          }
        }],
        'usage' => {
          'prompt_tokens' => 15,
          'completion_tokens' => 30
        }
      }
    end
    let(:response_headers) do
      {
        'x-ratelimit-remaining-requests' => '250',
        'x-ratelimit-remaining-tokens' => '12000'
      }
    end
    let(:response) { double('response', headers: response_headers) }

    it 'includes usage limits in built message' do
      # Create the message with usage limits
      message_data = data['choices'][0]['message']
      message = RubyLLM::Message.new(
        role: :assistant,
        content: message_data['content'],
        input_tokens: data['usage']['prompt_tokens'],
        output_tokens: data['usage']['completion_tokens'],
        model_id: data['model'],
        usage_limits: described_class.send(:parse_usage_limits, response_headers)
      )

      expect(message.content).to eq('Test response')
      expect(message.role).to eq(:assistant)
      expect(message.input_tokens).to eq(15)
      expect(message.output_tokens).to eq(30)
      expect(message.model_id).to eq('gpt-4-turbo')
      expect(message.usage_limits).to eq({
        remaining_requests: 250,
        remaining_tokens: 12000
      })
    end
  end
end