# frozen_string_literal: true

require 'kafka'

module MusicalGoggles
  class KafkaClient

    attr_reader :kafka, :consumer_topic, :producer_topic, :message_queue

    def initialize(bootstrap_servers:, consumer_topic:, producer_topic:)
      @kafka = Kafka.new(bootstrap_servers, client_id: 'musical-goggles')
      @consumer_topic = consumer_topic
      @producer_topic = producer_topic
      @message_queue = Queue.new
    end

    def start_consumer
      kafka.consumer(group_id: 'musical-goggles').tap(&method(:start))
    end

    def send(user, message)
      kafka.deliver_message(message, key: user, topic: producer_topic)
    end

    def receive
      message_queue.pop
    end

    private

    def start(consumer)
      consumer.subscribe(consumer_topic, start_from_beginning: false)
      Thread.new do
        consumer.each_message do |message|
          message_queue << message
        end
      end.join(3)
      clear
    end

    def clear
      message_queue.clear
    end
  end
end
