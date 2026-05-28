//
//  ZHHAnimatedNumberLabel+Formatting.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.

//  文本格式化工具与正则匹配

import Foundation

// MARK: - 正则常量

/// 整数格式检测正则（与 `zhh_setTextValue:` 中正则行为一致）
let integerFormatRegex: NSRegularExpression? = {
    try? NSRegularExpression(pattern: "%[^fega]*[dioux]", options: [])
}()

/// 数字主体正则，用于从文本中提取前缀、数字主体和后缀
let animatedNumberBodyRegex: NSRegularExpression? = {
    try? NSRegularExpression(pattern: "[+-]?(?:\\d[\\d,]*)(?:\\.\\d+)?", options: [])
}()

// MARK: - 格式化工具

extension ZHHAnimatedNumberLabel {

    /// 按当前格式配置生成最终显示字符串。
    func formatString(value: CGFloat) -> String {
        let fmt = zhh_format ?? "%f"
        if let regex = integerFormatRegex,
           regex.firstMatch(in: fmt, options: [], range: NSRange(location: 0, length: (fmt as NSString).length)) != nil {
            return String(format: fmt, safeIntValue(value))
        }
        return String(format: fmt, value)
    }

    /// 安全的 Int 转换，防止 CGFloat 超出 Int 范围导致溢出崩溃
    /// - Parameter value: 待转换的浮点值
    /// - Returns: 安全范围内的 Int 值
    func safeIntValue(_ value: CGFloat) -> Int {
        guard value.isFinite else { return 0 }
        // 使用安全边界值，确保在 Int64 范围内不会溢出
        let safeMax: CGFloat = 9.2e18
        let safeMin: CGFloat = -9.2e18
        if value >= safeMax { return Int.max }
        if value <= safeMin { return Int.min }
        return Int(value)
    }

    // MARK: - 动画工具方法

    /// 运行完成后的回调。
    func runCompletionIfNeeded() {
        guard let completion = zhh_completionBlock else { return }
        zhh_completionBlock = nil
        completion()
    }
}
