#!/bin/bash
# 简化版本 - 直接执行

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用sudo运行此脚本"
    exit 1
fi

DBG_PCI=/home/munic/mucse/sw/sw-driver/tools/dbg-pci/dbg-pci

case "${1:-disable}" in
    disable)
        sack_value_1=0x0
        sack_value_2=0x8008081E
        sack_value_3=0x8008081E
        ;;
    enable)
        sack_value_1=0x1
        sack_value_2=0x1808081E
        sack_value_3=0x1808081E
        ;;
    *)
        echo "用法: $0 [disable|enable]"
        exit 1
        ;;
esac

echo "开始${1:-disable} vendor ID为0x8848的设备sack功能..."
echo "====================================="

count=0
success=0

# 查找并处理设备
while read bdf; do
    if [ -n "$bdf" ] && [[ "$bdf" == *.0 ]]; then
        count=$((count + 1))
        echo ""
        echo "处理设备 $count: $bdf"
        
        if "$DBG_PCI" -s "$bdf" --writebar 4 -o 0x82114 --count 1 --val "$sack_value_1" \
            && "$DBG_PCI" -s "$bdf" --writebar 4 -o 0x90140 --count 1 --val "$sack_value_2" \
            && "$DBG_PCI" -s "$bdf" --writebar 4 -o 0x84140 --count 1 --val "$sack_value_3"; then
            echo "状态: 成功"
            success=$((success + 1))
        else
            echo "状态: 失败"
        fi
    fi
done < <(lspci -D -d 8848:8620 2>/dev/null | awk '{print $1}')

echo ""
echo "====================================="
echo "处理完成!"
echo "找到设备: $count 个"
echo "成功配置: $success 个"
echo "====================================="

