//
//  MainViewController.h
//  LastPark
//
//  Created by Eugene Yakubovich on 12/23/13.
//  Copyright (c) 2013 Eugene Yakubovich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "LastParkModel.h"

@interface MainViewController : UIViewController <MKMapViewDelegate>

@property LastParkModel* model;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
