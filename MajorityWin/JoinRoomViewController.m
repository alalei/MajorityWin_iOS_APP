//
//  JoinRoomViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-17.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "JoinRoomViewController.h"

@interface JoinRoomViewController ()

@end

@implementation JoinRoomViewController
bool joinRoomSuccess = false;

- (IBAction)exitVoteJRVC:(id)sender {
    [self exitVote:self NSString:@"JRVC2VC" ];
}

// Click the "enter room" button
- (IBAction)joinRoomWithRoomNO:(id)sender
{
    NSString *roomNumStr = [_roomNumText text];
    if (roomNumStr == nil || [roomNumStr isEqualToString:@""]) {
        UIAlertView *alert1 = [[UIAlertView alloc]
                              initWithTitle:@""
                              message:@"Please input a room number"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"OK",nil];
        [alert1 show];
        return;
    }
    if (DEBUG_VERBOSE) {
        NSLog(@"room num got from text: %@", roomNumStr);
    }

    gRoomNO = roomNumStr;
    [self joinRoom:gRoomNO];
    [[self roomNumText]resignFirstResponder];
    
}

// Touch screen to end editing
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view]endEditing:YES];
}

// Based method of join room used by different button action
- (void)joinRoom:(NSString *)roomNO
{
    joinRoomSuccess = false;
    if ( [self isDecimal:roomNO]) {
        gRoomNO = roomNO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                           [self requestThread];
                           dispatch_async(dispatch_get_main_queue(),
                                          ^{[self updateUIWithResult];}
                                          );
                       }
                       );
        
    }
    else if( gErrorType == ERROR_DATA_FORMAT){
        UIAlertView *alert2 = [[UIAlertView alloc]
                               initWithTitle:@"Data Error"
                               message:@"Error: input data format is wrong"
                               delegate:self
                               cancelButtonTitle:@"Cancel"
                               otherButtonTitles:@"OK",nil];
        [alert2 show];
    }
    
}

// Send request of join room ro server
- (void) requestThread
{
    NSString *response = [self startSynRequest:[REST_JOIN_ROOM stringByAppendingFormat:@"?roomID=%@&username=%@",gRoomNO,gUsername] verboseMode:true];
    if (response == nil) {
        NSLog(@"error: response: %@",  response);
    }
    if (![response isEqualToString:REST_JOIN_ROOM_SUCCESS]) {
        if (DEBUG_VERBOSE) {
            NSLog(@"ERROR data: %@", gResponseString);
        }
        
        UIAlertView *alert3 = [[UIAlertView alloc]
                               initWithTitle:@"Error"
                               message:@"Service is not availble"
                               delegate:self
                               cancelButtonTitle:@"Cancel"
                               otherButtonTitles:@"OK",nil];
        [alert3 show];
        return;
    }
    
    joinRoomSuccess = true;
}

// Act after getting the response from server
- (void) updateUIWithResult
{
    [NSThread sleepForTimeInterval:0.5];
    if (joinRoomSuccess){
        gRoomCreator = false;
        [self performSegueWithIdentifier:@"JRVC2WFVVC" sender:self];
    }
}



/*
 * ----- QR code handling -----
 */

// open camera and start scan
//      when click "Scan" button, start to scan the QRcode process
- (IBAction)scanQRcode:(id)sender {
    
# if ENABLE_QR
    
    ZBarReaderController *reader = [ZBarReaderController new];
    reader.readerDelegate = self;
    ZBarImageScanner *scanner = reader.scanner;
    
    [scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
    [self presentViewController:reader animated:YES completion:nil];
    
#endif
    
}

// process the QRcode
-(void) imagePickerController:(UIImagePickerController*) reader didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
# if ENABLE_QR
    
    // get the QRcode result
    id <NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for (symbol in results) {
        break;
    }
    
    // print the QR content
    NSString *textQR = symbol.data;
    if (DEBUG_VERBOSE){
        NSLog(@"The QRcode is %@",textQR);
    }
    
    // exit the scan UI
    if (DEBUG_VERBOSE){
        NSLog(@"exit scan");
    }
    [reader dismissViewControllerAnimated:NO completion:^{
        [self joinRoom:textQR];
    }];
    
# endif
    
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
