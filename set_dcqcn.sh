#!/bin/bash
# 简化版本 - 直接执行

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用sudo运行此脚本"
    exit 1
fi

DBG_PCI=/home/munic/hihan/sw/sw-driver/tools/dbg-pci/dbg-pci

case "${1:-disable}" in
    disable)
        dcqcn_value=0xC0000001
        ;;
    enable)
        dcqcn_value=0xC0000011
        ;;
    *)
        echo "用法: $0 [disable|enable]"
        exit 1
        ;;
esac

echo "开始${1:-disable} vendor ID为0x8848的设备DCQCN功能..."
echo "====================================="

count=0
success=0

# 查找并处理设备
while read bdf; do
    if [ -n "$bdf" ] && [[ "$bdf" == *.0 ]]; then
        count=$((count + 1))
        echo ""
        echo "处理设备 $count: $bdf"
        
        if "$DBG_PCI" -s "$bdf" --writebar 4 -o 0x8e120 --val "$dcqcn_value"; then
            echo "状态: 成功"
            success=$((success + 1))
        else
            echo "状态: 失败"
        fi
    fi
done < <(lspci -D -d 8848: 2>/dev/null | awk '{print $1}')

echo ""
echo "====================================="
echo "处理完成!"
echo "找到设备: $count 个"
echo "成功配置: $success 个"
echo "====================================="
