#!/bin/bash

# Define Kafka binary path
KAFKA_BIN_PATH="/kaf01/kafka/bin"

# Define Kafka bootstrap servers
BOOTSTRAP_SERVERS="ip:port,ip:port,ip:port"

# Define topic configurations
PARTITIONS=8
REPLICATION_FACTOR=3

# List of Kafka topics to create
TOPIC_NAMES=(
    "Example : bcc-nsb-srps-sila"
    "topics name"
    "......."
)

echo "---"
echo "Starting Kafka topic creation process..."
echo "Bootstrap Servers: ${BOOTSTRAP_SERVERS}"
echo "Partitions: ${PARTITIONS}"
echo "Replication Factor: ${REPLICATION_FACTOR}"
echo "---"

# Loop through each topic name and create it
for TOPIC in "${TOPIC_NAMES[@]}"; do
    echo "Attempting to create topic: ${TOPIC}..."

    # Construct and execute the command
    "${KAFKA_BIN_PATH}/kafka-topics.sh" \
        --bootstrap-server "${BOOTSTRAP_SERVERS}" \
        --topic "${TOPIC}" \
        --create \
        --partitions "${PARTITIONS}" \
        --replication-factor "${REPLICATION_FACTOR}"

    # Check the exit status of the previous command
    if [ $? -eq 0 ]; then
        echo "  Successfully created topic: ${TOPIC}"
    else
        echo "  Failed to create topic: ${TOPIC}. Please check the error message above."
        # Optionally, uncomment the next line to stop on the first error
        # exit 1
    fi
    echo "---"
done

echo "Kafka topic creation process completed."
echo ""

# --- Displaying all created topics ---
echo "---"
echo "Displaying all topics on bootstrap servers: ${BOOTSTRAP_SERVERS}"
echo "---"

"${KAFKA_BIN_PATH}/kafka-topics.sh" \
    --bootstrap-server "${BOOTSTRAP_SERVERS}" \
    --list

echo "---"
echo "Verification complete."
