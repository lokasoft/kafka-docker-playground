#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

${DIR}/../../environment/plaintext/start.sh "${PWD}/docker-compose.plaintext.yml"


echo "Sending messages to topic hbase-test"
docker exec -i broker kafka-console-producer --broker-list broker:9092 --topic hbase-test --property parse.key=true --property key.separator=, << EOF
key1,value1
key2,value2
key3,value3
EOF

echo "Creating HBase sink connector"
docker exec connect \
     curl -X POST \
     -H "Content-Type: application/json" \
     --data '{
               "name": "hbase-sink",
               "config": {
                    "connector.class": "io.confluent.connect.hbase.HBaseSinkConnector",
                    "tasks.max": "1",
                    "key.converter":"org.apache.kafka.connect.storage.StringConverter",
                    "value.converter":"org.apache.kafka.connect.storage.StringConverter",
                    "confluent.topic.bootstrap.servers": "broker:9092",
                    "confluent.topic.replication.factor":1,
                    "hbase.zookeeper.quorum": "hbase",
                    "hbase.zookeeper.property.clientPort": "2181",
                    "auto.create.tables": "true",
                    "auto.create.column.families": "true",
                    "table.name.format": "example_table",
                    "topics": "hbase-test"
          }}' \
     http://localhost:8083/connectors | jq .

sleep 10

echo "Verify data is in HBase: type scan 'example_table' and then exit"
docker exec -it hbase /bin/bash entrypoint.sh
