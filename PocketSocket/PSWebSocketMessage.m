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
