#!/bin/bash

# 定义需要设置为up的接口列表
interfaces=(
    "ens7f0np0"
    "ens7f1np1"
    "ens11f0np0"
    "ens11f1np1"
    "enp158s0f0np0"
    "enp158s0f1np1"
    "enp177s0f0np0"
    "enp177s0f1np1"
)

# 遍历所有接口并设置为up
for iface in "${interfaces[@]}"; do
    echo "Setting interface $iface up..."
    ip link set "$iface" up

    # 检查操作是否成功
    if [ $? -eq 0 ]; then
        echo "Successfully set $iface up"
    else
        echo "Failed to set $iface up" >&2
    fi
done

echo "All specified interfaces have been processed."

