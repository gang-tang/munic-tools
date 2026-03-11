#!/bin/bash

# RDMA counter paths (adjust if needed)
TX_COUNTER="/sys/class/infiniband/mlx5_4/ports/1/counters/port_xmit_data"
RX_COUNTER="/sys/class/infiniband/mlx5_4/ports/1/counters/port_rcv_data"
INTERVAL_SEC=3  # Sampling interval (seconds)

# Check if counter files exist
if [ ! -f "$TX_COUNTER" ] || [ ! -f "$RX_COUNTER" ]; then
    echo "Error: RDMA counters not found. Are the drivers loaded?"
    exit 1
fi

# Initialize previous values
prev_tx=$(cat "$TX_COUNTER")
prev_rx=$(cat "$RX_COUNTER")

# Function to calculate and format bandwidth
calculate_bandwidth() {
    local delta=$1
    local delta_per_sec=$((delta * 4/ INTERVAL_SEC))
    local gbps=$(echo "scale=2; $delta_per_sec * 8 / 1000000000" | bc)
    echo "$delta_per_sec bytes/sec ($gbps Gbps)"
}

echo "Monitoring RDMA bandwidth (TX/RX) every $INTERVAL_SEC seconds..."
echo "Press Ctrl+C to stop."
echo "-----------------------------------------------"
printf "%-10s | %-20s | %-20s\n" "Time" "TX Rate" "RX Rate"
echo "-----------------------------------------------"

while true; do
    sleep "$INTERVAL_SEC"

    # Read current values
    current_tx=$(cat "$TX_COUNTER")
    current_rx=$(cat "$RX_COUNTER")

    # Calculate deltas
    delta_tx=$((current_tx - prev_tx))
    delta_rx=$((current_rx - prev_rx))

    # Compute bandwidth
    tx_rate=$(calculate_bandwidth "$delta_tx")
    rx_rate=$(calculate_bandwidth "$delta_rx")

    # Print results in a table format
    printf "%-10s | %-20s | %-20s\n" "$(date '+%H:%M:%S')" "$tx_rate" "$rx_rate"

    # Update previous values
    prev_tx=$current_tx
    prev_rx=$current_rx
done

