//
//  PSWebSocketDriver.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSWebSocketTypes.h"
#import "PSWebSocketMessage.h"

@class PSWebSocketDriver;

@protocol PSWebSocketDriverDelegate <NSObject>

@required

- (void)driverDidOpen:(PSWebSocketDriver *)driver;
- (void)driver:(PSWebSocketDriver *)driver didReceiveMessage:(id)message;
- (void)driver:(PSWebSocketDriver *)driver didReceivePing:(NSData *)ping;
- (void)driver:(PSWebSocketDriver *)driver didReceivePong:(NSData *)pong;
- (void)driver:(PSWebSocketDriver *)driver didFailWithError:(NSError *)error;
- (void)driver:(PSWebSocketDriver *)driver didCloseWithCode:(NSInteger)code reason:(NSString *)reason;
- (void)driver:(PSWebSocketDriver *)driver write:(NSData *)data;

@end
@interface PSWebSocketDriver : NSObject

#pragma mark - Class Methods

+ (BOOL)isWebSocketRequest:(NSURLRequest *)request;

#pragma mark - Properties

@property (nonatomic, assign, readonly) PSWebSocketMode mode;
@property (nonatomic, weak) id <PSWebSocketDriverDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *protocol;

#pragma mark - Initialization

+ (instancetype)clientDriverWithRequest:(NSURLRequest *)request;
+ (instancetype)serverDriverWithRequest:(NSURLRequest *)request;

#pragma mark - Actions

- (void)start;
- (void)sendText:(NSString *)text;
- (void)sendBinary:(NSData *)binary;
- (void)sendCloseCode:(NSInteger)code reason:(NSString *)reason;
- (void)sendPing:(NSData *)data;
- (void)sendPong:(NSData *)data;

- (NSUInteger)execute:(void *)bytes maxLength:(NSUInteger)maxLength;

@end
