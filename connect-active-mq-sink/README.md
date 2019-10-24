# ActiveMQ Sink connector

## Objective

Quickly test [ActiveMQ Sink](https://docs.confluent.io/current/connect/kafka-connect-activemq/sink/index.html#kconnect-long-activemq-sink-connector) connector.

Using ActiveMQ Docker [image](https://hub.docker.com/r/rmohr/activemq/)

## Pre-requisites

* `docker-compose` (example `brew cask install docker`)
* `jq` (example `brew install jq`)


## How to run

Simply run:

```
$ ./active-mq-sink.sh
```

## Details of what the script is doing

ActiveMQ UI is reachable at [http://127.0.0.1:8161](http://127.0.0.1:8161]) (`admin/admin`)

Sending messages to topic `sink-messages`

```bash
$ docker container exec -i broker kafka-console-producer --broker-list broker:9092 --topic sink-messages << EOF
This is my message
EOF
```

The connector is created with:

```bash
$ docker container exec connect \
     curl -X POST \
     -H "Content-Type: application/json" \
     --data '{
               "name": "active-mq-sink",
               "config": {
                    "connector.class": "io.confluent.connect.jms.ActiveMqSinkConnector",
                    "topics": "sink-messages",
                    "activemq.url": "tcp://activemq:61616",
                    "activemq.username": "admin",
                    "activemq.password": "admin",
                    "jms.destination.name": "DEV.QUEUE.1",
                    "jms.destination.type": "queue",
                    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
                    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
                    "confluent.license": "",
                    "confluent.topic.bootstrap.servers": "broker:9092",
                    "confluent.topic.replication.factor": "1"
          }}' \
     http://localhost:8083/connectors | jq .
```

Get messages from DEV.QUEUE.1 JMS queue:

```bash
$ curl -XGET -u admin:admin -d "body=message" http://localhost:8161/api/message/DEV.QUEUE.1?type=queue
```

We get:

```
This is my message
```

N.B: Control Center is reachable at [http://127.0.0.1:9021](http://127.0.0.1:9021])