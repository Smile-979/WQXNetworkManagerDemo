//
//  WQXNetworkManager.h
//  WQXTools
//
//  Created by 温群香 on 2021/1/28.
//

/**
 如果项目需要支持http请求，请完成以下2项:
 1. 请在 Info.plist 文件里添加 App Transport Security Settings
 2. 设置 Allow Arbitrary Loads 为 YES

 请注意：
 1. 需依赖于 AFNetworking 4.x
 2. 这里没有设置缓存，如果需要的话，请自行设计缓存
 */

#import <Foundation/Foundation.h>

@import AFNetworking;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 枚举
/** 网络状态 */
typedef NS_ENUM(NSInteger, WQXNetworkStatus) {
    /** 未知网络 */
    WQXNetworkStatusUnknown,
    /** 无网络 */
    WQXNetworkStatusNotReachable,
    /** 运营商网络 */
    WQXNetworkStatusReachableViaWWAN,
    /** WIFI网络 */
    WQXNetworkStatusReachableViaWiFi
};

#pragma mark - Block
/**
 请求成功的block

 @param responseObject 返回数据
 */
typedef void(^WQXRequestSuccessBlock)(id responseObject);

/**
 请求失败的block

 @param error 错误信息
 */
typedef void(^WQXRequestFailedBlock)(NSError *error);

/**
 网络状态的block

 @param status 网络状态
 */
typedef void(^WQXNetworkStatusBlock)(WQXNetworkStatus status);

@interface WQXNetworkManager : NSObject

/**
 在这里进行网络请求的全局配置，每次发送请求都会调用该block
 用法：
 [WQXNetworkManager wqx_globalConfigWithBlock:^(AFHTTPSessionManager * _Nonnull sessionManager) {
     // 可以在这里设置请求超时时间
     sessionManager.requestSerializer.timeoutInterval = 60.0f;

     // 可以在这里设置请求头，也可以调用wqx_setValue:forHTTPHeaderField:进行单独设置
     [sessionManager.requestSerializer setValue:@"cookie" forHTTPHeaderField:@"Cookie"];

     // 如果发送的请求是完整url，那么内部会忽略baseURL，如果只是路径，那么必须设置baseURL。
     // 例如：[WQXNetworkManager wqx_GET:@"index/banner" ...]; // 此时需要设置baseURL
     // 例如：[WQXNetworkManager wqx_GET:@"https://api.example.com/index/banner" ...]; // 此时内部会忽略baseURL

     // 根据RFC808[https://tools.ietf.org/html/rfc1808]规定：
     // 使用relative to 方法组合时，baseURL必须以"/"结尾，与baseURL组合的字符串不能以"/"开头。
     [sessionManager setValue:[NSURL URLWithString:@"https://api.example.com/"] forKey:@"baseURL"];
 }];
 */
+ (void)wqx_globalConfigWithBlock:(nullable void(^)(AFHTTPSessionManager *sessionManager))completion;

/** 开始监听网络状态，一旦状态发生变化，将会通过block返回 */
+ (void)wqx_startMonitoringNetworkStatusWithBlock:(nullable WQXNetworkStatusBlock)block;

/** 当前网络状态，默认为WQXNetworkStatusUnknown，调用方法后可获取真实值：wqx_startMonitoringNetworkStatusWithBlock: */
+ (WQXNetworkStatus)wqx_getNetworkStatus;

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
                      failure:(nullable WQXRequestFailedBlock)failure;

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
                       failure:(nullable WQXRequestFailedBlock)failure;

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
                             failure:(nullable WQXRequestFailedBlock)failure;

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
             failure:(nullable WQXRequestFailedBlock)failure;

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
              failure:(nullable WQXRequestFailedBlock)failure;

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
                    failure:(nullable WQXRequestFailedBlock)failure;

/** 取消指定的HTTP请求 */
+ (void)wqx_cancelRequestWithTask:(NSURLSessionTask *)task;

/** 取消所有HTTP请求 */
+ (void)wqx_cancelAllRequest;

/** 设置HTTPHeader */
+ (void)wqx_setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 配置自建证书的HTTPS请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103

 @param cerPath 自建HTTPS证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO;

 即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName = NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外一个域名。
 因为SSL证书上的域名是独立的,假如证书上注册的域名是www.example.com, 那么mail.example.com是无法验证通过的.
 */
+ (void)wqx_setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;

@end

NS_ASSUME_NONNULL_END
