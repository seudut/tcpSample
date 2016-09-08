//
//  TcpServer.m
//  tcpSample
//
//  Created by Peng Li on 9/5/16.
//  Copyright © 2016 Peng Li. All rights reserved.
//

#import "TcpServer.h"
#import <CoreFoundation/CoreFoundation.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define DEFAULT_PORT 8888

void readStream (CFReadStreamRef stream, CFStreamEventType type,void * clientCallBackInfo);
void writeStream (CFWriteStreamRef stream,CFStreamEventType eventType, void * clientCallBackInfo);
void acceptCallback(CFSocketRef sock, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info);


//CFWriteStreamRef outStream;
//CFReadStreamRef  inStream;

CFWriteStreamRef outputStream;

@implementation TcpServer
{
    CFSocketRef sock;
    dispatch_queue_t queue;
    
}

- (BOOL) startServer
{
    return [self startServerWithPort:DEFAULT_PORT];
}

- (BOOL) initServer:(NSUInteger)port
{
    // create socket
    sock = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, acceptCallback, NULL);
    if (!sock) {
        NSLog(@"%@ create socket failed", NSStringFromSelector(_cmd));
        return false;
    }
    
    // set socket options
    int optval = 1;
    setsockopt(CFSocketGetNative(sock), SOL_SOCKET, SO_REUSEADDR, (void *)&optval, sizeof(optval));
    
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(port);
    sin.sin_addr.s_addr = INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&sin, sizeof(sin));
    
    // bind
    if (CFSocketSetAddress(sock, sincfd)) {
        NSLog(@"%@ bind failed", NSStringFromSelector(_cmd));
        CFRelease(sincfd);
        return false;
    }
    
    CFRelease(sincfd);
    
    // listen
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, sock, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), socketsource, kCFRunLoopDefaultMode);
    
    // add observers for notifications from sockets
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onMessageReceived:) name:@"OnMessageReceived" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onClientConnected:) name:@"OnClientConnected" object:nil];
    
    // create queue for CFRunLoopRun
    queue = dispatch_queue_create("tcp_queue", nil);
    
    NSLog(@"%@ server start success, port=%lu", NSStringFromSelector(_cmd), (unsigned long)port);
    return true;
}

- (BOOL) startServerWithPort:(NSUInteger)port
{
    bool ret = [self initServer:port];
    
    if (ret) {
        dispatch_async(queue, ^{
            CFRunLoopRun();
        });
    } else {
        [self stopServer];
    }
    
    return ret;
}

- (void) stopServer
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    // remove observers
    [[NSNotificationCenter defaultCenter]removeObserver:self];
//    dispatch_release(queue);
    // close the sockets
    CFSocketInvalidate(sock);
}

- (void) sendMessage:(NSString *)message
{
    const char * string = [message UTF8String];
    uint8_t * uint8b = (uint8_t *)string;
    
    if (outputStream != NULL) {
        CFWriteStreamWrite(outputStream, uint8b, message.length);
    }
    
}

void acceptCallback(CFSocketRef sock, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    if (callbackType != kCFSocketAcceptCallBack)
    {
        NSLog(@"Unknown callback type");
        exit(1);
    }
    
    // get remote IP
    CFSocketNativeHandle nativeSockHandle = * (CFSocketNativeHandle *)data;
    uint8_t name[SOCK_MAXADDRLEN];
    socklen_t nameLen = sizeof(name);
    if (getpeername(nativeSockHandle, (struct sockaddr *)name, &nameLen) !=0 ) {
        NSLog(@"getpeername error");
        exit(1);
    }
    
    char * remoteIP = inet_ntoa(((struct sockaddr_in *)name)->sin_addr);
    
    // notify remote connected
    NSLog(@"client connected - %@", [NSString stringWithUTF8String:remoteIP]);
    [[NSNotificationCenter defaultCenter]postNotificationName:@"OnClientConnected" object:[NSString stringWithUTF8String:remoteIP]];
    
    CFReadStreamRef inStream;
    CFWriteStreamRef outStream;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, *(CFSocketNativeHandle *)data, &inStream, &outStream);
    
    
    CFStreamClientContext streamContext = {0,NULL,NULL,NULL};
    if (!CFReadStreamSetClient(inStream, kCFStreamEventHasBytesAvailable, readStream, &streamContext)) {
        exit(1);
    }
    if (!CFWriteStreamSetClient(outStream, kCFStreamEventCanAcceptBytes, writeStream, &streamContext)) {
        exit(1);
    }
    
    CFReadStreamScheduleWithRunLoop(inStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFWriteStreamScheduleWithRunLoop(outStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamOpen(inStream);
    CFWriteStreamOpen(outStream);
}


// observers functions

- (void) onMessageReceived:(NSNotification *)notification {
    NSString * message = notification.object;
    NSLog(@"onMessageReceived");
    if (message.length > 0) {
        [self.delegate onMsgRecv:message];
    }
}

- (void) onClientConnected:(NSNotification *)notification {
//    NSString * ip = notification.object;
//    NSLog(@"%@ - remote ip is %@", NSStringFromSelector(_cmd), ip);
    [self.delegate onConnected:(NSString *)notification.object];
}


void readStream (CFReadStreamRef stream, CFStreamEventType type,void * clientCallBackInfo)
{
    UInt8 buff[255] = {0};
    CFReadStreamRead(stream, buff, 255);
//    printf("printf - stream =%s", buff);
//    NSString * str = [[NSString alloc]initWithUTF8String:(const char *)buff];
//    NSLog(@"readStream - %@", str);
    NSLog(@"readStream - %@", [NSString stringWithUTF8String:(char *)buff]);
    [[NSNotificationCenter defaultCenter]postNotificationName:@"OnMessageReceived" object:[NSString stringWithUTF8String:(const char*)buff]];
}

void writeStream (CFWriteStreamRef stream,CFStreamEventType eventType, void * clientCallBackInfo) {
    outputStream = stream;
}




@end
