//
//  WelcomeViewController.m
//  MajorityWin
//
//  Created by fish on 14-4-27.
//  Copyright (c) 2014年 xlei. All rights reserved.
//

#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [NSThread sleepForTimeInterval:3];
    [self performSegueWithIdentifier:@"WVC2RVC" sender:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set background
    //method 1
    UIImage *image = [UIImage imageNamed:@"Wallpaper.jpg"];
    self.view.layer.contents = (id) image.CGImage;
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor; // make background transparent
    //method 2
    //UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    //imageView.image = [[UIImage imageNamed:@"backgroundx.jpg"] stretchableImageWithLeftCapWidth:left topCapHeight:top];
    //[self.view addSubview:imageView];
    //method 3
    //[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundx.jpg"]]];
    
     
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
