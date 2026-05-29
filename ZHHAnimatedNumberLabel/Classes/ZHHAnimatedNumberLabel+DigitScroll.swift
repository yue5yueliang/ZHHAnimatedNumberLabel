//
//  ZHHAnimatedNumberLabel+DigitScroll.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.

//  按位滚动引擎，适合金币、积分、余额、运营数据等强调"翻位感"的动画

import UIKit

// MARK: - 按位滚动引擎

extension ZHHAnimatedNumberLabel {

    /// 是否可安全使用按位滚动引擎
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
        logicalDigitString = newText
        digitContainerView.subviews.forEach { $0.removeFromSuperview() }

        // 当前后缀一致时，仅让数字主体滚动，前缀和后缀保持静态
        if let oldParsed = parseAnimatedText(sourceText),
           let newParsed = parseAnimatedText(newText),
           oldParsed.prefix == newParsed.prefix,
           oldParsed.suffix == newParsed.suffix {
            let baseY = (bounds.height - font.lineHeight) * 0.5
            let prefixWidth = textWidth(newParsed.prefix)

            // 前缀和后缀固定渲染，不参与滚动动画
            if !newParsed.prefix.isEmpty {
                digitContainerView.addSubview(makeStaticLabel(text: newParsed.prefix, x: 0, y: baseY))
            }
            if !newParsed.suffix.isEmpty {
                let layout = buildCharacterLayouts(for: Array(newParsed.number))
                digitContainerView.addSubview(makeStaticLabel(text: newParsed.suffix, x: prefixWidth + layout.totalWidth, y: baseY))
            }

            // 仅对数字主体逐位做动画
            let numberLayout = buildCharacterLayouts(for: Array(newParsed.number))
            // 无前后缀时（纯数字），根据 textAlignment 做水平对齐
            let effectiveXOffset: CGFloat
            if newParsed.prefix.isEmpty && newParsed.suffix.isEmpty {
                effectiveXOffset = horizontalAlignOffset(totalContentWidth: numberLayout.totalWidth)
            } else {
                effectiveXOffset = prefixWidth
            }
            animateDigitSlots(
                oldChars: Array(oldParsed.number),
                newChars: Array(newParsed.number),
                xOffset: effectiveXOffset,
                referenceOldText: oldParsed.number,
                referenceNewText: newParsed.number,
                duration: animateDuration,
                token: currentToken
            ) { [weak self] in
                guard let self else { return }
                let finalText = newParsed.prefix + newParsed.number + newParsed.suffix
                self.displayedDigitString = finalText
                self.logicalDigitString = finalText
                self.renderDigitTextImmediately(finalText)
                self.runCompletionIfNeeded()
            }
            return
        }

        // 拆分失败时退回到整串字符逐位比较
        let fallbackLayout = buildCharacterLayouts(for: Array(newText))
        let xOffset = horizontalAlignOffset(totalContentWidth: fallbackLayout.totalWidth)
        animateDigitSlots(
            oldChars: Array(sourceText),
            newChars: Array(newText),
            xOffset: xOffset,
            referenceOldText: sourceText,
            referenceNewText: newText,
            duration: animateDuration,
            token: currentToken
        ) { [weak self] in
            guard let self else { return }
            self.displayedDigitString = newText
            self.logicalDigitString = newText
            self.renderDigitTextImmediately(newText)
            self.runCompletionIfNeeded()
        }
    }

    // MARK: - 核心按位滚动动画循环（提取自 animateDigitString / animateParsedDigitText）

    /// 执行按位滚动动画的核心循环
    /// - Parameters:
    ///   - oldChars: 旧字符数组
    ///   - newChars: 新字符数组
    ///   - xOffset: 数字区域的 X 轴偏移量（用于前后缀场景）
    ///   - referenceOldText: 用于判断滚动方向的旧文本
    ///   - referenceNewText: 用于判断滚动方向的新文本
    ///   - duration: 动画持续时间
    ///   - token: 动画令牌，用于废弃旧回调
    ///   - onAllFinished: 所有位动画完成后的回调
    func animateDigitSlots(
        oldChars: [Character],
        newChars: [Character],
        xOffset: CGFloat,
        referenceOldText: String,
        referenceNewText: String,
        duration: TimeInterval,
        token: Int,
        onAllFinished: @escaping () -> Void
    ) {
        let oldLayout = buildCharacterLayouts(for: oldChars)
        let newLayout = buildCharacterLayouts(for: newChars)
        let baseY = (bounds.height - font.lineHeight) * 0.5

        var finishCount = 0
        let totalCount = max(oldChars.count, newChars.count)

        if totalCount == 0 {
            onAllFinished()
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
            let oldAbsoluteFrame = oldIndex >= 0 ? CGRect(x: xOffset + oldFrame.minX, y: baseY, width: oldFrame.width, height: oldFrame.height) : .zero
            let newAbsoluteFrame = newIndex >= 0 ? CGRect(x: xOffset + newFrame.minX, y: baseY, width: newFrame.width, height: newFrame.height) : .zero

            if oldChar == newChar, let c = newChar {
                let label = makeDigitLabel(text: String(c), frame: newAbsoluteFrame)
                digitContainerView.addSubview(label)
                finishCount += 1
                // 如果所有位都相同，立即触发完成回调
                if finishCount == totalCount {
                    onAllFinished()
                }
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

            // 根据当前模式决定新数字从上方还是下方进入
            let isIncrease = shouldDigitIncrease(oldChar: oldChar, newChar: newChar, oldText: referenceOldText, newText: referenceNewText)
            if let newLabel {
                newLabel.alpha = 0
                newLabel.frame.origin.y = isIncrease ? slotFrame.height : -slotFrame.height
            }

            let delay = TimeInterval(totalCount - offset - 1) * zhh_digitStagger
            let completion: (Bool) -> Void = { _ in
                // 如果期间已经开启了新一轮动画，则丢弃旧回调，避免旧状态覆盖新状态
                guard token == self.digitAnimationToken else { return }
                finishCount += 1
                if finishCount == totalCount {
                    onAllFinished()
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

    // MARK: - 立即渲染

    /// 立即渲染按位滚动文本，不执行动画。
    func renderDigitTextImmediately(_ value: String) {
        digitContainerView.subviews.forEach { $0.removeFromSuperview() }
        text = nil
        attributedText = nil

        // 立即渲染时也保持"前后缀静态、数字主体独立布局"的结构
        if let parsed = parseAnimatedText(value) {
            let baseY = (bounds.height - font.lineHeight) * 0.5
            let prefixWidth = textWidth(parsed.prefix)
            let layout = buildCharacterLayouts(for: Array(parsed.number))
            let offsetX: CGFloat
            if parsed.prefix.isEmpty && parsed.suffix.isEmpty {
                offsetX = horizontalAlignOffset(totalContentWidth: layout.totalWidth)
            } else {
                offsetX = prefixWidth
            }
            if !parsed.prefix.isEmpty {
                let prefixLabel = makeStaticLabel(text: parsed.prefix, x: 0, y: baseY)
                digitContainerView.addSubview(prefixLabel)
            }
            for (idx, ch) in parsed.number.enumerated() {
                guard idx < layout.frames.count else { continue }
                var frame = layout.frames[idx]
                frame.origin.x += offsetX
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
        let baseY = (bounds.height - font.lineHeight) * 0.5
        let offsetX = horizontalAlignOffset(totalContentWidth: layout.totalWidth)
        for (idx, ch) in chars.enumerated() {
            guard idx < layout.frames.count else { continue }
            var frame = layout.frames[idx]
            frame.origin.x += offsetX
            frame.origin.y = baseY
            let label = makeDigitLabel(text: String(ch), frame: frame)
            digitContainerView.addSubview(label)
        }
        displayedDigitString = value
    }

    // MARK: - 工厂方法

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

    // MARK: - 布局计算

    /// 计算当前字体下文本的显示宽度。
    func textWidth(_ text: String) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font as Any]).width)
    }

    /// 根据 textAlignment 计算水平对齐偏移量（仅对无前后缀的纯数字/纯文本生效）。
    func horizontalAlignOffset(totalContentWidth: CGFloat) -> CGFloat {
        let availableWidth = bounds.width
        switch textAlignment {
        case .center:
            return max(0, (availableWidth - totalContentWidth) * 0.5)
        case .right, .natural:
            return max(0, availableWidth - totalContentWidth)
        default:
            return 0
        }
    }

    /// 数字位宽度的最小下限，随字号缩放，避免小字号被固定 10pt 强行撑宽。
    var minDigitLayoutWidth: CGFloat {
        max(2, font.pointSize * 0.55)
    }

    /// 为字符序列生成逐位布局信息。
    func buildCharacterLayouts(for chars: [Character]) -> (frames: [CGRect], totalWidth: CGFloat, defaultWidth: CGFloat) {
        let minWidth = minDigitLayoutWidth
        let defaultWidth = max(("0" as NSString).size(withAttributes: [.font: font as Any]).width, minWidth)
        let rawMaxDigitWidth = cachedMaxDigitWidth
        // digitWidthScale 控制等宽缩放：1.0 = 最宽数字宽度，0.0 = 各字符实际宽度
        let effectiveScale = max(0, min(zhh_digitWidthScale, 2.0))
        let digitWidth: CGFloat
        if effectiveScale <= 0 {
            // 使用各字符实际宽度（不等宽模式）
            digitWidth = 0
        } else {
            digitWidth = rawMaxDigitWidth * effectiveScale
        }
        var frames: [CGRect] = []
        var x: CGFloat = 0
        for ch in chars {
            let isDigit = ch.isNumber
            let rawWidth = (String(ch) as NSString).size(withAttributes: [.font: font as Any]).width
            let w: CGFloat
            if isDigit {
                if effectiveScale <= 0 {
                    w = max(rawWidth, defaultWidth * 0.35)
                } else {
                    w = digitWidth
                }
            } else {
                w = max(rawWidth, defaultWidth * 0.35)
            }
            frames.append(CGRect(x: x, y: 0, width: ceil(w), height: ceil(font.lineHeight)))
            x += ceil(w)
        }
        return (frames, x, defaultWidth)
    }

    /// 缓存的最大数字宽度（font 不变时复用）
    var cachedMaxDigitWidth: CGFloat {
        if cachedLayoutFont == font, cachedDigitWidth > 0 {
            return cachedDigitWidth
        }
        cachedLayoutFont = font
        cachedDigitWidth = computeMaxDigitWidth()
        return cachedDigitWidth
    }

    /// 计算当前字体下数字字符的最大宽度。
    func computeMaxDigitWidth() -> CGFloat {
        var width: CGFloat = 0
        for ch in "0123456789" {
            let w = (String(ch) as NSString).size(withAttributes: [.font: font as Any]).width
            width = max(width, w)
        }
        return max(width, minDigitLayoutWidth)
    }

    // MARK: - 动画控制

    /// 移除按位滚动容器中的所有动画。
    func cancelDigitAnimations() {
        for subview in digitContainerView.subviews {
            subview.layer.removeAllAnimations()
            for nested in subview.subviews {
                nested.layer.removeAllAnimations()
            }
        }
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
