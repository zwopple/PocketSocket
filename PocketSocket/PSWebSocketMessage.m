//
//  PSWebSocketMessage.m
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import "PSWebSocketMessage.h"

const NSString *PSWebSocketMessageInfoDataKey = @"data";
const NSString *PSWebSocketMessageInfoTextKey = @"text";
const NSString *PSWebSocketMessageInfoCloseCodeKey = @"closeCode";
const NSString *PSWebSocketMessageInfoCloseReasonKey = @"closeReason";

@implementation PSWebSocketMessage

- (instancetype)initWithOpCode:(PSWebSocketOpCode)opcode info:(NSDictionary *)info {
    if((self = [super init])) {
        _opcode = opcode;
        _info = info;
    }
    return self;
}

@end
