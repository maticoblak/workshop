//
//  BaseShader.h
//  workshop
//
//  Created by Crt Gregoric on 3. 07. 15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLKit;
@class OpenGLES;

@interface BaseShader : NSObject

- (instancetype)initWithContext:(EAGLContext *)context;
- (BOOL)loadShaderSourceNamed:(NSString *)sourceName;
- (void)use;
- (void)setVertexPositionsPointer:(GLfloat *)vertexPositionsPointer withDimension:(GLfloat)dimension stride:(GLsizei)stride;
- (void)setColor:(UIColor *)color;

@end
