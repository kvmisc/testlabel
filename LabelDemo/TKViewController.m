//
//  TKViewController.m
//  LabelDemo
//
//  Created by Kevin Wu on 7/30/14.
//  Copyright (c) 2014 Tapmob. All rights reserved.
//

#import "TKViewController.h"

@implementation TKViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self addAnimatedView];
  
  [self addAttributedLabel];
}

- (void)addAnimatedView
{
  UIView *animatedView = [[UIView alloc] init];
  animatedView.backgroundColor = [UIColor redColor];
  [self.view addSubview:animatedView];
  animatedView.frame = CGRectMake(10.0, 10.0, 300.0, 100.0);
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"pig.gif" ofType:nil];
  NSData *data = [[NSData alloc] initWithContentsOfFile:path];
  
  TKAnimatedLayer *animatedLayer = [[TKAnimatedLayer alloc] init];
  [animatedLayer prepare:data];
  [animatedView.layer addSublayer:animatedLayer];
  CGSize frameSize = [animatedLayer preferredFrameSize];
  animatedLayer.frame = CGRectMake((animatedView.bounds.size.width-frameSize.width)/2.0,
                                   (animatedView.bounds.size.height-frameSize.height)/2.0,
                                   frameSize.width, frameSize.height);
  [animatedLayer startAnimating];
}

- (void)addAttributedLabel
{
  NSString *shortText = @"Have a [pig] nice day.";
  
  NSString *longText = @"Having now a [qq1] good house and a [qq2] very sufficient income, he intended to marry; and in seeking a reconciliation with the Longbourn family he had a wife in view, as he meant to choose one of [qq3] the daughters, if he found them as handsome and amiable as they were represented by common report. This was his plan of amends--of atonement--for inheriting their father's estate; and he thought it an excellent one, full of eligibility and suitableness, and excessively generous [qq4] and disinterested on his own part.";
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"emotions.plist" ofType:nil];
  NSArray *attrs = [[NSArray alloc] initWithContentsOfFile:path];
  
  TTTAttributedLabel *shortLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
  shortLabel.imageAttrs = attrs;
  shortLabel.numberOfLines = 0;
  shortLabel.text = shortText;
  [self.view addSubview:shortLabel];
  CGSize shortSize = [shortLabel sizeThatFits:CGSizeMake(300.0, 10000.0)];
  NSLog(@"Short Size: %@", NSStringFromCGSize(shortSize));
  shortLabel.frame = CGRectMake(10.0, 120.0, 300.0, shortSize.height);
  
  
  TTTAttributedLabel *longLabel = [[TTTAttributedLabel alloc] init];
  longLabel.imageAttrs = attrs;
  longLabel.numberOfLines = 0;
  longLabel.text = longText;
  [self.view addSubview:longLabel];
  CGSize longSize = [longLabel sizeThatFits:CGSizeMake(300.0, 10000.0)];
  NSLog(@"Long Size: %@", NSStringFromCGSize(longSize));
  longLabel.frame = CGRectMake(10.0, shortLabel.frame.origin.y+shortLabel.bounds.size.height+10.0, 300.0, longSize.height);
  
  
  shortLabel.layer.borderColor = [UIColor blackColor].CGColor;
  shortLabel.layer.borderWidth = 1.0;
}

@end
