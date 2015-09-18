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
#import "WSContext.h"
#import "BaseShader.h"
#import "FrameBuffer.h"

@interface MainView()

@property (nonatomic, strong) WSContext *contextObject;
@property (nonatomic, strong) FrameBuffer *frameBuffer;

@property (nonatomic, strong) BaseShader *shader;

@property (nonatomic, strong) CADisplayLink *displayLink; // display link for animation

@property (nonatomic) BOOL isInitialized; // indicates weather the openGL has already been initialized

@property (nonatomic) GLfloat backgroundGrayscaleFactor; // used just to see the animation is working on the background

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
    self.contextObject = [[WSContext alloc] init];
    self.frameBuffer = [[FrameBuffer alloc] initWithContext:self.contextObject];
    self.shader = [[BaseShader alloc] initWithContext:self.contextObject];
    
    [self.contextObject performBlock:^{
        [self.frameBuffer loadBuffersWithView:self];
        [self.shader loadShaderSourceNamed:@"ColorShader"];
    }];
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
    [self.contextObject performBlock:^{
        [self.frameBuffer bindFrameBuffer];
        [self clearBackground]; // clear the background
        [self drawShape]; // draw some shape
    }];
    [self.frameBuffer present];
}

- (void)clearBackground
{
    GLfloat value = fabsf(self.backgroundGrayscaleFactor);
    glClearColor(value, value, value, 1.0f); // set some clear color. This can be done only once to gain performance if the color is always the same
    
    /*
     Alternate backgroundGrayscaleFactor in range [-1, 1]
     */
    self.backgroundGrayscaleFactor += .01f;
    if(self.backgroundGrayscaleFactor > 1.0f)
    {
        self.backgroundGrayscaleFactor -= 2.0f;
    }
    
    /*
     Clear the color
     */
    glClear(GL_COLOR_BUFFER_BIT); // clear the color. To also clear the depth buffer you may use (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    [GlobalTools checkError]; // check for possible errors
}

/*! Draw some test shape
 */
- (void)drawShape
{
    [self.shader use];
    
    GLfloat vertexData[3][3] = {
        -1.0f, 1.0f, .0f,
        .0f, 1.0f, .0f,
        1.0f, .0f, .0f,

    };

    [self.shader setVertexPositionsPointer:(GLfloat *)vertexData withDimension:3 stride:0];
    [self.shader setColor:[UIColor greenColor]];
    
    /*
     The actual drawing
     We need to specify what shape we are drawing. This could be triangles, lines, points...
     We need to specify the starting position index (0 is first)
     We need to specify the number of vertices we will be drawing
     */
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
    
    [GlobalTools checkError]; // check for possible errors
    
    /*
     Now try a line that is animated
     */
    static CGFloat angle = .0f;
    CGFloat radius = .5f;
    angle += .01f; // will increase each frame
    GLfloat linePositions[] = {
        .0f, .0f,
        sinf(angle)*radius, cosf(angle)*radius
    };
    glLineWidth(12.0f); // meed to set some line width
    
    [self.shader setVertexPositionsPointer:linePositions withDimension:2 stride:0];
    [self.shader setColor:[UIColor redColor]];
    
    glDrawArrays(GL_LINE_STRIP, 0, 2);
}

@end
