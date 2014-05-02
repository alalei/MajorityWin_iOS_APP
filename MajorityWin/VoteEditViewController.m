//
//  VoteEditViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-18.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "VoteEditViewController.h"

@interface VoteEditViewController ()
@property (weak, nonatomic) IBOutlet UITextField *labelTopic;
@property (weak, nonatomic) IBOutlet UITextField *labelOptions;
@property (weak, nonatomic) IBOutlet UILabel *optionsDisplay;
@property (weak, nonatomic) IBOutlet UILabel *labelTimer;


@property NSString *topicContent;
@property NSString *optionsContent;
@property NSMutableArray *arrayOptions;
@property NSString *option1;
@property NSString *option2;
@property NSString *option3;
@property NSMutableString *labelOptionsNew;

// Json Object
@property NSData *jsonData;

@end

@implementation VoteEditViewController

int roomStatus;
int requestCounter;
int errorCounter;
NSString *sendJsonData;
static UIViewController * voteEditViewControllerRef;
bool isExitToMain = false;
float timeInterval= 1;
int timeCounter = 120;
NSTimer * timer = nil;

// Click on add button
- (IBAction)addOptions:(id)sender {
    [self createOptionsArray:[self getText:self.labelOptions]];
    [self concatenateOpions];
    [[self optionsDisplay]setText:self.labelOptionsNew];
    [[self labelOptions]resignFirstResponder];
}

// Dismiss keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view]endEditing:YES];
}

// Click on done button
//      If the topic is not null, create Json object, otherwise do nothing
- (IBAction)editDone:(id)sender {
    
    if (self.arrayOptions == NULL || self.arrayOptions == nil || self.arrayOptions.count == 0) {
        
        if (timer!=nil){
            [timer invalidate];
            timer = nil;
        }
        
        // dismiss the keyboard
        [[self labelTopic]resignFirstResponder];
        [[self labelOptions]resignFirstResponder];
        
        // Show alert message for no options created
        NSLog(@"Please add options first!");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No options" message:@"Please create options first!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
        
    } else {
        
        // get topic
        self.topicContent = [self getText:self.labelTopic];
        NSLog(@"Place is %@ ", self.topicContent);
        [[self labelTopic]resignFirstResponder];
        [[self labelOptions]resignFirstResponder];
        
        if (self.topicContent.length != 0) {
            // create Json object
            NSData *jsonNSData = [self createJson];
            sendJsonData = [[NSString alloc] initWithData:jsonNSData encoding:NSUTF8StringEncoding];
            if (DEBUG_JSON) NSLog(@"json to string: %@",sendJsonData);
            voteEditViewControllerRef = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                           ^{
                               [self requestThread];
                               dispatch_async(dispatch_get_main_queue(),
                                              ^{[self updateUIWithResult];}
                                              );
                           }
                           );
            gAppStatus = ROOMSTATUS_EDIT_TOPIC;
        }
    }
}

// Thread to submit edited theme
 - (void) requestThread
{
    roomStatus = ROOMSTATUS_APP_PENDING;
    requestCounter = 3;
    errorCounter = 3;
    
    // submit topic/question
    NSString *url = [REST_SUBMIT_QUESTION stringByAppendingFormat:@"?roomID=%@&question=%@",gRoomNO,sendJsonData];
    NSString * response;
    while (errorCounter>=0) {
        errorCounter--;
        response = [self requestServeralTimes:url requestCounter:(int)requestCounter];
        if (response != nil) {
            if ([response isEqualToString:REST_SUBMIT_QUESTION_SUCCESS] ) {
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
    
    roomStatus = ROOMSTATUS_START_VOTE;
}

// Update after submitting edited theme
 - (void) updateUIWithResult
{
    if (voteEditViewControllerRef == nil) {
        return;
    }
    
    if (roomStatus == ROOMSTATUS_START_VOTE){
        // jump to vote view
        NSLog(@"before performSegueWithIdentifier, voteEditViewController: %@", voteEditViewControllerRef);
        [voteEditViewControllerRef performSegueWithIdentifier:@"VEVC2VVC" sender:voteEditViewControllerRef];
    } else {
        
    }

}

// Click on exit button
- (IBAction)exitVoteVEVC:(id)sender {
    if (timer != nil){
        [timer invalidate];
        timer = nil;
    }
    
    isExitToMain = true;
    voteEditViewControllerRef = self;
    UIActionSheet * actionSheet = [[UIActionSheet alloc]
                                   initWithTitle:@"Are you sure to exit voting?"
                                   delegate:self
                                   cancelButtonTitle:@"No ~"
                                   destructiveButtonTitle:@"Yes, I'm sure."
                                   otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic; // set style
    
    [actionSheet showInView:self.view];
}

// Click on giveup leader button
- (IBAction)giveUpLeader:(id)sender {
    if (timer != nil){
        [timer invalidate];
        timer = nil;
    }
    
    // if the user is leader, request needed to sent to server
    isExitToMain = false;
    voteEditViewControllerRef = self;
    UIActionSheet * actionSheet = [[UIActionSheet alloc]
                                   initWithTitle:@"will you give up to be leader?"
                                   delegate:self
                                   cancelButtonTitle:@"No ~"
                                   destructiveButtonTitle:@"Yes, I'm sure."
                                   otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic; // set style
    
    [actionSheet showInView:self.view];
}

// act after user clicking exit button or giveup leader button
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0){ // click "Yes"
        if (isExitToMain){
            // clicked "Exit Vote" button
            isExitToMain = false;
            gRestart = true;
            [voteEditViewControllerRef performSegueWithIdentifier:@"VEVC2VC" sender:voteEditViewControllerRef];
        }
        else {
            // clicked "Give Up" button
            [self giveupLeaderRequest];
            
        }
     }
}

- (void) giveupLeaderRequest
{
    NSString *url = [REST_GIVE_UP_LEADER stringByAppendingFormat:@"?roomID=%@&currentLeader=%@",gRoomNO,gUsername];
    NSString * response;
    
    // response is new leader's name
    response = [self startSynRequest:url verboseMode:true];
    
    if (response == nil) {
        NSLog(@"failed to give up leader");
        return;
    }
    
    NSLog(@"give up leader: response: %@", response);
    if (![response isEqualToString:gUsername]){
        gLeader = response;
        [NSThread sleepForTimeInterval:1];
        NSLog(@"succeed to give up leader");
        gLeader = nil;
    }
    
    [voteEditViewControllerRef performSegueWithIdentifier:@"VEVC2WFVVC" sender:voteEditViewControllerRef];
}



// Create options array
//      If the option is null, don't add it into the array
-(void)createOptionsArray:(NSString *)option {
    if (option.length != 0) {
        [self.arrayOptions addObject:option];
    }
    for (NSObject * object in self.arrayOptions){
        NSLog(@"The options are : %@", object);
    }
}

// Concatenate options label
-(void)concatenateOpions {
    NSMutableString *labelOptions = [[NSMutableString alloc] init];
    for (NSObject *object in self.arrayOptions) {
        [labelOptions appendString:(NSString *)object];
        [labelOptions appendString:@".\n"];
        NSLog(@"The options are : %@", object);
    }
    self.labelOptionsNew = labelOptions;
}

// Create Json
-(NSData *) createJson {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    // Set topic
    [dictionary setValue:self.topicContent forKey:@"topic"];
    
    // Set options options
    NSInteger objectNo = [self.arrayOptions count];
    
    for (int i = 0; i < objectNo; i++) {
        NSString *optionKey = [NSString stringWithFormat:@"option%d", i];
        NSString *optionValue = [self.arrayOptions objectAtIndex:i];
        [dictionary setObject:optionValue forKey:optionKey];
        NSLog(@"The key is %@ and the value is %@", optionKey, optionValue);
    }
    
    self.jsonData = nil;
    if ([NSJSONSerialization isValidJSONObject:dictionary]) {
        NSError *error;
        //self.jsonData= [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
        self.jsonData= [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
        NSLog(@"Register JSON:%@",[[NSString alloc] initWithData:self.jsonData encoding:NSUTF8StringEncoding]);
    }
    return self.jsonData;
}


// implement getText method
- (NSString *)getText: (UITextField *) textFieldName {
    
    // original string
    NSString *textContent = [textFieldName text];
    // trim estra space and return
    NSString *textContentTrim =[textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
    // alert content
    NSString *message;
    NSString *title;
    
    if (textContentTrim == NULL || textContentTrim == nil || textContentTrim.length == 0)
    {
        // if content is null
        title = @"Failure";
        message = @"Please fill in the content";
        
    } else {
        // if content not null
        [textFieldName setText:@""];
        return textContentTrim;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
    [alert show];
    
    NSLog(@"The original content is %@", textContent);
    NSLog(@"The trimed content is %@", textContentTrim);
    return textContentTrim;
}

// Time counter
//      count down time for editing vote. Refresh the time field in view controller every second
//      if time up, leave VoteEdit view
- (void) counter
{
    timeCounter = (int) (timeCounter - timeInterval);
    if (timeCounter >=0) {
        [self.labelTimer setText:[@"" stringByAppendingFormat:@"Time: %d s",timeCounter]];
    }
    
    if (timeCounter<=0) {
        if (DEBUG_VERBOSE) {
            NSLog(@"Time up");
        }
        if (timer != nil){
            [timer invalidate];
            timer = nil;
        }
        
        // if the user is leader, request needed to be sent to server
        isExitToMain = false;
        voteEditViewControllerRef = self;
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:nil
                              message:@"Time is out. New leader will be selected"
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        [self giveupLeaderRequest];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    // viewDidLoad is called exactly once, when the view controller is first loaded into memory
    // viewDidAppear is called when the view is actually visible, and can be called multiple times during the lifecycle of a View Controller
    
    [super viewDidAppear:animated];
    voteEditViewControllerRef = self;
    
    // set timer (limits time for editing vote)
    timeInterval= 1;
    timeCounter = 120;
    if (timer!= nil) {
        [timer invalidate];
    }
    timer =[NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(counter) userInfo:nil repeats:YES];
    [self.labelTimer setText:[@"" stringByAppendingFormat:@"Time: %d s",timeCounter]];
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
    
    // Set background
    UIImage *image = [UIImage imageNamed:@"Background.jpg"];
    self.view.layer.contents = (id) image.CGImage;
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;
    
    self.arrayOptions = [NSMutableArray arrayWithCapacity:10];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Click “add” button
- (IBAction)editVote:(id)sender {
    
}

@end
