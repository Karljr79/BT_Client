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


@interface PaymentViewController () <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, strong) Braintree *braintree;
@property (nonatomic, strong) BTApplePayPaymentMethod *applePayPaymentMethod;
@property (nonatomic, copy) void (^completionBlock)(NSString *nonce);

@end

@implementation PaymentViewController

- (instancetype)initWithBraintree:(Braintree *)braintree completion:(void (^)(NSString *nonce))completion {
    self = [super init];
    if (self) {
        self.braintree = braintree;
        self.completionBlock = completion;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![PKPaymentAuthorizationViewController class]) {
        self.btnApplePay.hidden = YES;
    }
    else {
        self.btnApplePay.hidden = NO;
    }

    Braintree *braintree = [Braintree braintreeWithClientToken:self.clientToken];
    
    //set initial state of switch and text fields
    [self.switchVault setOn:NO];
    [self hideCustomerText];
    
    //[self getNewClientToken];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    [self getNewClientToken];
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

- (NSArray *)supportedNetworks {
    return @[ PKPaymentNetworkAmex ];
}

- (IBAction)pressApplePay:(id)sender {
    [self.provider createPaymentMethod:BTPaymentProviderTypeApplePay];
    
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"merchant.com.braintreepayments.dev-dcopeland";
    request.paymentSummaryItems = @[ [PKPaymentSummaryItem summaryItemWithLabel:@"An Item"
                                                                         amount:[NSDecimalNumber decimalNumberWithString:@"0.5"]],
                                     [PKPaymentSummaryItem summaryItemWithLabel:@"An add-on"
                                                                         amount:[NSDecimalNumber decimalNumberWithString:@"1.0"]] ];
    request.countryCode = @"US";
    request.currencyCode = @"USD";
    request.applicationData = [@"Some random application data" dataUsingEncoding:NSUTF8StringEncoding];
    request.merchantCapabilities = PKMerchantCapability3DS;
    request.supportedNetworks = self.supportedNetworks;
    
    PKPaymentAuthorizationViewController *vc = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
    vc.delegate = self;
    
    if (vc) {
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        NSLog(@"Error creating Apple Pay payment");
    }

}

- (void)handlePayment {
    Braintree *braintree = [Braintree braintreeWithClientToken:self.clientToken];
    self.provider = [braintree paymentProviderWithDelegate:self];
    
    self.provider.paymentSummaryItems = @[
                                          [PKPaymentSummaryItem summaryItemWithLabel:@"COMPANY NAME" amount:[NSDecimalNumber decimalNumberWithString:@"1"]]
                                          ];
    
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
        // Send payment information to your server:
        //   - applePayPaymentMethod.nonce
        //   - applePayPaymentMethod.shippingAddress
        //   - applePayPaymentMethod.billingAddress
        //   - applePayPaymentMethod.shippingMethod
        // Clean up any UI now that the payment is complete
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
        //TODO Add validation here?
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
              // Handle failure communicating with your server
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
