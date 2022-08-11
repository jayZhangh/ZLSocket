//
//  ViewController.m
//  SocketServerDemo
//
//  Created by ZhangLiang on 2022/8/11.
//

#import "ViewController.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

static int const kMaxConnectCount = 5;

@interface ViewController ()

- (IBAction)listenAction:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *msgLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)listenSocket {
    // 创建server socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1) {
        NSLog(@"server socket创建失败.");
    } else {
        // 绑定地址和端口
        struct sockaddr_in server_addr;
        server_addr.sin_len = sizeof(struct sockaddr_in);
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(4444);
        server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
        bzero(&(server_addr.sin_zero), 8);
        
        int bind_result = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (bind_result == -1) {
            NSLog(@"绑定端口失败");
        } else {
            if (listen(server_socket, kMaxConnectCount) == -1) {
                NSLog(@"监听失败");
            } else {
                for (int i = 0; i < kMaxConnectCount; i++) {
                    //接收客户端的连接
                    [self acceptClientWithServerSocket:server_socket];
                }
            }
        }
    }
}

// 创建线程接收客户端
- (void)acceptClientWithServerSocket:(int)server_socket {
    __block struct sockaddr_in client_address;
    __block socklen_t address_len;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // 创建新的socket
        while(1) {
            int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
            if (client_socket == -1) {
                NSLog(@"接收客户端连接失败.");
            } else {
                NSLog(@"客户端 in, socket:%d", client_socket);
                // 接收客户端数据
                [self recvFromClientWithSocket:client_socket];
            }
        }
    });
}

// 接收客户端数据
- (void)recvFromClientWithSocket:(int)client_socket {
    while(1) {
        // 接收客户端传来的数据
        char buf[1024] = {0};
        long iReturn = recv(client_socket, buf, 1024, 0);
        if (iReturn > 0) {
            NSString *msg = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
            NSLog(@"客户端来消息了: %@", msg);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.msgLab.text = msg;
            });
            
            
            [self sendMsg:@"服务端发送d消息." toClient:client_socket];
        } else if (iReturn == -1) {
            NSLog(@"读取消息失败.");
            break;
        } else if (iReturn == 0) {
            NSLog(@"客户端走了.");
            close(client_socket);
            break;
        }
    }
}

// 给客户端发送消息
- (void)sendMsg:(NSString *)msg toClient:(int)client_socket {
    char *buf[1024] = {0};
    const char *p1 = (char *)buf;
    p1 = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(client_socket, p1, 1024, 0);
}

- (IBAction)listenAction:(id)sender {
    [self listenSocket];
}

@end
