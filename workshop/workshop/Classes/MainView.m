//
//  MainView.m
//  workshop
//
//  Created by Matic Oblak on 6/30/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

@import GLKit;
@import OpenGLES;
#import "MainView.h"
#import "GlobalTools.h"

@interface MainView()

@property (nonatomic, strong) EAGLContext *context; // main context

@property (nonatomic) GLuint frameBuffer; // id of the main frame buffer
@property (nonatomic) GLuint renderBuffer; // id of the main render buffer
@property (nonatomic) CGSize bufferSize; // size of the main buffer

@property (nonatomic, strong) CADisplayLink *displayLink; // display link for animation

@property (nonatomic) BOOL isInitialized; // indicates weather the openGL has already been initialized

@end


@implementation MainView

/*! Override layer class
 @discussion This is needed to be able to use renderbufferStorage:fromDrawable: A simple must-have
 */
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - initialization

/*! Will initialize all basic openGL components for the view
 */
- (void)initializeOpenGL
{
    [self initializeContext];
    [self initializeFrameAndRenderBuffer];
    
    self.isInitialized = YES;
}

#pragma mark context

/*! Generate a context
 @discussion A context must be crated and set as current to be able to do anything with th openGL
 */
- (void)initializeContext
{
    /*
     Context is initialized with the version you are going to use. We will use ES2.
     After you have your main context another may be created using the previous' share group to share resources. This is very useful for heavy operations to be used in background thread such as texture loading.
     */
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
/*
    Set context is per thread as this is its main reason for existance. You should idealy have 1 context per thread which uses the openGL. Multiple contexts on the same thread are valid but you need to set it every time as current. Using a context on multiple thread is something you should never do but is still possible.
 */
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark buffers

- (void)initializeFrameAndRenderBuffer
{
    /*
     For the main buffer a layer must be used to generate the render buffer from the view. This is the iOS way of binding the buffer with the UIView. Other platforms generally use different approaches.
     */
    CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
    layer.opaque = YES;
    /*
     will need to manually set the scale for retina display.
     Note that default is 1.0 for all devices and is valid but your display will ahve a low resolution.
     */
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]) {
        layer.contentsScale = [UIScreen mainScreen].scale;
    }
    
    /*
     Generate the frame buffer
     */
    GLuint frameBuffer; // will hold the generated ID
    glGenFramebuffers(1, &frameBuffer); // generate only 1
    self.frameBuffer = frameBuffer; // assign to store as the local variable
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer); // bind to set as current
    
    GLuint renderBuffer; // will hold the generated ID
    glGenRenderbuffers(1, &renderBuffer); // generate only 1
    self.renderBuffer = renderBuffer; // assign to store as the local variable
    glBindRenderbuffer(GL_RENDERBUFFER, self.renderBuffer); // bind to set as current
    
    /*
     At this point both of the buffers are emty as in they have no data allocated.
     We will allocate it to be bound with the view and have appropriate format.
     This is mandatory for the render buffers bound to an UIView
     */
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer]; // will allocate the data on the GPU
    
    /*
     We need to attach the render buffer to the frame buffer to be used.
     Note that the frame buffer does not contain any pixel data at all but just a number of render buffers.
     This might be confusing at this point but a frame buffer might later contain multiple render buffers for instance a color buffer, a depth buffer, a stencil buffer, even a texture...
     The current render buffer is a color buffer.
     */
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer); // attach as color buffer
    
    /*
     We need to get the width and height since the render buffer was created for us and do not know its size
     */
    GLint width, height; // Containers for the size values
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width); // get width
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height); // get height
    self.bufferSize = CGSizeMake(width, height); // assign the size as we might need it later
    
    /*
     We still need to specify what part of the buffer will be used.
     We will set the full buffer frame.
     Try play around with some other values to get a better understanding of this function.
     */
    glViewport(0, 0, width, height);
    
    /*
     Check if we produced some errors
     */
    [GlobalTools framebufferStatusValid]; // will check the currently bound frame buffer if all is ok
    [GlobalTools checkError]; // will check for any other errors
}

#pragma mark - animation

- (CADisplayLink *)displayLink
{
    /*
     A standard display link implementation. Will most likely fire 60FPS if possible.
     This is much like using an NSTimer
     */
    if(_displayLink == nil)
    {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame)];
    }
    return _displayLink;
}

/*! Will start the animation
 @discussion openGL will be initialized if not yet
 */
- (void)startAnimating
{
    if(self.isInitialized == NO)
    {
        [self initializeOpenGL];
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                       forMode:NSRunLoopCommonModes];
}
- (void)stopAnimating
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

#pragma mark - draw

/*! A main draw loop method
 */
- (void)drawFrame
{
    [self clearBackground]; // clear the background
    [self presetnRenderbuffer]; // show the current buffer on screen
}

- (void)clearBackground
{
    glClearColor(1.0f, .0f, .0f, 1.0f); // set some clear color. This can be done only once to gain performance
    glClear(GL_COLOR_BUFFER_BIT); // clear the color. To also clear the depth buffer you may use (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    [GlobalTools checkError]; // check for possible errors
}

- (void)presetnRenderbuffer
{
    [self.context presentRenderbuffer:self.renderBuffer]; // will present the buffer on the screen
    [GlobalTools checkError]; // check for possible errors
}

@end
