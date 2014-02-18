//
//  PSWebSocketInflater.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSWebSocketInflater : NSObject

#pragma mark - Initialization

- (instancetype)initWithWindowBits:(NSInteger)windowBits;

#pragma mark - Actions

- (BOOL)begin:(NSMutableData *)buffer error:(NSError *__autoreleasing *)outError;
- (BOOL)appendBytes:(const void *)bytes length:(NSUInteger)length error:(NSError *__autoreleasing *)outError;
- (BOOL)end:(NSError *__autoreleasing *)outError;
- (void)reset;

@end
