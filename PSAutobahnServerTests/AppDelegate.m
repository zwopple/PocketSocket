//
//  AppDelegate.m
//  PSAutobahnServerTests
//
//  Created by Robert Payne on 31/03/16.
//  Copyright © 2016 Zwopple Limited. All rights reserved.
//

#import "AppDelegate.h"
#import "PSWebSocketServer.h"

@interface AppDelegate () <PSWebSocketServerDelegate>

@property(nonatomic, strong) PSWebSocketServer *server;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  // Create a local server at a random available port
  self.server = [PSWebSocketServer localServer];
  self.server.delegate = self;
  [self.server start];

  return YES;
}

#pragma mark - PSWebSocketServerDelegate

- (void)serverDidStart:(PSWebSocketServer *)server {
  NSLog(@"WebSockets Server started at port %zd", server.port);
}
- (void)server:(PSWebSocketServer *)server didFailWithError:(NSError *)error {
  [NSException raise:NSInternalInconsistencyException
              format:@"didFailWithError: %@", error.localizedDescription];
}
- (void)serverDidStop:(PSWebSocketServer *)server {
  [NSException raise:NSInternalInconsistencyException
              format:@"Server stopped unexpected."];
}

- (void)server:(PSWebSocketServer *)server
    webSocketDidOpen:(PSWebSocket *)webSocket {
}
- (void)server:(PSWebSocketServer *)server
            webSocket:(PSWebSocket *)webSocket
    didReceiveMessage:(id)message {
  [webSocket send:message];
}
- (void)server:(PSWebSocketServer *)server
           webSocket:(PSWebSocket *)webSocket
    didFailWithError:(NSError *)error {
}
- (void)server:(PSWebSocketServer *)server
           webSocket:(PSWebSocket *)webSocket
    didCloseWithCode:(NSInteger)code
              reason:(NSString *)reason
            wasClean:(BOOL)wasClean {
}

@end
