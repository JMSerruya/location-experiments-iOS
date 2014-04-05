//
//  ViewController.h
//  LocationClient
//
//  Created by Ezequiel A Becerra on 4/2/14.
//  Copyright (c) 2014 Ezequiel A Becerra. All rights reserved.
//

#import <UIKit/UIKit.h>

//  Frameworks
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>{
    CLGeocoder *_geocoder;
    CLLocationManager *_locationManager;
    
    __weak IBOutlet UIButton *_updateLocationButton;
    __weak IBOutlet UILabel *_addressLabel;
    __weak IBOutlet UILabel *_dateLabel;
}

@property (assign) BOOL isUpdatingLocation;

- (IBAction)updateLocationButtonPressed:(id)sender;
@end
