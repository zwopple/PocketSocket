//
//  PSWebSocket.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSWebSocketErrorCodes.h"
#import "PSWebSocketStatusCodes.h"

typedef NS_ENUM(NSInteger, PSWebSocketReadyState) {
    PSWebSocketReadyStateConnecting = 0,
    PSWebSocketReadyStateOpen,
    PSWebSocketReadyStateClosing,
    PSWebSocketReadyStateClosed
};

@class PSWebSocket;

@protocol PSWebSocketDelegate <NSObject>

@required
- (void)webSocketDidOpen:(PSWebSocket *)webSocket;
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end

@interface PSWebSocket : NSObject

#pragma mark - Properties

@property (nonatomic, assign, readonly) PSWebSocketReadyState readyState;
@property (nonatomic, weak) id <PSWebSocketDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

#pragma mark - Initialization

+ (instancetype)clientSocketWithRequest:(NSURLRequest *)request;

#pragma mark - Actions

- (void)open;
- (void)send:(id)message;
- (void)ping:(NSData *)pingData handler:(void (^)(NSData *pongData))handler;
- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

@end
