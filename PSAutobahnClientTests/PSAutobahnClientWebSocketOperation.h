//
//  PSAutobahnClientTestOperation.h
//  PocketSocket
//
//  Created by Robert Payne on 19/02/14.
//  Copyright (c) 2014 Zwopple Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSWebSocket.h"

@interface PSAutobahnClientWebSocketOperation : NSOperation <PSWebSocketDelegate>

@property (strong) NSError *error;
@property (strong) id message;
@property (assign) BOOL echo;

- (instancetype)initWithURL:(NSURL *)URL;

@end
