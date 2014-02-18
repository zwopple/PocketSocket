//
//  PSAutobahnClientTestOperation.m
//  PocketSocket
//
//  Created by Robert Payne on 19/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import "PSAutobahnClientWebSocketOperation.h"
#import "PSWebSocket.h"

@interface PSAutobahnClientWebSocketOperation() <PSWebSocketDelegate>

@property (strong) PSWebSocket *webSocket;
@property (assign) BOOL isFinished;
@property (assign) BOOL isExecuting;

@end
@implementation PSAutobahnClientWebSocketOperation

#pragma mark - Class Properties

+ (BOOL)automaticallyNotifiesObserversOfIsExecuting {
    return NO;
}
+ (BOOL)automaticallyNotifiesObserversOfIsFinished {
    return NO;
}

#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)URL {
    if((self = [super init])) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        _webSocket = [PSWebSocket clientSocketWithRequest:request];
        _webSocket.delegate = self;
        _webSocket.delegateQueue = dispatch_queue_create(nil, nil);
        _isExecuting = NO;
        _isFinished = NO;
    }
    return self;
}

#pragma mark - NSOperation

- (BOOL)isConcurrent {
    return YES;
}
- (void)start {
    self.isExecuting = YES;
    [_webSocket open];
}

#pragma mark - PSWebSocketDelegate

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
//    NSLog(@"webSocketDidOpen:");
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
//    NSLog(@"webSocket: didReceiveMessage: %@", message);
    if(self.echo) {
        [webSocket send:message];
    } else {
        self.message = message;
    }
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
//    NSLog(@"webSocket: didFailWithError: %@", error);
    self.error = error;
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.isFinished = YES;
    self.isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
}
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
//    NSLog(@"webSocket: didCloseWithCode: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO");
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.isFinished = YES;
    self.isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
}

@end
