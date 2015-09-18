//
//  WSContext.m
//  workshop
//
//  Created by Gasper on 03/07/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import "WSContext.h"


#import "GlobalTools.h"
#import "WSOperationContainer.h"

@interface WSContext()

@property (nonatomic, strong) NSThread *thread;
@end

@implementation WSContext


-(instancetype)init
{
    if (self = [super init])
    {
        [self initializeContext];
    }
    
    return self;
}


/*! Generate a context
 @discussion A context must be crated and set as current to be able to do anything with th openGL
 */
- (void)initializeContext
{
    /*
     Context is initialized with the version you are going to use. We will use ES2.
     After you have your main context another may be created using the previous' share group to share resources. This is very useful for heavy operations to be used in background thread such as texture loading.
     */
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.thread = [NSThread currentThread];
}

- (void)performBlock:(void (^)(void))block
{
    [self performBlock:block withCallback:nil];
}

- (void)performBlockOnContextThread:(WSOperationContainer *)container
{
    /*
     Set context is per thread as this is its main reason for existance. You should idealy have 1 context per thread which uses the openGL. Multiple contexts on the same thread are valid but you need to set it every time as current. Using a context on multiple thread is something you should never do but is still possible.
     */
    [EAGLContext setCurrentContext:self.glContext];
    if (container.block)
    {
        container.block();
    }
    
    if (container.callbackBlock)
    {
        container.callbackBlock();
    }
}

- (void)performBlock:(void (^)(void))block withCallback:(void (^)(void))returnBlock
{
    WSOperationContainer *container = [[WSOperationContainer alloc] init];
    container.block = block;
    container.callbackBlock = returnBlock;
    
    [self performSelector:@selector(performBlockOnContextThread:) onThread:self.thread withObject:container waitUntilDone:NO];
    
}

-(void)setAsCurrent
{
    [self performBlock:^{
        [EAGLContext setCurrentContext:self.glContext];
    }];
}

-(void)presentRenderBufferWithID:(NSInteger)bufferID
{
    [self performBlock:^{
        [self.glContext presentRenderbuffer:bufferID]; // will present the buffer on the screen
        [GlobalTools checkError]; // check for possible errors

    }];
}




@end
