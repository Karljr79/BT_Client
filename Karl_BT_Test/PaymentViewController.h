//
//  PaymentViewController.h
//  Karl_BT_Test
//
//  Created by Hirschhorn Jr, Karl on 2/18/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Braintree/Braintree.h>

@interface PaymentViewController : UIViewController <BTDropInViewControllerDelegate>
//actions
- (IBAction)toggleSwitch:(id)sender;
- (IBAction)pressPayButton:(id)sender;
//properties
@property NSString *clientToken;
@property NSString *nonce;
@property (weak, nonatomic) IBOutlet UISwitch *switchVault;
@property (weak, nonatomic) IBOutlet UITextField *txtFirstName;
@property (weak, nonatomic) IBOutlet UITextField *txtLastName;
@property (weak, nonatomic) IBOutlet UITextField *txtCustomerId;
@property (weak, nonatomic) IBOutlet UITextField *txtAmount;

@end
