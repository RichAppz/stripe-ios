//
//  STPCardParamsTest.m
//  Stripe
//
//  Created by Joey Dong on 6/19/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;


#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPCardParamsTest : XCTestCase

@end

@implementation STPCardParamsTest

#pragma mark -

- (void)testLast4ReturnsCardNumberLast4 {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    cardParams.number = @"4242424242424242";
    XCTAssertEqualObjects(cardParams.last4, @"4242");
}

- (void)testLast4ReturnsNilWhenNoCardNumberSet {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    XCTAssertNil(cardParams.last4);
}

- (void)testLast4ReturnsNilWhenCardNumberIsLessThanLength4 {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    cardParams.number = @"123";
    XCTAssertNil(cardParams.last4);
}

#pragma mark - Description Tests

- (void)testDescription {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    XCTAssert(cardParams.description);
}

#pragma mark - STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPCardParams rootObjectName], @"card");
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPCardParams *cardParams = [[STPCardParams alloc] init];

    NSDictionary *mapping = [STPCardParams propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([cardParams respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end
