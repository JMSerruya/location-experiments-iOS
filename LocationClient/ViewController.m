//
//  ViewController.m
//  LocationClient
//
//  Created by Ezequiel A Becerra on 4/2/14.
//  Copyright (c) 2014 Ezequiel A Becerra. All rights reserved.
//

#import "ViewController.h"

//  Helpers
#import "ServerAPIManager.h"

@interface ViewController ()
- (void)sendCoordinate:(CLLocationCoordinate2D)aCoord;
@end

@implementation ViewController

#pragma mark - Private

- (void)sendCoordinate:(CLLocationCoordinate2D)aCoord{
    SuccessBlock aSuccessBlock = ^(NSDictionary *successDict){
        BOOL success = [successDict[@"success"] boolValue];
        if (success){
            NSLog(@"#DEBUG: Post succeeded");
        }else{
            NSLog(@"#ERROR: %@", successDict[@"message"]);
        }
    };
    
    FailBlock aFailBlock = ^(NSError *error, NSData *dataReturned){
        NSLog(@"#ERROR: %@", [error localizedDescription]);
    };
    
    [[ServerAPIManager sharedInstance] postLocation:aCoord successBlock:aSuccessBlock failBlock:aFailBlock];
    
}

#pragma mark - Public

- (void)viewDidLoad{
    [super viewDidLoad];

    
    //  Geocoder
    _geocoder = [[CLGeocoder alloc] init];
    
    //  Location Manager
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.activityType = CLActivityTypeOther;
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    _locationManager.distanceFilter = 600;
    _locationManager.desiredAccuracy = 100;
    _locationManager.delegate = self;
    
    
    [self addObserver:self forKeyPath:@"isUpdatingLocation" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{

    if ([keyPath isEqualToString:@"isUpdatingLocation"]) {
        
        NSString *titleString = @"Start Updating Location";
        
        if (_isUpdatingLocation){
            titleString = @"Stop Updating Location";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_updateLocationButton setTitle:titleString forState:UIControlStateNormal];
            [_updateLocationButton setTitle:titleString forState:UIControlStateHighlighted];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    @try {
        [self removeObserver:self forKeyPath:@"isUpdatingLocation"];
    }
    @catch (NSException * __unused exception) {
    
    }
}

- (IBAction)updateLocationButtonPressed:(id)sender {
    
    if (!self.isUpdatingLocation){
        self.isUpdatingLocation = YES;
        [_locationManager startUpdatingLocation];
        
    }else{
        self.isUpdatingLocation = NO;
        [_locationManager stopUpdatingLocation];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    if ([locations count] > 0){
        CLLocation *newLocation = locations[0];
        
        if (CLLocationCoordinate2DIsValid(newLocation.coordinate)){
            
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            
            //  Get reverse geocoding
            [geocoder reverseGeocodeLocation:newLocation
                           completionHandler:^(NSArray *placemarks, NSError *error) {
                               
                               if ([placemarks count] > 0 && !error){
                                   CLPlacemark *placemark = [placemarks lastObject];
                                   
                                   //  Update to server its location
                                   SuccessBlock successBlock = ^(NSDictionary *successDict){
                                       //  #TODO find out if I should do something with the successful response
                                       if (placemark.subThoroughfare){
                                           _addressLabel.text = [NSString stringWithFormat:@"%@ %@, %@, %@", placemark.subThoroughfare, placemark.thoroughfare, placemark.locality, placemark.ISOcountryCode];
                                       }else{
                                           _addressLabel.text = [NSString stringWithFormat:@"%@, %@, %@", placemark.thoroughfare, placemark.locality, placemark.ISOcountryCode];
                                       }
                                       
                                       NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                       [formatter setDateFormat:@"dd-MM-yyyy hh:mm:ss"];
                                       
                                       
                                       NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
                                       _dateLabel.text = [NSString stringWithFormat:@"Last updated: %@", stringFromDate];
                                       
                                       NSLog(@"Updated location @ %@", newLocation);
                                   };
                                   
                                   FailBlock failBlock = ^(NSError *error, NSData *dataReturned){
                                       //  #TODO do something?
                                   };
                                   
                                   [[ServerAPIManager sharedInstance] postLocation:placemark.location.coordinate
                                                                      successBlock:successBlock
                                                                         failBlock:failBlock];
                                   
                               }else{
                                   NSLog(@"#DEBUG %@ Error:%@", NSStringFromSelector(_cmd), error.debugDescription);
                               }
                           }];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), error.debugDescription);
}
@end
