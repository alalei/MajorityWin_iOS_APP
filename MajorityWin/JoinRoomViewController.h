//
//  JoinRoomViewController.h
//  MajorityWin
//
//  Created by fish on 14-4-17.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "QREncoder.h"
#import <QuartzCore/QuartzCore.h>
#import "ZBarSDK.h"

@interface JoinRoomViewController : BaseViewController <ZBarCaptureDelegate>
//UIViewController

@property (weak, nonatomic) IBOutlet UITextField *roomNumText;

- (void)joinRoom:(NSString *)roomNO;

@end
