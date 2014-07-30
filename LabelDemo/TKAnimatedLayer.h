//
//  TKAnimatedLayer.h
//  LabelDemo
//
//  Created by Kevin Wu on 7/29/14.
//  Copyright (c) 2014 Tapmob. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>

@interface TKAnimatedLayer : CALayer {
  NSUInteger _frameCount;
  NSArray *_frameAry;
  NSArray *_delayAry;
  
  NSUInteger _loopCount;
  CGFloat _duration;
  
  BOOL _paused;
  NSUInteger _presentationIndex;
}

@property (nonatomic, readonly) NSUInteger presentationIndex;

- (void)prepare:(NSData *)data;

- (void)startAnimating;
- (void)stopAnimating;
- (void)pauseAnimating;
- (void)resumeAnimating;

@end
