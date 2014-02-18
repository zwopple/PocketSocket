//
//  PSWebSocketErrorCodes.h
//  PocketSocket
//
//  Created by Robert Payne on 19/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PSWebSocketErrorCodes) {
    PSWebSocketErrorCodeUnknown = 0,
    PSWebSocketErrorCodeTimedOut,
    PSWebSocketErrorCodeHandshakeFailed,
    PSWebSocketErrorCodeConnectionFailed
};
