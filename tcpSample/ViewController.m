//
//  ViewController.m
//  tcpSample
//
//  Created by Peng Li on 9/5/16.
//  Copyright © 2016 Peng Li. All rights reserved.
//

#import "ViewController.h"
#import "TcpServer.h"

@interface ViewController ()

@end

@implementation ViewController
{
    TcpServer *server;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    server = [[TcpServer alloc]init];
    [server setDelegate: (id <TcpServerDelegate>)self];
    
    
    [server startServer];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
