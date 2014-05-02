//
//  BaseViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-17.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@property (strong, nonatomic) NSMutableData *responseData;

@end

// REST API parameters for server-client protocol
extern NSString * const serverURL = @"http://majoritywinmobile.appspot.com/";
extern NSString * const REST_REGISTER_USER = @"Register";
extern NSString * const REST_SIGN_IN = @"Login";
extern NSString * const REST_REGISTER_SUCCESS = @"OK";
extern NSString * const REST_SIGNIN_SUCCESS = @"OK";
extern NSString * const REST_CREAT_ROOM = @"CreateRoom";
extern NSString * const REST_JOIN_ROOM = @"JoinRoom";
extern NSString * const REST_GET_ROOM_INFO = @"GetRoomInfo";
extern NSString * const REST_PICK_LEADER = @"PickLeader";
extern NSString * const REST_PICK_LEADER_SUCCESS = @"OK";
extern NSString * const REST_GIVE_UP_LEADER = @"GiveUpLeader";
extern NSString * const REST_CHECK_LEADER = @"CheckQuestionStatus";
extern NSString * const REST_JOIN_ROOM_SUCCESS = @"OK";
extern NSString * const REST_CHECK_SUBMIT = @"CheckSubmitStatus";
extern NSString * const REST_SUBMIT_QUESTION = @"SubmitQuestion";
extern NSString * const REST_SUBMIT_QUESTION_SUCCESS = @"OK";
extern NSString * const REST_GET_TOPIC = @"CheckQuestionStatus";
extern NSString * const REST_SUBMIT_VOTE = @"SubmitVote";
extern NSString * const REST_SUBMIT_VOTE_SUCCESS = @"OK";
extern NSString * const REST_SUBMIT_SUCCESS = @"OK";
extern NSString * const REST_WAIT_FOR_RESULT = @"CheckSubmitStatus";
extern NSString * const REST_NEXT_ROUND = @"StartNewRound";
extern NSString * const REST_NEXT_ROUND_SUCCESS = @"OK";

// global app parameters
extern NSString *gUsername = nil;
extern NSString *gRoomNO = nil;
extern int gAppStatus = ROOMSTATUS_BEFORE_START;
extern NSString *gResponseString = nil;
extern int gErrorType = NO_ERROR;
extern int gRoomSize = 50;
extern NSError *gError = nil;
extern NSString *gLeader = nil;
extern bool gRestart = false;
extern int gVotedOption =1;
extern bool gRoomCreator = false;
extern int gParticipantsNumber = 0;



@implementation BaseViewController

/* ----- server-client interaction ----- */

UIAlertView *connectingServerAlert = nil;

// response method after startRequest: API to be implemented in subclasses
- (void) afterGetResponse {}

// Asynchronized method to send requests and get response
//      Used for large data and unblocking requesting in UIViewcontroller
- (void) startRequest:(NSString *)restCommand
{
    gResponseString = nil;
    NSString *url = [serverURL stringByAppendingFormat:@"/%@", restCommand];
    NSURL *myURL = [NSURL URLWithString:url];
    NSTimeInterval timeoutInt = 5;  // timeout: senconds
    NSURLRequest *myRuquest = [NSURLRequest requestWithURL:myURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInt];
    if (DEBUG_VERBOSE) {
       NSLog(@"url = %@, timeoutInterval = %f", myURL, timeoutInt);
    }
    NSURLConnection *connection = [ [NSURLConnection alloc] initWithRequest:myRuquest delegate:self];
    if (connection) {
        _responseData = [NSMutableData new];
    }
    
    connectingServerAlert = [self showConnectingServerAlert];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // put data intos cache
    [_responseData appendData:data];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *responseString = [[NSString alloc] initWithData:_responseData encoding:NSASCIIStringEncoding];
    
    gErrorType = NO_ERROR;
    gResponseString = responseString;
    if (DEBUG_NETWORKING) {
        NSLog(@"startRequest: Received Data (String): %@", gResponseString);
    }
    
    [self closeConnectingServerAlert:connectingServerAlert];
    [self afterGetResponse];
    
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    gErrorType = ERROR_CONNECTION;
    NSLog(@"Failed to receive data. %@",[error localizedDescription]);
    
    [self closeConnectingServerAlert:connectingServerAlert];
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Connection Error"
                          message:@"Failed to connect the server. Do you want to try again?"
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"OK",nil];
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Cancel Tapped
        NSLog(@".");
    }
    else if (buttonIndex == 1) {
        // OK Tapped
        NSLog(@"");
    }
}

- (bool) serverResponseIsValid:(NSString *)string {
    if ([string isEqual:@""] || string == nil) {
        gErrorType = ERROR_INVALID_SERVICE;
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Protocol Error"
                              message:@"Failed to get data from the server."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return false;
    }
    return true;
}

// synchronized method: send requests and get response
//      try serveral times of requests before get valid response
//      based on: (NSString *) startSynRequest:(NSString *)restCommand verboseMode:(bool)verboseMode
- (NSString *) requestServeralTimes: (NSString *)url requestCounter:(int)requestCounter{
    bool verboseMode = false;
    NSString * response = nil;
    while (requestCounter >= 0 && gRestart == false) {
        if ( requestCounter <= 0){
            verboseMode = true;
        } else {
            verboseMode = false;
        }
        
        response = nil;
        if (DEBUG_VERBOSE) NSLog(@"submit: url: %@", url);
        response = [self startSynRequest:url verboseMode:(bool)verboseMode];
        if (DEBUG_NETWORKING) NSLog(@"response: %@", response);
        if (response != nil) {
            break;
        }
        requestCounter -- ;
        [NSThread sleepForTimeInterval:1];  // seconds
    }
    return response;
}

// synchronized method: send requests and get response
- (NSString *) startSynRequest:(NSString *)restCommand verboseMode:(bool)verboseMode
{
    NSString *url = [serverURL stringByAppendingFormat:@"/%@", restCommand];
    NSURL *myURL = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSTimeInterval timeoutInt = 5;      // timeout: senconds
    if (DEBUG_JSON) {
        NSLog(@"startSynRequest url: %@", myURL);
        NSLog(@"startSynRequest restCommand: %@", restCommand);
    }
    NSURLRequest *myRuquest = [NSURLRequest requestWithURL:myURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInt];
    NSData *nsdata = [ NSURLConnection sendSynchronousRequest:myRuquest returningResponse:nil error:nil];
    NSString *str = [[NSString alloc] initWithData:nsdata encoding:NSUTF8StringEncoding];
    if (str==nil) {
        gErrorType = ERROR_CONNECTION;
        if (verboseMode) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:@"Service is not available. Please check your account and other request informarion"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"OK",nil];
            [alert show];
        }
    }
    return str;
}



/* ----- Exit vote and return main page ----- */

NSInteger buttonIndexUIA = -1;
NSString *segueID;
UIViewController *viewController;

- (void)exitVote: (UIViewController *)currentViewController NSString:segueIdentification
{
    
    viewController = currentViewController;
    segueID = segueIdentification;
    UIActionSheet * actionSheet = [[UIActionSheet alloc]
                                   initWithTitle:@"Are you sure to exit voting?"
                                   delegate:self
                                   cancelButtonTitle:@"No ~"
                                   destructiveButtonTitle:@"Yes, I'm sure."
                                   otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic; // set style
    
    buttonIndexUIA = -2 ;
    [actionSheet showInView:self.view];
    
}

// Actions for actionsheet
//      the order where action excutes: clickedButtonAtIndex -> willDismissWithButtonIndex -> didDismissWithButtonIndex
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    buttonIndexUIA = buttonIndex;
    if (buttonIndexUIA == 0){
        // click "Yes"
        gRestart = true;
        [viewController performSegueWithIdentifier:segueID sender:viewController];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
}



/* ----- JSON parsing ----- */

- (NSString *) getParaFromJSONNSData:(NSData *)jsonData NSString:key
{
    NSError *error;
    NSDictionary *resultJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

    if (resultJSON == nil) {
        gErrorType = ERROR_JSON_PARSING;
        gError = error;
        NSLog(@"Error in Parsing Json: %@", error);
        return nil;
    }
    
    NSString *value = [resultJSON objectForKey:key];
    if (value == nil){
        gErrorType = ERROR_JSON_NOKEY;
        NSLog(@"Error in Parsing Json: not found key %@", key);
        return nil;
    }
    
    return value;
}

- (NSString *) getParaFromJSON:(NSString *)jsonString key:(NSString*)key
{
    NSError *error = [[NSError alloc] init];
    NSData *jsonData = [jsonString dataUsingEncoding:[NSString defaultCStringEncoding]];
    NSDictionary *resultJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

    if (DEBUG_JSON) NSLog(@"getParaFromJSON: resultJSON: %@", resultJSON);
    if (resultJSON == nil) {
        gErrorType = ERROR_JSON_PARSING;
        gError = error;
        NSLog(@"Error in Parsing Json: %@", error);
        return nil;
    }
    
    NSString *value = [resultJSON objectForKey:key];
    if (value == nil){
        gErrorType = ERROR_JSON_NOKEY;
        NSLog(@"Error in Parsing Json: not found key %@", key);
        return nil;
    }
    
    return value;
}

- (void) jsonAlert:(NSString *)errorContent
{
    UIAlertView *alertX = [[UIAlertView alloc]
                           initWithTitle:@"Json Alert"
                           message:[errorContent stringByAppendingString:@""]
                           //message:[errorContent stringByAppendingString:@"Do you want to try again?"]
                           delegate:self
                           cancelButtonTitle:@"Cancel"
                           otherButtonTitles:nil];
    [alertX show];
}



/* ----- other methods ----- */

// check whether it is a number
- (bool) isDecimal:(NSString *)string
{
    if (string == nil || [string isEqual:@""]) {
        return false;
    }
    
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    bool result = false;
    if ([nf numberFromString:string]!= nil) {
        result = true;
    }
    else {
        result = false;
        gErrorType = ERROR_DATA_FORMAT;
    }
    
    return result;
}

// switch between ViewControllers
- (void) switchUIView:(UIViewController *)viewController NSString:segueID
{
    if (viewController == nil){
        return;
    }
    
    [viewController performSegueWithIdentifier:segueID sender:viewController];
}

// pop an alert
- (UIAlertView *) showConnectingServerAlert
{
    UIAlertView * alertWithProgress = [[UIAlertView alloc]
                         initWithTitle:@"Connecting server ..."
                         message:nil
                         delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:nil];
    
     //UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    
    [alertWithProgress show];
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorView.center  = CGPointMake(alertWithProgress.frame.size.width/ 2 , alertWithProgress.frame.size.height/2);
    [indicatorView startAnimating];
    [alertWithProgress addSubview:indicatorView];
    
    return alertWithProgress;
}

// close a poped alert
- (void) closeConnectingServerAlert: (UIAlertView *)alertWithProgress
{
    [alertWithProgress dismissWithClickedButtonIndex:0 animated:YES];
}


/****************************/

/* ----- native methods ----- */

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
