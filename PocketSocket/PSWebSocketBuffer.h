//
//  PSWebSocketBuffer.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSWebSocketBuffer : NSObject

#pragma mark - Properties

@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSUInteger compactionLength;

#pragma mark - Actions

- (BOOL)hasBytesAvailable;
- (NSUInteger)bytesAvailable;
- (void)appendData:(NSData *)data;
- (void)appendBytes:(const void *)bytes length:(NSUInteger)length;
- (void)compact;
- (void)reset;
- (const void *)bytes;
- (void *)mutableBytes;
- (NSData *)data;

@end
