PocketSocket
============

Objective-C websocket library for building things that work in realtime on iOS and OS X.

### Features

* Conforms fully to [RFC6455](http://tools.ietf.org/html/rfc6455) websocket protocol
* Support for websocket compression via the [permessage-deflate](http://tools.ietf.org/html/draft-ietf-hybi-permessage-compression-17) extension
* Passes all [Autobahn.ws](http://autobahn.ws) tests
* Client & Server modes (see notes below)
* TLS/SSL support
* Standalone `PSWebSocketDriver` for easy BYO networking IO

### Dependencies

* CFNetworking.framework
* Foundation.framework
* Security.framework
* CommonCrypto.framework (iOS)
* System.framework (OS X)
* libz.dylib

### Cocoapods Installation 

Add `pod 'PocketSocket'` to your Podfile and run `pod install`.

####`Using the PSWebSocket as a client`

The client supports both the `ws` and secure `wss` protocols. It will automatically negotiate the certificates for you from the certificate chain on the device it’s running and support for pinned certificates is planned.

```objc
#import <PSWebSocket/PSWebSocket.h>

@interface AppDelegate() <PSWebSocketDelegate>

@property (nonatomic, strong) PSWebSocket *socket;

@end
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // create the NSURLRequest that will be sent as the handshake
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"wss://example.com"]];
    
    // create the socket and assign delegate
    self.socket = [PSWebSocket clientSocketWithRequest:request];
    self.socket.delegate = self;
    
    // open socket
    [self.socket open];
    
    return YES;
}

#pragma mark - PSWebSocketDelegate

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
    NSLog(@"The websocket handshake completed and is now open!");
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"The websocket received a message: %@", message);
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"The websocket handshake/connection failed with an error: %@", error);
}
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"The websocket closed with code: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO");
}

@end

```

##### Gotchas

* PSWebSocket does not ever retain itself, you must keep a strong reference to it
* PSWebSocket will always enable compression if the server supports it
* PSWebSocket will timeout the open call based on the timeout interval set on the NSURLRequest

### Server API

The server API is in works, currently one can use the lower level driver API to deal with the protocol level framing and decoding.

### Driver API

###`PSWebSocketDriver`

An instance of `PSWebSocketDriver` is used to drive the entirety of any websocket connection. It deals with parsing incoming raw bytes and then writing back out appropriate bytes for responses. The driver has a limited set of commands:

* `start` - starts the driver and will deal with the handshaking
* `sendText:` - sends a text message
* `sendBinary:` - sends a binary message
* `sendCloseCode:reason:` - sends close message with code and optional reason
* `sendPing:` - sends a ping message with optional data
* `sendPong:` - sends a pong message with optional data
* `execute:maxLength` - have the driver execute on a raw byte stream, it will return the length of bytes it consumed

##### Client Mode


##### Server Mode


### Authors

* Robert Payne

### License

TBD
