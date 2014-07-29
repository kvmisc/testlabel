//
//  TKAnimatedLayer.m
//  LabelDemo
//
//  Created by Kevin Wu on 7/29/14.
//  Copyright (c) 2014 Tapmob. All rights reserved.
//

#import "TKAnimatedLayer.h"

@implementation TKAnimatedLayer

- (void)reloadWithData:(NSData *)data
{
  if ( [data length]<=0 ) {
    return;
  }
  
  _frameCount = 0;
  _frameList = nil;
  _loopCount = 0;
  _animationDuration = 0.0;
  _delayTimeList = nil;
  
  _currentFrameIndex = NSNotFound;
  
  if ( _sourceRef ) {
    CFRelease(_sourceRef);
  }
  
  _paused = NO;
  
  
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  self.opaque = YES;
  [CATransaction commit];
  
  _sourceRef = CGImageSourceCreateWithData(((__bridge CFDataRef)data), NULL);
  
  if ( _sourceRef ) {
    _frameCount = CGImageSourceGetCount(_sourceRef);
    
    _frameList = [[NSMutableArray alloc] init];
    for ( int i=0; i<_frameCount; ++i ) {
      CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_sourceRef, i, NULL);
      [_frameList addObject:((__bridge id)imageRef)];
      CFRelease(imageRef);
    }
    
    _loopCount = [[self class] loopCountOfSource:_sourceRef];
    
    _animationDuration = 0.0;
    
    _delayTimeList = [[NSMutableArray alloc] init];
    for ( NSUInteger i=0; i<_frameCount; ++i ) {
      CGFloat delayTime = [[self class] delayTimeOfSource:_sourceRef atIndex:i];
      _animationDuration += delayTime;
      [_delayTimeList addObject:[NSNumber numberWithDouble:delayTime]];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.opaque = ![[self class] hasAlphaOfSource:_sourceRef];
    [CATransaction commit];
    
    _currentFrameIndex = 0;
    [self display];
  }
}

- (void)startAnimating
{
  [self stopAnimating];
  
  if ( (!_sourceRef) || (_frameCount<=0) ) {
    return;
  }
  
  CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"currentFrameIndex"];
  animation.calculationMode = kCAAnimationDiscrete;
  animation.autoreverses = NO;
  if ( _loopCount>0 ) {
    animation.repeatCount = _loopCount;
  } else {
    animation.repeatCount = HUGE_VALF;
  }
  
  NSMutableArray *values = [[NSMutableArray alloc] init];
  NSMutableArray *keyTimes = [[NSMutableArray alloc] init];
  NSTimeInterval lastDurationFraction = 0.0;
  for ( NSUInteger i=0; i<_frameCount; ++i ) {
    [values addObject:[NSNumber numberWithUnsignedInteger:i]];
    
    NSTimeInterval delayTime = [[_delayTimeList objectAtIndex:i] floatValue];
    NSTimeInterval currentDurationFraction = 0.0;
    if ( i>0 ) {
      currentDurationFraction = lastDurationFraction + delayTime / _animationDuration;
    }
    lastDurationFraction = currentDurationFraction;
    [keyTimes addObject:[NSNumber numberWithDouble:currentDurationFraction]];
  }
  
  //add final destination value
  [values addObject:[NSNumber numberWithUnsignedInteger:_frameCount]];
  [keyTimes addObject:[NSNumber numberWithDouble:1.0]];
  
  animation.values = values;
  animation.keyTimes = keyTimes;
  animation.duration = _animationDuration;
  
  [self addAnimation:animation forKey:@"GIFAnimation"];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationWillEnterForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
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

- (CGSize)sizeOfImage
{
  CGSize size = CGSizeZero;
  if ( _sourceRef ) {
    CFDictionaryRef dictionaryRef = CGImageSourceCopyPropertiesAtIndex(_sourceRef, 0, NULL);
    if ( dictionaryRef ) {
      NSNumber *width = ((__bridge NSNumber *)CFDictionaryGetValue(dictionaryRef, kCGImagePropertyPixelWidth));
      size.width = [width floatValue];
      NSNumber *height = ((__bridge NSNumber *)CFDictionaryGetValue(dictionaryRef, kCGImagePropertyPixelHeight));
      size.height = [height floatValue];
      CFRelease(dictionaryRef);
    }
  }
  return size;
}


- (void)applicationDidEnterBackground
{
  self.speed = 0.0;
}

- (void)applicationWillEnterForeground
{
  self.speed = 1.0;
  if ( !_paused ) {
    [self startAnimating];
  }
}


- (id)init
{
  self = [super init];
  if ( self ) {
    _currentFrameIndex = NSNotFound;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  _frameCount = 0;
  _frameList = nil;
  _loopCount = 0;
  _animationDuration = 0.0;
  _delayTimeList = nil;
  
  _currentFrameIndex = NSNotFound;
  
  if ( _sourceRef ) {
    CFRelease(_sourceRef);
  }
  
  _paused = NO;
}

- (void)display
{
  if ( _sourceRef ) {
    NSUInteger index = [((TBGIFLayer *)[self presentationLayer]) currentFrameIndex];
    if ( index<_frameCount ) {
      [CATransaction begin];
      [CATransaction setDisableActions:YES];
      self.contents = [_frameList objectAtIndex:index];
      [CATransaction commit];
    }
  }
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
  return [key isEqualToString:@"currentFrameIndex"];
}


+ (BOOL)hasAlphaOfSource:(CGImageSourceRef)sourceRef
{
  BOOL hasAlpha = NO;
  if ( sourceRef ) {
    CFDictionaryRef dictionaryRef = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if ( dictionaryRef ) {
      const void *value = CFDictionaryGetValue(dictionaryRef, kCGImagePropertyHasAlpha);
      hasAlpha = (value==kCFBooleanTrue);
      CFRelease(dictionaryRef);
    }
  }
  return hasAlpha;
}

+ (NSUInteger)loopCountOfSource:(CGImageSourceRef)sourceRef
{
  NSUInteger loopCount = 0;
  if ( sourceRef ) {
    CFDictionaryRef dictionaryRef = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if ( dictionaryRef ) {
      NSNumber *value = ((__bridge NSNumber *)CFDictionaryGetValue(dictionaryRef, kCGImagePropertyGIFLoopCount));
      loopCount = [value unsignedIntegerValue];
      CFRelease(dictionaryRef);
    }
  }
  return loopCount;
}

+ (CGFloat)delayTimeOfSource:(CGImageSourceRef)sourceRef atIndex:(NSUInteger)idx
{
  CGFloat delayTime = 0.0;
  if ( sourceRef ) {
    CFDictionaryRef dictionaryRef = CGImageSourceCopyPropertiesAtIndex(sourceRef, idx, NULL);
    if ( dictionaryRef ) {
      CFDictionaryRef gifDictionaryRef = NULL;
      if ( CFDictionaryGetValueIfPresent(dictionaryRef, kCGImagePropertyGIFDictionary, ((const void **)(&gifDictionaryRef))) ) {
        const void *delayTimeValue = NULL;
        if ( CFDictionaryGetValueIfPresent(gifDictionaryRef, kCGImagePropertyGIFUnclampedDelayTime, &delayTimeValue) ) {
          delayTime = [((__bridge NSNumber *)delayTimeValue) floatValue];
          if ( delayTime<=0.0 ) {
            if ( CFDictionaryGetValueIfPresent(gifDictionaryRef, kCGImagePropertyGIFDelayTime, &delayTimeValue) ) {
              delayTime = [((__bridge NSNumber *)delayTimeValue) floatValue];
            }
          }
        }
      }
      CFRelease(dictionaryRef);
    }
  }
  return delayTime;
}

@end
