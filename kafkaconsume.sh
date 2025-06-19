#!/bin/bash

# Define Kafka binary path
KAFKA_BIN_PATH="/kaf01/kafka/bin"

# Define Kafka bootstrap servers
BOOTSTRAP_SERVERS="ip:port,ip:port,ip:port"

# Duration to consume logs for each topic in seconds
CONSUME_DURATION_SECONDS=3

# List of Kafka topics to check
TOPIC_NAMES=(
    "Example : bcc"
    "add topucs name"
    "........"
)

echo "---"
echo "Starting Kafka log check process..."
echo "Bootstrap Servers: ${BOOTSTRAP_SERVERS}"
echo "Check duration per topic: ${CONSUME_DURATION_SECONDS} seconds"
echo "---"

# Function to check for actual log content in a topic
# It runs the consumer, captures output, and filters out common status messages.
check_for_logs() {
    local topic_name="$1"
    # Use a temporary file with a unique ID (PID) to store consumer output for analysis
    local output_file="/tmp/kafka_consumer_output_${topic_name}_$$.txt"

    echo "  Checking topic: ${topic_name} for logs (waiting ${CONSUME_DURATION_SECONDS}s)..."

    # Run the consumer with timeout.
    # --from-beginning: Start consuming from the earliest offset.
    # --max-messages 1: Exit after consuming 1 message (if logs exist), which speeds up the check.
    # &> "$output_file": Redirect both stdout and stderr to the temporary file.
    timeout "${CONSUME_DURATION_SECONDS}s" \
        "${KAFKA_BIN_PATH}/kafka-console-consumer.sh" \
        --bootstrap-server "${BOOTSTRAP_SERVERS}" \
        --topic "${topic_name}" \
        --from-beginning \
        --max-messages 1 \
        &> "$output_file"

    # Check if the temporary file exists and has content.
    if [ -s "$output_file" ]; then
        # Filter out common Kafka/Java log prefixes and console consumer status messages.
        # We're looking for lines that are actual data messages.
        FILTERED_MESSAGES=$(grep -vE '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} (INFO|WARN|ERROR|DEBUG|TRACE|FATAL) ' \
                                "$output_file" | \
                            grep -vE '^(Processed a total of|Consumed [0-9]+ messages in|Starting consumer|\[[0-9]+\] (DEBUG|INFO|WARN|ERROR|FATAL)|^$|^[[:space:]]*$|^\[main\])' \
                           )

        # Count the number of lines that are likely actual messages
        MESSAGE_COUNT=$(echo "$FILTERED_MESSAGES" | wc -l)

        if [ "$MESSAGE_COUNT" -gt 0 ]; then
            echo "  --> Topic ${topic_name} HAS logs. Displaying the first few lines:"
            echo "$FILTERED_MESSAGES" | head -n 5
            # Clean up the temporary file
            rm -f "$output_file"
            return 0 # Logs found
        else
            echo "  --> Topic ${topic_name} does NOT appear to have new logs in the last ${CONSUME_DURATION_SECONDS} seconds or only contains boilerplate messages."
            # Clean up the temporary file
            rm -f "$output_file"
            return 1 # No logs found
        fi
    else
        echo "  --> Topic ${topic_name} did not produce any output (could be empty or connection issue)."
        # Even if the file is empty, try to remove it
        rm -f "$output_file"
        return 1
    fi
}

# Loop through each topic and check for logs
for TOPIC in "${TOPIC_NAMES[@]}"; do
    check_for_logs "${TOPIC}"
    echo "---"
done

echo "Kafka log check process completed."
