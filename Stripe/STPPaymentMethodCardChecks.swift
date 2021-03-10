//
//  STPPaymentMethodCardChecks.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The result of a check on a Card address or CVC.
@objc
public enum STPPaymentMethodCardCheckResult: Int {
  /// The check passed.
  case pass
  /// The check failed.
  case failed
  /// The check is unavailable.
  case unavailable
  /// The value was not checked.
  case unchecked
  /// Represents an unknown or null value.
  case unknown
}

/// Checks on Card address and CVC.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-checks
public class STPPaymentMethodCardChecks: NSObject, STPAPIResponseDecodable {
  override required init() {
    super.init()
  }

  @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardChecks.self), self),
      // Properties
      "addressLine1Check: \(allResponseFields["address_line1_check"] ?? "")",
      "addressPostalCodeCheck: \(allResponseFields["address_postal_code_check"] ?? "")",
      "cvcCheck: \(allResponseFields["cvc_check"] ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  @objc(checkResultFromString:)
  class func checkResult(from string: String?) -> STPPaymentMethodCardCheckResult {
    let check = string?.lowercased()
    if check == "pass" {
      return .pass
    } else if check == "failed" {
      return .failed
    } else if check == "unavailable" {
      return .unavailable
    } else if check == "unchecked" {
      return .unchecked
    } else {
      return .unknown
    }
  }

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let cardChecks = self.init()
    cardChecks.allResponseFields = response
    return cardChecks
  }
}
