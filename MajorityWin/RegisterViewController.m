//
//  RegisterViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-27.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "RegisterViewController.h"

@interface RegisterViewController ()

@end

@implementation RegisterViewController


NSString *username = nil;
NSString *password = nil;
bool isRegistrationRequest = false;
UIAlertView *alertView = nil;   // alertView to show "connecting  to server"

// Click signin button
- (IBAction)signin:(id)sender {
    username = _usernameTextView.text;
    password = _passwordTextView.text;
    isRegistrationRequest = false;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self requestThread];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{[self updateUIWithResult];}
                                      );
                   }
                   );
    [[self usernameTextView] resignFirstResponder];
    [[self passwordTextView] resignFirstResponder];
    alertView = [self showConnectingServerAlert];
    NSLog(@"pop ConnectingServerAlert");
}

// Click register button
- (IBAction)register:(id)sender {
    username = _usernameTextView.text;
    password = _passwordTextView.text;
    isRegistrationRequest = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self requestThread];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{[self updateUIWithResult];}
                                      );
                   }
                   );
    [[self usernameTextView] resignFirstResponder];
    [[self passwordTextView] resignFirstResponder];
    alertView = [self showConnectingServerAlert];
    NSLog(@"pop ConnectingServerAlert");
}

// Thread to send request of registration to server
- (void) requestThread
{
    NSString *url = nil;
    NSString * response;
    gErrorType = ERROR_INVALID_SERVICE;
    
    if (isRegistrationRequest){
        url = [REST_REGISTER_USER stringByAppendingFormat:@"?username=%@&password=%@",username, password];
    } else {
        url = [REST_SIGN_IN stringByAppendingFormat:@"?username=%@&password=%@",username, password];
    }
    
    response = [self startSynRequest:url verboseMode:true];
    if (response == nil) {
        gErrorType = ERROR_INVALID_SERVICE;
    }
    if (![response isEqual:REST_REGISTER_SUCCESS] && ![response isEqual:REST_SIGNIN_SUCCESS]){
        if (DEBUG_VERBOSE) {
            NSLog(@"ERROR data: %@", response);
        }
        
        gErrorType = ERROR_INVALID_SERVICE;
        NSString * message = nil;
        if (isRegistrationRequest){
            message = @"Service is not availble. Please try again";
        } else {
            message = @"Please confirm username and passsword";
        }
        UIAlertView *alert3 = [[UIAlertView alloc]
                               initWithTitle:@""
                               message:message
                               delegate:self
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil];
        [alert3 show];
         NSLog(@"login: pop error alert");
        return;
    }
    
    gErrorType = NO_ERROR;
    
    // register or login successfully
    gUsername = username;

}

//  Act after getting response from server
- (void) updateUIWithResult
{
    if (alertView != nil) {
        [self closeConnectingServerAlert:alertView];
    }
    if (gErrorType == NO_ERROR) {
        [self performSegueWithIdentifier:@"RVC2VC" sender:self];
    }
    NSLog(@"No jump UI");
}

// Touch screen to end editing
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view]endEditing:YES];
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
