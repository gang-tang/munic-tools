#!/bin/bash

# Configuration
APP_DIR="/home/munic/hihan/sw/sw-driver/tools/rsu-tool/app"
RPD_FILE="/home/munic/FPGA_BITS/munic_test_r2126/munic_test.rpd"
VENDOR_ID="8848"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run with sudo"
   exit 1
fi

# --- Global Concurrency Check ---
# Check if any screen sessions starting with 'rsu_' already exist.
# Note: We use 'sudo screen -ls' because the sessions are owned by root.
if sudo screen -ls | grep -q "\.rsu_"; then
    echo "-------------------------------------------------------"
    echo "ERROR: An upgrade task is already running in screen!"
    echo "Active sessions found:"
    sudo screen -ls | grep "\.rsu_"
    echo "Please wait for these to finish or kill them before restarting."
    echo "-------------------------------------------------------"
    exit 1
fi

# --- Dynamic Device Detection ---
DEVICES=($(lspci -d "${VENDOR_ID}:" | cut -d':' -f1 | sort -u))

# Safety check: Exit if no devices are found
if [ ${#DEVICES[@]} -eq 0 ]; then
    echo "Error: No PCIe devices with Vendor ID $VENDOR_ID found."
    exit 1
fi

echo "Found ${#DEVICES[@]} device(s) on bus(es): ${DEVICES[*]}"
echo "-------------------------------------------------------"

# --- Loop and Launch ---
for dev in "${DEVICES[@]}"; do
    SESSION="rsu_${dev}"

    # -dmS creates a detached screen session
    # No need for 'sudo' inside the bash -c because the script is already root
    screen -dmS "$SESSION" bash -c "
        cd $APP_DIR && \
        ./munic_rsu -d $dev -u $RPD_FILE -s 0
    "

    echo "Started screen session: $SESSION for Bus $dev"
done

echo "-------------------------------------------------------"
echo "All sessions started. Use 'sudo screen -ls' to monitor them."
