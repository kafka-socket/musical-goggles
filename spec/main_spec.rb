# frozen_string_literal: true

require 'jwt'
require 'musical_goggles'

RSpec.describe 'Websocket to kafka bidirectional bridge' do
  let(:user_uid) { 'musical_goggles' }
  let(:jwt_secret) { 'your-256-bit-secret' }
  let(:payload) { { user_uid: user_uid } }
  let(:token) { JWT.encode(payload, jwt_secret, 'HS256') }
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

    let(:message) { 'wazzup' }
    let(:push_message) { 'watching a game, having a bud' }

    it 'sends message via websockets and gets it back via kafka and vice versa' do
      ws.connect
      init_message = kafka.receive
      expect(init_message.key).to eq(user_uid)
      expect(init_message.value).to be_empty
      expect(init_message.headers['type']).to eq('init')

      ws.send(message)
      text_message = kafka.receive
      expect(text_message.key).to eq(user_uid)
      expect(text_message.value).to eq(message)
      expect(text_message.headers['type']).to eq('text')

      kafka.send(user_uid, push_message)
      return_message = ws.receive
      expect(return_message).to eq(push_message)

      ws.close
      close_message = kafka.receive
      expect(close_message.key).to eq(user_uid)
      expect(close_message.value).to be_empty
      expect(close_message.headers['type']).to eq('terminate')
    end
  end
end
