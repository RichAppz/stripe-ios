//
//  STPPaymentIntentTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPPaymentIntentTest: XCTestCase {
  func testIdentifierFromSecret() {
    XCTAssertEqual(
      STPPaymentIntent.id(fromClientSecret: "pi_123_secret_XYZ"),
      "pi_123")
    XCTAssertEqual(
      STPPaymentIntent.id(fromClientSecret: "pi_123_secret_RandomlyContains_secret_WhichIsFine"),
      "pi_123")

    XCTAssertNil(STPPaymentIntent.id(fromClientSecret: ""))
    XCTAssertNil(STPPaymentIntent.id(fromClientSecret: "po_123_secret_HasBadPrefix"))
    XCTAssertNil(STPPaymentIntent.id(fromClientSecret: "MissingSentinalForSplitting"))
  }

  // MARK: - Description Tests
  func testDescription() {
    let paymentIntent = STPFixtures.paymentIntent()

    XCTAssertNotNil(paymentIntent)
    let desc = paymentIntent.description
    XCTAssertTrue(desc.contains(NSStringFromClass(type(of: paymentIntent).self)))
    XCTAssertGreaterThan((desc.count), 500, "Custom description should be long")
  }

  // MARK: - STPAPIResponseDecodable Tests
  func testDecodedObjectFromAPIResponseRequiredFields() {
    let fullJson = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)

    XCTAssertNotNil(
      STPPaymentIntent.decodedObject(fromAPIResponse: fullJson), "can decode with full json")

    let requiredFields = ["id", "client_secret", "amount", "currency", "livemode", "status"]

    for field in requiredFields {
      var partialJson = fullJson

      XCTAssertNotNil(partialJson?[field])
      partialJson?.removeValue(forKey: field)

      XCTAssertNil(STPPaymentIntent.decodedObject(fromAPIResponse: partialJson))
    }
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response = STPTestUtils.jsonNamed("PaymentIntent")!
    let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: response)!

    XCTAssertEqual(paymentIntent.stripeId, "pi_1Cl15wIl4IdHmuTbCWrpJXN6")
    XCTAssertEqual(
      paymentIntent.clientSecret, "pi_1Cl15wIl4IdHmuTbCWrpJXN6_secret_EkKtQ7Sg75hLDFKqFG8DtWcaK")
    XCTAssertEqual(paymentIntent.amount, 2345)
    XCTAssertEqual(paymentIntent.canceledAt, Date(timeIntervalSince1970: 1_530_911_045))
    XCTAssertEqual(paymentIntent.captureMethod, .manual)
    XCTAssertEqual(paymentIntent.confirmationMethod, .automatic)
    XCTAssertEqual(paymentIntent.created, Date(timeIntervalSince1970: 1_530_911_040))
    XCTAssertEqual(paymentIntent.currency, "usd")
    XCTAssertEqual(paymentIntent.stripeDescription, "My Sample PaymentIntent")
    XCTAssertFalse(paymentIntent.livemode)
    XCTAssertEqual(paymentIntent.receiptEmail, "danj@example.com")

    // nextAction
    XCTAssertNotNil(paymentIntent.nextAction)
    XCTAssertEqual(paymentIntent.nextAction!.type, .redirectToURL)
    XCTAssertNotNil(paymentIntent.nextAction!.redirectToURL)
    XCTAssertNotNil(paymentIntent.nextAction!.redirectToURL!.url)
    let returnURL = paymentIntent.nextAction!.redirectToURL!.returnURL
    XCTAssertNotNil(returnURL)
    XCTAssertEqual(returnURL, URL(string: "payments-example://stripe-redirect"))
    let url = paymentIntent.nextAction!.redirectToURL!.url
    XCTAssertNotNil(url)

    XCTAssertEqual(
      url,
      URL(
        string:
          "https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk"
      ))
    XCTAssertEqual(paymentIntent.sourceId, "src_1Cl1AdIl4IdHmuTbseiDWq6m")
    XCTAssertEqual(paymentIntent.status, .requiresAction)

    XCTAssertEqual(
      paymentIntent.paymentMethodTypes, [NSNumber(value: STPPaymentMethodType.card.rawValue)])

    // lastPaymentError

    XCTAssertNotNil(paymentIntent.lastPaymentError)
    XCTAssertEqual(paymentIntent.lastPaymentError!.code, "payment_intent_authentication_failure")
    XCTAssertEqual(
      paymentIntent.lastPaymentError!.docURL,
      "https://stripe.com/docs/error-codes/payment-intent-authentication-failure")
    XCTAssertEqual(
      paymentIntent.lastPaymentError!.message,
      "The provided PaymentMethod has failed authentication. You can provide payment_method_data or a new PaymentMethod to attempt to fulfill this PaymentIntent again."
    )
    XCTAssertNotNil(paymentIntent.lastPaymentError!.paymentMethod)
    XCTAssertEqual(paymentIntent.lastPaymentError!.type, .invalidRequest)

    XCTAssertEqual(paymentIntent.allResponseFields as NSDictionary, response as NSDictionary)
  }
}
