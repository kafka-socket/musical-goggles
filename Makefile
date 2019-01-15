.PHONY: run docker kafka kafkap
.DEFAULT_GOAL := run

run:
	bundle exec rspec ./spec

docker:
	KAFKA_ADVERTISED_HOST_NAME=`ipconfig getifaddr en0` docker-compose up -d

listen:
	kafka-console-consumer.sh \
		--bootstrap-server localhost:9092 \
		--from-beginning \
		--topic ws-to-kafka \
		--property "print.timestamp=true" \
		--property "print.key=true"

send:
	kafka-console-producer.sh \
		--broker-list localhost:9092 \
		--topic kafka-to-ws \
		--property "parse.key=true" \
		--property "key.separator=:"
