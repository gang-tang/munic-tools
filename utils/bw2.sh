# Interface name (adjust as needed)
INTERFACE="ens7f0np0"
INTERVAL_SEC=3  # Sampling interval (seconds)

# Function to fetch RDMA bytes from ethtool
get_rdma_bytes() {
    local type=$1  # "tx" or "rx"
    sudo ethtool -S $INTERFACE | grep "${type}_vport_rdma_unicast_bytes" | awk '{print $2}'
}

# Verify ethtool supports the counters
if ! sudo ethtool -S $INTERFACE | grep -q "_vport_rdma_unicast_bytes"; then
    echo "Error: RDMA counters not found in ethtool for $INTERFACE."
    echo "Ensure the NIC is RDMA-capable and drivers are loaded."
    exit 1
fi

# Initialize previous values
prev_tx=$(get_rdma_bytes "tx")
prev_rx=$(get_rdma_bytes "rx")

# Bandwidth calculation function
calculate_rate() {
    local delta=$1
    local delta_per_sec=$(echo "scale=2; $delta / $INTERVAL_SEC" | bc)
    local gbps=$(echo "scale=2; $delta_per_sec * 8 / 1000000000" | bc)
    echo "$delta_per_sec bytes/sec ($gbps Gbps)"
}

echo "Monitoring RDMA TX/RX bandwidth via ethtool every $INTERVAL_SEC seconds..."
echo "Press Ctrl+C to stop."
echo "-----------------------------------------------"
printf "%-10s | %-20s | %-20s\n" "Time" "TX Rate" "RX Rate"
echo "-----------------------------------------------"

while true; do
    sleep "$INTERVAL_SEC"

    # Get current values
    current_tx=$(get_rdma_bytes "tx")
    current_rx=$(get_rdma_bytes "rx")

    # Calculate deltas
    delta_tx=$((current_tx - prev_tx))
    delta_rx=$((current_rx - prev_rx))

    # Compute rates
    tx_rate=$(calculate_rate "$delta_tx")
    rx_rate=$(calculate_rate "$delta_rx")

    # Print results
    printf "%-10s | %-20s | %-20s\n" "$(date '+%H:%M:%S')" "$tx_rate" "$rx_rate"

    # Update previous values
    prev_tx=$current_tx
    prev_rx=$current_rx
done

