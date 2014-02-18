//
//  PSWebSocketDeflater.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSWebSocketDeflater : NSObject

#pragma mark - Initialization

- (instancetype)initWithWindowBits:(NSInteger)windowBits memoryLevel:(NSUInteger)memoryLevel;

#pragma mark - Actions

- (BOOL)begin:(NSMutableData *)buffer error:(NSError *__autoreleasing *)outError;
- (BOOL)appendBytes:(const void *)bytes length:(NSUInteger)length error:(NSError *__autoreleasing *)outError;
- (BOOL)end:(NSError *__autoreleasing *)outError;
- (void)reset;

@end
