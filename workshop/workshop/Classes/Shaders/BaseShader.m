//
//  BaseShader.m
//  workshop
//
//  Created by Crt Gregoric on 3. 07. 15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

@import GLKit;
@import OpenGLES;

#import "WSContext.h"
#import "BaseShader.h"

typedef enum : NSUInteger {
    shaderAttributePosition,
    shaderAttributeCount
} shaderAttributes;

typedef enum : NSUInteger {
    shaderUniformColor,
    shaderUniformCount
} shaderUnitorms;


@interface BaseShader () {
    GLint shaderAttributeIds[shaderAttributeCount];
    GLint shaderUniformIds[shaderUniformCount];
}

@property (nonatomic, strong) WSContext *context;

@property (nonatomic, strong) NSString *shaderSourceName;

@property (nonatomic) GLuint shaderProgram;
@property (nonatomic) GLuint fragmentShader;
@property (nonatomic) GLuint vertexShader;

@property (nonatomic) GLint positionAttribute;

@end

@implementation BaseShader

- (NSString *)stringForAtrtibuteID:(shaderAttributes)name
{
    switch (name) {
        case shaderAttributePosition:
            return @"attributePostion";
            break;
            
        default:
            break;
    }
    return  nil;
}

- (NSString *)stringForUniformID:(shaderUnitorms)name
{
    switch (name) {
        case shaderUniformColor:
            return @"uniformColor";
            break;
            
        default:
            break;
    }
    return  nil;
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

- (instancetype)init
{
    if((self = [super init]))
    {
        for (NSInteger i=0; i<shaderAttributeCount; i++)
        {
            shaderAttributeIds[i] = 0;
        }
        for (NSInteger i=0; i<shaderUniformCount; i++)
        {
            shaderUniformIds[i] = 0;
        }
    }
    return self;
}

- (instancetype)initWithContext:(WSContext *)context
{
    self = [self init];
    
    if (self)
    {
        self.context = context;
    }
    
    return self;
}

- (void)dealloc
{
    GLuint vertexShader = self.vertexShader;
    GLuint fragmentShader = self.fragmentShader;
    GLuint shaderProgram = self.shaderProgram;
    [self.context performBlock:^{
        if (vertexShader)
        {
            glDeleteShader(vertexShader);
        }
        
        if (fragmentShader)
        {
            glDeleteShader(fragmentShader);
        }
        
        if (shaderProgram)
        {
            glDeleteProgram(shaderProgram);
        }
    }];
    
}

- (BOOL)loadShaderSourceNamed:(NSString *)sourceName
{
    self.shaderSourceName = sourceName;
    
    [self compileShader];
    [self linkShader];
    
    [self linkAttributesAndUniforms];
    
    return YES;
}

- (void)linkAttributesAndUniforms
{
    for (NSInteger i=0; i<shaderAttributeCount; i++)
    {
        shaderAttributeIds[i] = glGetAttribLocation(self.shaderProgram, [[self stringForAtrtibuteID:i] UTF8String]);
    }
    for (NSInteger i=0; i<shaderUniformCount; i++)
    {
        shaderUniformIds[i] = glGetUniformLocation(self.shaderProgram, [[self stringForAtrtibuteID:i] UTF8String]);
    }
}

- (BOOL)compileShader
{
    NSString *vshSourceName = [NSString stringWithFormat:@"%@.vsh", self.shaderSourceName];
    NSString *fshSourceName = [NSString stringWithFormat:@"%@.fsh", self.shaderSourceName];
    
    NSString *vertexShaderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:vshSourceName];
    NSString *fragmentShaderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fshSourceName];
    
    GLint status;
    NSString *shaderSourceString = nil;
    
    // vertex shader
    shaderSourceString = [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil]; // get string from file
    
    if (!shaderSourceString || shaderSourceString.length == 0) {
        NSLog(@"Failed to load fragment shader string");
        return NO;
    }
    
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

- (void)use
{
    glUseProgram(self.shaderProgram);
}

- (void)setVertexPositionsPointer:(GLfloat *)vertexPositionsPointer withDimension:(GLfloat)dimension stride:(GLsizei)stride
{
    glEnableVertexAttribArray(shaderAttributeIds[shaderAttributePosition]);
    
    glVertexAttribPointer(shaderAttributeIds[shaderAttributePosition], // a previously gotten index for the position in the shader
                          dimension, // number of dimensions
                          GL_FLOAT, // what type of data are we having (GLfloat)
                          GL_FALSE, // normalization is usefull for normals, never for positions
                          stride, // zero means tightly packed (one vertex after another) otherwise number of bytes between the 2 vertex data which in this case would be 3*sizof(GLfloat)
                          vertexPositionsPointer // the data pointer
                          );
}

- (void)setColor:(UIColor *)color
{
    CGFloat colorComponents[4];
    [color getRed:colorComponents green:colorComponents+1 blue:colorComponents+2 alpha:colorComponents+3];
    glUniform4f(glGetUniformLocation(self.shaderProgram, "uniformColor"), colorComponents[0], colorComponents[1], colorComponents[2], colorComponents[3]);
}

@end
