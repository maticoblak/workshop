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

@property (nonatomic) GLuint shaderProgram; // shader program ID
@property (nonatomic) GLuint fragmentShader; // fragment shader ID
@property (nonatomic) GLuint vertexShader; // vertex shader ID

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
    [self initializeContext];
    [self initializeFrameAndRenderBuffer];
    [self initializeShaders];
    
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

#pragma mark Shaders

- (void)initializeShaders
{
    [self compileShader];
    [self linkShader];
}

- (GLuint)shaderProgram
{
    if(_shaderProgram == 0)
    {
        /*
         A program may carry multiple shaders such as in our case one fragment and one vertex shader
         */
        _shaderProgram = glCreateProgram();
    }
    return _shaderProgram;
}

/*! Compile shaders
 @discussion This method will retrieve shader source code from the TXT files and send it to the GPU. The GPU will then try to compile the shaders and if successfull they may be used.
 */
- (BOOL)compileShader
{
    /*
     define paths
     */
    NSString *vertexShaderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ColorShader.vsh"]; // vertex shader path
    NSString *fragmentShaderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ColorShader.fsh"]; // fragment shader path
    
    GLint status; // will check the status once compiled
    NSString *shaderSourceString = nil; // the source string received from the file
    
// vertex shader
    shaderSourceString = [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil]; // get string from file
    const GLchar *sString = (GLchar *)[shaderSourceString UTF8String]; // convert to C string
    self.vertexShader = glCreateShader(GL_VERTEX_SHADER); // create vertex shader
    glShaderSource(self.vertexShader, 1, &sString, NULL); // set shader source data
    glCompileShader(self.vertexShader); // compile the shader
    
    /*
     Get the compile log from the shader
     */
    GLint logLength = 0;
    glGetShaderiv(self.vertexShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = malloc(sizeof(GLchar)*logLength);
        glGetShaderInfoLog(_vertexShader, logLength, &logLength, log);
        NSString *logString = [NSString stringWithCString:log encoding:NSUTF8StringEncoding];
        NSLog(@"Vertex shader compile log:\n%@", logString);
        free(log);
    }

    /*
     Get the compile status from the shader
     */
    glGetShaderiv(self.vertexShader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(self.vertexShader);
        self.vertexShader = 0;
        return NO;
    }
//fragment shader
    
    /*
     All the same as with the vertex shader (but using GL_FRAGMENT_SHADER)
     */
    shaderSourceString = [NSString stringWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:nil];
    if (!shaderSourceString || shaderSourceString.length == 0) {
        NSLog(@"Failed to load fragment shader string");
        return NO;
    }
    sString = (GLchar *)[shaderSourceString UTF8String];
    self.fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(self.fragmentShader, 1, &sString, NULL);
    glCompileShader(self.fragmentShader);
    
    logLength = 0;
    glGetShaderiv(self.fragmentShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = malloc(sizeof(GLchar)*logLength);
        glGetShaderInfoLog(self.fragmentShader, logLength, &logLength, log);
        NSString *logString = [NSString stringWithCString:log encoding:NSUTF8StringEncoding];
        NSLog(@"Fragment shader compile log:\n%@", logString);
        free(log);
    }

    glGetShaderiv(self.fragmentShader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(self.fragmentShader);
        self.fragmentShader = 0;
        return NO;
    }
    
    return YES;
}
/*! Linking the shaders
 @discussion At this point the compiled shaders will be attached to the program and linked together to create a usable unit.
 */
- (BOOL)linkShader
{
    glAttachShader(self.shaderProgram, self.vertexShader); // attach vertex shader
    glAttachShader(self.shaderProgram, self.fragmentShader); // attach fragment shader
    
    GLint status;
    glLinkProgram(self.shaderProgram); // link all together

    /*
     Check log
     */
    GLint logLength = 0;
    glGetProgramiv(self.shaderProgram, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = malloc(sizeof(GLchar)*logLength);
        glGetProgramInfoLog(self.shaderProgram, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
    /*
     Check status
     */
    glGetProgramiv(self.shaderProgram, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    /*
     At this point we have a program on the GPU which can be run on the GPU.
     */
    
    return YES;
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
    [self drawShape]; // draw some shape
    [self presetnRenderbuffer]; // show the current buffer on screen
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

- (void)presetnRenderbuffer
{
    [self.context presentRenderbuffer:self.renderBuffer]; // will present the buffer on the screen
    [GlobalTools checkError]; // check for possible errors
}

/*! Draw some test shape
 */
- (void)drawShape
{
    /*
     We need to specify what program shoul the GPU run for the drawing
     */
    glUseProgram(self.shaderProgram);
    
    /*
     To access the values in the shader we will need to search them by string in the source code.
     There are 2 different types:
     - Attributes: These are values that are applied for every vertex such as position
     - Uniforms: These are values that are applied for every draw call such as color
     
     So in this case we have a triangle with 3 vertices. Each has a different position but all have the same color. Ergo a position is an attribute and the color is an uniform
     */
    int positionAttribute = glGetAttribLocation(self.shaderProgram, "attPosition"); // get attribute position
    glEnableVertexAttribArray(positionAttribute); // every attribute must be explicitly enabled (can be done only once to gain performance)
    
    /*
     Just generate some position data.
     We will use 3 dimensions but could easily use 2 for this case.
     
     Note that the default coordinate system is in range [-1, 1] for all axises. That means (0,0,0) is in the center of the screen.
     Top = 1, bottom = -1, left = -1, right = 1
     */
    GLfloat vertexData[3][3] = {
        .0f, .0f, .0f,
        .0f, 1.0f, .0f,
        1.0f, .0f, .0f
    };
    
    /*
     Tha data pointer must be set to the GPU for where the positions are stored and what kind of data it should expect.
     These data must persist until the draw call is completed so if the draw call is in another method they should be stored as a property for NSData object for instance.
     */
    glVertexAttribPointer(positionAttribute, // a previously gotten index for the position in the shader
                          3, // number of dimensions
                          GL_FLOAT, // what type of data are we having (GLfloat)
                          GL_FALSE, // normalization is usefull for normals, never for positions
                          0, // zero means tightly packed (one vertex after another) otherwise number of bytes between the 2 vertex data which in this case would be 3*sizof(GLfloat)
                          vertexData // the data pointer
                          );
    
    /*
     Set some color.
     Will get the location of the color uniform and set the RGBA values for it
     */
    glUniform4f(glGetUniformLocation(self.shaderProgram, "uniformColor"), .0f, .2f, .4f, 1.0f);
    
    /*
     The actual drawing
     We need to specify what shape we are drawing. This could be triangles, lines, points...
     We need to specify the starting position index (0 is first)
     We need to specify the number of vertices we will be drawing
     */
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    [GlobalTools checkError]; // check for possible errors
    
    
    /*
     Now try a line that is animated
     */
    static CGFloat angle = .0f;
    CGFloat radius = .5f;
    angle += .01f; // will increase each frame
    GLfloat linePositions[2][2] = {
        .0f, .0f,
        sinf(angle)*radius, cosf(angle)*radius
    };
    glLineWidth(12.0f); // meed to set some line width
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, linePositions);
    glUniform4f(glGetUniformLocation(self.shaderProgram, "uniformColor"), 1.0f, .0f, .0f, 1.0f);
    glDrawArrays(GL_LINE_STRIP, 0, 2);
}

@end
