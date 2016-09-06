//
//  TcpServer.h
//  tcpSample
//
//  Created by Peng Li on 9/5/16.
//  Copyright © 2016 Peng Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TcpServerDelegate <NSObject>
- (void) onMessageReceived:(NSString *)message;
//- (void) onConnected();
@end

@interface TcpServer : NSObject

@property (nonatomic, weak) id<TcpServerDelegate> delegate;

- (BOOL) startServer;
- (BOOL) startServerWithPort:(NSUInteger) port;
- (void) stopServer;
- (void) sendMessage:(NSString *)message;

@end
