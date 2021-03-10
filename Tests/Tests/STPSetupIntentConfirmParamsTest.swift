//
//  STPSetupIntentConfirmParamsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/15/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPSetupIntentConfirmParamsTest: XCTestCase {
  func testInit() {
    for params in [
      STPSetupIntentConfirmParams(clientSecret: "secret"),
      STPSetupIntentConfirmParams(),
      STPSetupIntentConfirmParams(),
    ] {
      XCTAssertNotNil(params)
      XCTAssertNotNil(params.clientSecret)
      XCTAssertNotNil(params.additionalAPIParameters)
      XCTAssertEqual(params.additionalAPIParameters.count, 0)
      XCTAssertNil(params.paymentMethodID)
      XCTAssertNil(params.returnURL)
      XCTAssertNil(params.useStripeSDK)
    }
  }

  func testDescription() {
    let params = STPSetupIntentConfirmParams()
    XCTAssertNotNil(params.description)
  }

  func testDefaultMandateData() {
    let params = STPSetupIntentConfirmParams()
    params.paymentMethodParams = STPPaymentMethodParams()
    params.paymentMethodParams?.rawTypeString = "card"
  }

  // MARK: STPFormEncodable Tests
  func testRootObjectName() {
    XCTAssertNil(STPSetupIntentConfirmParams.rootObjectName())
  }

  func testPropertyNamesToFormFieldNamesMapping() {
    let params = STPSetupIntentConfirmParams()

    let mapping = STPSetupIntentConfirmParams.propertyNamesToFormFieldNamesMapping()

    for propertyName in mapping.keys {
      XCTAssertFalse(propertyName.contains(":"))
      XCTAssert(params.responds(to: NSSelectorFromString(propertyName)))
    }

    for formFieldName in mapping.values {
      XCTAssert(formFieldName.count > 0)
    }

    XCTAssertEqual(mapping.values.count, Set<String>(mapping.values).count)
  }

  func testCopy() {
    let params = STPSetupIntentConfirmParams(clientSecret: "test_client_secret")
    params.paymentMethodParams = STPPaymentMethodParams()
    params.paymentMethodID = "test_payment_method_id"
    params.returnURL = "fake://testing_only"
    params.useStripeSDK = NSNumber(value: true)
    params.additionalAPIParameters = [
      "other_param": "other_value"
    ]

    let paramsCopy = params.copy() as! STPSetupIntentConfirmParams
    XCTAssertEqual(params.clientSecret, paramsCopy.clientSecret)
    XCTAssertEqual(params.paymentMethodID, paramsCopy.paymentMethodID)

    // assert equal, not equal objects, because this is a shallow copy
    XCTAssertEqual(params.paymentMethodParams, paramsCopy.paymentMethodParams)

    XCTAssertEqual(params.returnURL, paramsCopy.returnURL)
    XCTAssertEqual(params.useStripeSDK, paramsCopy.useStripeSDK)
    XCTAssertEqual(
      params.additionalAPIParameters as NSDictionary,
      paramsCopy.additionalAPIParameters as NSDictionary)

  }

  func testClientSecretValidation() {
    XCTAssertFalse(
      STPSetupIntentConfirmParams.isClientSecretValid("seti_12345"),
      "'seti_12345' is not a valid client secret.")
    XCTAssertFalse(
      STPSetupIntentConfirmParams.isClientSecretValid("seti_12345_secret_"),
      "'seti_12345_secret_' is not a valid client secret.")
    XCTAssertFalse(
      STPSetupIntentConfirmParams.isClientSecretValid(
        "seti_a1b2c3_secret_x7y8z9seti_a1b2c3_secret_x7y8z9"),
      "'seti_a1b2c3_secret_x7y8z9seti_a1b2c3_secret_x7y8z9' is not a valid client secret.")
    XCTAssertFalse(
      STPSetupIntentConfirmParams.isClientSecretValid("pi_a1b2c3_secret_x7y8z9"),
      "'pi_a1b2c3_secret_x7y8z9' is not a valid client secret.")

    XCTAssertTrue(
      STPSetupIntentConfirmParams.isClientSecretValid("seti_a1b2c3_secret_x7y8z9"),
      "'seti_a1b2c3_secret_x7y8z9' is a valid client secret.")
    XCTAssertTrue(
      STPSetupIntentConfirmParams.isClientSecretValid(
        "seti_1Eq5kyGMT9dGPIDGxiSp4cce_secret_FKlHb3yTI0YZWe4iqghS8ZXqwwMoMmy"),
      "'seti_1Eq5kyGMT9dGPIDGxiSp4cce_secret_FKlHb3yTI0YZWe4iqghS8ZXqwwMoMmy' is a valid client secret."
    )
  }
}
