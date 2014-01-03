//
//  MainViewController.m
//  LastPark
//
//  Created by Eugene Yakubovich on 12/23/13.
//  Copyright (c) 2013 Eugene Yakubovich. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocationManager.h>

#import "MainViewController.h"
#import "LastParkModel.h"
#import "DevicesViewController.h"

@interface MainViewController () {
    BOOL mapPositioned;
}
@end

@implementation MainViewController

@synthesize model = _model;

- (MainViewController*) init {
    self = [super init];

    if( self ) {
        // TODO: need better map positioning logic
        mapPositioned = FALSE;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];    
	// Do any additional setup after loading the view, typically from a nib.

    // not the best place to own a model
    self.model = [[LastParkModel alloc] init];
    
    self.mapView.delegate = self;
    
    [self placePins];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lastParkUpdated:) name:LPLastParkUpdatedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    CLLocationCoordinate2D pos = _mapView.userLocation.location.coordinate;
    
    if( pos.latitude != 0.0 && pos.longitude != 0.0 ) {
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(pos, 500, 500);
        [_mapView setRegion:viewRegion animated:YES];
        
        mapPositioned = TRUE;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if( !mapPositioned ) {
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 500, 500);
        [_mapView setRegion:viewRegion animated:YES];
        
        mapPositioned = TRUE;
    }
}

- (void)placePins {
    for( LastParkDevice* device in _model.devices ) {
        if( device.selected ) {
            MKPointAnnotation* pin = [[MKPointAnnotation alloc] init];
            pin.coordinate = device.lastLocation.coordinate;
            pin.title = device.name;
            pin.subtitle = [NSDateFormatter localizedStringFromDate:device.lastDisconnect
                                                          dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
            
            [self.mapView addAnnotation:pin];
        }
    }
}

- (void)lastParkUpdated:(NSNotification*)notification {
    // clear all annotations
    [_mapView removeAnnotations:_mapView.annotations];
    [self placePins];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"LPPin";

    if (![annotation isKindOfClass:[MKPointAnnotation class]])
        return nil;
    
    MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if( annotationView == nil ) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        annotationView.image = [UIImage imageNamed:@"pin.png"];
    } else {
        annotationView.annotation = annotation;
    }
        
    return annotationView;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DevicesViewController *devicesController = segue.destinationViewController;
    devicesController.model = _model;
}

@end
