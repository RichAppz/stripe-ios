//
//  STPMocks.m
//  Stripe
//
//  Created by Ben Guo on 4/5/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPMocks.h"

#import "STPFixtures.h"
#import "StripeiOS_Tests-Swift.h"

@interface STPPaymentConfiguration (STPMocks)

/**
 Mock apple pay enabled response to just be based on setting and not hardware
 capability.

 `paymentConfigurationWithApplePaySupportingDevice` forwards calls to the
 real method to this stub
 */
- (BOOL)stpmock_applePayEnabled;

@end

@implementation STPPaymentConfiguration (STPMocks)

- (BOOL)stpmock_applePayEnabled {
    return self.applePayEnabled;
}

@end

