//
//  STPAnalyticsClientTest.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPFixtures.h"


@interface STPAPIClient (Testing)
+ (NSDictionary *)parametersForPayment:(PKPayment *)payment;
@end

@interface STPAnalyticsClient (Testing)
+ (BOOL)shouldCollectAnalytics;
@property (nonatomic) NSSet *productUsage;
@end

@interface STPAnalyticsClientTest : XCTestCase

@end

@implementation STPAnalyticsClientTest

- (void)testShouldCollectAnalytics_alwaysFalseInTest {
    XCTAssertFalse([STPAnalyticsClient shouldCollectAnalytics]);
}

- (void)testTokenTypeFromParameters {
    STPCardParams *card = [STPFixtures cardParams];
    NSDictionary *cardDict = [self buildTokenParams:card];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:cardDict], @"card");

    STPBankAccountParams *bank = [STPFixtures bankAccountParams];
    NSDictionary *bankDict = [self buildTokenParams:bank];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:bankDict], @"bank_account");

    PKPayment *applePay = [STPFixtures applePayPayment];
    NSDictionary *applePayDict = [self addTelemetry:[STPAPIClient parametersForPayment:applePay]];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:applePayDict], @"apple_pay");
}

#pragma mark - Tests various classes report usage

- (void)testApplePayContextAddsUsage{
    id delegate;
    STPApplePayContext *_ = [[STPApplePayContext alloc] initWithPaymentRequest:[STPFixtures applePayRequest] delegate:delegate];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}

#pragma mark - Helpers

- (NSDictionary *)buildTokenParams:(nonnull NSObject<STPFormEncodable> *)object {
    return [self addTelemetry:[STPFormEncoder dictionaryForObject:object]];
}

- (NSDictionary *)addTelemetry:(NSDictionary *)params {
    // STPAPIClient adds these before determining the token type,
    // so do the same in the test
    return [[STPTelemetryClient sharedInstance] paramsByAddingTelemetryFieldsToParams:params];
}

@end
