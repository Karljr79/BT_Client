//
//  LoginViewController.m
//  Karl_BT_Test
//
//  Created by Hirschhorn Jr, Karl on 2/18/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "LoginViewController.h"
#import "Constants.h"
#import <AFNetworking/AFNetworking.h>
#import "Mixpanel.h"

@implementation LoginViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    //disable the Next button
    [[self.navigationItem rightBarButtonItem] setEnabled:NO];
}

- (IBAction)btnLogin:(id)sender {
    //TODO Add validation here
    NSDictionary *params = @{@"id": self.txtMerchantID.text};
    
    //start the spinner
    [self.progLogin startAnimating];
    
    //This is a BAD example of a login, but lets pretend that this is secure :)
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager GET:URL_LOGIN
      parameters:params
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Successfully logged in to merchant ID: %@", self.txtMerchantID.text);
             //enable next button
             [[self.navigationItem rightBarButtonItem] setEnabled:YES];
             
             //track Mixpanel Event
             
             
             //transition to purchase screens
             [self performSegueWithIdentifier:@"postLogin" sender:self];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // show alert
             [self showAlertWithTitle:@"Login" andMessage:@"Login failed, try again"];
         }];
}

//close keyboard if view is tapped
- (void)viewTapped:(UITapGestureRecognizer *)tgr
{
    CGRect framer = CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height);
    [UIView animateWithDuration:0.4f animations:^{
        self.view.frame = framer;}];
    [self.txtMerchantID resignFirstResponder];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:self
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    [alertView show];
}
@end
