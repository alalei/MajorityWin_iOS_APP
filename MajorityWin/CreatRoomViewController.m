//
//  CreatRoomViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-17.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "CreatRoomViewController.h"

@interface CreatRoomViewController ()

@property (weak, nonatomic) IBOutlet UILabel *roomNumber;


@end

@implementation CreatRoomViewController


- (IBAction)exitVoteCRVC:(id)sender {
    [self exitVote:self NSString:@"CRVC2VC" ];
}

- (IBAction)enterRoom:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self requestThread];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{[self updateUIWithResult];}
                                      );
                   }
                   );
    gAppStatus = ROOMSTATUS_SELECT_LEADER;
    
}

// Send request of join room ro server
- (void) requestThread{
    NSString *response;
    gErrorType = NO_ERROR;
    
    if ( [self isDecimal:gRoomNO]) {
        response = [self startSynRequest:[REST_JOIN_ROOM stringByAppendingFormat:@"?roomID=%@&username=%@", gRoomNO, gUsername] verboseMode:true];
    }
    else if( gErrorType == ERROR_DATA_FORMAT){
        return;
    }
    
    if (![response isEqualToString:REST_JOIN_ROOM_SUCCESS]) {
        if (DEBUG_ACCOUNT) NSLog(@"response is not REST_JOIN_ROOM_SUCCESS: %@", REST_JOIN_ROOM_SUCCESS);
        gErrorType = ERROR_INVALID_SERVICE;
        return;
    }
}

- (void) updateUIWithResult{
    if (gErrorType == ERROR_INVALID_SERVICE) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:@"Service is not availble. Please check the room number, and try again."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return;
    } else if (gErrorType == ERROR_DATA_FORMAT) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Data Error"
                              message:@"Error: data Format is wrong. Room number is valid digits."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    gRoomCreator = true;
    [self performSegueWithIdentifier:@"CRVC2WFVVC" sender:self];
}

// Display status
-(void)textDisplay:(UILabel *)textField currentStatus:(NSString *)status {
    [textField setText:status];
}


//Resize image
- (UIImage *)resizeImage:(UIImage *)image withQuality:(CGInterpolationQuality)quality rate:(CGFloat)rate
{
    
    UIImage *resized = nil;
    
    CGFloat width = image.size.width * rate;
    CGFloat height = image.size.height * rate;
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Set background
    UIImage *imageB = [UIImage imageNamed:@"Background.jpg"];
    self.view.layer.contents = (id) imageB.CGImage;
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;
    
    // Create room by QRcode
    NSString *theString = gRoomNO;
    
    UIImage *image = [QREncoder encode:theString];
    
    // Resize without interpolating by 5 times larger
    UIImage *resized = [self resizeImage:image
                             withQuality:kCGInterpolationNone
                                    rate:5.0];
    
    // Display the QRcode
    UIImageView *imageView = [[UIImageView alloc] initWithImage:resized];
    imageView.frame = CGRectMake(110, 180, 100, 100);
    [self.view addSubview:imageView];
    
    // Show room number
    NSString *stringRoomNo = [NSString stringWithFormat:@"Room No.: %@", theString];
    [self textDisplay:self.roomNumber currentStatus:stringRoomNo];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



@end
