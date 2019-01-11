# frozen_string_literal: true

require 'musical_goggles'

RSpec.describe 'Websocket to kafka bidirectional bridge' do
  let(:token) { <<~TOKEN.delete("\n") }
    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwidXNl
    cl91aWQiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMn0.UhOiwlNwWRy9I_uTVQ4dy
    USt8MHtT9uJiMJiJjVH87M
  TOKEN
  let(:url) { "ws://localhost:3030/ws?token=#{token}" }
  let(:ws) { MusicalGoggles::WebsocketClient.new(url) }

  let(:kafka) do
    MusicalGoggles::KafkaClient.new(
      bootstrap_servers: ['localhost:9092'],
      consumer_topic: 'my-topic',
      producer_topic: 'their-topic'
    )
  end

  context 'websocket to kafka full cycle' do
    before { kafka.start_consumer }
    before { ws.connect }

    let(:message) { 'wazzup' }
    let(:push_message) { 'watching a game, having a bud' }

    it 'sends message via websockets and gets it back via kafka and vice versa' do
      init_message = kafka.receive
      expect(init_message.value).to be_empty
      expect(init_message.headers['type']).to eq('init')

      ws.send(message)
      text_message = kafka.receive
      expect(text_message.value).to eq(message)
      expect(text_message.headers['type']).to eq('text')

      kafka.send('John Doe', push_message)
      return_message = ws.receive
      expect(return_message).to eq(push_message)

      ws.close
      close_message = kafka.receive
      expect(close_message.value).to be_empty
      expect(close_message.headers['type']).to eq('terminate')
    end
  end
end
