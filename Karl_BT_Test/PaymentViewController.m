//
//  PaymentViewController.m
//  Karl_BT_Test
//
//  Created by Hirschhorn Jr, Karl on 2/18/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PaymentViewController.h"
#import "Constants.h"
#import <Braintree/Braintree.h>
#import <AFNetworking/AFNetworking.h>
#import "Mixpanel.h"


@interface PaymentViewController () <BTPaymentMethodCreationDelegate>

@property (nonatomic, strong) Braintree *braintree;
@property (nonatomic, strong) BTPaymentProvider *provider;
@property (nonatomic, copy) void (^completionBlock)(NSString *nonce);
@property (nonatomic, strong) NSNumberFormatter *currencyFormatter;

@end

@implementation PaymentViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    Braintree *braintree = [Braintree braintreeWithClientToken:self.clientToken];
    
    self.provider = [braintree paymentProviderWithDelegate:self];
    
    
    if ([self.provider canCreatePaymentMethodWithProviderType:BTPaymentProviderTypeApplePay]) {
        self.btnApplePay.hidden = YES;
    }
    else {
        self.btnApplePay.hidden = NO;
    }
    
    //set initial state of switch and text fields
    [self.switchVault setOn:NO];
    [self hideCustomerText];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    //get a fresh client token
    [self getNewClientToken];
}

//handle the toggle for the vault
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

- (NSArray *)supportedNetworks {
    return @[ PKPaymentNetworkAmex, PKPaymentNetworkVisa ];
}

- (IBAction)pressApplePay:(id)sender {
    
    Braintree *braintree = [Braintree braintreeWithClientToken:self.clientToken];
    
    self.provider = [braintree paymentProviderWithDelegate:self];
    
    self.provider.paymentSummaryItems = @[
        [PKPaymentSummaryItem summaryItemWithLabel:@"Karl's PayPal Stuff"  amount:[NSDecimalNumber decimalNumberWithString:self.txtAmount.text]]
    ];
    
    [self.provider createPaymentMethod:BTPaymentProviderTypeApplePay];
    
}

- (void)handlePayment {
    Braintree *braintree = [Braintree braintreeWithClientToken:self.clientToken];
    
    //create DropIn View Controller
    BTDropInViewController *dropInViewController = [braintree dropInViewControllerWithDelegate:self];
    
    dropInViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                          target:self
                                                                                                          action:@selector(userDidCancelPayment)];
    [dropInViewController setCallToActionText:@"Pay Now"];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:dropInViewController];
    
    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
    
}

- (void)userDidCancelPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark Drop In Methods

- (void)dropInViewController:(__unused BTDropInViewController *)viewController didSucceedWithPaymentMethod:(BTPaymentMethod *)paymentMethod {
    self.nonce = paymentMethod.nonce;
    [self postNonceToServer:self.nonce]; // Send payment method nonce to your server
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dropInViewControllerDidCancel:(__unused BTDropInViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark BT Payment Method Creator Delegate

- (void)paymentMethodCreator:(id)sender requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentMethodCreator:(id)sender requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)paymentMethodCreator:(id)sender didCreatePaymentMethod:(BTPaymentMethod *)paymentMethod {
    if ([paymentMethod isKindOfClass:[BTApplePayPaymentMethod class]]) {
        BTApplePayPaymentMethod *applePayPaymentMethod = (BTApplePayPaymentMethod *)paymentMethod;
        [self postNonceToServer:applePayPaymentMethod.nonce];
    }
}

- (void)postNonceToServer:(NSString *)paymentMethodNonce {
    NSString *vaultStatus = @"no";
    NSDictionary *params = nil;
    
    //will we be saving this customer to the vault?
    if([self.switchVault isOn])
    {
        vaultStatus = @"yes";
        //TODO Add validation here?
        params = @{@"amount": self.txtAmount.text,
                   @"vault" : vaultStatus,
                   @"payment-method-nonce" : paymentMethodNonce,
                   @"cust_first_name" : self.txtFirstName,
                   @"cust_last_name" : self.txtLastName,
                   @"cust_id" : self.txtCustomerId };
    }
    else
    {
        vaultStatus = @"no";
        //TODO Add text field validation here?
        params = @{@"amount": self.txtAmount.text,
                   @"vault" : vaultStatus,
                   @"payment-method-nonce" : paymentMethodNonce};
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
     manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:URL_PURCHASE
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              [self showAlertWithTitle:@"Payment" andMessage:@"Payment Successful"];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              [self showAlertWithTitle:@"Client Token" andMessage:@"Failed to Retrieve Client Token"];
          }];
}

- (void)getNewClientToken {
    //retrieve Client Token from the Server
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager GET:URL_CLIENT
      parameters:@""
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // Setup braintree with responseObject[@"client_token"]
             self.clientToken = responseObject[@"client_token"];
             NSLog(@"Successfully retrieved client token");
             NSLog(@"Client Token: %@", self.clientToken);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // show alert
             [self showAlertWithTitle:@"Client Token" andMessage:@"Failed to Retrieve Client Token"];
         }];
}

//close keyboard if view is tapped
- (void)viewTapped:(UITapGestureRecognizer *)tgr
{
    CGRect framer = CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height);
    [UIView animateWithDuration:0.4f animations:^{
        self.view.frame = framer;}];
    [_txtAmount resignFirstResponder];
    [_txtCustomerId resignFirstResponder];
    [_txtFirstName resignFirstResponder];
    [_txtLastName resignFirstResponder];
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

#pragma mark BTPaymentProvider Methods





@end
