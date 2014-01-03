//
//  DevicesViewController.m
//  LastPark
//
//  Created by Eugene Yakubovich on 12/26/13.
//  Copyright (c) 2013 Eugene Yakubovich. All rights reserved.
//

#import "DevicesViewController.h"
#import "LastParkModel.h"

@implementation DevicesViewController

@synthesize model = _model;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(devicesChanged:) name:LPDevicesChangedNotification object:nil];
}

- (void) viewDidDisappear:(BOOL)animated {
    [_model save];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _model.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];

    LastParkDevice* device = [self.model.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;

    if( device.selected )
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LastParkDevice* device = [self.model.devices objectAtIndex:indexPath.row];
    device.selected = !device.selected;
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if( device.selected )
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void) devicesChanged:(NSNotification*)notification {
    [self.tableView reloadData];
}

@end
