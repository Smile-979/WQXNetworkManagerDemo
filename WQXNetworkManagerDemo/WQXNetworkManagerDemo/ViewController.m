//
//  ViewController.m
//  WQXNetworkManagerDemo
//
//  Created by 温群香 on 2021/1/28.
//

#import "ViewController.h"

#import "WQXNetworkManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self example1];
//    [self example2];
//    [self example3];
//    [self example4];
}

/** GET请求 */
- (void)example1 {
    NSURLSessionTask *task = [WQXNetworkManager wqx_GET:@"recommendPoetry" parameters:nil success:^(id  _Nonnull responseObject) {
        // 此时已经是主线程，无需切换线程
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        NSLog(@"请求成功：%@", responseObject);
    } failure:^(NSError * _Nonnull error) {
        // 此时已经是主线程，无需切换线程
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        NSLog(@"请求失败：%@", error);
    }];
    NSLog(@"task：%@", task);
}

/** POST请求 */
- (void)example2 {
    NSDictionary *parameters = @{@"name": @"古风二首 二"};
    NSURLSessionTask *task = [WQXNetworkManager wqx_POST:@"searchPoetry" parameters:parameters success:^(id  _Nonnull responseObject) {
        // 此时已经是主线程，无需切换线程
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        NSLog(@"请求成功：%@", responseObject);
    } failure:^(NSError * _Nonnull error) {
        // 此时已经是主线程，无需切换线程
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        NSLog(@"请求失败：%@", error);
    }];
    NSLog(@"task：%@", task);
}

/** 覆盖baseURL的GET请求 */
- (void)example3 {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/d"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    NSString *key = @"请填写自己的聚合key";
    NSString *urlString = [NSString stringWithFormat:@"http://v.juhe.cn/todayOnhistory/queryEvent.php?key=%@&date=%@", key, today];
    NSURLSessionTask *task = [WQXNetworkManager wqx_GET:urlString parameters:nil success:^(id  _Nonnull responseObject) {
        // 此时已经是主线程，无需切换线程
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        NSLog(@"请求成功：%@", responseObject);
    } failure:^(NSError * _Nonnull error) {
        // 此时已经是主线程，无需切换线程
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        NSLog(@"请求失败：%@", error);
    }];
    NSLog(@"task：%@", task);
}

/** 异步请求 */
- (void)example4 {
    NSLog(@"请求开始");
    // 不要给人家增加负担，写5就好了
    for (int i = 0; i < 5; i ++) {
        [WQXNetworkManager wqx_asyncGET:@"recommendPoetry" parameters:nil success:^(id  _Nonnull responseObject) {
            // 此时已经是主线程，无需切换线程
            NSLog(@"当前线程：%@", [NSThread currentThread]);
            NSLog(@"请求成功：%@", responseObject);
        } failure:^(NSError * _Nonnull error) {
            // 此时已经是主线程，无需切换线程
            NSLog(@"当前线程：%@", [NSThread currentThread]);
            NSLog(@"请求失败：%@", error);
        }];
    }
    NSLog(@"请求结束");
}

@end
