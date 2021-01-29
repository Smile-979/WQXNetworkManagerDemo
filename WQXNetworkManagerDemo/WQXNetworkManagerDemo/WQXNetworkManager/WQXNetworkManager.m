//
//  WQXNetworkManager.m
//  WQXTools
//
//  Created by 温群香 on 2021/1/28.
//

#import "WQXNetworkManager.h"

@interface WQXNetworkManager ()

@property (nonatomic, strong) NSMutableArray *wqx_sessionTaskArray;
@property (nonatomic, strong) AFHTTPSessionManager *wqx_sessionManager;
@property (nonatomic, assign) WQXNetworkStatus wqx_networkStatus;
@property (nonatomic, strong) dispatch_queue_t wqx_queue;
@property (copy) void (^wqx_globalConfigBlock)(AFHTTPSessionManager *sessionManager);

@end

@implementation WQXNetworkManager

+ (instancetype)wqx_sharedManager {
    static WQXNetworkManager *wqx_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wqx_instance = [[WQXNetworkManager alloc] init];
    });
    return wqx_instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _wqx_sessionTaskArray = [[NSMutableArray alloc] init];
        _wqx_sessionManager = [AFHTTPSessionManager manager];
        _wqx_sessionManager.securityPolicy = [AFSecurityPolicy defaultPolicy];
        _wqx_sessionManager.securityPolicy.allowInvalidCertificates = YES;
        _wqx_sessionManager.securityPolicy.validatesDomainName = NO;
        _wqx_sessionManager.requestSerializer.timeoutInterval = 30.0f;
        _wqx_sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", @"text/html", nil];
        _wqx_queue = dispatch_queue_create("com.wenqunxiang.wqxtools.queue", DISPATCH_QUEUE_CONCURRENT);
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    }
    return self;
}

/** 在这里进行网络请求的全局配置，每次发送请求都会调用该block */
+ (void)wqx_globalConfigWithBlock:(nullable void(^)(AFHTTPSessionManager *sessionManager))completion {
    [WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock = completion;
}

/** 开始监听网络状态，一旦状态发生变化，将会通过block返回 */
+ (void)wqx_startMonitoringNetworkStatusWithBlock:(nullable WQXNetworkStatusBlock)block {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown: {
                    [WQXNetworkManager wqx_sharedManager].wqx_networkStatus = WQXNetworkStatusUnknown;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(WQXNetworkStatusUnknown) : nil;
                    });
                    break;
                }
                case AFNetworkReachabilityStatusNotReachable: {
                    [WQXNetworkManager wqx_sharedManager].wqx_networkStatus = WQXNetworkStatusNotReachable;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(WQXNetworkStatusNotReachable) : nil;
                    });
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWWAN: {
                    [WQXNetworkManager wqx_sharedManager].wqx_networkStatus = WQXNetworkStatusReachableViaWWAN;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(WQXNetworkStatusReachableViaWWAN) : nil;
                    });
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWiFi: {
                    [WQXNetworkManager wqx_sharedManager].wqx_networkStatus = WQXNetworkStatusReachableViaWiFi;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(WQXNetworkStatusReachableViaWiFi) : nil;
                    });
                    break;
                }

                default:
                    break;
            }
#ifdef DEBUG
            if (status == AFNetworkReachabilityStatusUnknown) {
                NSLog(@"当前网络状态：未知网络");
            }else if (status == AFNetworkReachabilityStatusNotReachable) {
                NSLog(@"当前网络状态：无网络");
            }else if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
                NSLog(@"当前网络状态：运营商网络");
            }else if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
                NSLog(@"当前网络状态：Wi-Fi网络");
            }
#endif
        }];
        [manager startMonitoring];
    });
}

/** 当前网络状态，默认为WQXNetworkStatusUnknown，调用方法后可获取真实值：startMonitoringNetworkStatus: */
+ (WQXNetworkStatus)wqx_getNetworkStatus {
    return [WQXNetworkManager wqx_sharedManager].wqx_networkStatus;
}

/**
 GET请求

 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用wqx_cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)wqx_GET:(nullable NSString *)path
                   parameters:(nullable id)parameters
                      success:(nullable WQXRequestSuccessBlock)success
                      failure:(nullable WQXRequestFailedBlock)failure {
    if ([WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock) {
        [WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock([WQXNetworkManager wqx_sharedManager].wqx_sessionManager);
    }
    if (path) {
        path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    }
    if ([path.lowercaseString hasPrefix:@"http"]) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager setValue:nil forKey:@"baseURL"];
    }
    NSURLSessionTask *sessionTask = [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager GET:path parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            success ? success(responseObject) : nil;
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure(error) : nil;
        });
    }];
    sessionTask ? [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray addObject:sessionTask] : nil;
    return sessionTask;
}

/**
 POST请求

 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用wqx_cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)wqx_POST:(nullable NSString *)path
                    parameters:(nullable id)parameters
                       success:(nullable WQXRequestSuccessBlock)success
                       failure:(nullable WQXRequestFailedBlock)failure {
    if ([WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock) {
        [WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock([WQXNetworkManager wqx_sharedManager].wqx_sessionManager);
    }
    if (path) {
        path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    }
    if ([path.lowercaseString hasPrefix:@"http"]) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager setValue:nil forKey:@"baseURL"];
    }
    NSURLSessionTask *sessionTask = [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager POST:path parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            success ? success(responseObject) : nil;
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure(error) : nil;
        });
    }];
    sessionTask ? [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray addObject:sessionTask] : nil;
    return sessionTask;
}

/**
 上传文件

 @param fileData    文件二进制数据
 @param key         服务器是通过什么字段获取二进制就传什么，默认一般是：file
 @param fileName    保存在服务器时的文件名称
 @param mimeType    文件类型
 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用wqx_cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)wqx_uploadFile:(NSData *)fileData
                                 key:(nullable NSString *)key
                            fileName:(nullable NSString *)fileName
                            mimeType:(nullable NSString *)mimeType
                                path:(nullable NSString *)path
                          parameters:(nullable id)parameters
                             success:(nullable WQXRequestSuccessBlock)success
                             failure:(nullable WQXRequestFailedBlock)failure {
    if (!fileData || ![fileData isKindOfClass:[NSData class]] || fileData.length == 0) {
        return nil;
    }
    if ([WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock) {
        [WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock([WQXNetworkManager wqx_sharedManager].wqx_sessionManager);
    }
    if (path) {
        path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    }
    if ([path.lowercaseString hasPrefix:@"http"]) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager setValue:nil forKey:@"baseURL"];
    }
    NSURLSessionTask *sessionTask = [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager POST:path parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:fileData name:key fileName:fileName mimeType:mimeType];
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            success ? success(responseObject) : nil;
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure(error) : nil;
        });
    }];
    sessionTask ? [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray addObject:sessionTask] : nil;
    return sessionTask;
}

/**
 异步GET请求

 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 */
+ (void)wqx_asyncGET:(nullable NSString *)path
          parameters:(nullable id)parameters
             success:(nullable WQXRequestSuccessBlock)success
             failure:(nullable WQXRequestFailedBlock)failure {
    dispatch_async([WQXNetworkManager wqx_sharedManager].wqx_queue, ^{
        if ([WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock) {
            [WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock([WQXNetworkManager wqx_sharedManager].wqx_sessionManager);
        }
        NSString *urlPath = path;
        if (urlPath) {
            urlPath = [urlPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        }
        if ([urlPath.lowercaseString hasPrefix:@"http"]) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager setValue:nil forKey:@"baseURL"];
        }
        NSURLSessionTask *sessionTask = [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager GET:urlPath parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                success ? success(responseObject) : nil;
            });
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure ? failure(error) : nil;
            });
        }];
        sessionTask ? [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray addObject:sessionTask] : nil;
    });
}

/**
 异步POST请求

 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 */
+ (void)wqx_asyncPOST:(nullable NSString *)path
           parameters:(nullable id)parameters
              success:(nullable WQXRequestSuccessBlock)success
              failure:(nullable WQXRequestFailedBlock)failure {
    dispatch_async([WQXNetworkManager wqx_sharedManager].wqx_queue, ^{
        if ([WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock) {
            [WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock([WQXNetworkManager wqx_sharedManager].wqx_sessionManager);
        }
        NSString *urlPath = path;
        if (urlPath) {
            urlPath = [urlPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        }
        if ([urlPath.lowercaseString hasPrefix:@"http"]) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager setValue:nil forKey:@"baseURL"];
        }
        NSURLSessionTask *sessionTask = [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager POST:urlPath parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                success ? success(responseObject) : nil;
            });
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure ? failure(error) : nil;
            });
        }];
        sessionTask ? [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray addObject:sessionTask] : nil;
    });
}

/**
 异步上传文件

 @param fileData    文件二进制数据
 @param key         服务器是通过什么字段获取二进制就传什么，默认一般是：file
 @param fileName    保存在服务器时的文件名称
 @param mimeType    文件类型
 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 */
+ (void)wqx_asyncUploadFile:(NSData *)fileData
                        key:(nullable NSString *)key
                   fileName:(nullable NSString *)fileName
                   mimeType:(nullable NSString *)mimeType
                       path:(nullable NSString *)path
                 parameters:(nullable id)parameters
                    success:(nullable WQXRequestSuccessBlock)success
                    failure:(nullable WQXRequestFailedBlock)failure {
    dispatch_async([WQXNetworkManager wqx_sharedManager].wqx_queue, ^{
        if (!fileData || ![fileData isKindOfClass:[NSData class]] || fileData.length == 0) return;
        if ([WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock) {
            [WQXNetworkManager wqx_sharedManager].wqx_globalConfigBlock([WQXNetworkManager wqx_sharedManager].wqx_sessionManager);
        }
        NSString *urlPath = path;
        if (urlPath) {
            urlPath = [urlPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        }
        if ([urlPath.lowercaseString hasPrefix:@"http"]) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager setValue:nil forKey:@"baseURL"];
        }
        NSURLSessionTask *sessionTask = [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager POST:urlPath parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            [formData appendPartWithFileData:fileData name:key fileName:fileName mimeType:mimeType];
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                success ? success(responseObject) : nil;
            });
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:task];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure ? failure(error) : nil;
            });
        }];
        sessionTask ? [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray addObject:sessionTask] : nil;
    });
}

/** 取消指定的HTTP请求 */
+ (void)wqx_cancelRequestWithTask:(NSURLSessionTask *)task {
    if (![task isKindOfClass:[NSURLSessionTask class]]) return;
    @synchronized (self) {
        for (id obj in [WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray) {
            if ([obj isEqual:task]) {
                [task cancel];
                [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeObject:obj];
                break;
            }
        }
    }
}

/** 取消所有HTTP请求 */
+ (void)wqx_cancelAllRequest {
    @synchronized (self) {
        for (id obj in [WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray) {
            [((NSURLSessionTask *)obj) cancel];
        }
        [[WQXNetworkManager wqx_sharedManager].wqx_sessionTaskArray removeAllObjects];
    }
}

/** 设置HTTPHeader */
+ (void)wqx_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

/**
 配置自建证书的HTTPS请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103

 @param cerPath 自建HTTPS证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO;

 即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName = NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外一个域名。
 因为SSL证书上的域名是独立的,假如证书上注册的域名是www.example.com, 那么mail.example.com是无法验证通过的.
 */
+ (void)wqx_setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    [[WQXNetworkManager wqx_sharedManager].wqx_sessionManager setSecurityPolicy:securityPolicy];
}

@end
