//
//  PaymentViewController.m
//  Karl_BT_Test
//
//  Created by Hirschhorn Jr, Karl on 2/18/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PaymentViewController.h"
#import <Braintree/Braintree.h>
#import <AFNetworking/AFNetworking.h>


@interface PaymentViewController ()

@end

@implementation PaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set initial state of switch and text fields
    [self.switchVault setOn:NO];
    [self hideCustomerText];
    
    //retrieve Client Token from the Server
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager GET:@"https://karlpartner-karljr791.c9.io/client_token"
      parameters:@""
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // Setup braintree with responseObject[@"client_token"]
             self.clientToken = responseObject[@"client_token"];
             NSLog(@"Success");
             NSLog(@"Client Token: %@", self.clientToken);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // show alert
             [self showAlertWithTitle:@"Client Token" andMessage:@"Failed to Retrieve Client Token"];
         }];
}

- (IBAction)toggleSwitch:(id)sender {
    if([self.switchVault isOn])
    {
        [self showCustomerText];
    }
    else
    {
        [self hideCustomerText];
    }
}

- (IBAction)pressPayButton:(id)sender {
    [self handlePayment];
}

- (void)handlePayment {
    Braintree *braintree = [Braintree braintreeWithClientToken:self.clientToken];
    
    //create DropIn View Controller
    BTDropInViewController *dropInViewController = [braintree dropInViewControllerWithDelegate:self];
    
    dropInViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                          target:self
                                                                                                          action:@selector(userDidCancelPayment)];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:dropInViewController];
    
    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
    
}

- (void)userDidCancelPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dropInViewController:(__unused BTDropInViewController *)viewController didSucceedWithPaymentMethod:(BTPaymentMethod *)paymentMethod {
    self.nonce = paymentMethod.nonce;
    [self postNonceToServer:self.nonce]; // Send payment method nonce to your server
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dropInViewControllerDidCancel:(__unused BTDropInViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postNonceToServer:(NSString *)paymentMethodNonce {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"https://karlpartner-karljr791.c9.io/payment"
       parameters:@{ @"amount": self.txtAmount.text,
                     @"vault": @"no",
                     @"payment-method-nonce": paymentMethodNonce}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              [self showAlertWithTitle:@"Payment" andMessage:@"Payment Successful"];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              // Handle failure communicating with your server
          }];
}

- (void)hideCustomerText {
    [self.txtFirstName setHidden:YES];
    [self.txtLastName setHidden:YES];
    [self.txtCustomerId setHidden:YES];
}

- (void)showCustomerText {
    [self.txtFirstName setHidden:NO];
    [self.txtLastName setHidden:NO];
    [self.txtCustomerId setHidden:NO];
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
