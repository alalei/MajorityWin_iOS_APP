//
//  VoteResultViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-17.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "VoteResultViewController.h"

@interface VoteResultViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelFinished;
@property (weak, nonatomic) IBOutlet UILabel *labelMarjorityAgreed;
@property (weak, nonatomic) IBOutlet UILabel *labelText;

@end

@implementation VoteResultViewController

int roomStatus2 = ROOMSTATUS_OTHER;
bool toNexrRound = false;

// Display status
-(void)textDisplay:(UILabel *)textField currentStatus:(NSString *)status {
    [textField setText:status];
}

// Click done button
- (IBAction)finished:(id)sender {
    // jump to main page
    [self exitVote:self NSString:@"VRVC2VC" ];
}

// Click next round button
- (IBAction)nextRound:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self nextRoundRequest];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{[self nextRoundAction];}
                                      );
                   }
                   );
}

- (void) nextRoundRequest
{
    NSString *url = [REST_NEXT_ROUND stringByAppendingFormat:@"?username=%@&roomID=%@",gUsername,gRoomNO];
    NSString * response;
    
    toNexrRound = false;
    response = [self startSynRequest:url verboseMode:true];
    
    if (response == nil) {
        NSLog(@"failed to go to next round");
        return;
    }
    
    if (DEBUG_NETWORKING) NSLog(@"next round: response: %@", response);
    if ([response isEqualToString:REST_NEXT_ROUND_SUCCESS]){
        toNexrRound = true;
        NSLog(@"succeed to go to next round");
        
        //gLeader will be used in next round
        gResponseString = nil;
        if([gLeader isEqual:gUsername]){
            gRoomCreator = true;
        } else {
            gRoomCreator = false;
        }
    }
}

- (void) nextRoundAction
{
    if (DEBUG_DISPLAY) {
        NSLog(@"toNextRound: %s", toNexrRound?"true":"false");
    }
    if (toNexrRound) {
        [self performSegueWithIdentifier:@"VRVC2WFVVC" sender:self];
        toNexrRound = false;
    }
    
}

// Click twitter button
- (IBAction)postTweet:(id)sender
{
    // check if it has twitter service
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        // retrieve required info
        UIDevice *myDevice = [UIDevice currentDevice];
        NSString *model = [myDevice model];
        NSString *systemVersion = [myDevice systemVersion];
        NSDate *currentTime = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        NSString *dateOutput = [dateFormatter stringFromDate:currentTime];
        NSString *result = [NSString stringWithFormat:@"By MajorityWin--Voting result: for the topic "];
        NSLog(@"%@ from %@  %@ at %@", result, model, systemVersion, dateOutput);
        NSString *tweet = [NSString stringWithFormat: @"%@ from %@  %@ at %@", result, model, systemVersion, dateOutput];
        
        [tweetSheet setInitialText:tweet];
        [self presentViewController:tweetSheet animated:YES completion:nil];
        
    } else {
        // no twitter service
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No twitter service" message:@"Please set twitter service first" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
    }
}


// Thread to refresh vote results
- (void) requestThread
{
    // wait for others to finished voting
    if (DEBUG_VERBOSE) NSLog(@"enter requestThread");
    roomStatus2 = ROOMSTATUS_APP_PENDING;
    int mostValidTime = 10000;
    
    while ( mostValidTime>0 && roomStatus2!= ROOMSTATUS_FINISH_VOTE ){
        mostValidTime--;
        
        // check room status
        int requestCounter = 3;
        int errorCounter = 3;
        int statusFromServer ;
        NSString *url = [REST_WAIT_FOR_RESULT stringByAppendingFormat:@"?roomID=%@",gRoomNO];
        NSString * response;
        while (errorCounter>=0) {
            errorCounter--;
            [NSThread sleepForTimeInterval:1];  // seconds
            response = [self requestServeralTimes:url requestCounter:(int)requestCounter];
            if (response != nil) {
                // check whether all members voted
                NSString *statusStr = [self getParaFromJSON:(NSString *)response key:@"status"];
                NSString *numOfFinished = [self getParaFromJSON:(NSString *)response key:@"numOfFinished"];
                NSString *numOfMajority = [self getParaFromJSON:(NSString *)response key:@"numOfMajority"];
                NSString *result = [self getParaFromJSON:(NSString *)response key:@"result"];
                
                if ( statusStr==nil && numOfFinished==nil && numOfMajority==nil) {
                    gErrorType = ERROR_INVALID_SERVICE;
                    if (errorCounter<0 ) {
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle:@"Error"
                                              message:@"Service is not available. Please check your account and submit again."
                                              delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK",nil];
                        [alert show];
                        return;
                    }
                }
                if (numOfFinished!=nil && numOfMajority!=nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self textDisplay:self.labelFinished currentStatus:[@"" stringByAppendingFormat:@"Finished: %@/%@", numOfFinished,numOfFinished]];
                        [self textDisplay:self.labelMarjorityAgreed currentStatus:[@"" stringByAppendingFormat:@"Marjority Agreed: %@/%@", numOfMajority, numOfFinished]];
                    });
                }
                
                statusFromServer = [statusStr intValue];
                if (DEBUG_JSON) {
                    NSLog(@"statusFromServer= %d, numOfFinished=%@ ,numOfMajority=%@", statusFromServer, numOfFinished, numOfMajority);
                }
                if (statusFromServer == ROOMSTATUS_FINISH_VOTE) {
                    if (DEBUG_VERBOSE) {
                        NSLog(@"vote seult: %@", result);
                    }
                    // display final vote result and jump out of refreshing loop
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self textDisplay:self.labelText currentStatus:[@"" stringByAppendingFormat:@"Vote finished: %@", result]];
                    });
                    roomStatus2 = ROOMSTATUS_FINISH_VOTE;
                    return;
                }
            }
        }
        
        if ( response == nil ){
            if (DEBUG_VERBOSE) NSLog(@"return false in requestServeralTimes");
            return;
        }
    }
}

- (void) updateUIWithResult
{
    if (roomStatus2 == ROOMSTATUS_FINISH_VOTE) {
        NSLog(@"finished voting");
    } else {
        NSLog(@"roomStatus is wrong: roomStatus ==%d", roomStatus2);
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    toNexrRound = false;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self requestThread];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{[self updateUIWithResult];}
                                      );
                   }
      );
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set background
    UIImage *image = [UIImage imageNamed:@"Background.jpg"];
    self.view.layer.contents = (id) image.CGImage;
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
