//
//  STPPaymentIntentParamsTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPPaymentIntentParamsTest: XCTestCase {
  func testInit() {
    for params in [
      STPPaymentIntentParams(clientSecret: "secret"),
      STPPaymentIntentParams(),
      STPPaymentIntentParams(),
    ] {
      XCTAssertNotNil(params)
      XCTAssertNotNil(params.clientSecret)
      XCTAssertNotNil(params.additionalAPIParameters)
      XCTAssertEqual(params.additionalAPIParameters.count, 0)

      XCTAssertNil(params.stripeId, "invalid secrets, no stripeId")
      XCTAssertNil(params.sourceParams)
      XCTAssertNil(params.sourceId)
      XCTAssertNil(params.receiptEmail)
      XCTAssertNil(params.savePaymentMethod)
      XCTAssertNil(params.returnURL)
      XCTAssertNil(params.setupFutureUsage)
      XCTAssertNil(params.useStripeSDK)
      XCTAssertNil(params.mandateData)
      XCTAssertNil(params.paymentMethodOptions)
    }
  }

  func testDescription() {
    let params = STPPaymentIntentParams()
    XCTAssertNotNil(params.description)
  }

  // MARK: STPFormEncodable Tests
  func testRootObjectName() {
    XCTAssertNil(STPPaymentIntentParams.rootObjectName())
  }

  func testPropertyNamesToFormFieldNamesMapping() {
    let params = STPPaymentIntentParams()

    let mapping = STPPaymentIntentParams.propertyNamesToFormFieldNamesMapping()

    for propertyName in mapping.keys {
      XCTAssertFalse(propertyName.contains(":"))
      XCTAssert(params.responds(to: NSSelectorFromString(propertyName)))
    }

    for formFieldName in mapping.values {
      XCTAssert(formFieldName.count > 0)
    }

    XCTAssertEqual(mapping.values.count, NSSet(array: (mapping as NSDictionary).allValues).count)
  }

  func testCopy() {
    let params = STPPaymentIntentParams(clientSecret: "test_client_secret")
    params.paymentMethodParams = STPPaymentMethodParams()
    params.paymentMethodId = "test_payment_method_id"
    params.savePaymentMethod = NSNumber(value: true)
    params.returnURL = "fake://testing_only"
    params.setupFutureUsage = STPPaymentIntentSetupFutureUsage(rawValue: Int(truncating: NSNumber(value: 1)))
    params.useStripeSDK = NSNumber(value: true)
    params.mandateData = STPMandateDataParams(
      customerAcceptance: STPMandateCustomerAcceptanceParams(type: .offline, onlineParams: nil)!)
    params.paymentMethodOptions = STPConfirmPaymentMethodOptions()
    params.additionalAPIParameters = [
      "other_param": "other_value"
    ]

    let paramsCopy = params.copy() as! STPPaymentIntentParams
    XCTAssertEqual(params.clientSecret, paramsCopy.clientSecret)
    XCTAssertEqual(params.paymentMethodId, paramsCopy.paymentMethodId)

    // assert equal, not equal objects, because this is a shallow copy
    XCTAssertEqual(params.paymentMethodParams, paramsCopy.paymentMethodParams)
    XCTAssertEqual(params.mandateData, paramsCopy.mandateData)

    XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.none)
    XCTAssertEqual(params.savePaymentMethod, paramsCopy.savePaymentMethod)
    XCTAssertEqual(params.returnURL, paramsCopy.returnURL)
    XCTAssertEqual(params.useStripeSDK, paramsCopy.useStripeSDK)
    XCTAssertEqual(params.paymentMethodOptions, paramsCopy.paymentMethodOptions)
    XCTAssertEqual(
      params.additionalAPIParameters as NSDictionary,
      paramsCopy.additionalAPIParameters as NSDictionary)

  }

  func testClientSecretValidation() {
    XCTAssertFalse(
      STPPaymentIntentParams.isClientSecretValid("pi_12345"),
      "'pi_12345' is not a valid client secret.")
    XCTAssertFalse(
      STPPaymentIntentParams.isClientSecretValid("pi_12345_secret_"),
      "'pi_12345_secret_' is not a valid client secret.")
    XCTAssertFalse(
      STPPaymentIntentParams.isClientSecretValid("pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9"),
      "'pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9' is not a valid client secret.")
    XCTAssertFalse(
      STPPaymentIntentParams.isClientSecretValid("seti_a1b2c3_secret_x7y8z9"),
      "'seti_a1b2c3_secret_x7y8z9' is not a valid client secret.")

    XCTAssertTrue(
      STPPaymentIntentParams.isClientSecretValid("pi_a1b2c3_secret_x7y8z9"),
      "'pi_a1b2c3_secret_x7y8z9' is a valid client secret.")
    XCTAssertTrue(
      STPPaymentIntentParams.isClientSecretValid(
        "pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA"),
      "'pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA' is a valid client secret.")
  }
}
