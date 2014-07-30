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
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  button.frame = CGRectMake(10, 10, 300, 40);
  [button addTarget:self action:@selector(doit1:) forControlEvents:UIControlEventTouchUpInside];
  button.layer.borderWidth = 1;
  button.layer.borderColor = [UIColor blackColor].CGColor;
  [self.view addSubview:button];
  
  button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  button.frame = CGRectMake(10, 60, 300, 40);
  [button addTarget:self action:@selector(doit2:) forControlEvents:UIControlEventTouchUpInside];
  button.layer.borderWidth = 1;
  button.layer.borderColor = [UIColor blackColor].CGColor;
  [self.view addSubview:button];
  
  button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  button.frame = CGRectMake(10, 110, 300, 40);
  [button addTarget:self action:@selector(doit3:) forControlEvents:UIControlEventTouchUpInside];
  button.layer.borderWidth = 1;
  button.layer.borderColor = [UIColor blackColor].CGColor;
  [self.view addSubview:button];
  
}


- (void)doit1:(id)sender
{
  UIView *animatedView = [[UIView alloc] init];
  animatedView.backgroundColor = [UIColor redColor];
  [self.view addSubview:animatedView];
  animatedView.frame = CGRectMake(10.0, 160.0, 300.0, 300.0);
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"earth.gif" ofType:nil];
  NSData *data = [[NSData alloc] initWithContentsOfFile:path];
  
  TKAnimatedLayer *animatedLayer = [[TKAnimatedLayer alloc] init];
  [animatedLayer prepare:data];
  [animatedView.layer addSublayer:animatedLayer];
  CGSize frameSize = [animatedLayer preferredFrameSize];
  animatedLayer.frame = CGRectMake(0.0, 0.0, frameSize.width, frameSize.height);
  _animatedLayer = animatedLayer;
  [_animatedLayer startAnimating];
}

- (void)doit2:(id)sender
{
}

- (void)doit3:(id)sender
{
}

@end
