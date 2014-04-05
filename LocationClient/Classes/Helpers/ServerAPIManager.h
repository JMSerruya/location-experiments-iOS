//
//  ServerAPIManager.h
//  LocationClient
//
//  Created by Ezequiel A Becerra on 4/2/14.
//  Copyright (c) 2014 Ezequiel A Becerra. All rights reserved.
//

#import <Foundation/Foundation.h>

//  Libs
#import <AFNetworking/AFNetworking.h>

//  Frameworks
#import <CoreLocation/CoreLocation.h>

typedef void(^SuccessBlock)(NSDictionary *successDict);
typedef void(^FailBlock)(NSError *error, NSData *dataReturned);

@interface ServerAPIManager : NSObject{
    NSURL *_baseURL;
    AFHTTPRequestOperationManager *_operationManager;    
}

+ (instancetype)sharedInstance;

- (void)postLocation:(CLLocationCoordinate2D)coords
        successBlock:(SuccessBlock)aSuccessBlock
           failBlock:(FailBlock)aFailblock;
@end
