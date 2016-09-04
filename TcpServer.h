//
//  TcpServer.h
//  tcpSample
//
//  Created by Peng Li on 9/5/16.
//  Copyright © 2016 Peng Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TcpServer : NSObject

- (void) startServerWithPort:(NSUInteger) port;
- (void) stopServer;

@end
