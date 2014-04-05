//
//  ServerAPIManager.m
//  LocationClient
//
//  Created by Ezequiel A Becerra on 4/2/14.
//  Copyright (c) 2014 Ezequiel A Becerra. All rights reserved.
//

#import "ServerAPIManager.h"

@interface ServerAPIManager()

-(FailBlock)defaultFailBlock;

-(void)requestWithMethod:(NSString *)method
            relativePath:(NSString *)relativePath
            successBlock:(SuccessBlock)successBlock
               failBlock:(FailBlock)failBlock
              parameters:(NSDictionary *)params;

@end

@implementation ServerAPIManager

#pragma mark - Private

-(FailBlock)defaultFailBlock{
    FailBlock retBlock = ^(NSError *error, NSData *dataReturned){
        //  #TODO log errors to a service maybe?
        NSLog(@"#DEBUG %@", NSStringFromSelector(_cmd));
    };
    
    return retBlock;
}

-(void)requestWithMethod:(NSString *)method
            relativePath:(NSString *)relativePath
            successBlock:(SuccessBlock)successBlock
               failBlock:(FailBlock)failBlock
              parameters:(NSDictionary *)params{
    
    /*  If the method hasn't specified a particular failBlock, then use a default failBlock
     *  handled by this class */
    if (failBlock == nil){
        failBlock = [self defaultFailBlock];
    }
    
    void (^aSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        
        NSError *parseError = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:operation.responseData
                                                                           options:NSJSONReadingAllowFragments
                                                                             error:&parseError];
        if (!parseError){
            //  All the responses are suposed to be a JSON dictionary
            dispatch_async(dispatch_get_main_queue(), ^{
                if (successBlock){
                    successBlock(responseDictionary);
                }
            });
        }else{
            //  There was an error at parsing the JSON
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failBlock){
                    failBlock(parseError, operation.responseData);
                }
            });
        }
    };
    
    void (^aFailBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error){
        //  There was an error at the request or no data returned
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failBlock){
                failBlock(operation.error, operation.responseData);
            }
        });
    };
    
    if ([method isEqualToString:@"GET"]){
        
        [_operationManager GET:relativePath
                    parameters:params
                       success:aSuccessBlock
                       failure:aFailBlock];
        
    }else if ([method isEqualToString:@"POST"]){
        
        [_operationManager POST:relativePath
                     parameters:params
                        success:aSuccessBlock
                        failure:aFailBlock];
        
    }else if ([method isEqualToString:@"DELETE"]){
        
        [_operationManager DELETE:relativePath
                       parameters:params
                          success:aSuccessBlock
                          failure:aFailBlock];
        
    }else{
        NSLog(@"#ERROR METHOD NOT IMPLEMENTED: %@ %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    }
}

#pragma mark - Public

+ (instancetype)sharedInstance{
    static ServerAPIManager *sharedInstance;
    if (!sharedInstance){
        sharedInstance = [[ServerAPIManager alloc] init];
    }
    return sharedInstance;
}

- (id)init{
    self = [super init];
    if (self){
        _baseURL = [NSURL URLWithString:@"http://betzerralocationserver.herokuapp.com"];
        
        //  Init AFHTTPRequestOperationManager
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:_baseURL];
        _operationManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _operationManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain",@"application/json", nil];
    }
    return self;
}

- (void)postLocation:(CLLocationCoordinate2D)coords successBlock:(SuccessBlock)successBlock failBlock:(FailBlock)failBlock{
    
    NSDictionary *params = @{@"latitude" : @(coords.latitude),
                             @"longitude" : @(coords.longitude),
                             @"userId" : @"betzerra"};
    
    void (^completionBlock)(NSData *data, NSURLResponse *response, NSError *error) = ^(NSData *data, NSURLResponse *response, NSError *error){
        
        if (error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failBlock){
                    failBlock(error, data);
                }
            });
        }else{
            
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:&parseError];
            
            if (parseError){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failBlock){
                        failBlock(parseError, data);
                    }
                });
                
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (successBlock){
                        successBlock(responseDictionary);
                    }
                });
            }
        }
    };
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [_baseURL URLByAppendingPathComponent:@"location"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60.0];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    [urlRequest setHTTPBody:postData];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:completionBlock];
    [dataTask resume];
    
//    [self requestWithMethod:@"POST" relativePath:@"location" successBlock:aSuccessBlock failBlock:aFailblock parameters:params];
}

@end
