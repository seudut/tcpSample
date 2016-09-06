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

#define DEFAULT_PORT 8888

//NSLog(@"%@", NSStringFromSelector(_cmd)); // Objective-C


CFWriteStreamRef outStream;
CFReadStreamRef  inStream;



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
    
    // add observers for message received
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(getMessage:) name:@"TCPServerGetMessage" object:nil];

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
//    dispatch_release(self->queue);
    // close the sockets
    CFSocketInvalidate(sock);
}

- (void) sendMessage:(NSString *)message
{
    const char * string = [message UTF8String];
    uint8_t * uint8b = (uint8_t *)string;
    
    if (outStream != NULL) {
        CFWriteStreamWrite(outStream, uint8b, message.length);
    }
    
}

void acceptCallback(CFSocketRef sock, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    if (callbackType != kCFSocketAcceptCallBack)
    {
        NSLog(@"Unknown callback type");
        exit(1);
    }
    NSLog(@"client connected");
    
//    CFReadStreamRef inStream;
//    CFWriteStreamRef outStream;
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

-(void)getMessage:(NSNotification *)notification {
    NSString * message = notification.object;
    NSLog(@"getMessage");
    if (message.length > 0) {
        [self showMessage:message];
//        [self performSelectorOnMainThread:@selector(showMessage:) withObject:message waitUntilDone:YES];
//        dispatch_async (dispatch_get_main_queue(), ^{
//            [self showMessage:message];
    //});
    }
}


-(void)showMessage:(NSString *)message {
    NSLog(@"showMessage from getMessage, to");
    [self.delegate onMessageReceived:message];
}


void readStream (CFReadStreamRef stream, CFStreamEventType type,void * clientCallBackInfo)
{
    UInt8 buff[255];
    CFReadStreamRead(stream, buff, 255);
    NSLog(@"readStream - %@", [NSString stringWithUTF8String:(char *)buff]);
//    printf("received: %s",buff);
    [[NSNotificationCenter defaultCenter]postNotificationName:@"TCPServerGetMessage" object:[NSString stringWithUTF8String:(const char*)buff]];
}

void writeStream (CFWriteStreamRef stream,CFStreamEventType eventType, void * clientCallBackInfo) {
    outStream = stream;
}




@end
