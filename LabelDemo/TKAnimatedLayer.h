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
  NSMutableArray *_frameList;
  NSUInteger _loopCount;
  CGFloat _animationDuration;
  NSMutableArray *_delayTimeList;
  
  NSUInteger _currentFrameIndex;
  
  
  CGImageSourceRef _sourceRef;
  
  BOOL _paused;
}

@property (nonatomic, readonly) NSUInteger currentFrameIndex;

- (void)prepare:(NSData *)data;

- (void)startAnimating;
- (void)stopAnimating;
- (void)pauseAnimating;
- (void)resumeAnimating;

- (CGSize)sizeOfImage;

@end
