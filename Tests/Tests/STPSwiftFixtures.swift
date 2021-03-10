//
//  STPSwiftFixtures.swift
//  StripeiOS Tests
//
//  Created by David Estes on 10/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

@testable import Stripe

class MockEphemeralKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
  func createCustomerKey(
    withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock
  ) {
    completion(STPFixtures.ephemeralKey().allResponseFields, nil)
  }
}
