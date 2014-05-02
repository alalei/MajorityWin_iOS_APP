//
//  _ViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-14.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "_ViewController.h"

@interface _ViewController ()

@end

@implementation _ViewController

// Click creat room button
//      send request of create room to server
- (IBAction)creatRoom:(id)sender {
    
    [self startRequest:[REST_CREAT_ROOM stringByAppendingFormat:@"?username=%@&roomsize=%d",gUsername,gRoomSize]];
}

// Act after get response from server
- (void)afterGetResponse
{
    [super afterGetResponse];
    
    // Check whether room number is legal
    gRoomNO = gResponseString;
    if (![self isDecimal:gRoomNO] && gErrorType == ERROR_DATA_FORMAT){
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Data Error"
                              message:@"Error: data Format is wrong"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"OK",nil];
        [alert show];
        return;
    }
    if (DEBUG_NETWORKING) {
        NSLog(@"RoomNo: %@", gRoomNO);
    }
    
    [self performSegueWithIdentifier:@"VC2CRVC" sender:self];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set background
    UIImage *image = [UIImage imageNamed:@"Background.jpg"];
    self.view.layer.contents = (id) image.CGImage;
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;    
    
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // Clear app global parameters
    gResponseString = nil;
    gRoomNO = 0;
    gRoomCreator = false;
    gLeader = nil;
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
