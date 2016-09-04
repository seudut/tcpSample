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

@implementation TcpServer
{
    CFSocketRef sock;
    NSInputStream *inputStream;
    
}

- (void) startServerWithPort:(NSUInteger)port
{
    // create socket
    sock = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, handleConnect, NULL);
    if (!sock) {
        NSLog(@"creating socket failed");
        return;
    }
    NSLog(@"start server");
    
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(port);
    sin.sin_addr.s_addr = INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&sin, sizeof(sin));
    
    // bind
    if (CFSocketSetAddress(sock, sincfd))
    {
        NSLog(@"setAddress failed");
        return;
    }
    
    CFRelease(sincfd);
    
    // listen
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, sock, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), socketsource, kCFRunLoopDefaultMode);
    
}

- (void) stopServer
{
    NSLog(@"stopServer");
    CFSocketInvalidate(sock);
}

void handleConnect(CFSocketRef sock, CFSocketCallBackType callbackType, CFDataRef dataRef, const void *data, void *info)
{
    if (callbackType == kCFSocketAcceptCallBack)
        NSLog(@"Accept callback");
    
    return;
}

@end