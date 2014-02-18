//
//  PSWebSocketMessage.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSWebSocketTypes.h"

extern const NSString *PSWebSocketMessageInfoDataKey;
extern const NSString *PSWebSocketMessageInfoTextKey;
extern const NSString *PSWebSocketMessageInfoCloseCodeKey;
extern const NSString *PSWebSocketMessageInfoCloseReasonKey;

@interface PSWebSocketMessage : NSObject

#pragma mark - Properties

@property (nonatomic, assign, readonly) PSWebSocketOpCode opcode;
@property (nonatomic, strong, readonly) NSDictionary *info;

#pragma mark - Initialization

- (instancetype)initWithOpCode:(PSWebSocketOpCode)opcode info:(NSDictionary *)info;

@end
