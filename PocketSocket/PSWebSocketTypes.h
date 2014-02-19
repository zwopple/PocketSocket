//  Copyright 2014 Zwopple Limited
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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
