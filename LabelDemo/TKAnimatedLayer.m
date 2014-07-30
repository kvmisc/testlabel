//
//  TKAnimatedLayer.m
//  LabelDemo
//
//  Created by Kevin Wu on 7/29/14.
//  Copyright (c) 2014 Tapmob. All rights reserved.
//

#import "TKAnimatedLayer.h"

CGFloat SourceGetDelay(CGImageSourceRef sourceRef, NSUInteger idx)
{
  CGFloat delay = 0.0;
  if ( sourceRef ) {
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, idx, NULL);
    if ( properties ) {
      
      CFDictionaryRef dictionaryRef = NULL;
      if ( CFDictionaryGetValueIfPresent(properties, kCGImagePropertyGIFDictionary, ((const void **)(&dictionaryRef))) ) {
        const void *value = NULL;
        if ( CFDictionaryGetValueIfPresent(dictionaryRef, kCGImagePropertyGIFUnclampedDelayTime, &value) ) {
          delay = [((__bridge NSNumber *)value) floatValue];
          if ( delay<=0.0 ) {
            if ( CFDictionaryGetValueIfPresent(dictionaryRef, kCGImagePropertyGIFDelayTime, &value) ) {
              delay = [((__bridge NSNumber *)value) floatValue];
            }
          }
        }
      }
      CFRelease(properties);
    }
  }
  return delay;
}

NSUInteger SourceGetLoopCount(CGImageSourceRef sourceRef)
{
  NSUInteger loopCount = 0;
  if ( sourceRef ) {
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if ( properties ) {
      
      NSNumber *value = ((__bridge NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyGIFLoopCount));
      loopCount = [value unsignedIntegerValue];
      CFRelease(properties);
    }
  }
  return loopCount;
}

BOOL SourceHasAlpha(CGImageSourceRef sourceRef)
{
  BOOL hasAlpha = NO;
  if ( sourceRef ) {
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if ( properties ) {
      const void *value = CFDictionaryGetValue(properties, kCGImagePropertyHasAlpha);
      hasAlpha = (value==kCFBooleanTrue);
      CFRelease(properties);
    }
  }
  return hasAlpha;
}



@implementation TKAnimatedLayer

- (id)init
{
  self = [super init];
  if ( self ) {
    _presentationIndex = NSNotFound;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  _frameCount = 0;
  _frameAry = nil;
  _delayAry = nil;
  
  _loopCount = 0;
  _duration = 0.0;
  
  _paused = NO;
  _presentationIndex = NSNotFound;
}



- (void)prepare:(NSData *)data
{
  if ( [data length]>0 ) {
    
    [self clean];
    
    [self updateOpaque:YES];
    
    
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData(((__bridge CFDataRef)data), NULL);
    
    if ( sourceRef ) {
      _frameCount = CGImageSourceGetCount(sourceRef);
      
      NSMutableArray *frameAry = [[NSMutableArray alloc] init];
      for ( int i=0; i<_frameCount; ++i ) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, i, NULL);
        [frameAry addObject:((__bridge id)imageRef)];
        CFRelease(imageRef);
      }
      _frameAry = frameAry;
      
      NSMutableArray *delayAry = [[NSMutableArray alloc] init];
      for ( NSUInteger i=0; i<_frameCount; ++i ) {
        CGFloat delay = SourceGetDelay(sourceRef, i);
        _duration += delay;
        [delayAry addObject:[NSNumber numberWithDouble:delay]];
      }
      _delayAry = delayAry;
      
      
      _loopCount = SourceGetLoopCount(sourceRef);
      //_duration = ...;
      
      
      [self updateOpaque:!SourceHasAlpha(sourceRef)];
      
      //_paused = NO;
      _presentationIndex = 0;
      
      CFRelease(sourceRef);
      
      
      [self display];
    }
    
  }
}

- (void)startAnimating
{
  [self stopAnimating];
  
  if ( _frameCount>0 ) {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"presentationIndex"];
    animation.calculationMode = kCAAnimationDiscrete;
    animation.autoreverses = NO;
    animation.repeatCount = (_loopCount>0) ? _loopCount : HUGE_VALF;
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    NSMutableArray *keyTimes = [[NSMutableArray alloc] init];
    NSTimeInterval lastDurationFraction = 0.0;
    for ( NSUInteger i=0; i<_frameCount; ++i ) {
      [values addObject:[NSNumber numberWithUnsignedInteger:i]];
      
      NSTimeInterval delayTime = [[_delayAry objectAtIndex:i] floatValue];
      NSTimeInterval currentDurationFraction = 0.0;
      if ( i>0 ) {
        currentDurationFraction = lastDurationFraction + delayTime / _duration;
      }
      lastDurationFraction = currentDurationFraction;
      [keyTimes addObject:[NSNumber numberWithDouble:currentDurationFraction]];
    }
    
    //add final destination value
    [values addObject:[NSNumber numberWithUnsignedInteger:_frameCount]];
    [keyTimes addObject:[NSNumber numberWithDouble:1.0]];
    
    animation.values = values;
    animation.keyTimes = keyTimes;
    animation.duration = _duration;
    
    [self addAnimation:animation forKey:@"GIFAnimation"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
  }
}

- (void)stopAnimating
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self removeAnimationForKey:@"GIFAnimation"];
}

- (void)pauseAnimating
{
  self.speed = 0.0;
  _paused = YES;
}

- (void)resumeAnimating
{
  self.speed = 1.0;
  _paused = NO;
  if ( ![self animationForKey:@"GIFAnimation"] ) {
    [self startAnimating];
  }
}


- (void)display
{
  if ( _frameCount>0 ) {
    NSUInteger index = [[self presentationLayer] presentationIndex];
    if ( index<_frameCount ) {
      [CATransaction begin];
      [CATransaction setDisableActions:YES];
      self.contents = [_frameAry objectAtIndex:index];
      [CATransaction commit];
    }
  }
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
  return [key isEqualToString:@"presentationIndex"];
}



- (void)clean
{
  _frameCount = 0;
  _frameAry = nil;
  _delayAry = nil;
  
  _loopCount = 0;
  _duration = 0.0;
  
  _paused = NO;
  _presentationIndex = NSNotFound;
}

- (void)updateOpaque:(BOOL)newOpaque
{
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  self.opaque = newOpaque;
  [CATransaction commit];
}

- (void)didEnterBackground
{
  self.speed = 0.0;
}

- (void)willEnterForeground
{
  self.speed = 1.0;
  if ( !_paused ) {
    [self startAnimating];
  }
}

@end
