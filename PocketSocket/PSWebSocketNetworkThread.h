//
//  PSWebSocketNetworkThread.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSWebSocketNetworkThread : NSThread

#pragma mark - Singleton

+ (instancetype)sharedNetworkThread;

#pragma mark - Properties

@property (nonatomic, strong, readonly) NSRunLoop *runLoop;

@end
