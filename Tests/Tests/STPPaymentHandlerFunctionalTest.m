//
//  STPPaymentHandlerFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Stripe;
#import <OCMock/OCMock.h>
#import <SafariServices/SafariServices.h>

#import "STPTestingAPIClient.h"


@interface STPPaymentHandlerFunctionalTest : XCTestCase <STPAuthenticationContext>
@property (nonatomic) id presentingViewController;
@end

@interface STPPaymentHandler (Test) <SFSafariViewControllerDelegate>
- (BOOL)_canPresentWithAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext error:(NSError **)error;
@end

@implementation STPPaymentHandlerFunctionalTest

- (void)setUp {
    self.presentingViewController = OCMClassMock([UIViewController class]);
    [STPAPIClient sharedClient].publishableKey = STPTestingDefaultPublishableKey;
}

- (UIViewController *)authenticationPresentingViewController {
    return self.presentingViewController;
}

@end
