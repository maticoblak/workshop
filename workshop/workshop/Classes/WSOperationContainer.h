//
//  WSOperationContainer.h
//  workshop
//
//  Created by Gasper on 03/07/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WSOperationContainer : NSObject

@property (nonatomic, strong) void (^block)();
@property (nonatomic, strong) void (^callbackBlock)();

@end
