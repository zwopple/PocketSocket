//
//  PSWebSocketStatusCodes.h
//  PocketSocket
//
//  Created by Robert Payne on 19/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PSWebSocketStatusCode) {
    PSWebSocketStatusCodeNormal = 1000,
    PSWebSocketStatusCodeGoingAway = 1001,
    PSWebSocketStatusCodeProtocolError = 1002,
    PSWebSocketStatusCodeUnhandledType = 1003,
    // 1004 reserved
    PSWebSocketStatusCodeNoStatusReceived = 1005,
    // 1006 reserved
    PSWebSocketStatusCodeInvalidUTF8 = 1007,
    PSWebSocketStatusCodePolicyViolated = 1008,
    PSWebSocketStatusCodeMessageTooBig = 1009
};