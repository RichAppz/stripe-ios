//
//  STPCustomerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>



#import "STPTestUtils.h"

@interface STPCustomerTest : XCTestCase
@end

@implementation STPCustomerTest

- (void)testDecoding_invalidJSON {
    STPCustomer *sut = [STPCustomer decodedObjectFromAPIResponse:@{}];
    XCTAssertNil(sut);
}

- (void)testDecoding_validJSON {
    NSMutableDictionary *card1 = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
    card1[@"id"] = @"card_123";

    NSMutableDictionary *card2 = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
    card2[@"id"] = @"card_456";

    NSMutableDictionary *applePayCard1 = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
    applePayCard1[@"id"] = @"card_apple_pay1";
    applePayCard1[@"tokenization_method"] = @"apple_pay";

    NSMutableDictionary *applePayCard2 = [applePayCard1 mutableCopy];
    applePayCard2[@"id"] = @"card_apple_pay2";

    NSDictionary *cardSource = [STPTestUtils jsonNamed:@"CardSource"];

    NSMutableDictionary *customer = [[STPTestUtils jsonNamed:@"Customer"] mutableCopy];
    NSMutableDictionary *sources = [customer[@"sources"] mutableCopy];
    sources[@"data"] = @[applePayCard1, card1, applePayCard2, card2, cardSource];
    customer[@"default_source"] = card1[@"id"];
    customer[@"sources"] = sources;

    STPCustomer *sut = [STPCustomer decodedObjectFromAPIResponse:customer];
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(sut.stripeID, customer[@"id"]);
}

@end
