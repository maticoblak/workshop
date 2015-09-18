//
//  FrameBuffer.h
//  workshop
//
//  Created by Mišo Lubarda on 03/07/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GLKit;
@import OpenGLES;
@class WSContext;

@interface FrameBuffer : NSObject

@property (nonatomic, strong) UIColor *backgroundClearColor;
@property (nonatomic, readonly) CGSize bufferSize; // size of the main buffer

- (instancetype)initWithContext:(WSContext *)context;
- (void)loadBuffersWithView:(UIView *)view;

- (void)bindFrameBuffer;
- (void)bindRenderBuffer;

- (void)present;
- (void)clear;

@end
