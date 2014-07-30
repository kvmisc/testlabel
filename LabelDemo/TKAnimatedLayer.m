//
//  TKAnimatedLayer.m
//  LabelDemo
//
//  Created by Kevin Wu on 7/29/14.
//  Copyright (c) 2014 Tapmob. All rights reserved.
//

#import "TKAnimatedLayer.h"

inline static CGFloat SourceGetWidth(CGImageSourceRef sourceRef)
{
  CGFloat width = 0.0;
  if ( sourceRef ) {
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if ( properties ) {
      
      NSNumber *value = ((__bridge NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth));
      width = [value floatValue];
      CFRelease(properties);
    }
  }
  return width;
}

inline static CGFloat SourceGetHeight(CGImageSourceRef sourceRef)
{
  CGFloat height = 0.0;
  if ( sourceRef ) {
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if ( properties ) {
      
      NSNumber *value = ((__bridge NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight));
      height = [value floatValue];
      CFRelease(properties);
    }
  }
  return height;
}

inline static CGFloat SourceGetDelay(CGImageSourceRef sourceRef, NSUInteger idx)
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

inline static NSUInteger SourceGetLoopCount(CGImageSourceRef sourceRef)
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

inline static BOOL SourceHasAlpha(CGImageSourceRef sourceRef)
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
  
  [self clean];
}


- (void)prepare:(NSData *)data
{
  //DDLogInfo(@"[GIF] %@", THIS_METHOD);
  
  if ( [data length]>0 ) {
    
    [self clean];
    
    [self updateOpaque:YES];
    
    
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData(((__bridge CFDataRef)data), NULL);
    
    if ( sourceRef ) {
      _frameSize = CGSizeMake(SourceGetWidth(sourceRef), SourceGetHeight(sourceRef));
      
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
  //DDLogInfo(@"[GIF] %@", THIS_METHOD);
  [self stopAnimating];
  
  if ( _frameCount>0 ) {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"presentationIndex"];
    animation.calculationMode = kCAAnimationDiscrete;
    animation.autoreverses = NO;
    animation.repeatCount = (_loopCount>0) ? _loopCount : HUGE_VALF;
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    NSMutableArray *keyTimes = [[NSMutableArray alloc] init];
    
    for ( NSUInteger i=0; i<_frameCount; ++i ) {
      [values addObject:[NSNumber numberWithUnsignedInteger:i]];
      
      NSTimeInterval fraction = 0.0;
      for ( int j=0; j<i; ++j ) {
        fraction += [[_delayAry objectAtIndex:j] floatValue];
      }
      [keyTimes addObject:[NSNumber numberWithDouble:fraction/_duration]];
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
  //DDLogInfo(@"[GIF] %@", THIS_METHOD);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self removeAnimationForKey:@"GIFAnimation"];
}

- (void)pauseAnimating
{
  //DDLogInfo(@"[GIF] %@", THIS_METHOD);
  self.speed = 0.0;
  _paused = YES;
}

- (void)resumeAnimating
{
  //DDLogInfo(@"[GIF] %@", THIS_METHOD);
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
      //DDLogInfo(@"[GIF] %@ %u", THIS_METHOD, index);
      [CATransaction begin];
      [CATransaction setDisableActions:YES];
      self.contents = [_frameAry objectAtIndex:index];
      [CATransaction commit];
    }
  }
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
  //DDLogInfo(@"[GIF] %@", THIS_METHOD);
  return [key isEqualToString:@"presentationIndex"];
}

- (CGSize)preferredFrameSize
{
  return _frameSize;
}



- (void)clean
{
  _frameSize = CGSizeZero;
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
