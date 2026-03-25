//
//  OCDemoViewController.m
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import "OCDemoViewController.h"
@import ZHHAnimatedNumberLabel;

@interface OCDemoViewController ()

@property (nonatomic, strong) ZHHAnimatedNumberLabel *label;
@property (nonatomic, strong) ZHHAnimatedNumberLabel *coinLabel;
@property (nonatomic, strong) ZHHAnimatedNumberLabel *coinLabelDigitSmooth;
@property (nonatomic, strong) ZHHAnimatedNumberLabel *coinLabelDigitDrop;
@property (nonatomic, assign) NSInteger coinTotal;
@property (nonatomic, assign) NSInteger coinTotalDigitSmooth;
@property (nonatomic, assign) NSInteger coinTotalDigitDrop;
@property (nonatomic, strong) NSTimer *coinTimer;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation OCDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"OC 示例";
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];

    CGFloat leftX = 24;
    CGFloat columnSpacing = 12;
    CGFloat columnWidth = floor((CGRectGetWidth(self.view.bounds) - leftX * 2 - columnSpacing) * 0.5);
    CGFloat rightX = leftX + columnWidth + columnSpacing;
    CGFloat rowHeight = 36;
    CGFloat rowSpacing = 14;
    self.label.frame = CGRectMake(leftX, 15, columnWidth, rowHeight);

    [self.scrollView addSubview:self.label];

    // make one that counts up
    ZHHAnimatedNumberLabel *myLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(rightX, 15, columnWidth, rowHeight)];
    myLabel.zhh_animationStyle = ZHHNumberAnimationStyleLinear;
    myLabel.zhh_format = @"%d";
    [self.scrollView addSubview:myLabel];
    [myLabel zhh_animateValue:1 toValue:10 duration:3.0];

    // make one that counts up from 5% to 10%, using ease in out (the default)
    ZHHAnimatedNumberLabel *countPercentageLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(leftX, 15 + rowHeight + rowSpacing, columnWidth, rowHeight)];
    [self.scrollView addSubview:countPercentageLabel];
    countPercentageLabel.zhh_format = @"%.1f%%";
    [countPercentageLabel zhh_animateValue:5 toValue:10];

    // count up using a string that uses a number formatter
    ZHHAnimatedNumberLabel *scoreLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(rightX, 15 + rowHeight + rowSpacing, columnWidth, rowHeight)];
    [self.scrollView addSubview:scoreLabel];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    scoreLabel.zhh_formatBlock = ^NSString * _Nullable(CGFloat value) {
        NSString *formatted = [formatter stringFromNumber:@((int)value)];
        return [NSString stringWithFormat:@"Score: %@", formatted];
    };
    scoreLabel.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
    [scoreLabel zhh_animateValue:0 toValue:10000 duration:2.5];

    // count up with attributed string
    NSInteger toValue = 100;
    ZHHAnimatedNumberLabel *attributedLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(leftX, 15 + (rowHeight + rowSpacing) * 2, columnWidth, rowHeight)];
    [self.scrollView addSubview:attributedLabel];
    attributedLabel.zhh_attributedFormatBlock = ^NSAttributedString * _Nullable(CGFloat value) {
        NSDictionary *normal = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20] };
        NSDictionary *highlight = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:20] };

        NSString *prefix = [NSString stringWithFormat:@"%d", (int)value];
        NSString *postfix = [NSString stringWithFormat:@"/%d", (int)toValue];

        NSMutableAttributedString *prefixAttr = [[NSMutableAttributedString alloc] initWithString:prefix attributes:highlight];
        NSAttributedString *postfixAttr = [[NSAttributedString alloc] initWithString:postfix attributes:normal];
        [prefixAttr appendAttributedString:postfixAttr];

        return prefixAttr;
    };
    [attributedLabel zhh_animateValue:0 toValue:toValue duration:2.5];

    self.label.zhh_animationStyle = ZHHNumberAnimationStyleEaseInOut;
    self.label.zhh_format = @"%d%%";

    __weak typeof(self) weakSelf = self;
    self.label.zhh_completionBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.label.textColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
    };

    [self.label zhh_animateValue:0 toValue:100];

    // make one that counts up
    ZHHAnimatedNumberLabel *countLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(rightX, 15 + (rowHeight + rowSpacing) * 2, columnWidth, rowHeight)];
    countLabel.textColor = UIColor.blackColor;
    countLabel.backgroundColor = UIColor.yellowColor;
    countLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    countLabel.zhh_animationStyle = ZHHNumberAnimationStyleLinear;
    countLabel.zhh_format = @"%d";
    [self.scrollView addSubview:countLabel];
    [countLabel zhh_animateValue:200 toValue:1000 duration:1.0];
    
    // task style random coin reward
    CGFloat coinStartY = 165;
    self.coinLabel.frame = CGRectMake(leftX, coinStartY, columnWidth, rowHeight);
    self.coinLabelDigitSmooth.frame = CGRectMake(leftX, coinStartY + rowHeight + rowSpacing, columnWidth, rowHeight);
    self.coinLabelDigitDrop.frame = CGRectMake(leftX, coinStartY + (rowHeight + rowSpacing) * 2, columnWidth, rowHeight);
    [self.scrollView addSubview:self.coinLabel];
    [self.scrollView addSubview:self.coinLabelDigitSmooth];
    [self.scrollView addSubview:self.coinLabelDigitDrop];
    
    UIButton *randomButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CGFloat buttonY = coinStartY + (rowHeight + rowSpacing) * 3 + 8;
    CGFloat buttonWidth = floor((CGRectGetWidth(self.view.bounds) - leftX * 2 - columnSpacing * 2) / 3);
    randomButton.frame = CGRectMake(leftX, buttonY, buttonWidth, rowHeight);
    [randomButton setTitle:@"随机+金币" forState:UIControlStateNormal];
    [randomButton addTarget:self action:@selector(handleRandomIncrement) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:randomButton];
    
    UIButton *taskButton = [UIButton buttonWithType:UIButtonTypeSystem];
    taskButton.frame = CGRectMake(leftX + buttonWidth + columnSpacing, buttonY, buttonWidth, rowHeight);
    [taskButton setTitle:@"连续任务(5次)" forState:UIControlStateNormal];
    [taskButton addTarget:self action:@selector(handleContinuousTask) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:taskButton];
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    resetButton.frame = CGRectMake(leftX + (buttonWidth + columnSpacing) * 2, buttonY, buttonWidth, rowHeight);
    [resetButton setTitle:@"重置" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(handleReset) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:resetButton];
    
    [self.coinLabel zhh_animateValue:self.coinTotal toValue:self.coinTotal duration:0];
    [self.coinLabelDigitSmooth zhh_animateValue:self.coinTotalDigitSmooth toValue:self.coinTotalDigitSmooth duration:0];
    [self.coinLabelDigitDrop zhh_animateValue:self.coinTotalDigitDrop toValue:self.coinTotalDigitDrop duration:0];
    
    [self addEngineCompareSamplesWithStartY:buttonY + rowHeight + 28];
    [self addAnimationStyleSamplesWithStartY:buttonY + rowHeight + 170];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), buttonY + rowHeight + 360);
}

- (ZHHAnimatedNumberLabel *)label {
    if (!_label) {
        _label = [[ZHHAnimatedNumberLabel alloc] init];
        _label.textColor = UIColor.blackColor;
        _label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
        _label.frame = CGRectMake(24, 50, 220, 36);
    }
    return _label;
}

- (ZHHAnimatedNumberLabel *)coinLabel {
    if (!_coinLabel) {
        _coinLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(24, 360, 220, 36)];
        _coinLabel.textColor = UIColor.systemOrangeColor;
        _coinLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _coinLabel.zhh_animationEngine = ZHHAnimationEngineInterpolate;
        _coinLabel.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
        _coinLabel.zhh_format = @"金币：%d";
    }
    return _coinLabel;
}

- (ZHHAnimatedNumberLabel *)coinLabelDigitSmooth {
    if (!_coinLabelDigitSmooth) {
        _coinLabelDigitSmooth = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(24, 410, 220, 36)];
        _coinLabelDigitSmooth.textColor = UIColor.systemGreenColor;
        _coinLabelDigitSmooth.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _coinLabelDigitSmooth.zhh_animationEngine = ZHHAnimationEngineDigitScroll;
        _coinLabelDigitSmooth.zhh_digitScrollStyle = ZHHDigitScrollStyleSmooth;
        _coinLabelDigitSmooth.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
        _coinLabelDigitSmooth.zhh_format = @"金币平滑：%d";
    }
    return _coinLabelDigitSmooth;
}

- (ZHHAnimatedNumberLabel *)coinLabelDigitDrop {
    if (!_coinLabelDigitDrop) {
        _coinLabelDigitDrop = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(24, 460, 220, 36)];
        _coinLabelDigitDrop.textColor = UIColor.systemPurpleColor;
        _coinLabelDigitDrop.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        _coinLabelDigitDrop.zhh_animationEngine = ZHHAnimationEngineDigitScroll;
        _coinLabelDigitDrop.zhh_digitScrollStyle = ZHHDigitScrollStyleDrop;
        _coinLabelDigitDrop.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
        _coinLabelDigitDrop.zhh_format = @"金币坠落：%d";
    }
    return _coinLabelDigitDrop;
}

- (void)startCoinTaskAnimation {
    [self.coinTimer invalidate];
    __weak typeof(self) weakSelf = self;
    __block NSInteger count = 0;
    self.coinTimer = [NSTimer scheduledTimerWithTimeInterval:0.9 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (count >= 5) {
            [timer invalidate];
            return;
        }
        [strongSelf performRandomIncrement];
        count += 1;
    }];
}

- (void)performRandomIncrement {
    NSInteger addValue = arc4random_uniform(26) + 3;
    NSInteger fromValue = self.coinTotal;
    self.coinTotal += addValue;
    [self.coinLabel zhh_animateValue:fromValue toValue:self.coinTotal duration:0.55];
    
    NSInteger addValueDigitSmooth = arc4random_uniform(26) + 3;
    NSInteger fromValueDigitSmooth = self.coinTotalDigitSmooth;
    self.coinTotalDigitSmooth += addValueDigitSmooth;
    [self.coinLabelDigitSmooth zhh_animateValue:fromValueDigitSmooth toValue:self.coinTotalDigitSmooth duration:0.55];
    
    NSInteger addValueDigitDrop = arc4random_uniform(26) + 3;
    NSInteger fromValueDigitDrop = self.coinTotalDigitDrop;
    self.coinTotalDigitDrop += addValueDigitDrop;
    [self.coinLabelDigitDrop zhh_animateValue:fromValueDigitDrop toValue:self.coinTotalDigitDrop duration:0.55];
}

- (void)handleRandomIncrement {
    [self.coinTimer invalidate];
    [self performRandomIncrement];
}

- (void)handleContinuousTask {
    [self startCoinTaskAnimation];
}

- (void)handleReset {
    [self.coinTimer invalidate];
    self.coinTotal = 0;
    self.coinTotalDigitSmooth = 0;
    self.coinTotalDigitDrop = 0;
    [self.coinLabel zhh_animateValue:[self.coinLabel zhh_currentValue] toValue:0 duration:0.35];
    [self.coinLabelDigitSmooth zhh_animateValue:[self.coinLabelDigitSmooth zhh_currentValue] toValue:0 duration:0.35];
    [self.coinLabelDigitDrop zhh_animateValue:[self.coinLabelDigitDrop zhh_currentValue] toValue:0 duration:0.35];
}

- (void)addEngineCompareSamplesWithStartY:(CGFloat)startY {
    CGFloat leftX = 24;
    CGFloat columnSpacing = 12;
    CGFloat columnWidth = floor((CGRectGetWidth(self.view.bounds) - leftX * 2 - columnSpacing) * 0.5);

    ZHHAnimatedNumberLabel *interpolateLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(leftX, startY, columnWidth, 36)];
    interpolateLabel.textColor = UIColor.systemBlueColor;
    interpolateLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    interpolateLabel.zhh_animationEngine = ZHHAnimationEngineInterpolate;
    interpolateLabel.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
    interpolateLabel.zhh_formatBlock = ^NSString * _Nullable(CGFloat value) {
        return [NSString stringWithFormat:@"插值引擎: %d", (int)value];
    };
    [self.scrollView addSubview:interpolateLabel];
    [interpolateLabel zhh_animateValue:12345 toValue:12888 duration:2.0];
    
    ZHHAnimatedNumberLabel *smoothLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(leftX, startY + 50, columnWidth, 36)];
    smoothLabel.textColor = UIColor.systemGreenColor;
    smoothLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    smoothLabel.zhh_animationEngine = ZHHAnimationEngineDigitScroll;
    smoothLabel.zhh_digitScrollStyle = ZHHDigitScrollStyleSmooth;
    smoothLabel.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
    smoothLabel.zhh_format = @"%d";
    [self.scrollView addSubview:smoothLabel];
    [smoothLabel zhh_animateValue:12345 toValue:12888 duration:0.5];
    
    ZHHAnimatedNumberLabel *dropLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(leftX, startY + 100, columnWidth, 36)];
    dropLabel.textColor = UIColor.systemPurpleColor;
    dropLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    dropLabel.zhh_animationEngine = ZHHAnimationEngineDigitScroll;
    dropLabel.zhh_digitScrollStyle = ZHHDigitScrollStyleDrop;
    dropLabel.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
    dropLabel.zhh_format = @"%d";
    [self.scrollView addSubview:dropLabel];
    [dropLabel zhh_animateValue:12345 toValue:12888 duration:0.5];
}

- (void)addAnimationStyleSamplesWithStartY:(CGFloat)startY {
    CGFloat leftX = 24;
    CGFloat columnSpacing = 12;
    CGFloat columnWidth = floor((CGRectGetWidth(self.view.bounds) - leftX * 2 - columnSpacing) * 0.5);
    CGFloat rightX = leftX + columnWidth + columnSpacing;
    NSArray<NSDictionary *> *styles = @[
        @{ @"name": @"EaseInOut", @"style": @(ZHHNumberAnimationStyleEaseInOut) },
        @{ @"name": @"EaseIn", @"style": @(ZHHNumberAnimationStyleEaseIn) },
        @{ @"name": @"EaseOut", @"style": @(ZHHNumberAnimationStyleEaseOut) },
        @{ @"name": @"Linear", @"style": @(ZHHNumberAnimationStyleLinear) },
        @{ @"name": @"EaseInBounce", @"style": @(ZHHNumberAnimationStyleEaseInBounce) },
        @{ @"name": @"EaseOutBounce", @"style": @(ZHHNumberAnimationStyleEaseOutBounce) }
    ];
    
    [styles enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat row = idx / 2;
        CGFloat x = idx % 2 == 0 ? leftX : rightX;
        CGFloat y = startY + row * 56;
        ZHHAnimatedNumberLabel *demoLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(x, y, columnWidth, 36)];
        demoLabel.textColor = UIColor.darkGrayColor;
        demoLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        demoLabel.zhh_animationStyle = [item[@"style"] integerValue];
        NSString *name = item[@"name"];
        demoLabel.zhh_formatBlock = ^NSString * _Nullable(CGFloat value) {
            return [NSString stringWithFormat:@"%@: %d", name, (int)value];
        };
        [self.scrollView addSubview:demoLabel];
        [demoLabel zhh_animateValue:0 toValue:1000 duration:3.5];
        
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(x, y + 34, columnWidth, 4)];
        bar.backgroundColor = UIColor.systemGray5Color;
        bar.layer.cornerRadius = 2;
        [self.scrollView addSubview:bar];
        
        UIView *progress = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 4)];
        progress.backgroundColor = UIColor.systemBlueColor;
        progress.layer.cornerRadius = 2;
        [bar addSubview:progress];
        
        [self animateProgress:progress style:[item[@"style"] integerValue] fullWidth:columnWidth];
    }];
}

- (void)animateProgress:(UIView *)progress style:(ZHHNumberAnimationStyle)style fullWidth:(CGFloat)fullWidth {
    if (style == ZHHNumberAnimationStyleLinear) {
        [UIView animateWithDuration:3.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            CGRect frame = progress.frame;
            frame.size.width = fullWidth;
            progress.frame = frame;
        } completion:nil];
    } else if (style == ZHHNumberAnimationStyleEaseIn) {
        [UIView animateWithDuration:3.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            CGRect frame = progress.frame;
            frame.size.width = fullWidth;
            progress.frame = frame;
        } completion:nil];
    } else if (style == ZHHNumberAnimationStyleEaseOut) {
        [UIView animateWithDuration:3.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect frame = progress.frame;
            frame.size.width = fullWidth;
            progress.frame = frame;
        } completion:nil];
    } else if (style == ZHHNumberAnimationStyleEaseInOut) {
        [UIView animateWithDuration:3.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect frame = progress.frame;
            frame.size.width = fullWidth;
            progress.frame = frame;
        } completion:nil];
    } else if (style == ZHHNumberAnimationStyleEaseInBounce) {
        [UIView animateWithDuration:3.5 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
            CGRect frame = progress.frame;
            frame.size.width = fullWidth;
            progress.frame = frame;
        } completion:nil];
    } else {
        [UIView animateWithDuration:3.5 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect frame = progress.frame;
            frame.size.width = fullWidth;
            progress.frame = frame;
        } completion:nil];
    }
}

- (void)dealloc {
    [self.coinTimer invalidate];
}

@end
