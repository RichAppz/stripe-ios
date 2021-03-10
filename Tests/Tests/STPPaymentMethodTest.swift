//
//  STPPaymentMethodTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPPaymentMethodTest: XCTestCase {
  // MARK: - STPPaymentMethodType Tests
  func testTypeFromString() {
    XCTAssertEqual(STPPaymentMethod.type(from: "card"), STPPaymentMethodType.card)
    XCTAssertEqual(STPPaymentMethod.type(from: "CARD"), STPPaymentMethodType.card)
    XCTAssertEqual(STPPaymentMethod.type(from: "card_present"), STPPaymentMethodType.cardPresent)
    XCTAssertEqual(STPPaymentMethod.type(from: "CARD_PRESENT"), STPPaymentMethodType.cardPresent)
    XCTAssertEqual(STPPaymentMethod.type(from: "unknown_string"), STPPaymentMethodType.unknown)
  }

  func testTypesFromStrings() {
    let rawTypes = [
      "card",
      "card_present",
    ]
    let expectedTypes: [STPPaymentMethodType] = [
      .card,
      .cardPresent,
    ]
    XCTAssertEqual(STPPaymentMethod.paymentMethodTypes(from: rawTypes), expectedTypes)
  }

  func testStringFromType() {
    let values: [STPPaymentMethodType] = [
      .card,
      .cardPresent,
      .unknown,
    ]
    for type in values {
      let string = STPPaymentMethod.string(from: type)

      switch type {
      case .card:
        XCTAssertEqual(string, "card")
      case .cardPresent:
        XCTAssertEqual(string, "card_present")
      case .unknown:
        XCTAssertNil(string)
      default:
        break
      }
    }
  }

  // MARK: - STPAPIResponseDecodable Tests
  func testDecodedObjectFromAPIResponseRequiredFields() {
    let fullJson = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)

    XCTAssertNotNil(
      STPPaymentMethod.decodedObject(fromAPIResponse: fullJson), "can decode with full json")

    let requiredFields = ["id"]

    for field in requiredFields {
      var partialJson = fullJson

      XCTAssertNotNil(partialJson?[field])
      partialJson?.removeValue(forKey: field)

      XCTAssertNil(STPPaymentIntent.decodedObject(fromAPIResponse: partialJson))
    }
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)
    let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: response)
    XCTAssertEqual(paymentMethod?.stripeId, "pm_123456789")
    XCTAssertEqual(paymentMethod?.created, Date(timeIntervalSince1970: 123_456_789))
    XCTAssertEqual(paymentMethod?.liveMode, false)
    XCTAssertEqual(paymentMethod?.type, .card)
    XCTAssertNotNil(paymentMethod?.billingDetails)
    XCTAssertNotNil(paymentMethod?.card)
    XCTAssertNil(paymentMethod?.customerId)
    XCTAssertEqual(paymentMethod!.allResponseFields as NSDictionary, response! as NSDictionary)
  }
}
