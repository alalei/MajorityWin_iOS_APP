//
//  VoteViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-18.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "VoteViewController.h"

@interface VoteViewController ()

@property NSArray *options;
@property NSInteger rowNum;
@property (weak, nonatomic) IBOutlet UILabel *labelTopic;
@property (weak, nonatomic) IBOutlet UIPickerView *votePicker;
@property (weak, nonatomic) IBOutlet UILabel *labelFinished;
@property (weak, nonatomic) IBOutlet UILabel *labelMarjorityAgreed;

// json object
@property NSData *jsonData;

@end

@implementation VoteViewController

int roomStatus = ROOMSTATUS_OTHER;
bool userFinishedVote = false;

// Display status
-(void)textDisplay:(UILabel *)textField currentStatus:(NSString *)status {
    [textField setText:status];
}

// Display PickerView
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.options count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.options[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
}


// Click exit button
- (IBAction)exitVoteVVC:(id)sender {
    [self exitVote:self NSString:@"VVC2VC"];
}


// Click vote button
- (IBAction)vote:(id)sender {
    NSString *choiceVoted;
    
    // rowNum: option index
    self.rowNum = [_votePicker selectedRowInComponent:0];
    gVotedOption = self.rowNum;
    NSLog(@"enter vote result");
    
    // print the row and content for selected option
    NSString *rowString = [NSString stringWithFormat:@"%li", (long)self.rowNum];
    NSLog(@"The row is %@", rowString);
    choiceVoted = [self.options objectAtIndex:self.rowNum];
    NSLog(@"The selecte one is %@", choiceVoted);
    
    // option selected alert
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Your choice is" message:[@"option" stringByAppendingFormat:@" %d: %@", gVotedOption+1, choiceVoted] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
    [alert show];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self requestThread];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{[self updateUIWithResult];}
                                      );
                   }
                   );
    
}


// Thread to send vote to server
- (void) requestThread
{
    // submit vote
    userFinishedVote = true;
    if (DEBUG_VERBOSE) NSLog(@"enter requestThread");
    roomStatus = ROOMSTATUS_APP_PENDING;
    int requestCounter = 3;
    int errorCounter = 3;
    
    // submit topic (question)
    NSString *url = [REST_SUBMIT_VOTE stringByAppendingFormat:@"?roomID=%@&option=%d",gRoomNO, gVotedOption];
    NSString * response;
    while (errorCounter>=0) {
        errorCounter--;
        response = [self requestServeralTimes:url requestCounter:(int)requestCounter];
        if (response != nil) {
            if ([response isEqualToString:REST_SUBMIT_VOTE_SUCCESS] ) {
                gErrorType = NO_ERROR;
                break;
            } else {
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
        }
        [NSThread sleepForTimeInterval:0.5];// seconds
    }
    
    if ( response == nil ){
        if (DEBUG_VERBOSE) NSLog(@"return false in requestServeralTimes");
        return;
    }
    
    roomStatus = ROOMSTATUS_FINISH_VOTE;
}


// Action after sending vote to server
- (void) updateUIWithResult
{
    if (roomStatus == ROOMSTATUS_FINISH_VOTE) {
        [self performSegueWithIdentifier:@"VVC2VRVC" sender:self];
    }
    else {
        NSLog(@"submit: wrong roomStatus: %d", roomStatus);
    }
}


// Set topic
-(void)setTopic:(NSString *)topic
{
    [[self labelTopic] setText:topic];
    NSLog(@"The topic is %@", topic);
}


// Thread to display the change of participants dynamically
- (void) refreshView
{
    [NSThread sleepForTimeInterval:1];// seconds
    // submit vote
    if (DEBUG_DISPLAY) NSLog(@"enter refreshView");
    int mostValidTime = 10000;
    
    while ( mostValidTime>0 && !userFinishedVote){
        mostValidTime--;
        [NSThread sleepForTimeInterval:0.5];    // seconds
        
        // check room status
        int requestCounter = 3;
        int errorCounter = 3;
        int statusFromServer ;
        NSString *url = [REST_WAIT_FOR_RESULT stringByAppendingFormat:@"?roomID=%@",gRoomNO];
        NSString * response;
        while (errorCounter>=0) {
            errorCounter--;
            [NSThread sleepForTimeInterval:0.5];// seconds
            response = [self requestServeralTimes:url requestCounter:(int)requestCounter];
            if (response != nil) {
                // check whether all members voted
                NSString *statusStr = [self getParaFromJSON:(NSString *)response key:@"status"];
                NSString *numOfFinished = [self getParaFromJSON:(NSString *)response key:@"numOfFinished"];
                NSString *numOfMajority = [self getParaFromJSON:(NSString *)response key:@"numOfMajority"];
                if ( statusStr==nil && numOfFinished==nil && numOfMajority==nil) {
                    gErrorType = ERROR_INVALID_SERVICE;
                    if (errorCounter<0 ) {
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle:@"Error"
                                              message:@"Service is not available. Please return to main page and try again."
                                              delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
                        [alert show];
                        return;
                    }
                }
                if (numOfFinished!=nil && numOfMajority!=nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self textDisplay:self.labelFinished currentStatus:[@"" stringByAppendingFormat:@"Finished: %@/%@", numOfFinished,numOfFinished]];
                        [self textDisplay:self.labelMarjorityAgreed currentStatus:[@"" stringByAppendingFormat:@"Marjority Agreed: %@/%@", numOfMajority, numOfFinished]];
                    });
                    break;
                }
                
                statusFromServer = [statusStr intValue];
                if (DEBUG_JSON) {
                    NSLog(@"statusFromServer= %d, numOfFinished=%@ ,numOfMajority=%@", statusFromServer, numOfFinished, numOfMajority);
                }
            }
            
            if (userFinishedVote) {
                break;
            }
        }
        
        if ( response == nil ){
            if (DEBUG_VERBOSE) NSLog(@"return false in requestServeralTimes");
            return;
        }
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Set background
    UIImage *image = [UIImage imageNamed:@"Background.jpg"];
    self.view.layer.contents = (id) image.CGImage;
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // request topic (question)
    int requestCounter = 3;
    NSString *url = [REST_GET_TOPIC stringByAppendingFormat:@"?roomID=%@",gRoomNO];
    NSString *response = [self requestServeralTimes:url requestCounter:(int)requestCounter];
    if (response == nil){
        if (DEBUG_VERBOSE) NSLog(@"return false in requestServeralTimes");
        return;
    }
    
    // correct escape characters
    response = [response stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    response = [response stringByReplacingOccurrencesOfString:@"\"{" withString:@" {"];
    response = [response stringByReplacingOccurrencesOfString:@"}\"" withString:@"} "];
    if (DEBUG_JSON) NSLog(@"voteView: response: %@",response);
    
    // parse json and get vote topic
    if (response == nil ) {
        if (DEBUG_JSON) NSLog(@"before parsing json: response is nil: %@",response);
        return;
    }
    
    NSError *error;
    self.jsonData = [response dataUsingEncoding:[NSString defaultCStringEncoding]];
    NSDictionary *resultJSONDic = [NSJSONSerialization JSONObjectWithData:_jsonData options:kNilOptions error:&error];
    if (DEBUG_JSON) NSLog(@"NSDictionary: %@",resultJSONDic);
    NSDictionary * voteContents = [resultJSONDic objectForKey:@"questions"];
    if (DEBUG_JSON) NSLog(@"question from NSDictionary: %@",voteContents);
    NSString * topic = [voteContents objectForKey:@"topic"];
    if (DEBUG_JSON) NSLog(@"topic: %@",topic);
    [self setTopic:topic];
   
    // Add to display array
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
    NSString * optionKey = @"option0";
    NSString * option = nil;
    int i = 0;
    while (optionKey!= nil && i <10 ) {
        optionKey = [NSString stringWithFormat:@"option%d",i];
        option = [voteContents objectForKey:optionKey];
        if (DEBUG_JSON) NSLog(@"add to array: option is %@:%@", optionKey, option);
        if (option!= nil) {
            [array addObject:option];
        }
        i++;
    }
    
    // NSMutableArray --> NSArray
    NSArray *optionNSArray = [array copy];
    if (DEBUG_JSON) NSLog(@"optionNSArray: %@",optionNSArray);
    
    // Set picker view content
    self.options = optionNSArray;
    
    // load pickerview
    [self.votePicker reloadAllComponents];
    
    // refresh page (participants)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self refreshView];
                   }
                   );
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
