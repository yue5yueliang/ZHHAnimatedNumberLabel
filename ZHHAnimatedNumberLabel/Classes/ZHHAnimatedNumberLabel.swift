//
//  ZHHAnimatedNumberLabel.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

import QuartzCore
import UIKit

// MARK: - Public Enums

/// UILabel 数字变化的动画方法
@objc(ZHHNumberAnimationStyle)
public enum ZHHNumberAnimationStyle: Int {
    /// 缓入缓出效果：动画以较慢速度开始和结束，中间加速。
    case easeInOut = 0
    /// 缓入效果：动画以较慢速度开始，然后逐渐加速。
    case easeIn = 1
    /// 缓出效果：动画以较快速度开始，然后逐渐减速。
    case easeOut = 2
    /// 线性效果：动画以恒定的速度进行。
    case linear = 3
    /// 缓入弹跳效果：动画以弹跳的方式逐渐加速进入。
    case easeInBounce = 4
    /// 缓出弹跳效果：动画以弹跳的方式逐渐减速结束。
    case easeOutBounce = 5
}

/// 动画引擎类型
@objc(ZHHAnimationEngine)
public enum ZHHAnimationEngine: Int {
    /// 插值引擎（默认）
    case interpolate = 0
    /// 按位滚动引擎
    case digitScroll = 1
}

/// 按位滚动风格
@objc(ZHHDigitScrollStyle)
public enum ZHHDigitScrollStyle: Int {
    /// 默认平滑滚动
    case smooth = 0
    /// 带坠落感的滚动
    case drop = 1
}

// MARK: - Public Type Aliases

/// 格式化的 Block，接收一个 `CGFloat` 值，返回格式化后的 `String`
public typealias ZHHAnimatedNumberLabelFormatBlock = (CGFloat) -> String?

/// 格式化的 Block，接收一个 `CGFloat` 值，返回格式化后的 `NSAttributedString`
public typealias ZHHAnimatedNumberLabelAttributedFormatBlock = (CGFloat) -> NSAttributedString?

// MARK: - Weak DisplayLink Proxy

/// 弱引用代理，避免 CADisplayLink 对 target 的强引用导致循环引用
final class ZHHWeakDisplayLinkProxy {
    private weak var target: ZHHAnimatedNumberLabel?

    init(target: ZHHAnimatedNumberLabel) {
        self.target = target
    }

    @objc func handleDisplayLink(_ link: CADisplayLink) {
        guard let target = target else {
            link.invalidate()
            return
        }
        target.handleDisplayLink(link)
    }
}

// MARK: - ZHHAnimatedNumberLabel

/// 动态数字变化的 UILabel，支持多种动画效果
@objcMembers
public class ZHHAnimatedNumberLabel: UILabel {

    // MARK: - Public Properties

    /// 显示数字的格式化字符串，例如：`@"%.2f"`、`@"%d"`
    /// 如果未设置 `formatBlock` 或 `attributedFormatBlock`，将使用此属性进行格式化
    @objc public var zhh_format: String?

    /// 数字变化的动画方法，例如线性变化、缓入缓出等
    @objc public var zhh_animationStyle: ZHHNumberAnimationStyle = .easeInOut

    /// 动画引擎，默认插值引擎
    @objc public var zhh_animationEngine: ZHHAnimationEngine = .interpolate

    /// 动画持续的时间，单位为秒，默认值为 2.0 秒
    @objc public var zhh_animationDuration: TimeInterval = 2.0

    /// 按位滚动动画持续时长，默认值为 0.35 秒
    @objc public var zhh_digitAnimationDuration: TimeInterval = 0.35

    /// 按位滚动延迟间隔，默认值为 0.03 秒
    @objc public var zhh_digitStagger: TimeInterval = 0.03

    /// 按位滚动是否使用弹簧动画，默认值为 YES
    @objc public var zhh_digitUseSpring: Bool = true

    /// 按位滚动风格，默认平滑滚动
    @objc public var zhh_digitScrollStyle: ZHHDigitScrollStyle = .smooth

    /// 按位滚动数字位宽度缩放系数，默认为 0.92（紧凑间距）。
    /// 1.0 = 等宽模式（间距大但绝对不抖），0.0 = 各字符实际宽度（最紧凑）。
    @objc public var zhh_digitWidthScale: CGFloat = 0.92

    /// 格式化回调 Block，返回一个自定义的 `String`
    /// 设置此属性时，优先级高于 `format`
    @objc public var zhh_formatBlock: ZHHAnimatedNumberLabelFormatBlock?

    /// 格式化回调 Block，返回一个自定义的 `NSAttributedString`
    /// 设置此属性时，优先级高于 `formatBlock`
    @objc public var zhh_attributedFormatBlock: ZHHAnimatedNumberLabelAttributedFormatBlock?

    /// 动画完成时的回调 Block
    @objc public var zhh_completionBlock: (() -> Void)?

    // MARK: - Internal Properties（供扩展访问）

    /// 插值动画相关属性
    var startingValue: CGFloat = 0
    var destinationValue: CGFloat = 0
    var progressTime: TimeInterval = 0
    var lastUpdate: TimeInterval = 0
    var totalTime: TimeInterval = 0

    /// 定时器
    var displayLink: CADisplayLink?
    var displayLinkProxy: ZHHWeakDisplayLinkProxy?

    /// 按位滚动相关属性
    var displayedDigitString: String = ""
    var logicalDigitString: String = ""
    var digitContainerView: UIView = UIView()
    var digitAnimationToken: Int = 0

    /// 布局缓存
    var cachedDigitWidth: CGFloat = 0
    var cachedLayoutFont: UIFont?

    // MARK: - Initialization

    /// 使用代码方式初始化组件。
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDigitContainerIfNeeded()
    }

    /// 使用归档方式初始化组件。
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDigitContainerIfNeeded()
    }

    /// 布局变化时同步更新按位滚动容器与当前显示内容。
    public override func layoutSubviews() {
        super.layoutSubviews()
        digitContainerView.frame = bounds
        if zhh_animationEngine == .digitScroll, bounds.width > 0, bounds.height > 0 {
            let currentText = logicalDigitString.isEmpty ? displayedDigitString : logicalDigitString
            if !currentText.isEmpty {
                renderDigitTextImmediately(currentText)
            }
        }
    }

    /// font 变更时清空布局缓存
    public override var font: UIFont! {
        didSet {
            cachedLayoutFont = nil
            cachedDigitWidth = 0
        }
    }

    /// 释放前停止插值动画定时器。
    deinit {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
    }
}

// MARK: - 动画启动方法（路由）

public extension ZHHAnimatedNumberLabel {
    /// 从指定的起始值动画到目标值，使用默认的动画时长
    /// - Parameters:
    ///   - startValue: 动画的起始值
    ///   - endValue: 动画的目标值
    @objc func zhh_animateValue(_ startValue: CGFloat, toValue endValue: CGFloat) {
        zhh_animateValue(startValue, toValue: endValue, duration: zhh_animationDuration)
    }

    /// 从指定的起始值动画到目标值，使用自定义的动画时长
    /// - Parameters:
    ///   - startValue: 动画的起始值
    ///   - endValue: 动画的目标值
    ///   - duration: 动画的持续时间（秒）
    @objc func zhh_animateValue(_ startValue: CGFloat, toValue endValue: CGFloat, duration: TimeInterval) {
        destinationValue = endValue
        if zhh_animationEngine == .digitScroll, canUseDigitScrollEngine {
            stopInterpolationIfNeeded()
            animateDigitString(from: formatString(value: startValue), to: formatString(value: endValue), duration: duration)
            return
        }
        animateInterpolateValue(startValue, toValue: endValue, duration: duration)
    }

    /// 从当前值开始动画过渡到目标值，使用默认动画时长
    /// - Parameter endValue: 最终显示的目标值
    @objc func zhh_animateToValue(_ endValue: CGFloat) {
        zhh_animateValue(zhh_currentValue(), toValue: endValue)
    }

    /// 从当前值开始动画过渡到目标值，可自定义动画时长
    /// - Parameters:
    ///   - endValue: 最终显示的目标值
    ///   - duration: 动画持续时间（单位：秒）
    @objc func zhh_animateToValue(_ endValue: CGFloat, duration: TimeInterval) {
        zhh_animateValue(zhh_currentValue(), toValue: endValue, duration: duration)
    }

    /// 从 0 开始动画过渡到目标值，使用默认动画时长
    /// - Parameter endValue: 最终显示的目标值
    @objc func zhh_animateFromZeroToValue(_ endValue: CGFloat) {
        zhh_animateValue(0.0, toValue: endValue)
    }

    /// 从 0 开始动画过渡到目标值，可自定义动画时长
    /// - Parameters:
    ///   - endValue: 最终显示的目标值
    ///   - duration: 动画持续时间（单位：秒）
    @objc func zhh_animateFromZeroToValue(_ endValue: CGFloat, duration: TimeInterval) {
        zhh_animateValue(0.0, toValue: endValue, duration: duration)
    }

    /// 获取当前动画进度对应的数值
    /// - Returns: 当前动画的数值
    @objc func zhh_currentValue() -> CGFloat {
        if zhh_animationEngine == .digitScroll {
            return destinationValue
        }
        guard totalTime > 0, progressTime < totalTime else {
            return destinationValue
        }
        let percent = CGFloat(progressTime / totalTime)
        let updateVal = ZHHAnimationEasing.progress(for: zhh_animationStyle, t: min(1, max(0, percent)))
        return startingValue + (updateVal * (destinationValue - startingValue))
    }

    /// 当前是否正在执行动画
    @objc var zhh_isAnimating: Bool {
        if zhh_animationEngine == .digitScroll {
            return digitContainerView.subviews.contains(where: { subview in
                let hasAnimation = subview.layer.animationKeys()?.isEmpty == false
                let nestedHasAnimation = subview.subviews.contains(where: {
                    $0.layer.animationKeys()?.isEmpty == false
                })
                return hasAnimation || nestedHasAnimation
            })
        }
        return displayLink != nil
    }

    /// 取消当前动画，立即显示目标值
    @objc func zhh_cancelAnimation() {
        if zhh_animationEngine == .digitScroll {
            cancelDigitAnimations()
            let finalText = logicalDigitString.isEmpty ? displayedDigitString : logicalDigitString
            if !finalText.isEmpty {
                renderDigitTextImmediately(finalText)
            }
        } else {
            stopInterpolationIfNeeded()
            setDisplayedValueByInterpolation(destinationValue)
            runCompletionIfNeeded()
        }
    }
}
