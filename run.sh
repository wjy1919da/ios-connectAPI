#!/bin/bash

# BabyCareUI 快速启动脚本

echo "🚀 启动 BabyCareUI 项目..."
echo ""

# 检查 Xcode 是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误: 未找到 Xcode。请先安装 Xcode。"
    exit 1
fi

echo "✅ 检测到 Xcode"
echo ""

# 选项菜单
echo "请选择启动方式："
echo "1. 在 Xcode 中打开项目（推荐）"
echo "2. 在 iPhone 15 模拟器中运行"
echo "3. 在 iPhone 15 Pro 模拟器中运行"
echo "4. 列出所有可用模拟器"
echo "5. 仅构建项目"
echo ""
read -p "请输入选项 (1-5): " choice

case $choice in
    1)
        echo "📱 正在打开 Xcode..."
        open BabyCareUI.xcodeproj
        echo "✅ 已在 Xcode 中打开项目！"
        echo "   提示: 按 ⌘R 运行应用"
        ;;
    2)
        echo "🔨 正在构建并启动 iPhone 15 模拟器..."
        xcrun simctl boot "iPhone 15" 2>/dev/null || true
        xcodebuild -project BabyCareUI.xcodeproj \
            -scheme BabyCareUI \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -configuration Debug \
            build
        echo "✅ 构建完成！正在启动应用..."
        xcrun simctl install booted BabyCareUI.app
        xcrun simctl launch booted com.babycare.BabyCareUI
        ;;
    3)
        echo "🔨 正在构建并启动 iPhone 15 Pro 模拟器..."
        xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || true
        xcodebuild -project BabyCareUI.xcodeproj \
            -scheme BabyCareUI \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -configuration Debug \
            build
        echo "✅ 构建完成！"
        ;;
    4)
        echo "📱 可用的 iOS 模拟器："
        xcrun simctl list devices available | grep "iPhone"
        ;;
    5)
        echo "🔨 正在构建项目..."
        xcodebuild -project BabyCareUI.xcodeproj \
            -scheme BabyCareUI \
            -configuration Debug \
            build
        echo "✅ 构建完成！"
        ;;
    *)
        echo "❌ 无效的选项"
        exit 1
        ;;
esac

echo ""
echo "🎉 完成！"
