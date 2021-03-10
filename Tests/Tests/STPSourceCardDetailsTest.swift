//
//  STPSourceCardDetailsTest.swift
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPSourceCardDetailsTest: XCTestCase {

  // MARK: - Description Tests
  func testDescription() {
    let cardDetails = STPSourceCardDetails.decodedObject(
      fromAPIResponse: STPTestUtils.jsonNamed("CardSource")!["card"] as? [AnyHashable: Any])
    XCTAssert(cardDetails?.description != nil)
  }

  // MARK: - STPAPIResponseDecodable Tests
  func testDecodedObjectFromAPIResponseRequiredFields() {
    let requiredFields: [String]? = []

    for field in requiredFields ?? [] {
      var response = STPTestUtils.jsonNamed("CardSource")?["card"] as? [AnyHashable: Any]
      response?.removeValue(forKey: field)

      XCTAssertNil(STPSourceCardDetails.decodedObject(fromAPIResponse: response))
    }

    XCTAssert(
      (STPSourceCardDetails.decodedObject(
        fromAPIResponse: STPTestUtils.jsonNamed("CardSource")!["card"] as? [AnyHashable: Any])
        != nil))
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response = STPTestUtils.jsonNamed("CardSource")?["card"] as? [AnyHashable: Any]
    let cardDetails = STPSourceCardDetails.decodedObject(fromAPIResponse: response)!

    XCTAssertEqual(cardDetails.brand, .visa)
    XCTAssertEqual(cardDetails.country, "US")
    XCTAssertEqual(cardDetails.expMonth, UInt(12))
    XCTAssertEqual(cardDetails.expYear, UInt(2034))
    XCTAssertEqual(cardDetails.funding, .debit)
    XCTAssertEqual(cardDetails.last4, "5556")

    XCTAssertEqual(cardDetails.allResponseFields as NSDictionary, response! as NSDictionary)
  }
}
