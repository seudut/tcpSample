//
//  TcpServer.h
//  tcpSample
//
//  Created by Peng Li on 9/5/16.
//  Copyright © 2016 Peng Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_PORT 8888

@protocol TcpServerDelegate <NSObject>
- (void) onMessageReceived:(NSString *)message;
@end

@interface TcpServer : NSObject

@property (nonatomic, weak) id<TcpServerDelegate> delegate;

- (void) startServer;
- (void) startServerWithPort:(NSUInteger) port;
- (void) stopServer;
- (void) sendMessage:(NSString *)message;

@end
