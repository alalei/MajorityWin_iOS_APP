//
//  WaitForVoteViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-17.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "WaitForVoteViewController.h"


@interface WaitForVoteViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelParticipants;
@property (weak, nonatomic) IBOutlet UILabel *roomNumber;
@property (weak, nonatomic) IBOutlet UILabel *roomInfomationLabel;

@end

@implementation WaitForVoteViewController


int commandType = ROOMSTATUS_OTHER;
int requestCounter = 0;
static int roomStatus;
static UIViewController * mainViewController;
bool isLeader;
bool startPickerleader = false;
static UILabel *roomNumber1;
static UILabel *labelParticipants1;
static UILabel *roomInfomationLabel1;
UIAlertView *connectingServerAlert;


// Display status
-(void)textDisplay:(UILabel *)textField currentStatus:(NSString *)status {
    [textField setText:status];
}

- (IBAction)exitVoteWFVVC:(id)sender {
    [self exitVote:self NSString:@"WFVVC2VC" ];
}

- (IBAction)beginVote:(id)sender {
    startPickerleader = true;
    
}

// Thread to refresh room information
//      Used in individual threads for requestLeader and requestStatus in loop
-(void)requestThread
{
    if (DEBUG_VERBOSE) NSLog(@"waitForVoteRoom: enter requestThread");
    gLeader = nil;
    isLeader = false;
    roomStatus = ROOMSTATUS_APP_PENDING;
    int mostValidTime = 600;
    
    while ( mostValidTime> 0 && roomStatus!= ROOMSTATUS_START_VOTE && !isLeader){
        mostValidTime--;
        
        // check room status
        int requestCounter = 3;
        int errorCounter = 5;
        int accumulatedErrorCounter =0;
        NSString *url = nil;
        NSString * response, *response2;
        
        // pick a leader
        if (startPickerleader) {
            if (DEBUG_NETWORKING) NSLog(@"start picking leader");
            response = [self requestServeralTimes:[REST_PICK_LEADER stringByAppendingFormat:@"?roomID=%@",gRoomNO] requestCounter:requestCounter];
            if (DEBUG_NETWORKING) NSLog(@"pick leader: response: %@", response);
            if (response == nil) {
                if (DEBUG_ACCOUNT) NSLog(@"response is nil");
                return;
            }
            if (![response isEqualToString:REST_PICK_LEADER_SUCCESS]) {
                if (DEBUG_ACCOUNT) NSLog(@"response is not REST_PICK_LEADER_SUCCESS: %@", REST_PICK_LEADER_SUCCESS);
                gErrorType = ERROR_INVALID_SERVICE;
                return;
            }
            startPickerleader = false;
        }
        
        while (errorCounter>=0) {
            // Delay times
            [NSThread sleepForTimeInterval:0.2];
            errorCounter--;
            url = [REST_GET_ROOM_INFO stringByAppendingFormat:@"?roomID=%@",gRoomNO];
            response = [self startSynRequest:url verboseMode:false];
            [NSThread sleepForTimeInterval:0.3];
            
            url = [REST_CHECK_LEADER stringByAppendingFormat:@"?roomID=%@",gRoomNO];
            response2 = [self startSynRequest:url verboseMode:false];
            
            if (response != nil || response2 != nil) {
                break;
            }
            if (errorCounter<0) {
                if (DEBUG_VERBOSE) NSLog(@"return false in requestServeralTimes");
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Error"
                                      message:@"Service is not available"
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"OK",nil];
                [alert show];
                return;
            }
            if (DEBUG_NETWORKING) NSLog(@"wait for vote. response: %@", response);
        }
        
        NSString *leader,*status,*participants;
        if (response2!=nil) {
            leader = [self getParaFromJSON:(NSString *)response2 key:@"leader"];
        }
        if (response!=nil) {
            status = [self getParaFromJSON:(NSString *)response key:@"status"];
            participants = [self getParaFromJSON:(NSString *)response key:@"participants"];
        }
        
        // Count continuous errors
        if ( leader==nil && status==nil && participants==nil) {
            accumulatedErrorCounter++;
            if (accumulatedErrorCounter > 8) {
                gErrorType = ERROR_INVALID_SERVICE;
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Error"
                                      message:@"Service is not available"
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"OK",nil];
                [alert show];
                return;
            }
        } else {
            accumulatedErrorCounter = 0;
        }
        
        // Get leader information
        if ( (leader != (id)[NSNull null])) {
            gLeader = leader;
            if ( [leader isEqualToString:gUsername]) {
                isLeader= true;
                // _beginVoteButton.hidden = NO;
                roomStatus = ROOMSTATUS_EDIT_TOPIC;
                NSLog(@"is leader: %@", gUsername);
                break;
            }
            
        }
        
        if (status!= nil && [status intValue] == ROOMSTATUS_START_VOTE) {
            roomStatus = ROOMSTATUS_START_VOTE;
            NSLog(@"is not leader, start vote");
            break;
        }
        
        // Get participants information
        if (participants!=nil) {
            // count the number of participants
            const char *charsinStr = [participants UTF8String];
            int participantsNum = 0;
            for (int i =0; i< participants.length; i++) {
                if (charsinStr[i] == ','){
                    participantsNum ++;
                }
            }
            if (participantsNum < 1){
                participantsNum = 1;
            }
            if (DEBUG_DISPLAY) NSLog(@"participants.length: %lu, %d", participants.length, participantsNum);
            gParticipantsNumber = participantsNum;
            
            // display the change of participants dynamically
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *roomInfo = [@"Waiting...\n\nPeople in the room:\n\n" stringByAppendingFormat:@"%@ ...",participants];
                if (gLeader != nil) {
                    roomInfo = [roomInfo stringByAppendingFormat:@"\nLeader: %@",gLeader];
                }
                
                [self textDisplay:roomInfomationLabel1 currentStatus:roomInfo];
                [self textDisplay:labelParticipants1 currentStatus:[@"" stringByAppendingFormat:@"Participants: %d", participantsNum]];
            });
        }
        
        [NSThread sleepForTimeInterval:0.5];
    }
}

// Do after requestThread
-(void)updateUIWithResult
{
    if (mainViewController == nil) {
        return;
    }
    if (isLeader) {
        // edit topic
        [mainViewController performSegueWithIdentifier:@"WFVVC2VEVC" sender:mainViewController];
    } else if (roomStatus == ROOMSTATUS_START_VOTE){
        // vote
        [mainViewController performSegueWithIdentifier:@"WFVVC2VVC" sender:mainViewController];
    } else {
        if (DEBUG_VERBOSE) NSLog(@"No UI jump, roomStatus = %d", roomStatus);
    }
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Initiate the viewcontroller
    if (gLeader != nil && [gLeader isEqualToString:gUsername]) {
        gRoomCreator = gUsername;
    }
    if (gRoomCreator) {
        _beginVoteButton.hidden = NO;
    } else {
        _beginVoteButton.hidden = YES;
    }
    roomNumber1 = self.roomNumber;
    labelParticipants1 = self.labelParticipants;
    roomInfomationLabel1 = self.roomInfomationLabel;
    isLeader = false;
    startPickerleader = false;
    mainViewController = self;
    
    // set initial display
    [self textDisplay:self.roomNumber currentStatus:[@"Room No.: " stringByAppendingFormat:@"%@",gRoomNO]];
    [self textDisplay:self.labelParticipants currentStatus:[@"" stringByAppendingFormat:@"Participants: 1"]];
    
    // set thread to refresh the view
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self requestThread];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{
                                          [self updateUIWithResult];
                                      }
                                      );
                   }
                   );
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _beginVoteButton.hidden = NO;
    
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
