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

#import "PSWebSocketBuffer.h"
#import "PSWebSocketDriver.h"
#import "PSWebSocketInternal.h"
#import "PSWebSocketNetworkThread.h"
#import "PSWebSocketServer.h"
#import "PSwebSocket.h"
#import <CFNetwork/CFNetwork.h>
#import <Security/SecureTransport.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netdb.h>
#import <netinet/in.h>

typedef NS_ENUM(NSInteger, PSWebSocketServerConnectionReadyState) {
  PSWebSocketServerConnectionReadyStateConnecting = 0,
  PSWebSocketServerConnectionReadyStateOpen,
  PSWebSocketServerConnectionReadyStateClosing,
  PSWebSocketServerConnectionReadyStateClosed
};

@interface PSWebSocketServerConnection : NSObject

@property(nonatomic, strong, readonly) NSString *identifier;
@property(nonatomic, assign) PSWebSocketServerConnectionReadyState readyState;
@property(nonatomic, strong) NSInputStream *inputStream;
@property(nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, assign) BOOL inputStreamOpenCompleted;
@property(nonatomic, assign) BOOL outputStreamOpenCompleted;
@property(nonatomic, strong) PSWebSocketBuffer *inputBuffer;
@property(nonatomic, strong) PSWebSocketBuffer *outputBuffer;

@end
@implementation PSWebSocketServerConnection

- (instancetype)init {
  if ((self = [super init])) {
    _identifier = [[NSProcessInfo processInfo] globallyUniqueString];
    _readyState = PSWebSocketServerConnectionReadyStateConnecting;
    _inputBuffer = [[PSWebSocketBuffer alloc] init];
    _outputBuffer = [[PSWebSocketBuffer alloc] init];
  }
  return self;
}

@end

void PSWebSocketServerAcceptCallback(CFSocketRef s, CFSocketCallBackType type,
                                     CFDataRef address, const void *data,
                                     void *info);

@interface PSWebSocketServer () <NSStreamDelegate, PSWebSocketDelegate>
@property(nonatomic) dispatch_queue_t workQueue;
@property(nonatomic) NSData *addrData;
@property(nonatomic) CFSocketContext socketContext;
@property(nonatomic) NSArray *SSLCertificates;

@property(nonatomic) BOOL running;
@property(nonatomic) BOOL secure;
@property(nonatomic) CFSocketRef socket;
@property(nonatomic) CFRunLoopSourceRef socketRunLoopSource;

@property(nonatomic) NSMutableSet *connections;
@property(nonatomic) NSMapTable *connectionsByStreams;

@property(nonatomic) NSMutableSet *webSockets;

@property(nonatomic) NSInteger port;
@end

@implementation PSWebSocketServer

#pragma mark - Properties

- (NSRunLoop *)runLoop {
  return [[PSWebSocketNetworkThread sharedNetworkThread] runLoop];
}

#pragma mark - Initialization
+ (instancetype)localServer {
  return [self.class serverWithHost:@"127.0.0.1" port:0];
}

+ (instancetype)serverWithHost:(NSString *)host port:(NSInteger)port {
  return [[self alloc] initWithHost:host port:port SSLCertificates:nil];
}

+ (instancetype)serverWithHost:(NSString *)host
                          port:(NSInteger)port
               SSLCertificates:(NSArray *)SSLCertificates {
  return [[self alloc] initWithHost:host
                               port:port
                    SSLCertificates:SSLCertificates];
}
- (instancetype)initWithHost:(NSString *)host
                        port:(NSInteger)port
             SSLCertificates:(NSArray *)SSLCertificates {
  if ((self = [super init])) {
    _workQueue = dispatch_queue_create(nil, nil);

    // copy SSL certificates
    _SSLCertificates = [SSLCertificates copy];
    _secure = (_SSLCertificates != nil);
    _port = port;
    // create addr data
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    if (host && host.length && ![host isEqualToString:@"0.0.0.0"]) {
      addr.sin_addr.s_addr = inet_addr(host.UTF8String);
      if (!addr.sin_addr.s_addr) {
        [NSException
             raise:@"Invalid host"
            format:@"Could not formulate internet address from host: %@", host];
        return nil;
      }
    } else {
      addr.sin_addr.s_addr = htonl(INADDR_ANY);
    }
    addr.sin_port = htons(port);
    _addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];

    // create socket context
    _socketContext =
        (CFSocketContext){0, (__bridge void *)self, NULL, NULL, NULL};

    _connections = [NSMutableSet set];
    _connectionsByStreams = [NSMapTable weakToWeakObjectsMapTable];

    _webSockets = [NSMutableSet set];
  }
  return self;
}

#pragma mark - Actions

- (void)start {
  __weak typeof(self) wself = self;
  [self executeWork:^{
    __strong typeof(self) sself = wself;
    [sself connect:NO];
  }];
}
- (void)stop {
  __weak typeof(self) wself = self;
  [self executeWork:^{
    __strong typeof(self) sself = wself;
    [sself disconnectGracefully:NO];
  }];
}

#pragma mark - Connection

- (void)connect:(BOOL)silent {
  if (_running) {
    return;
  }

  // create socket
  _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM,
                           IPPROTO_TCP, kCFSocketAcceptCallBack,
                           PSWebSocketServerAcceptCallback, &_socketContext);
  // configure socket
  int yes = 1;
  setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes,
             sizeof(yes));

  // bind
  CFSocketError err =
      CFSocketSetAddress(_socket, (__bridge CFDataRef)_addrData);
  if (err == kCFSocketError) {
    if (!silent) {
      [self notifyDelegateFailedToStart:[NSError
                                            errorWithDomain:NSPOSIXErrorDomain
                                                       code:errno
                                                   userInfo:nil]];
    }
    return;
  } else if (err == kCFSocketTimeout) {
    if (!silent) {
      [self notifyDelegateFailedToStart:[NSError
                                            errorWithDomain:NSPOSIXErrorDomain
                                                       code:ETIME
                                                   userInfo:nil]];
    }
    return;
  }

  // Get socket port in case we use a dynamic port
  if (self.port == 0) {
    struct sockaddr_in sin;
    bzero(&sin, sizeof(struct sockaddr_in));
    int addrlen = sizeof(sin);
    if (getsockname(CFSocketGetNative(_socket), (struct sockaddr *)&sin,
                    &addrlen) == 0) {
      self.port = ntohs(sin.sin_port);
    }
  }

  // schedule
  _socketRunLoopSource =
      CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);

  CFRunLoopRef runLoop = [[self runLoop] getCFRunLoop];
  CFRunLoopAddSource(runLoop, _socketRunLoopSource, kCFRunLoopDefaultMode);

  _running = YES;

  if (!silent) {
    [self notifyDelegateDidStart];
  }
}
- (void)disconnectGracefully:(BOOL)silent {
  if (!_running) {
    return;
  }

  for (PSWebSocketServerConnection *connection in _connections.allObjects) {
    [self disconnectConnectionGracefully:connection
                              statusCode:500
                             description:@"Service Going Away"
                                 headers:nil];
  }
  for (PSWebSocket *webSocket in _webSockets.allObjects) {
    [webSocket close];
  }

  [self pumpOutput];

  // disconnect
  __weak typeof(self) wself = self;
  [self executeWork:^{
    __strong typeof(self) sself = wself;
    [sself disconnect:silent];
  }];

  _running = NO;
}
- (void)disconnect:(BOOL)silent {
  if (_socketRunLoopSource) {
    CFRunLoopRef runLoop = [[self runLoop] getCFRunLoop];
    CFRunLoopRemoveSource(runLoop, _socketRunLoopSource, kCFRunLoopDefaultMode);
    CFRelease(_socketRunLoopSource);
    _socketRunLoopSource = nil;
  }

  if (_socket) {
    if (CFSocketIsValid(_socket)) {
      CFSocketInvalidate(_socket);
    }
    CFRelease(_socket);
    _socket = nil;
  }

  _running = NO;

  if (!silent) {
    [self notifyDelegateDidStop];
  }
}

#pragma mark - Accepting

- (void)accept:(CFSocketNativeHandle)handle {
  __weak typeof(self) wself = self;
  [self executeWork:^{
    __strong typeof(self) sself = wself;
    // create streams
    CFReadStreamRef readStream = nil;
    CFWriteStreamRef writeStream = nil;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, handle, &readStream,
                                 &writeStream);

    // fail if we couldn't get streams
    if (!readStream || !writeStream) {
      return;
    }

    // configure streams
    CFReadStreamSetProperty(
        readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(
        writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

    // enable SSL
    if (sself.secure) {
      NSMutableDictionary *opts = [NSMutableDictionary dictionary];

      opts[(__bridge id)kCFStreamSSLIsServer] = @YES;
      opts[(__bridge id)kCFStreamSSLCertificates] = _SSLCertificates;
      opts[(__bridge id)kCFStreamSSLValidatesCertificateChain] =
          @NO; // i.e. client certs

      CFReadStreamSetProperty(readStream, kCFStreamPropertySSLSettings,
                              (__bridge CFDictionaryRef)opts);
      CFWriteStreamSetProperty(writeStream, kCFStreamPropertySSLSettings,
                               (__bridge CFDictionaryRef)opts);

      SSLContextRef context = (SSLContextRef)CFWriteStreamCopyProperty(
          writeStream, kCFStreamPropertySSLContext);
      SSLSetClientSideAuthenticate(context, kTryAuthenticate);
      CFRelease(context);
    }

    // create connection
    PSWebSocketServerConnection *connection =
        [[PSWebSocketServerConnection alloc] init];
    connection.inputStream = CFBridgingRelease(readStream);
    connection.outputStream = CFBridgingRelease(writeStream);

    // attach connection
    [sself attachConnection:connection];

    // open
    [connection.inputStream open];
    [connection.outputStream open];

  }];
}

#pragma mark - WebSockets

- (void)attachWebSocket:(PSWebSocket *)webSocket {
  if ([_webSockets containsObject:webSocket]) {
    return;
  }
  [_webSockets addObject:webSocket];
  webSocket.delegate = self;
  webSocket.delegateQueue = _workQueue;
}
- (void)detachWebSocket:(PSWebSocket *)webSocket {
  if (![_webSockets containsObject:webSocket]) {
    return;
  }
  [_webSockets removeObject:webSocket];
  webSocket.delegate = nil;
}

#pragma mark - PSWebSocketDelegate

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
  [self notifyDelegateWebSocketDidOpen:webSocket];
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
  [self notifyDelegateWebSocket:webSocket didReceiveMessage:message];
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
  [self detachWebSocket:webSocket];
  [self notifyDelegateWebSocket:webSocket didFailWithError:error];
}
- (void)webSocket:(PSWebSocket *)webSocket
    didCloseWithCode:(NSInteger)code
              reason:(NSString *)reason
            wasClean:(BOOL)wasClean {
  [self detachWebSocket:webSocket];
  [self notifyDelegateWebSocket:webSocket
               didCloseWithCode:code
                         reason:reason
                       wasClean:wasClean];
}
- (void)webSocketDidFlushInput:(PSWebSocket *)webSocket {
  [self notifyDelegateWebSocketDidFlushInput:webSocket];
}
- (void)webSocketDidFlushOutput:(PSWebSocket *)webSocket {
  [self notifyDelegateWebSocketDidFlushOutput:webSocket];
}

#pragma mark - Connections

- (void)attachConnection:(PSWebSocketServerConnection *)connection {
  if ([_connections containsObject:connection]) {
    return;
  }
  [_connections addObject:connection];
  [_connectionsByStreams setObject:connection forKey:connection.inputStream];
  [_connectionsByStreams setObject:connection forKey:connection.outputStream];
  connection.inputStream.delegate = self;
  connection.outputStream.delegate = self;
  [connection.inputStream scheduleInRunLoop:[self runLoop]
                                    forMode:NSRunLoopCommonModes];
  [connection.outputStream scheduleInRunLoop:[self runLoop]
                                     forMode:NSRunLoopCommonModes];
}
- (void)detatchConnection:(PSWebSocketServerConnection *)connection {
  if (![_connections containsObject:connection]) {
    return;
  }
  [_connections removeObject:connection];
  [_connectionsByStreams removeObjectForKey:connection.inputStream];
  [_connectionsByStreams removeObjectForKey:connection.outputStream];
  [connection.inputStream removeFromRunLoop:[self runLoop]
                                    forMode:NSRunLoopCommonModes];
  [connection.outputStream removeFromRunLoop:[self runLoop]
                                     forMode:NSRunLoopCommonModes];
  connection.inputStream.delegate = nil;
  connection.outputStream.delegate = nil;
}
- (void)disconnectConnectionGracefully:(PSWebSocketServerConnection *)connection
                            statusCode:(NSInteger)statusCode
                           description:(NSString *)description
                               headers:(NSDictionary *)headers {
  if (connection.readyState >= PSWebSocketServerConnectionReadyStateClosing) {
    return;
  }
  connection.readyState = PSWebSocketServerConnectionReadyStateClosing;
  if (!description)
    description = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
  CFHTTPMessageRef msg = CFHTTPMessageCreateResponse(
      kCFAllocatorDefault, statusCode, (__bridge CFStringRef)description,
      kCFHTTPVersion1_1);
  for (NSString *name in headers) {
    CFHTTPMessageSetHeaderFieldValue(msg, (__bridge CFStringRef)name,
                                     (__bridge CFStringRef)headers[name]);
  }
  CFHTTPMessageSetHeaderFieldValue(msg, CFSTR("Connection"), CFSTR("Close"));
  CFHTTPMessageSetHeaderFieldValue(msg, CFSTR("Content-Length"), CFSTR("0"));
  NSData *data = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(msg));
  CFRelease(msg);
  [connection.outputBuffer appendData:data];
  [self pumpOutput];
  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), _workQueue,
                 ^{
                   __strong typeof(weakSelf) strongSelf = weakSelf;
                   if (strongSelf) {
                     [strongSelf disconnectConnection:connection];
                   }
                 });
}
- (void)disconnectConnection:(PSWebSocketServerConnection *)connection {
  if (connection.readyState == PSWebSocketServerConnectionReadyStateClosed) {
    return;
  }
  connection.readyState = PSWebSocketServerConnectionReadyStateClosed;
  [self detatchConnection:connection];
  [connection.inputStream close];
  [connection.outputStream close];
}

#pragma mark - Pumping

- (void)pumpInput {
  uint8_t chunkBuffer[4096];
  for (PSWebSocketServerConnection *connection in _connections.allObjects) {
    if (connection.readyState != PSWebSocketServerConnectionReadyStateOpen ||
        !connection.inputStream.hasBytesAvailable) {
      continue;
    }

    while (connection.inputStream.hasBytesAvailable) {
      NSInteger readLength = [connection.inputStream read:chunkBuffer
                                                maxLength:sizeof(chunkBuffer)];
      if (readLength > 0) {
        [connection.inputBuffer appendBytes:chunkBuffer length:readLength];
      } else if (readLength < 0) {
        [self disconnectConnection:connection];
      }
      if (readLength < sizeof(chunkBuffer)) {
        break;
      }
    }

    if (connection.inputBuffer.bytesAvailable > 4) {
      void *boundary =
          memmem(connection.inputBuffer.bytes,
                 connection.inputBuffer.bytesAvailable, "\r\n\r\n", 4);
      if (boundary == NULL) {
        // Haven't reached end of HTTP headers yet
        if (connection.inputBuffer.bytesAvailable >= 16384) {
          [self disconnectConnection:connection];
        }
        continue;
      }
      NSUInteger boundaryOffset = boundary + 4 - connection.inputBuffer.bytes;

      CFHTTPMessageRef msg = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
      CFHTTPMessageAppendBytes(msg, connection.inputBuffer.bytes,
                               connection.inputBuffer.bytesAvailable);
      if (!CFHTTPMessageIsHeaderComplete(msg)) {
        [self disconnectConnection:connection];
        CFRelease(msg);
        continue;
      }

      // move input buffer
      connection.inputBuffer.offset += boundaryOffset;
      if (connection.inputBuffer.hasBytesAvailable) {
        [self disconnectConnection:connection];
        CFRelease(msg);
        continue;
      }

      NSMutableURLRequest *request = [NSMutableURLRequest
          requestWithURL:CFBridgingRelease(CFHTTPMessageCopyRequestURL(msg))];
      request.HTTPMethod =
          CFBridgingRelease(CFHTTPMessageCopyRequestMethod(msg));

      NSDictionary *headers =
          CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(msg));
      [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request setValue:obj forHTTPHeaderField:key];
      }];

      if (![PSWebSocket isWebSocketRequest:request]) {
        [self disconnectConnectionGracefully:connection
                                  statusCode:501
                                 description:@"WebSockets only, please"
                                     headers:nil];
        CFRelease(msg);
        continue;
      }

      NSString *protocol = nil;
      if (_delegate) {
        NSHTTPURLResponse *response = nil;
        if (![self askDelegateShouldAcceptConnection:connection
                                             request:request
                                            response:&response]) {
          [self disconnectConnectionGracefully:connection
                                    statusCode:(response.statusCode ?: 403)
                                   description:nil
                                       headers:response.allHeaderFields];
          CFRelease(msg);
          continue;
        }
        protocol = response.allHeaderFields[@"Sec-WebSocket-Protocol"];
      }

      // detach connection
      [self detatchConnection:connection];

      // create webSocket
      PSWebSocket *webSocket =
          [PSWebSocket serverSocketWithRequest:request
                                   inputStream:connection.inputStream
                                  outputStream:connection.outputStream];
      webSocket.delegateQueue = _workQueue;

      // attach webSocket
      [self attachWebSocket:webSocket];

      // open webSocket
      [webSocket open];

      // clean up
      CFRelease(msg);
    }
  }
}
- (void)pumpOutput {
  for (PSWebSocketServerConnection *connection in _connections.allObjects) {
    if (connection.readyState != PSWebSocketServerConnectionReadyStateOpen &&
        connection.readyState != PSWebSocketServerConnectionReadyStateClosing) {
      continue;
    }

    while (connection.outputStream.hasSpaceAvailable &&
           connection.outputBuffer.hasBytesAvailable) {
      NSInteger writeLength = [connection.outputStream
              write:connection.outputBuffer.bytes
          maxLength:connection.outputBuffer.bytesAvailable];
      if (writeLength > 0) {
        connection.outputBuffer.offset += writeLength;
      } else if (writeLength < 0) {
        [self disconnectConnection:connection];
        break;
      }

      if (writeLength == 0) {
        break;
      }
    }

    if (connection.readyState == PSWebSocketServerConnectionReadyStateClosing &&
        !connection.outputBuffer.hasBytesAvailable) {
      [self disconnectConnection:connection];
    }
  }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
  __weak typeof(self) wself = self;
  [self executeWork:^{
    __strong typeof(self) sself = self;

    if (stream.delegate != sself) {
      [stream.delegate stream:stream handleEvent:event];
      return;
    }

    PSWebSocketServerConnection *connection =
        [sself.connectionsByStreams objectForKey:stream];
    NSAssert(connection, @"Connection should not be nil");

    if (event == NSStreamEventOpenCompleted) {
      if (stream == connection.inputStream) {
        connection.inputStreamOpenCompleted = YES;
      } else if (stream == connection.outputStream) {
        connection.outputStreamOpenCompleted = YES;
      }
    }
    if (!connection.inputStreamOpenCompleted ||
        !connection.outputStreamOpenCompleted) {
      return;
    }

    switch (event) {
    case NSStreamEventOpenCompleted: {
      if (connection.readyState ==
          PSWebSocketServerConnectionReadyStateConnecting) {
        connection.readyState = PSWebSocketServerConnectionReadyStateOpen;
      }
      [sself pumpInput];
      [sself pumpOutput];
      break;
    }
    case NSStreamEventErrorOccurred: {
      [sself disconnectConnection:connection];
      break;
    }
    case NSStreamEventEndEncountered: {
      [sself disconnectConnection:connection];
      break;
    }
    case NSStreamEventHasBytesAvailable: {
      [sself pumpInput];
      break;
    }
    case NSStreamEventHasSpaceAvailable: {
      [sself pumpOutput];
      break;
    }
    default:
      break;
    }
  }];
}

#pragma mark - Delegation

- (void)notifyDelegateDidStart {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    [sself.delegate serverDidStart:self];
  }];
}
- (void)notifyDelegateFailedToStart:(NSError *)error {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    [sself.delegate server:self didFailWithError:error];
  }];
}
- (void)notifyDelegateDidStop {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    [sself.delegate serverDidStop:self];
  }];
}

- (void)notifyDelegateWebSocketDidOpen:(PSWebSocket *)webSocket {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    [sself.delegate server:self webSocketDidOpen:webSocket];
  }];
}
- (void)notifyDelegateWebSocket:(PSWebSocket *)webSocket
              didReceiveMessage:(id)message {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    [sself.delegate server:self webSocket:webSocket didReceiveMessage:message];
  }];
}

- (void)notifyDelegateWebSocket:(PSWebSocket *)webSocket
               didFailWithError:(NSError *)error {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    [sself.delegate server:self webSocket:webSocket didFailWithError:error];
  }];
}
- (void)notifyDelegateWebSocket:(PSWebSocket *)webSocket
               didCloseWithCode:(NSInteger)code
                         reason:(NSString *)reason
                       wasClean:(BOOL)wasClean {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    [sself.delegate server:self
                 webSocket:webSocket
          didCloseWithCode:code
                    reason:reason
                  wasClean:wasClean];
  }];
}
- (void)notifyDelegateWebSocketDidFlushInput:(PSWebSocket *)webSocket {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    if ([sself.delegate
            respondsToSelector:@selector(server:webSocketDidFlushInput:)]) {
      [sself.delegate server:self webSocketDidFlushInput:webSocket];
    };
  }];
}
- (void)notifyDelegateWebSocketDidFlushOutput:(PSWebSocket *)webSocket {
  __weak typeof(self) wself = self;
  [self executeDelegate:^{
    __strong typeof(self) sself = wself;
    if ([sself.delegate
            respondsToSelector:@selector(server:webSocketDidFlushOutput:)]) {
      [sself.delegate server:self webSocketDidFlushOutput:webSocket];
    }
  }];
}
- (BOOL)askDelegateShouldAcceptConnection:
            (PSWebSocketServerConnection *)connection
                                  request:(NSURLRequest *)request
                                 response:(NSHTTPURLResponse **)outResponse {
  __block BOOL accept;
  __block NSHTTPURLResponse *response = nil;
  __weak typeof(self) wself = self;
  [self executeDelegateAndWait:^{
    __strong typeof(self) sself = wself;
    if ([sself.delegate respondsToSelector:@selector(server:
                                               acceptWebSocketWithRequest:
                                                                  address:
                                                                    trust:
                                                                 response:)]) {
      NSData *address = PSPeerAddressOfInputStream(connection.inputStream);
      SecTrustRef trust = (SecTrustRef)CFReadStreamCopyProperty(
          (__bridge CFReadStreamRef)connection.inputStream,
          kCFStreamPropertySSLPeerTrust);
      accept = [sself.delegate server:self
           acceptWebSocketWithRequest:request
                              address:address
                                trust:trust
                             response:&response];
      if (trust) {
        CFRelease(trust);
      }
    } else if ([sself.delegate
                   respondsToSelector:@selector(server:
                                          acceptWebSocketWithRequest:)]) {
      accept = [sself.delegate server:self acceptWebSocketWithRequest:request];
    } else {
      accept = YES;
    }
  }];
  *outResponse = response;
  return accept;
}

#pragma mark - Queueing

- (void)executeWork:(void (^)(void))work {
  NSParameterAssert(work);
  dispatch_async(_workQueue, work);
}
- (void)executeWorkAndWait:(void (^)(void))work {
  NSParameterAssert(work);
  dispatch_sync(_workQueue, work);
}
- (void)executeDelegate:(void (^)(void))work {
  NSParameterAssert(work);
  dispatch_async((_delegateQueue) ? _delegateQueue : dispatch_get_main_queue(),
                 work);
}
- (void)executeDelegateAndWait:(void (^)(void))work {
  NSParameterAssert(work);
  dispatch_sync((_delegateQueue) ? _delegateQueue : dispatch_get_main_queue(),
                work);
}

#pragma mark - Dealloc

- (void)dealloc {
  __weak typeof(self) wself = self;
  [self executeWorkAndWait:^{
    __strong typeof(self) sself = wself;
    [sself disconnect:YES];
  }];
}

@end

void PSWebSocketServerAcceptCallback(CFSocketRef s, CFSocketCallBackType type,
                                     CFDataRef address, const void *data,
                                     void *info) {
  [(__bridge PSWebSocketServer *)info accept:*(CFSocketNativeHandle *)data];
}
