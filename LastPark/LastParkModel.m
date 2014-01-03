//
//  LastParkModel.m
//  LastPark
//
//  Created by Eugene Yakubovich on 12/25/13.
//  Copyright (c) 2013 Eugene Yakubovich. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/NSNotification.h>
#import <BluetoothManager/BluetoothDevice.h>

#import "BluetoothScanner.h"

#import "LastParkModel.h"

NSString * const LPDevicesChangedNotification = @"LPDevicesChangedNotification";
NSString * const LPLastParkUpdatedNotification = @"LPLastParkUpdatedNotification";

@implementation LastParkDevice

@synthesize address = _address;
@synthesize name = _name;
@synthesize selected = _selected;
@synthesize lastLocation = _lastLocation;
@synthesize lastDisconnect = _lastDisconnect;
@synthesize acquiringLoc = _acquiringLoc;

- (id) initWithAddress:(id)address name:(NSString*)name {
    self = [super init];
    
    if( self ) {
        _address = address;
        _name = name;
        _selected = FALSE;
        _lastLocation = nil;
        _lastDisconnect = nil;
        _acquiringLoc = FALSE;
    }

    return self;
}

- (id) initWithDictionary:(NSDictionary*) dict {
    self = [super init];
    
    if( self ) {
        _address = [dict objectForKey:@"address"];
        _name = [dict objectForKey:@"name"];
        
        NSDictionary* loc = [dict objectForKey:@"where"];
        if( loc ) {
            CLLocationDegrees lat = [[loc objectForKey:@"lat"] doubleValue];
            CLLocationDegrees lng = [[loc objectForKey:@"lng"] doubleValue];
            _lastLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        }
        else
            _lastLocation = nil;
        
        _lastDisconnect = [dict objectForKey:@"when"];
        _selected = TRUE;
        _acquiringLoc = FALSE;
    }
    
    return self;
    
}

- (NSDictionary*) asDictionary {
    if( _lastLocation && _lastDisconnect ) {
        return @{
            @"address": _address,
            @"name": _name,
            @"where": @{
                @"lat": [NSNumber numberWithDouble: _lastLocation.coordinate.latitude],
                @"lng": [NSNumber numberWithDouble: _lastLocation.coordinate.longitude]
            },
            @"when": _lastDisconnect
        };
    }
    else {
        return @{
            @"address": _address,
            @"name": _name,
        };
    }
}

@end

// ========================================================================

@interface LastParkModel () {
    CLLocationManager* locationMgr;
    NSTimer* stopTimer;
    BluetoothScanner* bluetoothScanner;
}
@end

@implementation LastParkModel

@synthesize devices = _devices;

- (id) init {
    self = [super init];
    
    if( self ) {
        // found this online: since it's not possible to call startUpdatingLocation
        // in the background, start it now but set the accuracy to 3km. That will just
        // use cell towers and avoid using the GPS
        locationMgr = [[CLLocationManager alloc] init];
        locationMgr.delegate = self;
        locationMgr.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        locationMgr.distanceFilter = 3000;
        [locationMgr startUpdatingLocation];
        
        stopTimer = nil;
        bluetoothScanner = [[BluetoothScanner alloc] initWithDelegate:self];
        
        _devices = [[NSMutableArray alloc] init];
        [self load];
    }
    
    return self;
}

- (void) load {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSArray* devices = [defaults arrayForKey:@"devices"];
    
    for( NSDictionary* deviceDesc in devices ) {
        LastParkDevice* device = [[LastParkDevice alloc] initWithDictionary:deviceDesc];
        [_devices addObject:device];
    }
}

- (void) save {
    NSMutableArray* savedDevices = [NSMutableArray array];

    for( LastParkDevice* device in _devices ) {
        if( device.selected ) {
            [savedDevices addObject:[device asDictionary]];
        }
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:savedDevices forKey:@"devices"];
    [defaults synchronize];
}

- (void)addBluetoothDevice:(BluetoothDevice *)bluetoothDevice {
    // use network address as a key
    NSUInteger index = [_devices indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL* stop) {
        return [bluetoothDevice.address isEqual:((LastParkDevice*) obj).address];
    }];
    
    if( index == NSNotFound ) {
        LastParkDevice* device = [[LastParkDevice alloc] initWithAddress:bluetoothDevice.address name:bluetoothDevice.name];
        [_devices addObject:device];
    }
    else {
        LastParkDevice* device = [_devices objectAtIndex:index];
        if( ![device.name isEqualToString:bluetoothDevice.name] ) {
            // hmm, name changed for some reason -- update it
            device.name = bluetoothDevice.name;
        }
        else
            return;
    }
    
    [self fireDevicesChanged];
}

- (void)removeBluetoothDevice:(BluetoothDevice *)bluetoothDevice {
    NSUInteger index = [_devices indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL* stop) {
        return [bluetoothDevice.address isEqual:((LastParkDevice*) obj).address];
    }];
    
    if( index == NSNotFound ) {
        NSLog(@"removed device not found in our list: %@", bluetoothDevice.name);
        return;
    }

    LastParkDevice* device = [_devices objectAtIndex:index];
    if( device.selected ) {
        device.lastDisconnect = [[NSDate alloc] init];
        device.acquiringLoc = TRUE;

        [self startAcquireLocation];
    }
    else {
        [_devices removeObjectAtIndex:index];
        [self fireDevicesChanged];
    }
}

- (void) fireDevicesChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName:LPDevicesChangedNotification object:self];
}

- (void) fireLastParkUpdated {
    [[NSNotificationCenter defaultCenter] postNotificationName:LPLastParkUpdatedNotification object:self];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if( !stopTimer )
        return; // not acquiring position
    
    CLLocation* location = [locations lastObject];
    
    NSLog(@"New location, accuracy=%f", location.horizontalAccuracy);
    
    if( location.horizontalAccuracy < 55.0 ) {
        for( LastParkDevice* device in _devices ) {
            if( device.acquiringLoc ) {
                device.lastLocation = location;
                device.acquiringLoc = FALSE;
            }
        }
        
        [self fireLastParkUpdated];
        [self stopAcquireLocation];
        [self save];
    }
}

- (void)startAcquireLocation {
    if( !stopTimer ) {
        // location manager is already running.
        // just increase the desired accuracy to turn up the GPS
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest;
        locationMgr.distanceFilter = 5;
        locationMgr.pausesLocationUpdatesAutomatically = FALSE;
        stopTimer = [NSTimer scheduledTimerWithTimeInterval:180 target:self selector:@selector(timerFired:) userInfo:nil repeats:FALSE];
    }
}

- (void)stopAcquireLocation {
    // Not really stopping -- just drop the desired accuracy to avoid using GPS
    locationMgr.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    locationMgr.distanceFilter = 3000;
    locationMgr.pausesLocationUpdatesAutomatically = TRUE;
    [stopTimer invalidate];
    stopTimer = nil;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"failed to acquire location: %@", error.description);
}

- (void)timerFired:(NSTimer*)timer {
    NSLog(@"timed out acquiring accurate location");
    
    // failed to acquire loc in given time period.
    // stop doing that to avoid draining battery and
    // getting wrong position as the user probably walked
    // off too far
    [self stopAcquireLocation];
}

@end
