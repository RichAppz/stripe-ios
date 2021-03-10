//
//  STPPaymentMethodFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPTestingAPIClient.h"


@import Stripe;

@interface STPPaymentMethodFunctionalTest : XCTestCase

@end

@implementation STPPaymentMethodFunctionalTest

- (void)setUp {
    [super setUp];
}

- (void)testCreateCardPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodCardParams *card = [STPPaymentMethodCardParams new];
    card.number = @"4242424242424242";
    card.expMonth = @(10);
    card.expYear = @(2022);
    card.cvc = @"100";
    
    
    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithCard:card
                                                                       metadata:@{@"test_key": @"test_value"}];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method Card create"];
    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod *paymentMethod, NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(paymentMethod);
                                   XCTAssertNotNil(paymentMethod.stripeId);
                                   XCTAssertNotNil(paymentMethod.created);
                                   XCTAssertFalse(paymentMethod.liveMode);
                                   XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeCard);
                                   
                                   // Card
                                   XCTAssertEqual(paymentMethod.card.brand, STPCardBrandVisa);
                                   XCTAssertEqualObjects(paymentMethod.card.country, @"US");
                                   XCTAssertEqual(paymentMethod.card.expMonth, 10);
                                   XCTAssertEqual(paymentMethod.card.expYear, 2022);
                                   XCTAssertEqualObjects(paymentMethod.card.funding, @"credit");
                                   XCTAssertEqualObjects(paymentMethod.card.last4, @"4242");
                                   [expectation fulfill];
                               }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
