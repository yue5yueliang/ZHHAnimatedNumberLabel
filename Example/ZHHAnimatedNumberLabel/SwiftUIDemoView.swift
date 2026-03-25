//
//  SwiftUIDemoView.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

import SwiftUI
import ZHHAnimatedNumberLabel

private struct AnimatedNumberLabelView: UIViewRepresentable {
    var value: CGFloat
    var engine: ZHHAnimationEngine
    var digitStyle: ZHHDigitScrollStyle = .smooth

    func makeUIView(context: Context) -> ZHHAnimatedNumberLabel {
        let label = ZHHAnimatedNumberLabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .black
        label.zhh_format = "%.0f"
        label.zhh_animationStyle = .easeInOut
        label.zhh_animationEngine = engine
        label.zhh_digitScrollStyle = digitStyle
        return label
    }

    func updateUIView(_ uiView: ZHHAnimatedNumberLabel, context: Context) {
        uiView.zhh_animationEngine = engine
        uiView.zhh_digitScrollStyle = digitStyle
        if engine == .digitScroll {
            DispatchQueue.main.async {
                uiView.zhh_animateToValue(value, duration: 1.0)
            }
        } else {
            uiView.zhh_animateToValue(value, duration: 1.0)
        }
    }
}

struct SwiftUIDemoView: View {
    @State private var valueInterpolate: CGFloat = 0
    @State private var valueDigitSmooth: CGFloat = 0
    @State private var valueDigitDrop: CGFloat = 0
    @State private var taskTimer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            AnimatedNumberLabelView(value: valueInterpolate, engine: .interpolate)
                .frame(width: 220, height: 40)
                .padding(.horizontal, 20)
            Text("插值引擎")
                .font(.caption)
                .foregroundStyle(.blue)
            
            AnimatedNumberLabelView(value: valueDigitSmooth, engine: .digitScroll, digitStyle: .smooth)
                .frame(width: 220, height: 40)
                .padding(.horizontal, 20)
            Text("按位滚动引擎-平滑")
                .font(.caption)
                .foregroundStyle(.green)
            
            AnimatedNumberLabelView(value: valueDigitDrop, engine: .digitScroll, digitStyle: .drop)
                .frame(width: 220, height: 40)
                .padding(.horizontal, 20)
            Text("按位滚动引擎-坠落")
                .font(.caption)
                .foregroundStyle(.purple)
            
            Button("随机+金币") {
                let addInterpolate = CGFloat(Int.random(in: 5...30))
                let addDigitSmooth = CGFloat(Int.random(in: 5...30))
                let addDigitDrop = CGFloat(Int.random(in: 5...30))
                valueInterpolate += addInterpolate
                valueDigitSmooth += addDigitSmooth
                valueDigitDrop += addDigitDrop
            }
            
            Button("连续任务(5次)") {
                taskTimer?.invalidate()
                var count = 0
                taskTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { timer in
                    if count >= 5 {
                        timer.invalidate()
                        return
                    }
                    let addInterpolate = CGFloat(Int.random(in: 5...30))
                    let addDigitSmooth = CGFloat(Int.random(in: 5...30))
                    let addDigitDrop = CGFloat(Int.random(in: 5...30))
                    valueInterpolate += addInterpolate
                    valueDigitSmooth += addDigitSmooth
                    valueDigitDrop += addDigitDrop
                    count += 1
                }
            }
            
            Button("重置") {
                taskTimer?.invalidate()
                valueInterpolate = 0
                valueDigitSmooth = 0
                valueDigitDrop = 0
            }
        }
        .padding(.top, 100)
        .navigationTitle("SwiftUI 示例")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            taskTimer?.invalidate()
        }
    }
}
