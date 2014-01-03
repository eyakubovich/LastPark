//
//  LastParkModel.h
//  LastPark
//
//  Created by Eugene Yakubovich on 12/25/13.
//  Copyright (c) 2013 Eugene Yakubovich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

#import "BluetoothScanner.h"

extern NSString * const LPDevicesChangedNotification;
extern NSString * const LPLastParkUpdatedNotification;

@interface LastParkDevice : NSObject

@property (nonatomic) id address;
@property (nonatomic) NSString* name;
@property (nonatomic) BOOL selected;
@property (nonatomic) CLLocation* lastLocation;
@property (nonatomic) NSDate* lastDisconnect;
@property (nonatomic) BOOL acquiringLoc;

@end



@interface LastParkModel : NSObject <BluetoothScannerProtocol, CLLocationManagerDelegate>

@property NSMutableArray* devices;

- (void) save;

@end
