//
//  GlobalTools.m
//  workshop
//
//  Created by Matic Oblak on 6/30/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import "GlobalTools.h"

@import OpenGLES;

@implementation GlobalTools
+ (void)checkError
{
    GLenum result = glGetError();
    if(result)
    {
        switch (result)
        {
            case GL_NO_ERROR:
                NSLog(@"(OpenGL) Error occured: %d (%@)", result, @"GL_NO_ERROR");
                break;
            case GL_INVALID_ENUM:
                NSLog(@"(OpenGL) Error occured: %d (%@)", result, @"GL_INVALID_ENUM");
                break;
            case GL_INVALID_VALUE:
                NSLog(@"(OpenGL) Error occured: %d (%@)", result, @"GL_INVALID_VALUE");
                break;
            case GL_INVALID_OPERATION:
                NSLog(@"(OpenGL) Error occured: %d (%@)", result, @"GL_INVALID_OPERATION");
                break;
            case GL_OUT_OF_MEMORY:
                NSLog(@"(OpenGL) Error occured: %d (%@)", result, @"GL_OUT_OF_MEMORY");
                break;
            default:
                NSLog(@"(OpenGL) Error occured: %d (unknown)", result);
                break;
        }
    }
}
+ (BOOL)framebufferStatusValid
{
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Error creating framebuffer (error %d)", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    else
    {
        return YES;
    }
}
@end
