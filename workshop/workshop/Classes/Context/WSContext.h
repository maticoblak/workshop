//
//  WSContext.h
//  workshop
//
//  Created by Gasper on 03/07/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GLKit;
@import OpenGLES;

@interface WSContext : NSObject

@property (nonatomic, strong) EAGLContext *glContext; // main context


- (void)performBlock:(void (^)(void))block;
- (void)performBlock:(void (^)(void))block withCallback:(void (^)(void))returnBlock;

-(void)setAsCurrent;

-(void)presentRenderBufferWithID:(NSInteger)bufferID;

@end
