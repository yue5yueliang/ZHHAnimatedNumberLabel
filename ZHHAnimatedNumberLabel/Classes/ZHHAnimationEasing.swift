//
//  ZHHAnimationEasing.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.

//  动画缓动函数，用于控制动画的非线性程度

import UIKit

/// 动画缓动函数集合
enum ZHHAnimationEasing {
    /// 缓动速率常量
    private static let rate: Float = 3.0

    /// 线性动画
    static func linear(_ t: CGFloat) -> CGFloat {
        t
    }

    /// 缓入动画（Ease In）
    static func easeIn(_ t: CGFloat) -> CGFloat {
        CGFloat(powf(Float(t), rate))
    }

    /// 缓出动画（Ease Out）
    static func easeOut(_ t: CGFloat) -> CGFloat {
        CGFloat(1 - powf(1 - Float(t), rate))
    }

    /// 缓入缓出动画（Ease In-Out）
    static func easeInOut(_ t: CGFloat) -> CGFloat {
        var x = t * 2.0
        if x < 1.0 {
            return 0.5 * CGFloat(powf(Float(x), rate))
        }
        x = 2.0 - x
        return 0.5 * (2.0 - CGFloat(powf(Float(x), rate)))
    }

    /// 缓出反弹动画（Ease Out Bounce）
    static func easeOutBounce(_ t: CGFloat) -> CGFloat {
        let t = Float(t)
        if t < 4.0 / 11.0 {
            return CGFloat(powf(11.0 / 4.0, 2) * powf(t, 2))
        }
        if t < 8.0 / 11.0 {
            return CGFloat(3.0 / 4.0 + powf(11.0 / 4.0, 2) * powf(t - 6.0 / 11.0, 2))
        }
        if t < 10.0 / 11.0 {
            return CGFloat(15.0 / 16.0 + powf(11.0 / 4.0, 2) * powf(t - 9.0 / 11.0, 2))
        }
        return CGFloat(63.0 / 64.0 + powf(11.0 / 4.0, 2) * powf(t - 21.0 / 22.0, 2))
    }

    /// 缓入反弹动画（Ease In Bounce）
    static func easeInBounce(_ t: CGFloat) -> CGFloat {
        1.0 - easeOutBounce(1.0 - t)
    }

    /// 根据时间 t 计算当前动画进度
    /// - Parameters:
    ///   - style: 动画样式
    ///   - t: 时间进度（范围 [0, 1]）
    /// - Returns: 当前动画进度（范围 [0, 1]）
    static func progress(for style: ZHHNumberAnimationStyle, t: CGFloat) -> CGFloat {
        switch style {
        case .easeInOut: return easeInOut(t)
        case .easeIn: return easeIn(t)
        case .easeOut: return easeOut(t)
        case .linear: return linear(t)
        case .easeInBounce: return easeInBounce(t)
        case .easeOutBounce: return easeOutBounce(t)
        @unknown default: return linear(t)
        }
    }
}
