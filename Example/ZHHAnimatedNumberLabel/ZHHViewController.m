//
//  ZHHViewController.m
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

#import "ZHHViewController.h"
#import <ZHHAnneKit/ZHHAnneKit.h>
#import <ZHHAnimatedNumberLabel/ZHHAnimatedNumberLabel.h>

@interface ZHHViewController ()

@property (strong, nonatomic) ZHHAnimatedNumberLabel *label;

@end

@implementation ZHHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.label];
    
    // make one that counts up
    ZHHAnimatedNumberLabel* myLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(10, 130, 200, 40)];
    myLabel.zhh_animationStyle = ZHHNumberAnimationStyleLinear;
    myLabel.zhh_format = @"%d";
    [self.view addSubview:myLabel];
    [myLabel zhh_animateValue:1 toValue:10 duration:3.0];
    
    // make one that counts up from 5% to 10%, using ease in out (the default)
    ZHHAnimatedNumberLabel* countPercentageLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(10, 170, 200, 40)];
    [self.view addSubview:countPercentageLabel];
    countPercentageLabel.zhh_format = @"%.1f%%";
    [countPercentageLabel zhh_animateValue:5 toValue:10];
    
    
    // count up using a string that uses a number formatter
    ZHHAnimatedNumberLabel* scoreLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(10, 210, 200, 40)];
    [self.view addSubview:scoreLabel];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    scoreLabel.zhh_formatBlock = ^NSString* (CGFloat value)
    {
        NSString* formatted = [formatter stringFromNumber:@((int)value)];
        return [NSString stringWithFormat:@"Score: %@",formatted];
    };
    scoreLabel.zhh_animationStyle = ZHHNumberAnimationStyleEaseOut;
    [scoreLabel zhh_animateValue:0 toValue:10000 duration:2.5];
    
    // count up with attributed string
    NSInteger toValue = 100;
    ZHHAnimatedNumberLabel* attributedLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(10, 250, 200, 40)];
    [self.view addSubview:attributedLabel];
    attributedLabel.zhh_attributedFormatBlock = ^NSAttributedString* (CGFloat value)
    {
        NSDictionary* normal = @{ NSFontAttributeName: [UIFont fontWithName: @"HelveticaNeue-UltraLight" size: 20] };
        NSDictionary* highlight = @{ NSFontAttributeName: [UIFont fontWithName: @"HelveticaNeue" size: 20] };
        
        NSString* prefix = [NSString stringWithFormat:@"%d", (int)value];
        NSString* postfix = [NSString stringWithFormat:@"/%d", (int)toValue];
        
        NSMutableAttributedString* prefixAttr = [[NSMutableAttributedString alloc] initWithString: prefix
                                                                                       attributes: highlight];
        NSAttributedString* postfixAttr = [[NSAttributedString alloc] initWithString: postfix
                                                                          attributes: normal];
        [prefixAttr appendAttributedString: postfixAttr];
        
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
    ZHHAnimatedNumberLabel* countLabel = [[ZHHAnimatedNumberLabel alloc] initWithFrame:CGRectMake(10, 300, 200, 40)];
    countLabel.textColor = UIColor.blackColor;
    countLabel.backgroundColor = UIColor.yellowColor;
    countLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    countLabel.zhh_animationStyle = ZHHNumberAnimationStyleLinear;
    countLabel.zhh_format = @"%d";
    countLabel.zhh_edgeInsets = UIEdgeInsetsMake(5, 20, 5, 20);
    countLabel.zhh_cornerRadius = 8;
    [self.view addSubview:countLabel];
    [countLabel zhh_animateValue:200 toValue:1000 duration:1.0];
}

- (ZHHAnimatedNumberLabel *)label {
    if (!_label) {
        _label = [[ZHHAnimatedNumberLabel alloc] init];
        _label.textColor = UIColor.blackColor;
        _label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    }
    return _label;
}

@end
