# frozen_string_literal: true

require 'jwt'
require 'logger'
require 'musical_goggles'

RSpec.describe 'Websocket to kafka bidirectional bridge' do
  let(:logger) { Logger.new(STDOUT).tap { |log| log.level = Logger::DEBUG } }

  let(:user_uid) { 'musical_goggles' }
  let(:jwt_secret) { 'your-256-bit-secret' }
  let(:payload) { { user_uid: user_uid } }
  let(:token) { JWT.encode(payload, jwt_secret, 'HS256', { typ: 'JWT' }) }
  let(:url) { "ws://localhost:3030/ws?token=#{token}" }
  let(:ws) { MusicalGoggles::WebsocketClient.new(url: url, logger: logger) }

  let(:kafka) do
    MusicalGoggles::KafkaClient.new(
      bootstrap_servers: ['localhost:9092'],
      consumer_topic: 'ws-to-kafka',
      producer_topic: 'kafka-to-ws',
      logger: logger
    )
  end

  context 'websocket to kafka full cycle' do
    before { kafka.start_consumer }

    let(:message) { 'wazzup' }
    let(:push_message) { 'watching a game, having a bud' }

    it 'sends message via websockets and gets it back via kafka and vice versa' do
      ws.connect
      logger.debug('ws had been connected')
      init_message = kafka.receive
      logger.debug('init_message had been received')
      expect(init_message.key).to eq(user_uid)
      expect(init_message.value.to_s).to be_empty
      expect(init_message.headers['type']).to eq('init')

      ws.send(message)
      logger.debug('message had been sent via ws')
      text_message = kafka.receive
      logger.debug('message had been received via kafka')
      expect(text_message.key).to eq(user_uid)
      expect(text_message.value).to eq(message)
      expect(text_message.headers['type']).to eq('text')

      kafka.send(user_uid, push_message)
      logger.debug('message had been sent via kafka')
      return_message = ws.receive
      logger.debug('message had been received via ws')
      expect(return_message).to eq(push_message)

      ws.close
      logger.debug('ws connection had been closed')
      close_message = kafka.receive
      logger.debug('close_message had been sent via kafka')
      expect(close_message.key).to eq(user_uid)
      expect(close_message.value.to_s).to be_empty
      expect(close_message.headers['type']).to eq('terminate')
    end
  end
end
