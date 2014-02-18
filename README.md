PocketSocket
============

Objective-C websocket library for building things that work in realtime on iOS and OS X.

### Features

* Conforms fully to [RFC6455](http://tools.ietf.org/html/rfc6455) websocket protocol
* Support for websocket compression via the [permessage-deflate](http://tools.ietf.org/html/draft-ietf-hybi-permessage-compression-17) extension
* Passes all [Autobahn.ws](http://autobahn.ws) tests
* Client & Server modes (see notes below)
* TLS/SSL support
* Decoupled library for easily using pieces of it with existing networking libraries

### Dependencies

* CFNetworking.framework
* Foundation.framework
* Security.framework
* CommonCrypto.framework (iOS)
* System.framework (OS X)
* libz.dylib

### Installing

Installing is best done via cocoapods. Add `pod 'PocketSocket'` to your Podfile and run `pod install`.

### Client API

####`PSWebSocket`

Every `PSWebSocket` instance must be created with an `NSURLRequest`. In client mode this NSURLRequest is sent along to make the intial handshake with the server. You can include extra headers in addition to the `Sec-WebSocket-Protocol`. All other `Sec-WebSocket-*` headers will not be copied.

Once created one must call `open` which will initiate the connection to the server. From that point forward delegate methods will update you on the status and communication of the websocket.

##### Example

```objc
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://<path to server>"]];
PSWebSocket *socket = [PSWebSocket clientSocketWithRequest:request];
socket.delegate = self;
[socket open];
```

##### Gotchas

* PSWebSocket does not ever retain itself, you must keep a strong reference to it while the connection is open
* PSWebSocket will always enable compression if the server supports it
* PSWebSocket will timeout the open call based on the timeout interval set on the NSURLRequest

### Server API

The server API is in works, currently one can use the lower level driver API to deal with the protocol level framing and decoding.

### Driver API

###`PSWebSocketDriver`

A `PSWebSocketDriver` instance is responsible for serializing and deserializing the websocket protocol and negotiated extensions. It is a standalone class that works regardless of the network IO used with it.


### Authors

* Robert Payne

### License

TBD
