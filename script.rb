# frozen_string_literal: true

require 'pp'
require 'pry'

require 'musical_goggles/websocket_client'
require 'musical_goggles/kafka_client'

token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwidXNl" \
        "cl91aWQiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMn0.UhOiwlNwWRy9I_uTVQ4dy" \
        "USt8MHtT9uJiMJiJjVH87M"
url = "ws://localhost:3030/ws?token=#{token}"
ws = MusicalGoggles::WebsocketClient.new(url)

kfk = MusicalGoggles::KafkaClient.new(
  bootstrap_servers: ['localhost:9092'],
  consumer_topic: 'my-topic',
  producer_topic: 'their-topic'
)

binding.pry

ws.connect

pp kfk.receive.headers

ws.send("Hello")
pp kfk.receive

kfk.send("John Doe", "From ruby")
pp ws.receive


puts 'Done'
