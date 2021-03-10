//
//  STPPaymentIntentFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Stripe;


#import "STPTestingAPIClient.h"


@interface STPPaymentIntentFunctionalTest : XCTestCase
@end

@implementation STPPaymentIntentFunctionalTest

- (void)testCreatePaymentIntentWithTestingServer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PaymentIntent create."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil
                                                           completion:^(NSString * _Nullable clientSecret, NSError * _Nullable error) {
        XCTAssertNotNil(clientSecret);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCreatePaymentIntentWithInvalidCurrency {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PaymentIntent create."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{@"payment_method_types": @[@"bancontact"]} completion:^(NSString * _Nullable clientSecret, NSError * _Nullable error) {
        XCTAssertNil(clientSecret);
        XCTAssertNotNil(error);
        XCTAssertTrue([error.userInfo[[STPError errorMessageKey]] hasPrefix:@"Error creating PaymentIntent: The currency provided (usd) is invalid. Payments with bancontact support the following currencies: eur."]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testRetrievePreviousCreatedPaymentIntent {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(error);

                                           XCTAssertNotNil(paymentIntent);
                                           XCTAssertEqualObjects(paymentIntent.stripeId, @"pi_1GGCGfFY0qyl6XeWbSAsh2hn");
                                           XCTAssertEqual(paymentIntent.amount, 100);
                                           XCTAssertEqualObjects(paymentIntent.currency, @"usd");
                                           XCTAssertFalse(paymentIntent.livemode);
                                           XCTAssertNil(paymentIntent.sourceId);
                                           XCTAssertNil(paymentIntent.paymentMethodId);
                                           XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusCanceled);
                                           XCTAssertEqual(paymentIntent.setupFutureUsage, STPPaymentIntentSetupFutureUsageNone);
                                           XCTAssertNil(paymentIntent.nextAction);

                                           [expectation fulfill];
                                       }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testRetrieveWithWrongSecret {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_bad-secret"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(paymentIntent);

                                           XCTAssertNotNil(error);
                                           XCTAssertEqualObjects(error.domain, [STPError stripeDomain]);
                                           XCTAssertEqual(error.code, STPInvalidRequestError);
                                           XCTAssertEqualObjects(error.userInfo[[STPError errorParameterKey]],
                                                                 @"clientSecret");

                                           [expectation fulfill];
                             }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testRetrieveMismatchedPublishableKey {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_dCyfhfyeO2CZkcvT5xyIDdJj"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(paymentIntent);

                                           XCTAssertNotNil(error);
                                           XCTAssertEqualObjects(error.domain, [STPError stripeDomain]);
                                           XCTAssertEqual(error.code, STPInvalidRequestError);
                                           XCTAssertEqualObjects(error.userInfo[[STPError errorParameterKey]],
                                                                 @"intent");

                                           [expectation fulfill];
                                       }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmCanceledPaymentIntentFails {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe"];
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(paymentIntent);

                                    XCTAssertNotNil(error);
                                    XCTAssertEqualObjects(error.domain, [STPError stripeDomain]);
                                    XCTAssertEqual(error.code, STPInvalidRequestError);

                                    [expectation fulfill];
                                }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmPaymentIntentWith3DSCardPaymentMethodSucceeds {

    __block NSString *clientSecret = nil;
       XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
       [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
           XCTAssertNotNil(createdClientSecret);
           XCTAssertNil(creationError);
           [createExpectation fulfill];
           clientSecret = [createdClientSecret copy];
       }];
       [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
       XCTAssertNotNil(clientSecret);
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];
    
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    cardParams.number = @"4000000000003063";
    cardParams.expMonth = @(7);
    cardParams.expYear = @([[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]] + 5);
    
    params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams
                                                               metadata:nil];
    // returnURL must be passed in while confirming (not creation time)
    params.returnURL = @"example-app-scheme://authorized";
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");
                                    
                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, params.stripeId);
                                    XCTAssertFalse(paymentIntent.livemode);
                                    XCTAssertNotNil(paymentIntent.paymentMethodId);
                                    
                                    // sourceParams is the 3DS-required test card
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
                                    
                                    // STPRedirectContext is relying on receiving returnURL
                                    
                                    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
                                    XCTAssertEqualObjects(paymentIntent.nextAction.redirectToURL.returnURL,
                                                          [NSURL URLWithString:@"example-app-scheme://authorized"]);

                                    // Going to log all the fields so that you, the developer manually running this test, can inspect them
                                    NSLog(@"Confirmed PaymentIntent: %@", paymentIntent.allResponseFields);
                                    
                                    [expectation fulfill];
                                }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmPaymentIntentWithShippingDetailsSucceeds {
    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    cardParams.number = @"4242424242424242";
    cardParams.expMonth = @(7);
    cardParams.expYear = @([[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]] + 5);

    params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams
                                                               metadata:nil];

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
        XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

        XCTAssertNotNil(paymentIntent);
        XCTAssertEqualObjects(paymentIntent.stripeId, params.stripeId);
        XCTAssertFalse(paymentIntent.livemode);
        XCTAssertNotNil(paymentIntent.paymentMethodId);

        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmCardWithoutNetworkParam {
    __block NSString *clientSecret = nil;
       XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
       [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
           XCTAssertNotNil(createdClientSecret);
           XCTAssertNil(creationError);
           [createExpectation fulfill];
           clientSecret = [createdClientSecret copy];
       }];
       [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
       XCTAssertNotNil(clientSecret);
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];
    
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    cardParams.number = @"4242424242424242";
    cardParams.expMonth = @(7);
    cardParams.expYear = @([[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]] + 5);
    
    params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams
                                                               metadata:nil];

    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");
                                    
                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, params.stripeId);
                                    XCTAssertFalse(paymentIntent.livemode);
                                    XCTAssertNotNil(paymentIntent.paymentMethodId);
                                    
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusSucceeded);
                                    
                                    [expectation fulfill];
                                }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - Test Objective-C setupFutureUsage

- (void)testObjectiveCSetupFutureUsage {
  STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] init];
  params.setupFutureUsage = @(STPPaymentIntentSetupFutureUsageOnSession);
  XCTAssertEqualObjects(params.setupFutureUsageRawString, @"on_session");
}

@end
