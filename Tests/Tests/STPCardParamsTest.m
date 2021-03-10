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

- (void)testNameSharedWithAddress {
    STPCardParams *cardParams = [STPCardParams new];

    cardParams.name = @"James";
    XCTAssertEqualObjects(cardParams.name, @"James");
    XCTAssertEqualObjects(cardParams.address.name, @"James");

    STPAddress *address = [STPAddress new];
    address.name = @"Jim";

    cardParams.address = address;
    XCTAssertEqualObjects(cardParams.name, @"Jim");
    XCTAssertEqualObjects(cardParams.address.name, @"Jim");

    // Doesn't update `name`, since mutation invisible to the STPCardParams
    cardParams.address.name = @"Smith";
    XCTAssertEqualObjects(cardParams.name, @"Jim");
    XCTAssertEqualObjects(cardParams.address.name, @"Smith");
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

#pragma mark - NSCopying Tests

- (void)testCopyWithZone {
    STPCardParams *cardParams = [STPFixtures cardParams];
    cardParams.address = [STPFixtures address];
    STPCardParams *copiedCardParams = [cardParams copy];

    XCTAssertNotEqual(cardParams, copiedCardParams, @"should be different objects");

    // The property names we expect to *not* be equal objects
    NSArray *notEqualProperties = @[
                                    // these include the object's address, so they won't be the same across copies
                                    @"debugDescription",
                                    @"description",
                                    @"hash",
                                    // STPAddress does not override isEqual:, so this is pointer comparison
                                    @"address",
                                    ];

    // use runtime inspection to find the list of properties. If a new property is
    // added to the fixture, but not the `copyWithZone:` implementation, this should catch it
    for (NSString *property in [STPTestUtils propertyNamesOf:cardParams]) {
        if ([notEqualProperties containsObject:property]) {
            XCTAssertNotEqualObjects([cardParams valueForKey:property],
                                     [copiedCardParams valueForKey:property],
                                     @"%@", property);
        } else {
            XCTAssertEqualObjects([cardParams valueForKey:property],
                                  [copiedCardParams valueForKey:property],
                                  @"%@", property);
        }
    }
}

- (void)testAddressIsNotCopied {
    STPCardParams *cardParams = [STPFixtures cardParams];
    cardParams.address = [STPFixtures address];
    STPCardParams *secondCardParams = [STPCardParams new];

    secondCardParams.address = cardParams.address;
    cardParams.address.line1 = @"123 Main";

    XCTAssertEqualObjects(cardParams.address.line1, @"123 Main");
    XCTAssertEqualObjects(secondCardParams.address.line1, @"123 Main");
}

@end
