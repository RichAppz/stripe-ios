//
//  STPSourceFunctionalTest.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;


#import "STPTestingAPIClient.h"

@interface STPSourceFunctionalTest : XCTestCase
@end

@interface STPAPIClient (WritableURL)
@property (nonatomic, readwrite) NSURL *apiURL;
@end

@implementation STPSourceFunctionalTest

- (void)testCreateSource_bancontact {
    STPSourceParams *params = [STPSourceParams bancontactParamsWithAmount:1099
                                                                     name:@"Jenny Rosen"
                                                                returnURL:@"https://shop.example.com/crtABC"
                                                      statementDescriptor:@"ORDER AT123"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeBancontact);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner.name, params.owner[@"name"]);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCreateSource_card {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2024;
    card.currency = @"usd";
    card.name = @"Jenny Rosen";
    card.address.line1 = @"123 Fake Street";
    card.address.line2 = @"Apartment 4";
    card.address.city = @"New York";
    card.address.state = @"NY";
    card.address.country = @"USA";
    card.address.postalCode = @"10002";
    STPSourceParams *params = [STPSourceParams cardParamsWithCard:card];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeCard);
        XCTAssertEqualObjects(source.cardDetails.last4, @"4242");
        XCTAssertEqual(source.cardDetails.expMonth, card.expMonth);
        XCTAssertEqual(source.cardDetails.expYear, card.expYear);
        XCTAssertEqualObjects(source.owner.name, card.name);
        STPAddress *address = source.owner.address;
        XCTAssertEqualObjects(address.line1, card.address.line1);
        XCTAssertEqualObjects(address.line2, card.address.line2);
        XCTAssertEqualObjects(address.city, card.address.city);
        XCTAssertEqualObjects(address.state, card.address.state);
        XCTAssertEqualObjects(address.country, card.address.country);
        XCTAssertEqualObjects(address.postalCode, card.address.postalCode);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)skip_testCreateSourceVisaCheckout {
    // The SDK does not have a means of generating Visa Checkout params for testing. Supply your own
    // callId, and the correct publishable key, and you can run this test case
    // manually after removing the `skip_` prefix. It'll log the source's stripeID, and that
    // can be verified in dashboard.
    STPSourceParams *params = [STPSourceParams visaCheckoutParamsWithCallId:@""];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_"];
    client.apiURL = [NSURL URLWithString:@"https://api.stripe.com/v1"];

    XCTestExpectation *sourceExp = [self expectationWithDescription:@"VCO source created"];
    [client createSourceWithParams:params completion:^(STPSource * _Nullable source, NSError * _Nullable error) {
        [sourceExp fulfill];

        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeCard);
        XCTAssertEqual(source.flow, STPSourceFlowNone);
        XCTAssertEqual(source.status, STPSourceStatusChargeable);
        XCTAssertEqual(source.usage, STPSourceUsageReusable);
        XCTAssertTrue([source.stripeID hasPrefix:@"src_"]);
        NSLog(@"Created a VCO source %@", source.stripeID);
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)skip_testCreateSourceMasterpass {
    // The SDK does not have a means of generating Masterpass params for testing. Supply your own
    // cartId & transactionId, and the correct publishable key, and you can run this test case
    // manually after removing the `skip_` prefix. It'll log the source's stripeID, and that
    // can be verified in dashboard.
    STPSourceParams *params = [STPSourceParams masterpassParamsWithCartId:@"" transactionId:@""];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_"];
    client.apiURL = [NSURL URLWithString:@"https://api.stripe.com/v1"];

    XCTestExpectation *sourceExp = [self expectationWithDescription:@"Masterpass source created"];
    [client createSourceWithParams:params completion:^(STPSource * _Nullable source, NSError * _Nullable error) {
        [sourceExp fulfill];

        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeCard);
        XCTAssertEqual(source.flow, STPSourceFlowNone);
        XCTAssertEqual(source.status, STPSourceStatusChargeable);
        XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
        XCTAssertTrue([source.stripeID hasPrefix:@"src_"]);
        NSLog(@"Created a Masterpass source %@", source.stripeID);
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCreateSource_multibanco {
    STPSourceParams *params = [STPSourceParams multibancoParamsWithAmount:1099
                                                                returnURL:@"https://shop.example.com/crtABC"
                                                                    email:@"user@example.com"];
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqual(source.type, STPSourceTypeMultibanco);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
        XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"]);
        XCTAssertNotNil(source.redirect.url);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
