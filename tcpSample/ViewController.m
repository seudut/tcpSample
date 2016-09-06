//
//  ViewController.m
//  tcpSample
//
//  Created by Peng Li on 9/5/16.
//  Copyright © 2016 Peng Li. All rights reserved.
//

#import "ViewController.h"
#import "TcpServer.h"

@interface ViewController () <TcpServerDelegate>

@end

@implementation ViewController
{
    TcpServer *server;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    server = [[TcpServer alloc]init];
    [server setDelegate: (id <TcpServerDelegate>)self];
    
    if ([server startServer]) {
        NSLog(@"===TcpServer started===");
    }
    NSLog(@"did load");
        
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TcpServerDelegate

- (void)onMessageReceived:(NSString *)message
{
    NSLog(@"====%@====", message);
    [server sendMessage:@"woshilipeng"];
}


@end
