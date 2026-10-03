#!/usr/bin/env bash

REGOP_SCRIPT="/home/munic/hihan/sw/sw-driver/tools/test/RDMA_operation/regop.py"

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script with sudo" >&2
    exit 1
fi

if ! rdma_links=$(rdma link); then
    echo "Failed to retrieve RDMA links" >&2
    exit 1
fi

rdma_devices=$(awk '$1 == "link" { split($2, parts, "/"); print parts[1] }' <<< "$rdma_links" | sort -u)

if [[ -z "$rdma_devices" ]]; then
    echo "No RDMA devices found"
    exit 0
fi

found=0
success=0

while IFS= read -r rdma_device; do
    [[ -n "$rdma_device" ]] || continue

    sysfs_device="/sys/class/infiniband/${rdma_device}/device"
    [[ -r "$sysfs_device/vendor" && -r "$sysfs_device/device" ]] || continue

    vendor=$(< "$sysfs_device/vendor")
    device=$(< "$sysfs_device/device")
    if [[ "${vendor,,}" != "0x8848" || "${device,,}" != "0x8620" ]]; then
        continue
    fi

    found=$((found + 1))
    echo "Configuring app DSCP map on ${rdma_device} (PCI ${vendor}:${device})"
    if python3 "$REGOP_SCRIPT" --devices "$rdma_device" --event appdscp --dscpmap 48,48,40; then
        success=$((success + 1))
    else
        echo "Failed to configure ${rdma_device}" >&2
    fi
done <<< "$rdma_devices"

echo "Matched RDMA devices: ${found}"
echo "Successfully configured: ${success}"
[[ "$success" -eq "$found" ]]