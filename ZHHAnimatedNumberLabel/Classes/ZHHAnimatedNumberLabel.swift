//
//  ZHHAnimatedNumberLabel.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

import QuartzCore
import UIKit

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

// MARK: - 动画类型实现（原 ZHHUILabelCounter 协议与各计数器类，合并为静态方法）

/// 动画速率常量，用于控制动画的非线性程度
private enum ZHHAnimationEasing {
    private static let rate: Float = 3.0

    /// 线性动画
    static func linear(_ t: CGFloat) -> CGFloat {
        t // 线性动画直接返回时间进度
    }

    /// 缓入动画（Ease In）
    static func easeIn(_ t: CGFloat) -> CGFloat {
        CGFloat(powf(Float(t), rate)) // 时间进度的指数计算，创建缓入效果
    }

    /// 缓出动画（Ease Out）
    static func easeOut(_ t: CGFloat) -> CGFloat {
        CGFloat(1 - powf(1 - Float(t), rate)) // 反向计算，创建缓出效果
    }

    /// 缓入缓出动画（Ease In-Out）
    static func easeInOut(_ t: CGFloat) -> CGFloat {
        var x = t * 2.0 // 将时间进度分为两段
        if x < 1.0 {
            return 0.5 * CGFloat(powf(Float(x), rate)) // 前半段缓入
        }
        x = 2.0 - x
        return 0.5 * (2.0 - CGFloat(powf(Float(x), rate))) // 后半段缓出
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
        // 使用反弹公式计算缓入反弹效果
        1.0 - easeOutBounce(1.0 - t)
    }

/// 根据时间 t 计算当前动画进度（等价于原 `-zhh_update:`）。
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

// MARK: - 整数格式检测（与 `zhh_setTextValue:` 中正则行为一致）

private let integerFormatRegex: NSRegularExpression? = {
    try? NSRegularExpression(pattern: "%[^fega]*[dioux]", options: [])
}()

private let animatedNumberBodyRegex: NSRegularExpression? = {
    try? NSRegularExpression(pattern: "[+-]?(?:\\d[\\d,]*)(?:\\.\\d+)?", options: [])
}()

/// 格式化的 Block，接收一个 `CGFloat` 值，返回格式化后的 `NSString`
public typealias ZHHAnimatedNumberLabelFormatBlock = (CGFloat) -> String?

/// 格式化的 Block，接收一个 `CGFloat` 值，返回格式化后的 `NSAttributedString`
public typealias ZHHAnimatedNumberLabelAttributedFormatBlock = (CGFloat) -> NSAttributedString?

/// 动态数字变化的 UILabel，支持多种动画效果
@objcMembers
public class ZHHAnimatedNumberLabel: UILabel {

    /// 显示数字的格式化字符串，例如：`@"%.2f"`、`@"%d"`
    /// 如果未设置 `formatBlock` 或 `attributedFormatBlock`，将使用此属性进行格式化
    @objc public var zhh_format: String?

    /// 数字变化的动画方法，例如线性变化、缓入缓出等，枚举类型 `UILabelCountingMethod`
    @objc public var zhh_animationStyle: ZHHNumberAnimationStyle = .easeInOut

    /// 动画引擎，默认插值引擎
    @objc public var zhh_animationEngine: ZHHAnimationEngine = .interpolate

    /// 动画持续的时间，单位为秒，默认值为 2.0 秒
    @objc public var zhh_animationDuration: TimeInterval = 0

    /// 按位滚动动画持续时长，默认值为 0.35 秒
    @objc public var zhh_digitAnimationDuration: TimeInterval = 0.35

    /// 按位滚动延迟间隔，默认值为 0.03 秒
    @objc public var zhh_digitStagger: TimeInterval = 0.03

    /// 按位滚动是否使用弹簧动画，默认值为 YES
    @objc public var zhh_digitUseSpring: Bool = true

    /// 按位滚动风格，默认平滑滚动
    @objc public var zhh_digitScrollStyle: ZHHDigitScrollStyle = .smooth

    /// 格式化回调 Block，返回一个自定义的 `NSString`
    /// 设置此属性时，优先级高于 `format`
    @objc public var zhh_formatBlock: ZHHAnimatedNumberLabelFormatBlock?

    /// 格式化回调 Block，返回一个自定义的 `NSAttributedString`
    /// 设置此属性时，优先级高于 `formatBlock`
    @objc public var zhh_attributedFormatBlock: ZHHAnimatedNumberLabelAttributedFormatBlock?

    /// 动画完成时的回调 Block
    @objc public var zhh_completionBlock: (() -> Void)?

    // 插值动画相关属性
    private var startingValue: CGFloat = 0 // 动画起始值
    private var destinationValue: CGFloat = 0 // 动画目标值
    private var progressTime: TimeInterval = 0 // 当前进度时间
    private var lastUpdate: TimeInterval = 0 // 上次更新时间
    private var totalTime: TimeInterval = 0 // 动画总时长

    // 定时器和动画更新策略
    private var displayLink: CADisplayLink? // 定时器

    // 按位滚动相关属性
    private var digitLabels: [UILabel] = []
    private var displayedDigitString: String = "" // 当前已经稳定展示完成的字符串
    private var logicalDigitString: String = "" // 高频连续更新时记录最新目标字符串
    private var digitContainerView: UIView = UIView() // 按位滚动的承载容器
    private var digitAnimationToken: Int = 0 // 防止旧动画 completion 回写新状态

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
            // 布局变化后按最新逻辑字符串重排，避免首帧错位
            let currentText = logicalDigitString.isEmpty ? displayedDigitString : logicalDigitString
            if !currentText.isEmpty {
                renderDigitTextImmediately(currentText)
            }
        }
    }

    /// 释放前停止插值动画定时器。
    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - 动画启动方法（路由）

public extension ZHHAnimatedNumberLabel {
    /// 从指定的起始值 `startValue` 动画到目标值 `endValue`
    /// 使用默认的动画时长
    /// - Parameters:
    ///   - startValue: 动画的起始值
    ///   - endValue: 动画的目标值
    @objc func zhh_animateValue(_ startValue: CGFloat, toValue endValue: CGFloat) {
        if zhh_animationDuration == 0.0 {
            zhh_animationDuration = 2.0 // 默认动画时长为2秒
        }
        zhh_animateValue(startValue, toValue: endValue, duration: zhh_animationDuration)
    }

    /// 从指定的起始值 `startValue` 动画到目标值 `endValue`
    /// 使用自定义的动画时长
    /// - Parameters:
    ///   - startValue: 动画的起始值
    ///   - endValue: 动画的目标值
    ///   - duration: 动画的持续时间（秒）
    @objc func zhh_animateValue(_ startValue: CGFloat, toValue endValue: CGFloat, duration: TimeInterval) {
        destinationValue = endValue
        // 按位滚动仅在可安全拆分字符串时启用，否则自动回退到插值引擎
        if zhh_animationEngine == .digitScroll, canUseDigitScrollEngine {
            stopInterpolationIfNeeded()
            animateDigitString(from: formatString(value: startValue), to: formatString(value: endValue), duration: duration)
            return
        }
        animateInterpolateValue(startValue, toValue: endValue, duration: duration)
    }

    /// 从当前值开始动画过渡到目标值
    /// 使用默认动画时长
    /// - Parameter endValue: 最终显示的目标值
    @objc func zhh_animateToValue(_ endValue: CGFloat) {
        zhh_animateValue(zhh_currentValue(), toValue: endValue)
    }

    /// 从当前值开始动画过渡到目标值
    /// 可自定义动画时长
    /// - Parameters:
    ///   - endValue: 最终显示的目标值
    ///   - duration: 动画持续时间（单位：秒）
    @objc func zhh_animateToValue(_ endValue: CGFloat, duration: TimeInterval) {
        zhh_animateValue(zhh_currentValue(), toValue: endValue, duration: duration)
    }

    /// 从 0 开始动画过渡到目标值
    /// 使用默认动画时长
    /// - Parameter endValue: 最终显示的目标值
    @objc func zhh_animateFromZeroToValue(_ endValue: CGFloat) {
        zhh_animateValue(0.0, toValue: endValue)
    }

    /// 从 0 开始动画过渡到目标值
    /// 可自定义动画时长
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
}

// MARK: - 插值引擎

private extension ZHHAnimatedNumberLabel {
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

        // 创建定时器
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.add(to: .main, forMode: .common)
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
        // 检查是否使用整数格式
        if let regex = integerFormatRegex,
           regex.firstMatch(in: fmt, options: [], range: NSRange(location: 0, length: (fmt as NSString).length)) != nil {
            text = String(format: fmt, Int(value))
        } else {
            text = String(format: fmt, value)
        }
    }

    /// 停止当前插值动画并重置进度状态。
    func stopInterpolationIfNeeded() {
        displayLink?.invalidate()
        displayLink = nil
        progressTime = 0
        totalTime = 0
    }
}

// MARK: - 按位滚动引擎

private extension ZHHAnimatedNumberLabel {
    var canUseDigitScrollEngine: Bool {
        // 富文本和自定义格式化字符串难以稳定拆位，自动回退插值引擎
        zhh_attributedFormatBlock == nil && zhh_formatBlock == nil
    }

    /// 按需创建按位滚动所需的容器视图。
    func setupDigitContainerIfNeeded() {
        if digitContainerView.superview == nil {
            digitContainerView.backgroundColor = .clear
            digitContainerView.clipsToBounds = true
            digitContainerView.frame = bounds
            addSubview(digitContainerView)
        }
    }

    /// 执行整串文本的按位滚动动画。
    func animateDigitString(from oldText: String, to newText: String, duration: TimeInterval) {
        setupDigitContainerIfNeeded()
        cancelDigitAnimations()
        // 每启动一轮新动画就递增一次，用来废弃上一轮尚未回调完成的动画
        digitAnimationToken += 1
        let currentToken = digitAnimationToken
        let animateDuration = duration == 0 ? zhh_digitAnimationDuration : duration
        destinationValue = CGFloat((newText as NSString).doubleValue)
        text = nil
        attributedText = nil

        // 连续触发时，始终以上一次目标值作为新的起点，避免高位重复滚动
        let sourceText = logicalDigitString.isEmpty ? (displayedDigitString.isEmpty ? oldText : displayedDigitString) : logicalDigitString
        // 先写入本轮目标值，后续如果中途又来了新动画，就能从这里继续衔接
        logicalDigitString = newText
        // 每轮都从空容器开始重建，避免旧视图残留造成重叠
        digitContainerView.subviews.forEach { $0.removeFromSuperview() }

        // 当前后缀一致时，仅让数字主体滚动，前缀和后缀保持静态
        if let oldParsed = parseAnimatedText(sourceText),
           let newParsed = parseAnimatedText(newText),
           oldParsed.prefix == newParsed.prefix,
           oldParsed.suffix == newParsed.suffix {
            animateParsedDigitText(
                from: oldParsed,
                to: newParsed,
                duration: animateDuration,
                token: currentToken
            )
            return
        }

        // 拆分失败时退回到整串字符逐位比较
        let oldChars = Array(sourceText)
        let newChars = Array(newText)
        let oldLayout = buildCharacterLayouts(for: oldChars)
        let newLayout = buildCharacterLayouts(for: newChars)
        let oldStartX: CGFloat = 0
        let newStartX: CGFloat = 0
        let baseY = (bounds.height - font.lineHeight) * 0.5

        var finishCount = 0
        let totalCount = max(oldChars.count, newChars.count)
        if totalCount == 0 {
            runCompletionIfNeeded()
            return
        }

        for offset in 0..<totalCount {
            // 从低位向高位配对，保证进位、退位时每一位的比较关系稳定
            let oldIndex = oldChars.count - offset - 1
            let newIndex = newChars.count - offset - 1
            let oldChar = oldIndex >= 0 ? oldChars[oldIndex] : nil
            let newChar = newIndex >= 0 ? newChars[newIndex] : nil
            let oldFrame = oldIndex >= 0 ? oldLayout.frames[oldIndex] : .zero
            let newFrame = newIndex >= 0 ? newLayout.frames[newIndex] : .zero
            let oldAbsoluteFrame = oldIndex >= 0 ? CGRect(x: oldStartX + oldFrame.minX, y: baseY, width: oldFrame.width, height: oldFrame.height) : .zero
            let newAbsoluteFrame = newIndex >= 0 ? CGRect(x: newStartX + newFrame.minX, y: baseY, width: newFrame.width, height: newFrame.height) : .zero

            if oldChar == newChar, let c = newChar {
                let label = makeDigitLabel(text: String(c), frame: newAbsoluteFrame)
                digitContainerView.addSubview(label)
                finishCount += 1
                continue
            }

            var slotFrame = newAbsoluteFrame != .zero ? newAbsoluteFrame : oldAbsoluteFrame
            if newAbsoluteFrame != .zero, oldAbsoluteFrame != .zero {
                slotFrame = oldAbsoluteFrame.union(newAbsoluteFrame)
            }
            // 单个位的裁剪容器，只允许当前位在自己的槽位内上下滚动
            let slotView = UIView(frame: slotFrame)
            slotView.clipsToBounds = true
            slotView.backgroundColor = .clear
            digitContainerView.addSubview(slotView)

            let oldLabel = oldChar.map {
                makeDigitLabel(
                    text: String($0),
                    frame: CGRect(
                        // 子 label 挂在 slotView 内，这里要把绝对坐标换算成槽位内部坐标
                        x: oldAbsoluteFrame.minX - slotFrame.minX,
                        // 旧数字初始就在可视区域内
                        y: 0,
                        width: oldAbsoluteFrame.width,
                        height: slotFrame.height
                    )
                )
            }
            let newLabel = newChar.map {
                makeDigitLabel(
                    text: String($0),
                    frame: CGRect(
                        // 新数字同样使用槽位内部坐标，保证只在当前位范围内滚动
                        x: newAbsoluteFrame.minX - slotFrame.minX,
                        // 新数字先放在槽位下方，动画开始后再滚入可视区域
                        y: slotFrame.height,
                        width: newAbsoluteFrame.width,
                        height: slotFrame.height
                    )
                )
            }

            if let oldLabel { slotView.addSubview(oldLabel) }
            if let newLabel { slotView.addSubview(newLabel) }

            // 根据当前模式决定新数字从上方还是下方进入
            let isIncrease = shouldDigitIncrease(oldChar: oldChar, newChar: newChar, oldText: sourceText, newText: newText)
            if let newLabel {
                newLabel.alpha = 0
                newLabel.frame.origin.y = isIncrease ? slotFrame.height : -slotFrame.height
            }

            let delay = TimeInterval(totalCount - offset - 1) * zhh_digitStagger
            let completion: (Bool) -> Void = { _ in
                // 如果期间已经开启了新一轮动画，则丢弃旧回调，避免旧状态覆盖新状态
                guard currentToken == self.digitAnimationToken else { return }
                finishCount += 1
                if finishCount == totalCount {
                    self.displayedDigitString = newText
                    self.logicalDigitString = newText
                    // 收尾时统一重建最终静态视图，避免动画过程中的中间态残留
                    self.renderDigitTextImmediately(newText)
                    self.runCompletionIfNeeded()
                }
            }

            if zhh_digitUseSpring {
                UIView.animate(withDuration: animateDuration, delay: delay, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.7, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    oldLabel?.frame.origin.y = isIncrease ? -slotFrame.height : slotFrame.height
                    oldLabel?.alpha = 0
                    newLabel?.frame.origin.y = 0
                    newLabel?.alpha = 1
                }, completion: completion)
            } else {
                UIView.animate(withDuration: animateDuration, delay: delay, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    oldLabel?.frame.origin.y = isIncrease ? -slotFrame.height : slotFrame.height
                    oldLabel?.alpha = 0
                    newLabel?.frame.origin.y = 0
                    newLabel?.alpha = 1
                }, completion: completion)
            }
        }
    }

    /// 在前后缀固定不变时，仅对数字主体执行按位滚动动画。
    func animateParsedDigitText(
        from oldParsed: (prefix: String, number: String, suffix: String),
        to newParsed: (prefix: String, number: String, suffix: String),
        duration: TimeInterval,
        token: Int
    ) {
        let oldChars = Array(oldParsed.number)
        let newChars = Array(newParsed.number)
        let oldLayout = buildCharacterLayouts(for: oldChars)
        let newLayout = buildCharacterLayouts(for: newChars)
        let baseY = (bounds.height - font.lineHeight) * 0.5
        let prefixWidth = textWidth(oldParsed.prefix)
        let suffixX = prefixWidth + newLayout.totalWidth

        // 前缀和后缀固定渲染，不参与滚动动画
        if !newParsed.prefix.isEmpty {
            let prefixLabel = makeStaticLabel(text: newParsed.prefix, x: 0, y: baseY)
            digitContainerView.addSubview(prefixLabel)
        }
        if !newParsed.suffix.isEmpty {
            let suffixLabel = makeStaticLabel(text: newParsed.suffix, x: suffixX, y: baseY)
            digitContainerView.addSubview(suffixLabel)
        }

        var finishCount = 0
        let totalCount = max(oldChars.count, newChars.count)
        if totalCount == 0 {
            displayedDigitString = newParsed.prefix + newParsed.suffix
            logicalDigitString = displayedDigitString
            renderDigitTextImmediately(displayedDigitString)
            runCompletionIfNeeded()
            return
        }

        for offset in 0..<totalCount {
            // 仅对数字主体逐位做动画
            let oldIndex = oldChars.count - offset - 1
            let newIndex = newChars.count - offset - 1
            let oldChar = oldIndex >= 0 ? oldChars[oldIndex] : nil
            let newChar = newIndex >= 0 ? newChars[newIndex] : nil
            let oldFrame = oldIndex >= 0 ? oldLayout.frames[oldIndex] : .zero
            let newFrame = newIndex >= 0 ? newLayout.frames[newIndex] : .zero
            let oldAbsoluteFrame = oldIndex >= 0 ? CGRect(x: prefixWidth + oldFrame.minX, y: baseY, width: oldFrame.width, height: oldFrame.height) : .zero
            let newAbsoluteFrame = newIndex >= 0 ? CGRect(x: prefixWidth + newFrame.minX, y: baseY, width: newFrame.width, height: newFrame.height) : .zero

            if oldChar == newChar, let c = newChar {
                let label = makeDigitLabel(text: String(c), frame: newAbsoluteFrame)
                digitContainerView.addSubview(label)
                finishCount += 1
                continue
            }

            var slotFrame = newAbsoluteFrame != .zero ? newAbsoluteFrame : oldAbsoluteFrame
            if newAbsoluteFrame != .zero, oldAbsoluteFrame != .zero {
                slotFrame = oldAbsoluteFrame.union(newAbsoluteFrame)
            }
            let slotView = UIView(frame: slotFrame)
            slotView.clipsToBounds = true
            slotView.backgroundColor = .clear
            digitContainerView.addSubview(slotView)

            let oldLabel = oldChar.map {
                makeDigitLabel(
                    text: String($0),
                    frame: CGRect(
                        x: oldAbsoluteFrame.minX - slotFrame.minX,
                        y: 0,
                        width: oldAbsoluteFrame.width,
                        height: slotFrame.height
                    )
                )
            }
            let newLabel = newChar.map {
                makeDigitLabel(
                    text: String($0),
                    frame: CGRect(
                        x: newAbsoluteFrame.minX - slotFrame.minX,
                        y: slotFrame.height,
                        width: newAbsoluteFrame.width,
                        height: slotFrame.height
                    )
                )
            }

            if let oldLabel { slotView.addSubview(oldLabel) }
            if let newLabel { slotView.addSubview(newLabel) }

            let isIncrease = shouldDigitIncrease(oldChar: oldChar, newChar: newChar, oldText: oldParsed.number, newText: newParsed.number)
            if let newLabel {
                newLabel.alpha = 0
                newLabel.frame.origin.y = isIncrease ? slotFrame.height : -slotFrame.height
            }

            let delay = TimeInterval(totalCount - offset - 1) * zhh_digitStagger
            let completion: (Bool) -> Void = { _ in
                guard token == self.digitAnimationToken else { return }
                finishCount += 1
                if finishCount == totalCount {
                    let finalText = newParsed.prefix + newParsed.number + newParsed.suffix
                    self.displayedDigitString = finalText
                    self.logicalDigitString = finalText
                    self.renderDigitTextImmediately(finalText)
                    self.runCompletionIfNeeded()
                }
            }

            if zhh_digitUseSpring {
                UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.7, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    oldLabel?.frame.origin.y = isIncrease ? -slotFrame.height : slotFrame.height
                    oldLabel?.alpha = 0
                    newLabel?.frame.origin.y = 0
                    newLabel?.alpha = 1
                }, completion: completion)
            } else {
                UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    oldLabel?.frame.origin.y = isIncrease ? -slotFrame.height : slotFrame.height
                    oldLabel?.alpha = 0
                    newLabel?.frame.origin.y = 0
                    newLabel?.alpha = 1
                }, completion: completion)
            }
        }
    }

    /// 立即渲染按位滚动文本，不执行动画。
    func renderDigitTextImmediately(_ value: String) {
        digitContainerView.subviews.forEach { $0.removeFromSuperview() }
        text = nil
        attributedText = nil

        // 立即渲染时也保持“前后缀静态、数字主体独立布局”的结构
        if let parsed = parseAnimatedText(value) {
            let baseY = (bounds.height - font.lineHeight) * 0.5
            let prefixWidth = textWidth(parsed.prefix)
            let layout = buildCharacterLayouts(for: Array(parsed.number))
            if !parsed.prefix.isEmpty {
                let prefixLabel = makeStaticLabel(text: parsed.prefix, x: 0, y: baseY)
                digitContainerView.addSubview(prefixLabel)
            }
            for (idx, ch) in parsed.number.enumerated() {
                guard idx < layout.frames.count else { continue }
                var frame = layout.frames[idx]
                frame.origin.x += prefixWidth
                frame.origin.y = baseY
                let label = makeDigitLabel(text: String(ch), frame: frame)
                digitContainerView.addSubview(label)
            }
            if !parsed.suffix.isEmpty {
                let suffixLabel = makeStaticLabel(text: parsed.suffix, x: prefixWidth + layout.totalWidth, y: baseY)
                digitContainerView.addSubview(suffixLabel)
            }
            displayedDigitString = value
            return
        }

        let chars = Array(value)
        let layout = buildCharacterLayouts(for: chars)
        let startX: CGFloat = 0
        let baseY = (bounds.height - font.lineHeight) * 0.5
        for (idx, ch) in chars.enumerated() {
            guard idx < layout.frames.count else { continue }
            var frame = layout.frames[idx]
            frame.origin.x += startX
            frame.origin.y = baseY
            let label = makeDigitLabel(text: String(ch), frame: frame)
            digitContainerView.addSubview(label)
        }
        displayedDigitString = value
    }

    /// 创建参与滚动动画的单字符标签。
    func makeDigitLabel(text: String, frame: CGRect) -> UILabel {
        let label = UILabel(frame: frame)
        label.text = text
        label.textAlignment = textAlignment
        label.font = font
        label.textColor = textColor
        label.backgroundColor = .clear
        return label
    }

    /// 创建不参与动画的静态前缀或后缀标签。
    func makeStaticLabel(text: String, x: CGFloat, y: CGFloat) -> UILabel {
        let size = (text as NSString).size(withAttributes: [.font: font as Any])
        let label = UILabel(frame: CGRect(x: x, y: y, width: ceil(size.width), height: ceil(font.lineHeight)))
        label.text = text
        label.textAlignment = .left
        label.font = font
        label.textColor = textColor
        label.backgroundColor = .clear
        return label
    }

    /// 计算当前字体下文本的显示宽度。
    func textWidth(_ text: String) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font as Any]).width)
    }

    /// 为字符序列生成逐位布局信息。
    func buildCharacterLayouts(for chars: [Character]) -> (frames: [CGRect], totalWidth: CGFloat, defaultWidth: CGFloat) {
        let defaultWidth = max(("0" as NSString).size(withAttributes: [.font: font as Any]).width, 10)
        let digitWidth = maxDigitWidth()
        var frames: [CGRect] = []
        var x: CGFloat = 0
        for ch in chars {
            let isDigit = ch.isNumber
            let rawWidth = (String(ch) as NSString).size(withAttributes: [.font: font as Any]).width
            // 数字位统一使用等宽，避免 1/8/0 等字符宽度不同导致左右抖动
            let w = isDigit ? digitWidth : max(rawWidth, defaultWidth * 0.35)
            frames.append(CGRect(x: x, y: 0, width: ceil(w), height: ceil(font.lineHeight)))
            x += ceil(w)
        }
        return (frames, x, defaultWidth)
    }

    /// 移除按位滚动容器中的所有动画。
    func cancelDigitAnimations() {
        for subview in digitContainerView.subviews {
            subview.layer.removeAllAnimations()
            for nested in subview.subviews {
                nested.layer.removeAllAnimations()
            }
        }
    }

    /// 计算当前字体下数字字符的最大宽度。
    func maxDigitWidth() -> CGFloat {
        var width: CGFloat = 0
        for ch in "0123456789" {
            let w = (String(ch) as NSString).size(withAttributes: [.font: font as Any]).width
            width = max(width, w)
        }
        return max(width, 10)
    }

    /// 判断当前位动画应从上方还是下方进入。
    func shouldDigitIncrease(oldChar: Character?, newChar: Character?, oldText: String, newText: String) -> Bool {
        switch zhh_digitScrollStyle {
        case .smooth:
            // 平滑模式：整体方向统一
            return newText.compare(oldText, options: .numeric) != .orderedAscending
        case .drop:
            // 坠落模式：优先按当前位判断方向，更接近 SPScrollNumLabel 的视觉风格
            if let oldChar, let newChar, oldChar.isNumber, newChar.isNumber,
               let oldValue = Int(String(oldChar)), let newValue = Int(String(newChar)), oldValue != newValue {
                return newValue > oldValue
            }
            return newText.compare(oldText, options: .numeric) != .orderedAscending
        @unknown default:
            return newText.compare(oldText, options: .numeric) != .orderedAscending
        }
    }

    /// 将文本拆分为前缀、数字主体和后缀。
    func parseAnimatedText(_ text: String) -> (prefix: String, number: String, suffix: String)? {
        guard let regex = animatedNumberBodyRegex else { return nil }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        // 仅提取首个数字主体，前后内容作为静态区域保留
        let prefix = nsText.substring(with: NSRange(location: 0, length: match.range.location))
        let number = nsText.substring(with: match.range)
        let suffixLocation = match.range.location + match.range.length
        let suffix = nsText.substring(from: suffixLocation)
        return (prefix, number, suffix)
    }
}

// MARK: - 文本格式化工具

private extension ZHHAnimatedNumberLabel {
    /// 按当前格式配置生成最终显示字符串。
    func formatString(value: CGFloat) -> String {
        let fmt = zhh_format ?? "%f"
        if let regex = integerFormatRegex,
           regex.firstMatch(in: fmt, options: [], range: NSRange(location: 0, length: (fmt as NSString).length)) != nil {
            return String(format: fmt, Int(value))
        }
        return String(format: fmt, value)
    }

    // MARK: - 动画工具方法

    /// 运行完成后的回调。
    func runCompletionIfNeeded() {
        guard let completion = zhh_completionBlock else { return }
        zhh_completionBlock = nil
        completion()
    }
}
