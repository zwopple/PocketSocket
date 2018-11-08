//  Copyright 2014-Present Zwopple Limited
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

#import <XCTest/XCTest.h>

#import "PSWebSocket.h"
#import "PSWebSocketServer.h"

@interface FakeServerDelegate : NSObject <PSWebSocketServerDelegate> @end
@implementation FakeServerDelegate

- (void)server:(PSWebSocketServer *)server didFailWithError:(NSError *)error { }
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean { }
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error { }
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message { }
- (void)server:(PSWebSocketServer *)server webSocketDidOpen:(PSWebSocket *)webSocket { }
- (void)serverDidStart:(PSWebSocketServer *)server { }
- (void)serverDidStop:(PSWebSocketServer *)server { }

@end

@interface FakeServerDelegateWithFlushOutput : FakeServerDelegate @end
@implementation FakeServerDelegateWithFlushOutput

- (void)server:(PSWebSocketServer *)server webSocketDidFlushOutput:(PSWebSocket *)webSocket {}

@end

// opening the class for testing
@interface PSWebSocketServer() <PSWebSocketDelegate> @end

@interface PSWebSocketServerTests: XCTestCase @end
@implementation PSWebSocketServerTests

- (void)testChangingDelegateWhileFlushingOutputShouldNotCrashWithUnrecognizedSelector {
    FakeServerDelegateWithFlushOutput *delegateWithFlushOutput = [FakeServerDelegateWithFlushOutput new];
    FakeServerDelegate *delegate = [FakeServerDelegate new];

    PSWebSocketServer *sut = [PSWebSocketServer serverWithHost:@"" port:9999];
    sut.delegate = delegateWithFlushOutput;
    sut.delegateQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);

    PSWebSocket *socket = [PSWebSocket clientSocketWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://127.1/"]]];

    for (uint16_t i = 0; i < 5000; ++i) {
        sut.delegate = delegateWithFlushOutput;
        [sut webSocketDidFlushOutput:socket];
        sut.delegate = delegate;
    }
}

@end
