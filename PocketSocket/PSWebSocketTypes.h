//
//  PSWebSocketTypes.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, PSWebSocketOpCode) {
    PSWebSocketOpCodeContinuation = 0x0,
    PSWebSocketOpCodeText = 0x1,
    PSWebSocketOpCodeBinary = 0x2,
    // 0x3 -> 0x7 reserved
    PSWebSocketOpCodeClose = 0x8,
    PSWebSocketOpCodePing = 0x9,
    PSWebSocketOpCodePong = 0xA,
    // 0xB -> 0xF reserved
};

typedef NS_ENUM(NSInteger, PSWebSocketMode) {
    PSWebSocketModeClient = 0,
    PSWebSocketModeServer
};

static const uint8_t PSWebSocketFinMask = 0x80;
static const uint8_t PSWebSocketOpCodeMask = 0x0F;
static const uint8_t PSWebSocketRsv1Mask = 0x40;
static const uint8_t PSWebSocketRsv2Mask = 0x20;
static const uint8_t PSWebSocketRsv3Mask = 0x10;
static const uint8_t PSWebSocketMaskMask = 0x80;
static const uint8_t PSWebSocketPayloadLenMask = 0x7F;

#define PSWebSocketGUID @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
#define PSWebSocketErrorDomain @"PSWebSocketErrorDomain"
