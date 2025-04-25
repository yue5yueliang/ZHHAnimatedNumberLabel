//
//  ZHHAnimatedNumberLabel.h
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2024/12/26.
//  Copyright © 2024 桃色三岁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

/// UILabel 数字变化的动画方法
typedef NS_ENUM(NSInteger, ZHHNumberAnimationStyle) {
    /// 缓入缓出效果：动画以较慢速度开始和结束，中间加速。
    ZHHNumberAnimationStyleEaseInOut,
    /// 缓入效果：动画以较慢速度开始，然后逐渐加速。
    ZHHNumberAnimationStyleEaseIn,
    /// 缓出效果：动画以较快速度开始，然后逐渐减速。
    ZHHNumberAnimationStyleEaseOut,
    /// 线性效果：动画以恒定的速度进行。
    ZHHNumberAnimationStyleLinear,
    /// 缓入弹跳效果：动画以弹跳的方式逐渐加速进入。
    ZHHNumberAnimationStyleEaseInBounce,
    /// 缓出弹跳效果：动画以弹跳的方式逐渐减速结束。
    ZHHNumberAnimationStyleEaseOutBounce
};

/// 格式化的 Block，接收一个 `CGFloat` 值，返回格式化后的 `NSString`
typedef NSString* _Nullable (^ZHHAnimatedNumberLabelFormatBlock)(CGFloat value);

/// 格式化的 Block，接收一个 `CGFloat` 值，返回格式化后的 `NSAttributedString`
typedef NSAttributedString* _Nullable (^ZHHAnimatedNumberLabelAttributedFormatBlock)(CGFloat value);

/// 动态数字变化的 UILabel，支持多种动画效果
@interface ZHHAnimatedNumberLabel : UILabel
/// 显示数字的格式化字符串，例如：`@"%.2f"`、`@"%d"`
/// 如果未设置 `formatBlock` 或 `attributedFormatBlock`，将使用此属性进行格式化
@property (nonatomic, strong) NSString *zhh_format;

/// 数字变化的动画方法，例如线性变化、缓入缓出等，枚举类型 `UILabelCountingMethod`
@property (nonatomic, assign) ZHHNumberAnimationStyle zhh_animationStyle;

/// 动画持续的时间，单位为秒，默认值为 2.0 秒
@property (nonatomic, assign) NSTimeInterval zhh_animationDuration;

/// 格式化回调 Block，返回一个自定义的 `NSString`
/// 设置此属性时，优先级高于 `format`
@property (nonatomic, copy) ZHHAnimatedNumberLabelFormatBlock zhh_formatBlock;

/// 格式化回调 Block，返回一个自定义的 `NSAttributedString`
/// 设置此属性时，优先级高于 `formatBlock`
@property (nonatomic, copy) ZHHAnimatedNumberLabelAttributedFormatBlock zhh_attributedFormatBlock;

/// 动画完成时的回调 Block
@property (nonatomic, copy, nullable) void (^zhh_completionBlock)(void);
/// 从指定的起始值 `startValue` 动画到目标值 `endValue`
/// 使用默认的动画时长
/// @param startValue 动画的起始值
/// @param endValue 动画的目标值
- (void)zhh_animateValue:(CGFloat)startValue toValue:(CGFloat)endValue;

/// 从指定的起始值 `startValue` 动画到目标值 `endValue`
/// 使用自定义的动画时长
/// @param startValue 动画的起始值
/// @param endValue 动画的目标值
/// @param duration 动画的持续时间（秒）
- (void)zhh_animateValue:(CGFloat)startValue toValue:(CGFloat)endValue duration:(NSTimeInterval)duration;

/// 从当前值开始动画过渡到目标值
/// 使用默认动画时长
/// @param endValue 最终显示的目标值
- (void)zhh_animateToValue:(CGFloat)endValue;

/// 从当前值开始动画过渡到目标值
/// 可自定义动画时长
/// @param endValue 最终显示的目标值
/// @param duration 动画持续时间（单位：秒）
- (void)zhh_animateToValue:(CGFloat)endValue duration:(NSTimeInterval)duration;

/// 从 0 开始动画过渡到目标值
/// 使用默认动画时长
/// @param endValue 最终显示的目标值
- (void)zhh_animateFromZeroToValue:(CGFloat)endValue;

/// 从 0 开始动画过渡到目标值
/// 可自定义动画时长
/// @param endValue 最终显示的目标值
/// @param duration 动画持续时间（单位：秒）
- (void)zhh_animateFromZeroToValue:(CGFloat)endValue duration:(NSTimeInterval)duration;

/// 获取当前动画进度对应的数值
/// @return 当前动画的数值
- (CGFloat)zhh_currentValue;
@end

NS_ASSUME_NONNULL_END
