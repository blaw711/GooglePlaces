//
//  DetailLocationViewController.h
//  GooglePlaces
//
//  Created by Bob Law on 3/22/14.
//  Copyright (c) 2014 Bob Law. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface DetailLocationViewController : UIViewController

@property (strong, nonatomic) NSString *refenceString;
@property (strong, nonatomic) NSDictionary *place;

@end
