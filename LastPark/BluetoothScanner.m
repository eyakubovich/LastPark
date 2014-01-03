//
//  BluetoothScanner.m
//  BluetoothScanner
//
//  Created by Michael Dorner on 12.10.13.
//  Copyright (c) 2013 Michael Dorner. All rights reserved.
//

#import <BluetoothManager/BluetoothDevice.h>
#import <BluetoothManager/BluetoothManager.h>


#import "BluetoothScanner.h"

@interface BluetoothScanner ()

@property (nonatomic) BluetoothManager *bluetoothManager;
@property (nonatomic) id<BluetoothScannerProtocol> delegate;

- (void)addNotification;

@end


@implementation BluetoothScanner

- (id)initWithDelegate:(id<BluetoothScannerProtocol>)delegate {
    self = [super init];
    if (self) {
        _bluetoothManager = [BluetoothManager sharedInstance]; //  necessary, do not remove this line, although it is a singleton
        self.delegate = delegate;

        [self addNotification];
    }
    return self;
}


- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceConnectSuccess:) name:@"BluetoothDeviceConnectSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceDisconnectSuccess:) name:@"BluetoothDeviceDisconnectSuccessNotification" object:nil];


    // all available notifications belonging to BluetoothManager I could figure out - not used and therefore implemented in this demo app
    /*
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothPowerChanged:) name:@"BluetoothPowerChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothConnectabilityChanged:) name:@"BluetoothConnectabilityChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceUpdated:) name:@"BluetoothDeviceUpdatedNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDiscoveryStateChanged:) name:@"BluetoothDiscoveryStateChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceDiscovered:) name:@"BluetoothDeviceDiscoveredNotification" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDeviceConnectSuccess:) name:@"BluetoothDeviceConnectSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothConnectionStatusChanged:) name:@"BluetoothConnectionStatusChangedNotification" object:nil];
    */
    
    
    // this helped me very much to figure out the methods mentioned the lines above
    /*
    // credits to http://stackoverflow.com/a/3738387/1864294 :
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                    NULL,
                                    notificationCallback,
                                    NULL,
                                    NULL,  
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    */
}

/*
void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    if ([(NSString*)name characterAtIndex:0] == 'B') { // notice only notification they are associated with the BluetoothManager.framework
        NSLog(@"Callback detected: \n\t name: %@ \n\t object:%@", name, object);
    }
}
*/

- (void)bluetoothDeviceConnectSuccess:(NSNotification *)notification {
    BluetoothDevice *device = (BluetoothDevice *)[notification object];
    NSLog(@"Device connected: Name: %@\n", device.name);
    [self.delegate addBluetoothDevice:[device copy]];
}

- (void)bluetoothDeviceDisconnectSuccess:(NSNotification *)notification {
    BluetoothDevice *device = (BluetoothDevice *)[notification object];
    NSLog(@"Device disconnected: Name: %@\n", device.name);
    [self.delegate removeBluetoothDevice:device];
}


@end
