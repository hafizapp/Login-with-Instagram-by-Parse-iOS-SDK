//
//  ViewController.m
//  InstagramLogin
//
//  Created by Hafizur Rahman on 5/5/16.
//  Copyright © 2016 My Company. All rights reserved.
//

#import "ViewController.h"
#import <SafariServices/SafariServices.h>
#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "PFInstagramUtils.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface ViewController ()

@property (nonatomic, strong) IBOutlet UIButton *instagramButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([PFUser currentUser]) {
        [self.instagramButton setTitle:[NSString stringWithFormat:@"Logged In as %@", [[PFUser currentUser]objectForKey:PF_USER_NAME]] forState:UIControlStateNormal];
    }
    
}

- (void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
}

- (IBAction)loginWithInstagramPressed:(id)sender{
    
    
    if (![PFUser currentUser]) {
        
        [SVProgressHUD show];
        
        [[PFInstagramUtils shareDelegate] loginInstagramWithClientId:@"b5e3187a599345f6a288cccac09879da" withDirectURI:@"wicky://" block:^(PFUser * _Nullable user, BOOL isNew, NSError * _Nullable error) {
            
            if (!error) {
                if (isNew) {
                    NSLog(@"User newly created by instagram");
                }
                else{
                    NSLog(@"User just logged in by instagram");
                }
                
                [self.instagramButton setTitle:[NSString stringWithFormat:@"Logged In as %@", [user objectForKey:PF_USER_NAME]] forState:UIControlStateNormal];
            }
            
            else{
                NSLog(@"%@", error.localizedDescription);
                [[[UIAlertView alloc]initWithTitle:error.localizedDescription message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
            
            [SVProgressHUD dismiss];
        }];
    }
    else{
        [[[UIAlertView alloc]initWithTitle:[NSString stringWithFormat:@"You already logged In as %@", [[PFUser currentUser]objectForKey:PF_USER_NAME]] message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
