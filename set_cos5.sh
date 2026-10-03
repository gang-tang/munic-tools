#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi

DBG_PCI=${DBG_PCI:-/home/munic/mucse/sw/sw-driver/tools/dbg-pci/dbg-pci}
if [[ ! -x "$DBG_PCI" ]]; then
    echo "dbg-pci is not executable: $DBG_PCI" >&2
    exit 1
fi

OFFSETS=(
    0x70230 0x70234 0x70238 0x7023c
    0x70290 0x70294 0x70298 0x7029c
    0x70250 0x70254 0x70258 0x7025c
    0x702b0 0x702b4 0x702b8 0x702bc
    0x70270 0x70274 0x70278 0x7027c
    0x702d0 0x702d4 0x702d8 0x702dc
    0x70068 0x7006c 0x70088 0x7008c
    0x700b0 0x700b4 0x700d0 0x700d4
    0x70028 0x700E8 0x700EC 0x700F0
)

VALUES=(
    0 0 0x03000400 0x03000200
    0 0 0x03000400 0x03000200
    0 0 0x000002EE 0x000001EE
    0 0 0x000002EE 0x000001EE
    0 0 0x00000355 0x00000355
    0 0 0x00000355 0x00000355
    0x66666550 0x66666666 0x66666550 0x66666666
    0x00066560 0x50000000 0x00066560 0x50000000
    0x0036161F 0x40402001 0x40402001 5
)

device_count=0
successful_devices=0
failed_writes=0

while IFS= read -r bdf; do
    [[ -n "$bdf" && "$bdf" == *.0 ]] || continue

    device_count=$((device_count + 1))
    echo "Configuring $bdf"
    device_failed=0

    for index in "${!OFFSETS[@]}"; do
        offset=${OFFSETS[$index]}
        value=${VALUES[$index]}
        if ! "$DBG_PCI" -s "$bdf" --writebar 4 -o "$offset" --val "$value"; then
            echo "  FAILED: offset $offset value $value" >&2
            device_failed=1
            failed_writes=$((failed_writes + 1))
        fi
    done

    if (( device_failed == 0 )); then
        echo "  Status: success"
        successful_devices=$((successful_devices + 1))
    else
        echo "  Status: failed"
    fi
done < <(lspci -D -d 8848:8620 2>/dev/null | awk '{print $1}')

echo "Devices matched: $device_count"
echo "Devices configured successfully: $successful_devices"
echo "Failed writes: $failed_writes"

if (( failed_writes > 0 || device_count == 0 )); then
    exit 1
fi
