//
//  AppDelegate.m
//  WQXNetworkManagerDemo
//
//  Created by 温群香 on 2021/1/28.
//

#import "AppDelegate.h"

#import "WQXNetworkManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    // 设置全局网络请求
    [WQXNetworkManager wqx_globalConfigWithBlock:^(AFHTTPSessionManager * _Nonnull sessionManager) {
        // 可以在这里设置请求超时时间，默认是30秒
        sessionManager.requestSerializer.timeoutInterval = 60.0f;
        // 可以在这里设置请求头，也可以调用wqx_setValue:forHTTPHeaderField:进行单独设置
        [sessionManager.requestSerializer setValue:@"cookie" forHTTPHeaderField:@"Cookie"];
        // 设置baseURL
        [sessionManager setValue:[NSURL URLWithString:@"https://api.apiopen.top/"] forKey:@"baseURL"];
    }];

    // 监听网络状态
    [WQXNetworkManager wqx_startMonitoringNetworkStatusWithBlock:^(WQXNetworkStatus status) {
        // 在这里进行一些提醒，在Debug模式下，会在控制台自动log网络状态
    }];

    return YES;
}

@end
