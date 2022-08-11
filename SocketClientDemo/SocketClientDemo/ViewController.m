//
//  ViewController.m
//  SocketClientDemo
//
//  Created by ZhangLiang on 2022/8/11.
//

#import "ViewController.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

@interface ViewController ()

@property (nonatomic, assign) int server_socket;
@property (weak, nonatomic) IBOutlet UITextField *msgTxf;

- (IBAction)sendAction:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建服务端socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1) {
        NSLog(@"server_socket创建失败.");
    } else {
        // 绑定地址和端口
        struct sockaddr_in server_addr;
        server_addr.sin_len = sizeof(struct sockaddr_in);
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(4444);
        server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
        bzero(&(server_addr.sin_zero), 8);
        
        // 接收服务端的连接
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            // 连接server_socket
            int aResult = connect(server_socket, (struct sockaddr *)&server_addr, sizeof(struct sockaddr_in));
            if (aResult == -1) {
                NSLog(@"server_socket连接失败.");
            } else {
                self.server_socket = server_socket;
                [self acceptFromServer];
            }
        });
    }
}

// 从服务端接收消息
- (void)acceptFromServer {
    while(1) {
        // 接收服务端传来的数据
        char buf[1024];
        long iReturn = recv(self.server_socket, buf, 1024, 0);
        if (iReturn > 0) {
            NSLog(@"接收消息成功: %@", [NSString stringWithCString:buf encoding:NSUTF8StringEncoding]);
        } else if (iReturn == -1) {
            NSLog(@"接收消息失败.");
        }
    }
}

// 给服务端发送消息
- (void)sendMsg:(NSString *)msg {
    char *buf[1024] = {0};
    const char *p1 = (char *)buf;
    p1 = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(self.server_socket, p1, 1024, 0);
}

- (IBAction)sendAction:(id)sender {
    [self sendMsg:self.msgTxf.text];
}

@end
