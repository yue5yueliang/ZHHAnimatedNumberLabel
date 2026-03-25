# ZHHAnimatedNumberLabel

[![Version](https://img.shields.io/cocoapods/v/ZHHAnimatedNumberLabel.svg?style=flat)](https://cocoapods.org/pods/ZHHAnimatedNumberLabel)
[![License](https://img.shields.io/cocoapods/l/ZHHAnimatedNumberLabel.svg?style=flat)](https://cocoapods.org/pods/ZHHAnimatedNumberLabel)
[![Platform](https://img.shields.io/cocoapods/p/ZHHAnimatedNumberLabel.svg?style=flat)](https://cocoapods.org/pods/ZHHAnimatedNumberLabel)

一个轻量、流畅、可自定义的数字动画 `UILabel` 组件，现已重写为纯 Swift 版本。

支持：

- Swift 项目直接使用
- Objective-C 项目无缝调用
- SwiftUI 轻松封装
- 插值引擎与按位滚动引擎双模式
- `smooth` / `drop` 两种按位滚动风格
- 线性、缓入、缓出、弹跳等多种动画曲线

## 安装

### CocoaPods

```ruby
pod 'ZHHAnimatedNumberLabel'
```

当前版本要求：

- iOS 13.0+
- Swift 5.0+

## 快速使用

### Swift

```swift
import ZHHAnimatedNumberLabel

let label = ZHHAnimatedNumberLabel(frame: CGRect(x: 20, y: 120, width: 220, height: 40))
label.zhh_animationStyle = .easeInOut
label.zhh_format = "%d%%"
label.zhh_animateValue(0, toValue: 100)
```

### Swift 按位滚动

```swift
import ZHHAnimatedNumberLabel

let label = ZHHAnimatedNumberLabel(frame: CGRect(x: 20, y: 180, width: 220, height: 40))
label.zhh_format = "金币：%d"
label.zhh_animationEngine = .digitScroll
label.zhh_digitScrollStyle = .smooth
label.zhh_animateValue(128, toValue: 256, duration: 0.5)
```

### Objective-C

```objc
@import ZHHAnimatedNumberLabel;

ZHHAnimatedNumberLabel *label = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(20, 120, 220, 40)];
label.zhh_format = @"%d";
label.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
[label zhh_animateValue:0 toValue:1000 duration:1.5];
```

### Objective-C 按位滚动

```objc
@import ZHHAnimatedNumberLabel;

ZHHAnimatedNumberLabel *label = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(20, 180, 220, 40)];
label.zhh_format = @"金币：%d";
label.zhh_animationEngine = ZHHAnimationEngineDigitScroll;
label.zhh_digitScrollStyle = ZHHDigitScrollStyleDrop;
[label zhh_animateValue:200 toValue:388 duration:0.5];
```

### SwiftUI

```swift
import SwiftUI
import ZHHAnimatedNumberLabel

struct AnimatedNumberView: UIViewRepresentable {
    var value: CGFloat

    func makeUIView(context: Context) -> ZHHAnimatedNumberLabel {
        let label = ZHHAnimatedNumberLabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.zhh_format = "%.0f"
        label.zhh_animationEngine = .digitScroll
        label.zhh_digitScrollStyle = .smooth
        return label
    }

    func updateUIView(_ uiView: ZHHAnimatedNumberLabel, context: Context) {
        uiView.zhh_animateToValue(value, duration: 1.0)
    }
}
```

## 核心能力

### 1. 插值引擎

适合百分比、金额、积分、统计数值等连续变化动画。

```swift
label.zhh_animationEngine = .interpolate
label.zhh_animationStyle = .easeOut
```

### 2. 按位滚动引擎

适合金币、积分、余额、运营数据这类更强调“翻位感”的动画。

```swift
label.zhh_animationEngine = .digitScroll
```

### 3. 按位滚动风格

```swift
label.zhh_digitScrollStyle = .smooth
label.zhh_digitScrollStyle = .drop
```

## 格式化

### 使用格式字符串

```swift
label.zhh_format = "%.1f%%"
```

### 使用普通字符串回调

```swift
label.zhh_formatBlock = { value in
    "Score: \(Int(value))"
}
```

### 使用富文本回调

```swift
label.zhh_attributedFormatBlock = { value in
    let prefix = NSMutableAttributedString(
        string: "\(Int(value))",
        attributes: [.font: UIFont.boldSystemFont(ofSize: 20)]
    )
    prefix.append(
        NSAttributedString(
            string: "/100",
            attributes: [.font: UIFont.systemFont(ofSize: 16)]
        )
    )
    return prefix
}
```

## 示例工程

仓库内已提供三套示例：

- Swift 示例
- Objective-C 示例
- SwiftUI 示例

运行示例前先执行：

```bash
cd Example
pod install
```

## 作者

桃色三岁  
136769890@qq.com

## License

`ZHHAnimatedNumberLabel` 基于 MIT 协议开源，详见 `LICENSE`。
