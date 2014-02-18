//
//  PSWebSocketNetworkThread.m
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import "PSWebSocketNetworkThread.h"

@interface PSWebSocketNetworkThread() {
    dispatch_group_t _waitGroup;
}

@property (nonatomic, strong) NSRunLoop *runLoop;

@end
@implementation PSWebSocketNetworkThread

#pragma mark - Singleton

+ (instancetype)sharedNetworkThread {
	static id sharedNetworkThread = nil;
	static dispatch_once_t sharedNetworkThreadOnce = 0;
	dispatch_once(&sharedNetworkThreadOnce, ^{
		sharedNetworkThread = [[self alloc] init];
	});
	return sharedNetworkThread;
}

#pragma mark - Properties

- (NSRunLoop *)runLoop {
    dispatch_group_wait(_waitGroup, DISPATCH_TIME_FOREVER);
    return _runLoop;
}

#pragma mark - Initialization

- (instancetype)init {
	if((self = [super init])) {
		_waitGroup = dispatch_group_create();
        dispatch_group_enter(_waitGroup);
        
        self.name = @"com.zwopple.PSWebSocket.NetworkThread";
        [self start];
	}
	return self;
}
- (void)main {
    @autoreleasepool {
        _runLoop = [NSRunLoop currentRunLoop];
        dispatch_group_leave(_waitGroup);
        
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:0.0 target:nil selector:nil userInfo:nil repeats:NO];
        [_runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        
        while([_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            // no-op
        }
        
        NSAssert(NO, @"PSWebSocketNetworkThread should never exit.");
    }
}


@end
