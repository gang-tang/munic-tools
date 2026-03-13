#!/bin/bash

# Configuration
APP_DIR="/home/munic/hihan/sw/sw-driver/tools/rsu-tool/app"
RPD_FILE="/home/munic/FPGA_BITS/munic_test_r2126/munic_test.rpd"
VENDOR_ID="8848"

if [[ $EUID -ne 0 ]]; then
   echo "Please run with sudo"
   exit 1
fi

# --- Dynamic Device Detection ---
# This replaces the manual DEVICES=(29 3b 4b...)
# 1. lspci finds vendor 8848
# 2. cut grabs the Bus ID
# 3. sort -u ensures we don't start two screens for the same card
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
    # We use sudo inside the bash -c to ensure the tool has hardware access
    screen -dmS "$SESSION" bash -c "
        cd $APP_DIR && \
        sudo ./munic_rsu -d $dev -u $RPD_FILE -s 0
    "

    echo "Started screen session: $SESSION for Bus $dev"
done

echo "-------------------------------------------------------"
echo "All sessions started. Use 'screen -ls' to monitor them."
