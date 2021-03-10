//
//  STPPaymentMethodCardChecksTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import XCTest;


@interface STPPaymentMethodCardChecksTest : XCTestCase

@end

@implementation STPPaymentMethodCardChecksTest

- (void)testDecodedObjectFromAPIResponse {
    NSDictionary *response = @{@"address_line1_check": [NSNull null],
                               @"address_postal_code_check": [NSNull null],
                               @"cvc_check": [NSNull null]};
    NSArray<NSString *> *requiredFields = @[];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *mutableResponse = [response mutableCopy];
        [mutableResponse removeObjectForKey:field];
        XCTAssertNil([STPPaymentMethodCardChecks decodedObjectFromAPIResponse:mutableResponse]);
    }
    STPPaymentMethodCardChecks *checks = [STPPaymentMethodCardChecks decodedObjectFromAPIResponse:response];
    XCTAssertNotNil(checks);
}

- (void)testCheckResultFromString {
    XCTAssertEqual([STPPaymentMethodCardChecks checkResultFromString:@"pass"], STPPaymentMethodCardCheckResultPass);
    XCTAssertEqual([STPPaymentMethodCardChecks checkResultFromString:@"failed"], STPPaymentMethodCardCheckResultFailed);
    XCTAssertEqual([STPPaymentMethodCardChecks checkResultFromString:@"unavailable"], STPPaymentMethodCardCheckResultUnavailable);
    XCTAssertEqual([STPPaymentMethodCardChecks checkResultFromString:@"unchecked"], STPPaymentMethodCardCheckResultUnchecked);
    XCTAssertEqual([STPPaymentMethodCardChecks checkResultFromString:@"unknown_string"], STPPaymentMethodCardCheckResultUnknown);
    XCTAssertEqual([STPPaymentMethodCardChecks checkResultFromString:nil], STPPaymentMethodCardCheckResultUnknown);
}

@end
