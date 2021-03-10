//
//  STPFixtures.h
//  Stripe
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <PassKit/PassKit.h>
@import Stripe;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const STPTestJSONCustomer;

extern NSString *const STPTestJSONCard;

extern NSString *const STPTestJSONPaymentIntent;
extern NSString *const STPTestJSONSetupIntent;
extern NSString *const STPTestJSONPaymentMethodCard;
extern NSString *const STPTestJSONPaymentMethodApplePay;

extern NSString *const STPTestJSONSourceCard;

@interface STPFixtures : NSObject

/**
 A PKPaymentObject with test payment data.
 */
+ (PKPayment *)applePayPayment;

/**
 A PKPayment from the simulator that can be tokenized in testmode.
 */
+ (PKPayment *)simulatorApplePayPayment;

/**
 A valid PKPaymentRequest with dummy data.
 */
+ (PKPaymentRequest *)applePayRequest;

/**
 A CardParams object with a valid number, expMonth, expYear, and cvc.
 */
+ (STPCardParams *)cardParams;

/**
 A valid card object
 */
+ (STPCard *)card;

/**
 A Token for a card
 */
+ (STPToken *)cardToken;

/**
 A PaymentIntent object
 */
+ (STPPaymentIntent *)paymentIntent;

/**
 A SetupIntent object
 */
+ (STPSetupIntent *)setupIntent;

/**
 A PaymentConfiguration object with a fake publishable key. Use this to avoid
 triggering our asserts when publishable key is nil or invalid. All other values
 are at their original defaults.
 */
+ (STPPaymentConfiguration *)paymentConfiguration;

/**
 A customer-scoped ephemeral key that expires in 100 seconds.
 */
+ (STPEphemeralKey *)ephemeralKey;

/**
 A customer-scoped ephemeral key that expires in 10 seconds.
 */
+ (STPEphemeralKey *)expiringEphemeralKey;

/**
 A PaymentMethod object
 */
+ (STPPaymentMethod *)paymentMethod;

/**
 A STPPaymentMethodCardParams object with a valid number, expMonth, expYear, and cvc.
 */
+ (STPPaymentMethodCardParams *)paymentMethodCardParams;

/**
 An Apple Pay Payment Method object.
 */
+ (STPPaymentMethod *)applePayPaymentMethod;

@end

@interface STPJsonSources : NSObject

@end

NS_ASSUME_NONNULL_END
