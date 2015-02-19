//
//  LoginViewController.h
//  Karl_BT_Test
//
//  Created by Hirschhorn Jr, Karl on 2/18/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController
- (IBAction)btnLogin:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *txtMerchantID;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progLogin;


@end
