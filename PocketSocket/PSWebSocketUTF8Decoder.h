//
//  PSWebSocketUTF8Decoder.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PSWebSocketUTF8DecoderAccept 0
#define PSWebSocketUTF8DecoderReject 1

uint32_t PSWebSocketUTF8DecoderDecode(uint32_t* state, uint32_t* codep, uint32_t byte);