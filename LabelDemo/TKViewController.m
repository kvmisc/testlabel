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
  
  _animatedView = [[UIView alloc] init];
  _animatedView.backgroundColor = [UIColor redColor];
  [self.view addSubview:_animatedView];
  _animatedView.frame = CGRectMake(10.0, 160.0, 19.0, 19.0);
  
}


- (void)doit1:(id)sender
{
  NSString *path = [[NSBundle mainBundle] pathForResource:@"qq.gif" ofType:nil];
  _data = [[NSData alloc] initWithContentsOfFile:path];
}

- (void)doit2:(id)sender
{
  TKAnimatedLayer *animatedLayer = [[TKAnimatedLayer alloc] init];
  [animatedLayer prepare:_data];
  [_animatedView.layer addSublayer:animatedLayer];
  animatedLayer.frame = _animatedView.bounds;
  _animatedLayer = animatedLayer;
}

- (void)doit3:(id)sender
{
  [_animatedLayer startAnimating];
}

@end
