//
//  PSWebSocketMacros.h
//  PocketSocket
//
//  Created by Robert Payne on 18/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import "PSWebSocketTypes.h"

#define PSWebSocketSetOutError(e, c, d) if(e){ *e = [NSError errorWithDomain:PSWebSocketErrorDomain code:c userInfo:@{NSLocalizedDescriptionKey: d}]; }

static inline void _PSWebSocketLog(id self, NSString *format, ...) {
    __block va_list arg_list;
    va_start (arg_list, format);
    
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    
    va_end(arg_list);
    
    NSLog(@"[%@]: %@", self, formattedString);
}
#define PSWebSocketLog(...) _PSWebSocketLog(self, __VA_ARGS__)

static inline BOOL PSWebSocketOpCodeIsControl(PSWebSocketOpCode opcode) {
    return (opcode == PSWebSocketOpCodeClose ||
            opcode == PSWebSocketOpCodePing ||
            opcode == PSWebSocketOpCodePong);
};

static inline BOOL PSWebSocketOpCodeIsValid(PSWebSocketOpCode opcode) {
    return (opcode == PSWebSocketOpCodeClose ||
            opcode == PSWebSocketOpCodePing ||
            opcode == PSWebSocketOpCodePong ||
            opcode == PSWebSocketOpCodeText ||
            opcode == PSWebSocketOpCodeBinary ||
            opcode == PSWebSocketOpCodeContinuation);
};


static inline BOOL PSWebSocketCloseCodeIsValid(NSInteger closeCode) {
    if(closeCode < 1000) {
        return NO;
    }
    if(closeCode >= 1000 && closeCode <= 1011) {
        if(closeCode == 1004 ||
           closeCode == 1005 ||
           closeCode == 1006) {
            return NO;
        }
        return YES;
    }
    if(closeCode >= 3000 && closeCode <= 3999) {
        return YES;
    }
    if(closeCode >= 4000 && closeCode <= 4999) {
        return YES;
    }
    return NO;
}