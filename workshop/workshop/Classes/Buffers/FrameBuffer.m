//
//  FrameBuffer.m
//  workshop
//
//  Created by Mišo Lubarda on 03/07/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import "FrameBuffer.h"
#import "GlobalTools.h"

@import GLKit;
@import OpenGLES;

@interface FrameBuffer ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, weak) UIView *view;

@property (nonatomic) GLuint frameBuffer;
@property (nonatomic) GLuint renderBuffer;
@property (nonatomic, readwrite) CGSize bufferSize; // size of the main buffer

@end

@implementation FrameBuffer

- (instancetype)initWithContext:(EAGLContext *)context
{
    if (self = [super init])
    {
        self.context = context;
    }
    
    return self;
}

- (void)loadBuffersWithView:(UIView *)view
{
    self.view = view;
    
    CAEAGLLayer *layer = (CAEAGLLayer *)view.layer;
    layer.opaque = YES;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) {
        layer.contentsScale = [UIScreen mainScreen].scale;
    }
    
    GLuint frameBuffer; // will hold the generated ID
    glGenFramebuffers(1, &frameBuffer); // generate only 1
    self.frameBuffer = frameBuffer; // assign to store as the local variable
    [self bindFrameBuffer];
    
    GLuint renderBuffer; // will hold the generated ID
    glGenRenderbuffers(1, &renderBuffer); // generate only 1
    self.renderBuffer = renderBuffer; // assign to store as the local variable
    [self bindRenderBuffer];
    
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.renderBuffer);
    
    GLint width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    self.bufferSize = CGSizeMake(width, height);
    
    glViewport(0, 0, width, height);
    
    [GlobalTools framebufferStatusValid];
    [GlobalTools checkError];

}

- (void)bindFrameBuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer); // bind to set as current
}

- (void)bindRenderBuffer
{
    glBindRenderbuffer(GL_RENDERBUFFER, self.renderBuffer); // bind to set as current
}

- (void)present
{
    [self.context presentRenderbuffer:self.renderBuffer];
    [GlobalTools checkError];
}

- (void)clear
{
    CGFloat colorBuffer [4];
    
    colorBuffer[0] = 0.0f;
    colorBuffer[1] = 0.0f;
    colorBuffer[2] = 0.0f;
    colorBuffer[3] = 1.0f;
    
    if (self.backgroundClearColor)
    {
        [self.backgroundClearColor getRed:colorBuffer green:colorBuffer+1 blue:colorBuffer+2 alpha:colorBuffer+3];
    }
    
    glClearColor(colorBuffer[0], colorBuffer[1], colorBuffer[2], colorBuffer[3]);
    
    glClear(GL_COLOR_BUFFER_BIT);
}

@end
