#!/bin/bash

# File paths
MONITOR_DIR="/private-data"  # Path to the shared volume
START_SIGNAL="$MONITOR_DIR/start_signal.txt"
STOP_SIGNAL="$MONITOR_DIR/stop_signal.txt"
LOG_FILE="$MONITOR_DIR/energy_log_c38.txt"

# Wait for start signal
while [ ! -f "$START_SIGNAL" ]; do
    sleep 1
done

#echo "$(date): Energy monitoring started" >> $LOG_FILE

# Start monitoring
while [ ! -f "$STOP_SIGNAL" ]; do
    cat /energy-data/node-c38/intel-rapl:0/energy_uj >> $LOG_FILE
    (date +"%H:%M:%S.%3N") >> $LOG_FILE
    sleep 0.$(printf '%04d' $((10000 - 10#$(date +%4N))))
done

#echo "$(date): Energy monitoring stopped" >> $LOG_FILE
rm -f "$START_SIGNAL" #"$STOP_SIGNAL"
