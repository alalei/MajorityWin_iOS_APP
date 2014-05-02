//
//  BaseViewController.h
//  MajorityWin
//
//  Created by fish on 14-4-17.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import <UIKit/UIKit.h>

// debug configuration
#define ENABLE_QR false // compiling: enabling QR module
#define DEBUG_VERBOSE false
#define DEBUG_NETWORKING false
#define DEBUG_ACCOUNT false
#define DEBUG_JSON false
#define DEBUG_DISPLAY false


// protocol: RoomStatus
#define ROOMSTATUS_BEFORE_START 0
#define ROOMSTATUS_SELECT_LEADER 1
#define ROOMSTATUS_EDIT_TOPIC 1
#define ROOMSTATUS_WAIT_FOR_VOTE 1
#define ROOMSTATUS_START_VOTE 2
#define ROOMSTATUS_FINISH_VOTE 3
#define ROOMSTATUS_WAIT_FOR_RESULT 3
#define ROOMSTATUS_FINISH 3
#define ROOMSTATUS_REQUEST_LEADER 11
#define ROOMSTATUS_REQUEST_STATUS 12
#define ROOMSTATUS_OTHER 20
#define ROOMSTATUS_APP_PENDING 30


// REST API parameters for server-client protocol 
extern NSString * const REST_REGISTER_USER;
extern NSString * const REST_REGISTER_SUCCESS;
extern NSString * const REST_SIGNIN_SUCCESS;
extern NSString * const REST_SIGN_IN;
extern NSString * const REST_CREAT_ROOM;
extern NSString * const REST_JOIN_ROOM;
extern NSString * const REST_GET_ROOM_INFO;
extern NSString * const REST_PICK_LEADER;
extern NSString * const REST_PICK_LEADER_SUCCESS;
extern NSString * const REST_CHECK_LEADER;
extern NSString * const REST_GIVE_UP_LEADER;
extern NSString * const REST_JOIN_ROOM_SUCCESS;
extern NSString * const REST_CHECK_SUBMIT;
extern NSString * const REST_SUBMIT_QUESTION;
extern NSString * const REST_SUBMIT_QUESTION_SUCCESS;
extern NSString * const REST_GET_TOPIC;
extern NSString * const REST_SUBMIT_VOTE;
extern NSString * const REST_SUBMIT_VOTE_SUCCESS;
extern NSString * const REST_SUBMIT_SUCCESS;
extern NSString * const REST_WAIT_FOR_RESULT;
extern NSString * const REST_NEXT_ROUND;
extern NSString * const REST_NEXT_ROUND_SUCCESS;

// server parameters
extern NSString * const serverURL;

// error type
#define NO_ERROR 0
#define ERROR_CONNECTION 1
#define ERROR_DATA_FORMAT 2
#define ERROR_INVALID_SERVICE 3
#define ERROR_JSON_PARSING 4
#define ERROR_JSON_NOKEY 5

// global variable
extern NSString *gUsername;
extern NSString *gRoomNO;
extern int gRoomSize;
extern int gAppStatus;
extern NSString *gResponseString;
extern int gErrorType;
extern NSError *gError;
bool gRoomCreator;
extern NSString *gLeader;
extern int gVotedOption;
extern bool gRoomCreator;
extern int gParticipantsNumber;
extern bool gRestart;

@interface BaseViewController : UIViewController <UIActionSheetDelegate> {
}

/* ----- server-client interaction ----- */

// asynchronized requests to server
- (void) startRequest:(NSString *)restCommand;

// response API after startRequest; API to be implemented in subclasses
- (void) afterGetResponse;

// synchronized requests to server
- (NSString *) startSynRequest:(NSString *)restCommand verboseMode:(bool)verboseMode;

//synchronized requests to server in at most "requestCounter" times
- (NSString *) requestServeralTimes: (NSString *)url requestCounter:(int)requestCounter;


/* ----- Exit vote and return main page ----- */
- (void)exitVote:(UIViewController *)viewController NSString:segueIdentification;


/* ----- JSON parsing ----- */
- (NSString *) getParaFromJSON:(NSString *)jsonString key:(NSString*)key;
- (NSString *) getParaFromJSONNSData:(NSData *)jsonData NSString:key;
// pop an alert for error in reading JSON
- (void) jsonAlert:(NSString *)errorContent;


/* ----- other methods ----- */

// check whether it is a number
- (bool) isDecimal:(NSString *)string;

// pop an alert
- (UIAlertView *) showConnectingServerAlert;

// close a poped alert
- (void) closeConnectingServerAlert: (UIAlertView *)alertWithProgress;





@end
