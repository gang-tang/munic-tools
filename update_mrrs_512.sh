#!/bin/bash
# 简化版本 - 直接执行

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用sudo运行此脚本"
    exit 1
fi

# 获取所有vendor id为2290的设备并执行setpci
echo "开始处理vendor ID为0x8848的设备..."
echo "====================================="

count=0
success=0

# 查找并处理设备
lspci -D -d 8848: 2>/dev/null | awk '{print $1}' | while read bdf; do
    if [ -n "$bdf" ]; then
        count=$((count + 1))
        echo ""
        echo "处理设备 $count: $bdf"
        echo "原始值: $(setpci -s $bdf 78.l 2>/dev/null || echo 'N/A')"

        # 执行setpci命令
	if setpci -s "$bdf" CAP_EXP+08.w=2000:7000 2>/dev/null; then
            echo "新值: $(setpci -s $bdf 78.l 2>/dev/null || echo 'N/A')"
            echo "状态: 成功"
            success=$((success + 1))
        else
            echo "状态: 失败"
        fi
    fi
done

echo ""
echo "====================================="
echo "处理完成!"
echo "找到设备: $count 个"
echo "成功配置: $success 个"
echo "====================================="

