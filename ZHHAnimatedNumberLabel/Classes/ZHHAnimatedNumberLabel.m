//
//  ZHHAnimatedNumberLabel.m
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2024/12/26.
//  Copyright © 2024 桃色三岁. All rights reserved.
//

#import "ZHHAnimatedNumberLabel.h"

// 动画速率常量，用于控制动画的非线性程度
static const CGFloat kUILabelCounterRate = 3.0;

/// UILabelCounter 协议，用于定义更新动画进度的方法。
@protocol ZHHUILabelCounter <NSObject>

/// 根据时间 t 计算当前动画进度。
/// @param t 时间进度（范围 [0, 1]）
/// @return 当前动画进度（范围 [0, 1]）
- (CGFloat)zhh_update:(CGFloat)t;

@end

#pragma mark - 动画类型实现

/// 线性动画
@interface ZHHUILabelCounterLinear : NSObject <ZHHUILabelCounter>
@end

/// 缓入动画（Ease In）
@interface ZHHUILabelCounterEaseIn : NSObject <ZHHUILabelCounter>
@end

/// 缓出动画（Ease Out）
@interface ZHHUILabelCounterEaseOut : NSObject <ZHHUILabelCounter>
@end

/// 缓入缓出动画（Ease In-Out）
@interface ZHHUILabelCounterEaseInOut : NSObject <ZHHUILabelCounter>
@end

/// 缓入反弹动画（Ease In Bounce）
@interface ZHHUILabelCounterEaseInBounce : NSObject <ZHHUILabelCounter>
@end

/// 缓出反弹动画（Ease Out Bounce）
@interface ZHHUILabelCounterEaseOutBounce : NSObject <ZHHUILabelCounter>
@end

#pragma mark - 动画实现

@implementation ZHHUILabelCounterLinear
- (CGFloat)zhh_update:(CGFloat)t {
    return t; // 线性动画直接返回时间进度
}
@end

@implementation ZHHUILabelCounterEaseIn
- (CGFloat)zhh_update:(CGFloat)t {
    return powf(t, kUILabelCounterRate); // 时间进度的指数计算，创建缓入效果
}
@end

@implementation ZHHUILabelCounterEaseOut
- (CGFloat)zhh_update:(CGFloat)t {
    return 1.0 - powf(1.0 - t, kUILabelCounterRate); // 反向计算，创建缓出效果
}
@end

@implementation ZHHUILabelCounterEaseInOut
- (CGFloat)zhh_update:(CGFloat)t {
    t *= 2.0; // 将时间进度分为两段
    if (t < 1.0) {
        return 0.5 * powf(t, kUILabelCounterRate); // 前半段缓入
    } else {
        return 0.5 * (2.0 - powf(2.0 - t, kUILabelCounterRate)); // 后半段缓出
    }
}
@end

@implementation ZHHUILabelCounterEaseInBounce
- (CGFloat)zhh_update:(CGFloat)t {
    // 使用反弹公式计算缓入反弹效果
    return 1.0 - [[ZHHUILabelCounterEaseOutBounce new] zhh_update:1.0 - t];
}
@end

@implementation ZHHUILabelCounterEaseOutBounce
- (CGFloat)zhh_update:(CGFloat)t {
    if (t < 4.0 / 11.0) {
        return powf(11.0 / 4.0, 2) * powf(t, 2);
    } else if (t < 8.0 / 11.0) {
        return 3.0 / 4.0 + powf(11.0 / 4.0, 2) * powf(t - 6.0 / 11.0, 2);
    } else if (t < 10.0 / 11.0) {
        return 15.0 / 16.0 + powf(11.0 / 4.0, 2) * powf(t - 9.0 / 11.0, 2);
    } else {
        return 63.0 / 64.0 + powf(11.0 / 4.0, 2) * powf(t - 21.0 / 22.0, 2);
    }
}
@end

@interface ZHHAnimatedNumberLabel ()

// 动画相关属性
@property (nonatomic, assign) CGFloat startingValue;      // 动画起始值
@property (nonatomic, assign) CGFloat destinationValue;   // 动画目标值
@property (nonatomic, assign) NSTimeInterval progress;    // 当前进度时间
@property (nonatomic, assign) NSTimeInterval lastUpdate;  // 上次更新时间
@property (nonatomic, assign) NSTimeInterval totalTime;   // 动画总时长
@property (nonatomic, assign) CGFloat easingRate;         // 动画缓动速率

// 定时器和动画更新策略
@property (nonatomic, strong) CADisplayLink *timer;       // 定时器
@property (nonatomic, strong) id<ZHHUILabelCounter> counter; // 动画策略对象

@end

@implementation ZHHAnimatedNumberLabel

#pragma mark - 动画启动方法

/// 从指定值开始动画到目标值，默认动画持续时间。
- (void)zhh_animateValue:(CGFloat)startValue toValue:(CGFloat)endValue {
    if (self.zhh_animationDuration == 0.0f) {
        self.zhh_animationDuration = 2.0f; // 默认动画时长为2秒
    }
    [self zhh_animateValue:startValue toValue:endValue duration:self.zhh_animationDuration];
}

/// 从指定值开始动画到目标值，自定义动画持续时间。
- (void)zhh_animateValue:(CGFloat)startValue toValue:(CGFloat)endValue duration:(NSTimeInterval)duration {
    self.startingValue = startValue;
    self.destinationValue = endValue;

    // 移除之前的定时器
    [self.timer invalidate];
    self.timer = nil;

    // 如果格式为空，使用默认格式
    if (!self.zhh_format) {
        self.zhh_format = @"%f";
    }

    // 如果时长为0，直接设置目标值并结束
    if (duration == 0.0) {
        [self zhh_setTextValue:endValue];
        [self zhh_runCompletionBlock];
        return;
    }

    // 初始化动画参数
    self.easingRate = 3.0f;
    self.progress = 0;
    self.totalTime = duration;
    self.lastUpdate = CACurrentMediaTime();

    // 根据动画类型选择计数策略
    switch (self.zhh_animationStyle) {
        case ZHHNumberAnimationStyleLinear:
            self.counter = [ZHHUILabelCounterLinear new];
            break;
        case ZHHNumberAnimationStyleEaseIn:
            self.counter = [ZHHUILabelCounterEaseIn new];
            break;
        case ZHHNumberAnimationStyleEaseOut:
            self.counter = [ZHHUILabelCounterEaseOut new];
            break;
        case ZHHNumberAnimationStyleEaseInOut:
            self.counter = [ZHHUILabelCounterEaseInOut new];
            break;
        case ZHHNumberAnimationStyleEaseOutBounce:
            self.counter = [ZHHUILabelCounterEaseOutBounce new];
            break;
        case ZHHNumberAnimationStyleEaseInBounce:
            self.counter = [ZHHUILabelCounterEaseInBounce new];
            break;
    }

    // 创建定时器
    self.timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(zhh_updateValue:)];
    [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
}

/// 从当前值开始动画到目标值。
- (void)zhh_animateToValue:(CGFloat)endValue {
    [self zhh_animateValue:[self zhh_currentValue] toValue:endValue];
}

/// 从当前值开始动画到目标值，自定义动画持续时间。
- (void)zhh_animateToValue:(CGFloat)endValue duration:(NSTimeInterval)duration {
    [self zhh_animateValue:[self zhh_currentValue] toValue:endValue duration:duration];
}

/// 从0开始动画到目标值。
- (void)zhh_animateFromZeroToValue:(CGFloat)endValue {
    [self zhh_animateValue:0.0f toValue:endValue];
}

/// 从0开始动画到目标值，自定义动画持续时间。
- (void)zhh_animateFromZeroToValue:(CGFloat)endValue duration:(NSTimeInterval)duration {
    [self zhh_animateValue:0.0f toValue:endValue duration:duration];
}

#pragma mark - 动画更新

/// 更新动画值并刷新显示。
- (void)zhh_updateValue:(CADisplayLink *)timer {
    NSTimeInterval now = CACurrentMediaTime();
    self.progress += now - self.lastUpdate;
    self.lastUpdate = now;

    if (self.progress >= self.totalTime) {
        [self.timer invalidate];
        self.timer = nil;
        self.progress = self.totalTime;
    }

    [self zhh_setTextValue:[self zhh_currentValue]];

    if (self.progress == self.totalTime) {
        [self zhh_runCompletionBlock];
    }
}

/// 设置当前显示值，支持自定义格式。
- (void)zhh_setTextValue:(CGFloat)value {
    if (self.zhh_attributedFormatBlock) {
        self.attributedText = self.zhh_attributedFormatBlock(value);
    } else if (self.zhh_formatBlock) {
        self.text = self.zhh_formatBlock(value);
    } else {
        // 检查是否使用整数格式
        if ([self.zhh_format rangeOfString:@"%[^fega]*[dioux]" options:NSRegularExpressionSearch].location != NSNotFound) {
            self.text = [NSString stringWithFormat:self.zhh_format, (int)value];
        } else {
            self.text = [NSString stringWithFormat:self.zhh_format, value];
        }
    }
}

#pragma mark - 动画工具方法

/// 运行完成后的回调。
- (void)zhh_runCompletionBlock {
    if (self.zhh_completionBlock) {
        void (^completion)(void) = self.zhh_completionBlock;
        self.zhh_completionBlock = nil;
        completion();
    }
}

/// 获取当前动画值。
- (CGFloat)zhh_currentValue {
    if (self.progress >= self.totalTime) {
        return self.destinationValue;
    }

    CGFloat percent = self.progress / self.totalTime;
    CGFloat updateVal = [self.counter zhh_update:percent];
    return self.startingValue + (updateVal * (self.destinationValue - self.startingValue));
}

@end
