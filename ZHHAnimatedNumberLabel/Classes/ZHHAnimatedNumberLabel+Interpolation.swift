//
//  ZHHAnimatedNumberLabel+Interpolation.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.

//  插值动画引擎，适合百分比、金额、积分、统计数值等连续变化动画

import QuartzCore
import UIKit

// MARK: - 插值引擎

extension ZHHAnimatedNumberLabel {

    /// 从指定值开始动画到目标值，自定义动画持续时间。
    func animateInterpolateValue(_ startValue: CGFloat, toValue endValue: CGFloat, duration: TimeInterval) {
        startingValue = startValue
        destinationValue = endValue
        cancelDigitAnimations()
        digitContainerView.subviews.forEach { $0.removeFromSuperview() }
        logicalDigitString = ""

        // 移除之前的定时器
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil

        // 如果格式为空，使用默认格式
        if zhh_format == nil {
            zhh_format = "%f"
        }

        // 如果时长为0，直接设置目标值并结束
        if duration == 0.0 {
            setDisplayedValueByInterpolation(endValue)
            runCompletionIfNeeded()
            return
        }

        progressTime = 0
        totalTime = duration
        lastUpdate = CACurrentMediaTime()

        // 使用弱引用代理创建定时器，避免 CADisplayLink 强引用 target 导致循环引用
        let proxy = ZHHWeakDisplayLinkProxy(target: self)
        let link = CADisplayLink(target: proxy, selector: #selector(proxy.handleDisplayLink(_:)))
        link.add(to: .main, forMode: .common)
        displayLinkProxy = proxy
        displayLink = link
    }

    // MARK: - 动画更新

    /// 更新动画值并刷新显示。
    @objc func handleDisplayLink(_ link: CADisplayLink) {
        let now = CACurrentMediaTime()
        progressTime += now - lastUpdate
        lastUpdate = now

        if progressTime >= totalTime {
            displayLink?.invalidate()
            displayLink = nil
            displayLinkProxy = nil
            progressTime = totalTime
        }

        setDisplayedValueByInterpolation(zhh_currentValue())

        if progressTime >= totalTime {
            runCompletionIfNeeded()
        }
    }

    /// 设置当前显示值，支持自定义格式。
    func setDisplayedValueByInterpolation(_ value: CGFloat) {
        if let block = zhh_attributedFormatBlock {
            attributedText = block(value)
            return
        }
        if let block = zhh_formatBlock {
            text = block(value)
            return
        }
        let fmt = zhh_format ?? "%f"
        if let regex = integerFormatRegex,
           regex.firstMatch(in: fmt, options: [], range: NSRange(location: 0, length: (fmt as NSString).length)) != nil {
            text = String(format: fmt, safeIntValue(value))
        } else {
            text = String(format: fmt, value)
        }
    }

    /// 停止当前插值动画并重置进度状态。
    func stopInterpolationIfNeeded() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
        progressTime = 0
        totalTime = 0
    }
}
