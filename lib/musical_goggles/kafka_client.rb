# frozen_string_literal: true

require 'kafka'

module MusicalGoggles
  class KafkaClient

    attr_reader :kafka, :consumer_topic, :producer_topic, :message_queue, :logger
    attr_reader :consumer, :consumer_thread

    def initialize(bootstrap_servers:, consumer_topic:, producer_topic:, logger:)
      @kafka = Kafka.new(bootstrap_servers, client_id: 'musical-goggles')
      @consumer_topic = consumer_topic
      @producer_topic = producer_topic
      @logger = logger
      @message_queue = Queue.new
    end

    def start_consumer
      @consumer = kafka.consumer(group_id: 'musical-goggles').tap(&method(:start))
    end

    def stop_consumer
      consumer.stop
      consumer_thread.join
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
      @consumer_thread = Thread.new do
        consumer.each_message do |message|
          logger.debug(message.headers)
          message_queue << message
        end
      end.tap { |t| t.join(3) }
      clear
    end

    def clear
      logger.debug("Clearing queue...")
      message_queue.clear
    end
  end
end
