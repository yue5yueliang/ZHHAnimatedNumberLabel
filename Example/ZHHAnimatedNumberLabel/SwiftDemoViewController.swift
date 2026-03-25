//
//  SwiftDemoViewController.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

import UIKit
import ZHHAnimatedNumberLabel

final class SwiftDemoViewController: UIViewController {
    
    private var coinTotal: Int = 200
    private var coinTotalDigitSmooth: Int = 200
    private var coinTotalDigitDrop: Int = 200
    private var coinTimer: Timer?
    private let scrollView = UIScrollView()

    private lazy var label: ZHHAnimatedNumberLabel = {
        let value = ZHHAnimatedNumberLabel()
        value.textColor = .black
        value.font = .systemFont(ofSize: 15, weight: .bold)
        value.frame = CGRect(x: 24, y: 50, width: 220, height: 36)
        return value
    }()
    
    private lazy var coinLabel: ZHHAnimatedNumberLabel = {
        let value = ZHHAnimatedNumberLabel(frame: CGRect(x: 24, y: 360, width: 220, height: 36))
        value.textColor = .systemOrange
        value.font = .systemFont(ofSize: 18, weight: .bold)
        value.zhh_format = "金币：%d"
        value.zhh_animationEngine = .interpolate
        value.zhh_animationStyle = .easeOut
        return value
    }()
    
    private lazy var coinLabelDigitSmooth: ZHHAnimatedNumberLabel = {
        let value = ZHHAnimatedNumberLabel(frame: CGRect(x: 24, y: 410, width: 220, height: 36))
        value.textColor = .systemGreen
        value.font = .systemFont(ofSize: 18, weight: .bold)
        value.zhh_format = "金币平滑：%d"
        value.zhh_animationEngine = .digitScroll
        value.zhh_digitScrollStyle = .smooth
        value.zhh_animationStyle = .easeOut
        return value
    }()
    
    private lazy var coinLabelDigitDrop: ZHHAnimatedNumberLabel = {
        let value = ZHHAnimatedNumberLabel(frame: CGRect(x: 24, y: 460, width: 220, height: 36))
        value.textColor = .systemPurple
        value.font = .systemFont(ofSize: 18, weight: .bold)
        value.zhh_format = "金币坠落：%d"
        value.zhh_animationEngine = .digitScroll
        value.zhh_digitScrollStyle = .drop
        value.zhh_animationStyle = .easeOut
        return value
    }()
    
    private lazy var randomButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 24, y: 520, width: 120, height: 36)
        button.setTitle("随机+金币", for: .normal)
        button.addTarget(self, action: #selector(handleRandomIncrement), for: .touchUpInside)
        return button
    }()
    
    private lazy var taskButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 24, y: 566, width: 160, height: 36)
        button.setTitle("连续任务(5次)", for: .normal)
        button.addTarget(self, action: #selector(handleContinuousTask), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 24, y: 612, width: 120, height: 36)
        button.setTitle("重置", for: .normal)
        button.addTarget(self, action: #selector(handleReset), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Swift 示例"
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)

        let leftX: CGFloat = 24
        let columnSpacing: CGFloat = 12
        let columnWidth = floor((view.bounds.width - leftX * 2 - columnSpacing) * 0.5)
        let rightX = leftX + columnWidth + columnSpacing
        let rowHeight: CGFloat = 36
        let rowSpacing: CGFloat = 14

        label.frame = CGRect(x: leftX, y: 15, width: columnWidth, height: rowHeight)

        scrollView.addSubview(label)

        // make one that counts up
        let myLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: rightX, y: 15, width: columnWidth, height: rowHeight))
        myLabel.zhh_animationStyle = .linear
        myLabel.zhh_format = "%d"
        scrollView.addSubview(myLabel)
        myLabel.zhh_animateValue(1, toValue: 10, duration: 3.0)

        // make one that counts up from 5% to 10%, using ease in out (the default)
        let countPercentageLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: leftX, y: 15 + rowHeight + rowSpacing, width: columnWidth, height: rowHeight))
        countPercentageLabel.zhh_format = "%.1f%%"
        scrollView.addSubview(countPercentageLabel)
        countPercentageLabel.zhh_animateValue(5, toValue: 10)

        // count up using a string that uses a number formatter
        let scoreLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: rightX, y: 15 + rowHeight + rowSpacing, width: columnWidth, height: rowHeight))
        scrollView.addSubview(scoreLabel)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        scoreLabel.zhh_formatBlock = { value in
            let formatted = formatter.string(from: NSNumber(value: Int(value))) ?? "0"
            return "Score: \(formatted)"
        }
        scoreLabel.zhh_animationStyle = .easeOut
        scoreLabel.zhh_animateValue(0, toValue: 10000, duration: 2.5)

        // count up with attributed string
        let toValue: CGFloat = 100
        let attributedLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: leftX, y: 15 + (rowHeight + rowSpacing) * 2, width: columnWidth, height: rowHeight))
        scrollView.addSubview(attributedLabel)
        attributedLabel.zhh_attributedFormatBlock = { value in
            let normal: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "HelveticaNeue-UltraLight", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .ultraLight)
            ]
            let highlight: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "HelveticaNeue", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .regular)
            ]

            let prefix = "\(Int(value))"
            let postfix = "/\(Int(toValue))"

            let prefixAttr = NSMutableAttributedString(string: prefix, attributes: highlight)
            let postfixAttr = NSAttributedString(string: postfix, attributes: normal)
            prefixAttr.append(postfixAttr)
            return prefixAttr
        }
        attributedLabel.zhh_animateValue(0, toValue: toValue, duration: 2.5)

        label.zhh_animationStyle = .easeInOut
        label.zhh_format = "%d%%"
        label.zhh_completionBlock = { [weak self] in
            self?.label.textColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
        }
        label.zhh_animateValue(0, toValue: 100)

        // make one that counts up
        let countLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: rightX, y: 15 + (rowHeight + rowSpacing) * 2, width: columnWidth, height: rowHeight))
        countLabel.textColor = .black
        countLabel.backgroundColor = .yellow
        countLabel.font = .systemFont(ofSize: 15, weight: .bold)
        countLabel.zhh_animationStyle = .linear
        countLabel.zhh_format = "%d"
        scrollView.addSubview(countLabel)
        countLabel.zhh_animateValue(200, toValue: 1000, duration: 1.0)
        
        // task style random coin reward
        let coinStartY: CGFloat = 165
        coinLabel.frame = CGRect(x: leftX, y: coinStartY, width: columnWidth, height: rowHeight)
        coinLabelDigitSmooth.frame = CGRect(x: leftX, y: coinStartY + rowHeight + rowSpacing, width: columnWidth, height: rowHeight)
        coinLabelDigitDrop.frame = CGRect(x: leftX, y: coinStartY + (rowHeight + rowSpacing) * 2, width: columnWidth, height: rowHeight)
        scrollView.addSubview(coinLabel)
        scrollView.addSubview(coinLabelDigitSmooth)
        scrollView.addSubview(coinLabelDigitDrop)
        let buttonY = coinStartY + (rowHeight + rowSpacing) * 3 + 8
        let buttonWidth = floor((view.bounds.width - leftX * 2 - columnSpacing * 2) / 3)
        randomButton.frame = CGRect(x: leftX, y: buttonY, width: buttonWidth, height: rowHeight)
        taskButton.frame = CGRect(x: leftX + buttonWidth + columnSpacing, y: buttonY, width: buttonWidth, height: rowHeight)
        resetButton.frame = CGRect(x: leftX + (buttonWidth + columnSpacing) * 2, y: buttonY, width: buttonWidth, height: rowHeight)
        scrollView.addSubview(randomButton)
        scrollView.addSubview(taskButton)
        scrollView.addSubview(resetButton)
        coinLabel.zhh_animateValue(CGFloat(coinTotal), toValue: CGFloat(coinTotal), duration: 0)
        coinLabelDigitSmooth.zhh_animateValue(CGFloat(coinTotalDigitSmooth), toValue: CGFloat(coinTotalDigitSmooth), duration: 0)
        coinLabelDigitDrop.zhh_animateValue(CGFloat(coinTotalDigitDrop), toValue: CGFloat(coinTotalDigitDrop), duration: 0)
        
        addEngineCompareSamples(startY: buttonY + rowHeight + 28)
        addAnimationStyleSamples(startY: buttonY + rowHeight + 170)
        scrollView.contentSize = CGSize(width: view.bounds.width, height: buttonY + rowHeight + 360)
    }
    
    deinit {
        coinTimer?.invalidate()
    }
    
    private func startCoinTaskAnimation() {
        coinTimer?.invalidate()
        var count = 0
        coinTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { [weak self] timer in
            guard let self else { return }
            if count >= 5 {
                timer.invalidate()
                return
            }
            self.performRandomIncrement()
            count += 1
        }
    }
    
    private func performRandomIncrement() {
        let addValue = Int.random(in: 3...28)
        let fromValue = coinTotal
        coinTotal += addValue
        coinLabel.zhh_animateValue(CGFloat(fromValue), toValue: CGFloat(coinTotal), duration: 0.55)
        
        let addValueDigitSmooth = Int.random(in: 3...28)
        let fromValueDigitSmooth = coinTotalDigitSmooth
        coinTotalDigitSmooth += addValueDigitSmooth
        coinLabelDigitSmooth.zhh_animateValue(CGFloat(fromValueDigitSmooth), toValue: CGFloat(coinTotalDigitSmooth), duration: 0.55)
        
        let addValueDigitDrop = Int.random(in: 3...28)
        let fromValueDigitDrop = coinTotalDigitDrop
        coinTotalDigitDrop += addValueDigitDrop
        coinLabelDigitDrop.zhh_animateValue(CGFloat(fromValueDigitDrop), toValue: CGFloat(coinTotalDigitDrop), duration: 0.55)
    }
    
    @objc private func handleRandomIncrement() {
        coinTimer?.invalidate()
        performRandomIncrement()
    }
    
    @objc private func handleContinuousTask() {
        startCoinTaskAnimation()
    }
    
    @objc private func handleReset() {
        coinTimer?.invalidate()
        coinTotal = 0
        coinTotalDigitSmooth = 0
        coinTotalDigitDrop = 0
        coinLabel.zhh_animateValue(coinLabel.zhh_currentValue(), toValue: 0, duration: 0.35)
        coinLabelDigitSmooth.zhh_animateValue(coinLabelDigitSmooth.zhh_currentValue(), toValue: 0, duration: 0.35)
        coinLabelDigitDrop.zhh_animateValue(coinLabelDigitDrop.zhh_currentValue(), toValue: 0, duration: 0.35)
    }
    
    private func addEngineCompareSamples(startY: CGFloat) {
        let leftX: CGFloat = 24
        let columnSpacing: CGFloat = 12
        let columnWidth = floor((view.bounds.width - leftX * 2 - columnSpacing) * 0.5)

        let interpolateLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: leftX, y: startY, width: columnWidth, height: 36))
        interpolateLabel.textColor = .systemBlue
        interpolateLabel.font = .systemFont(ofSize: 15, weight: .medium)
        interpolateLabel.zhh_animationEngine = .interpolate
        interpolateLabel.zhh_animationStyle = .easeOut
        interpolateLabel.zhh_formatBlock = { value in
            "插值引擎: \(Int(value))"
        }
        scrollView.addSubview(interpolateLabel)
        interpolateLabel.zhh_animateValue(0, toValue: 12888, duration: 2.0)
        
        let smoothLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: leftX, y: startY + 50, width: columnWidth, height: 36))
        smoothLabel.textColor = .systemGreen
        smoothLabel.font = .systemFont(ofSize: 15, weight: .medium)
        smoothLabel.zhh_animationEngine = .digitScroll
        smoothLabel.zhh_digitScrollStyle = .smooth
        smoothLabel.zhh_animationStyle = .easeOut
        smoothLabel.zhh_format = "%d"
        scrollView.addSubview(smoothLabel)
        smoothLabel.zhh_animateValue(0, toValue: 12888, duration: 0.5)
        
        let dropLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: leftX, y: startY + 100, width: columnWidth, height: 36))
        dropLabel.textColor = .systemPurple
        dropLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dropLabel.zhh_animationEngine = .digitScroll
        dropLabel.zhh_digitScrollStyle = .drop
        dropLabel.zhh_animationStyle = .easeOut
        dropLabel.zhh_format = "%d"
        scrollView.addSubview(dropLabel)
        dropLabel.zhh_animateValue(0, toValue: 12888, duration: 0.5)
    }
    
    private func addAnimationStyleSamples(startY: CGFloat) {
        let leftX: CGFloat = 24
        let columnSpacing: CGFloat = 12
        let columnWidth = floor((view.bounds.width - leftX * 2 - columnSpacing) * 0.5)
        let rightX = leftX + columnWidth + columnSpacing
        let styles: [(String, ZHHNumberAnimationStyle)] = [
            ("EaseInOut", .easeInOut),
            ("EaseIn", .easeIn),
            ("EaseOut", .easeOut),
            ("Linear", .linear),
            ("EaseInBounce", .easeInBounce),
            ("EaseOutBounce", .easeOutBounce)
        ]
        
        for (index, item) in styles.enumerated() {
            let row = CGFloat(index / 2)
            let x = index % 2 == 0 ? leftX : rightX
            let y = startY + row * 56
            let demoLabel = ZHHAnimatedNumberLabel(frame: CGRect(x: x, y: y, width: columnWidth, height: 36))
            demoLabel.textColor = .darkGray
            demoLabel.font = .systemFont(ofSize: 14, weight: .medium)
            demoLabel.zhh_animationStyle = item.1
            demoLabel.zhh_formatBlock = { value in
                "\(item.0): \(Int(value))"
            }
            scrollView.addSubview(demoLabel)
            demoLabel.zhh_animateValue(0, toValue: 1000, duration: 3.5)
            
            let bar = UIView(frame: CGRect(x: x, y: y + 34, width: columnWidth, height: 4))
            bar.backgroundColor = UIColor.systemGray5
            bar.layer.cornerRadius = 2
            scrollView.addSubview(bar)
            
            let progress = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 4))
            progress.backgroundColor = UIColor.systemBlue
            progress.layer.cornerRadius = 2
            bar.addSubview(progress)
            
            animateProgress(progress, style: item.1, fullWidth: columnWidth)
        }
    }
    
    private func animateProgress(_ view: UIView, style: ZHHNumberAnimationStyle, fullWidth: CGFloat) {
        switch style {
        case .linear:
            UIView.animate(withDuration: 3.5, delay: 0, options: .curveLinear) {
                view.frame.size.width = fullWidth
            }
        case .easeIn:
            UIView.animate(withDuration: 3.5, delay: 0, options: .curveEaseIn) {
                view.frame.size.width = fullWidth
            }
        case .easeOut:
            UIView.animate(withDuration: 3.5, delay: 0, options: .curveEaseOut) {
                view.frame.size.width = fullWidth
            }
        case .easeInOut:
            UIView.animate(withDuration: 3.5, delay: 0, options: .curveEaseInOut) {
                view.frame.size.width = fullWidth
            }
        case .easeInBounce:
            UIView.animate(withDuration: 3.5, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.1, options: .curveEaseIn) {
                view.frame.size.width = fullWidth
            }
        case .easeOutBounce:
            UIView.animate(withDuration: 3.5, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8, options: .curveEaseOut) {
                view.frame.size.width = fullWidth
            }
        @unknown default:
            UIView.animate(withDuration: 3.5, delay: 0, options: .curveLinear) {
                view.frame.size.width = fullWidth
            }
        }
    }
}
