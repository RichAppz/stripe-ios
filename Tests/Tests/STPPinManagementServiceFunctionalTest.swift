//
//  STPPinManagementFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import PassKit
import XCTest

@testable import Stripe

class TestEphemeralKeyProvider: NSObject, STPIssuingCardEphemeralKeyProvider {
  func createIssuingCardKey(
    withAPIVersion apiVersion: String,
    completion: STPJSONResponseCompletionBlock
  ) {
    print("apiVersion \(apiVersion)")
    let response =
      [
        "id": "ephkey_token",
        "object": "ephemeral_key",
        "associated_objects": [
          [
            "type": "issuing.card",
            "id": "ic_token",
          ]
        ],
        "created": NSNumber(value: 1_556_656_558),
        "expires": NSNumber(value: 1_556_660_158),
        "livemode": NSNumber(value: true),
        "secret": "ek_live_secret",
      ] as [String: Any]
    completion(response, nil)
  }
}

