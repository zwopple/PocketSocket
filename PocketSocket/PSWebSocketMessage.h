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
