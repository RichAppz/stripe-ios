//
//  STPSourceCardDetails.swift
//  Stripe
//
//  Created by Brian Dorfman on 2/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// The status of this card's 3D Secure support.
/// - seealso: https://stripe.com/docs/sources/three-d-secure#check-requirement
@objc
public enum STPSourceCard3DSecureStatus: Int {
  /// 3D Secure is required. This card must be converted into a 3D Secure
  /// source for a charge on it to be successful.
  case `required`
  /// 3D Secure is optional. It is not required nor recommended for successful charging,
  /// but can be performed to help reduce the likelihood of fraud.
  case `optional`
  /// 3D Secure is not supported on this card.
  case notSupported
  /// 3D Secure is recommended. The process is not required, but it is highly recommended
  /// and has minimal impact to your conversion rate.
  case recommended
  /// The status of 3D Secure support on this card is unknown.
  case unknown
}

/// This class provides typed access to the contents of an STPSource `details`
/// dictionary for card sources.
public class STPSourceCardDetails: NSObject, STPAPIResponseDecodable {
  /// The last 4 digits of the card.
  @objc public private(set) var last4: String?
  /// The card's expiration month. 1-indexed (i.e. 1 == January)
  @objc public private(set) var expMonth: UInt = 0
  /// The card's expiration year.
  @objc public private(set) var expYear: UInt = 0
  /// The issuer of the card.
  @objc public private(set) var brand: STPCardBrand = .unknown
  /// The funding source for the card (credit, debit, prepaid, or other)
  @objc public private(set) var funding: STPCardFundingType = .other
  /// Two-letter ISO code representing the issuing country of the card.
  @objc public private(set) var country: String?
  /// True if this card was created through Apple Pay, false otherwise.
  @objc public private(set) var isApplePayCard = false
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  // See STPSourceCardDetails+Private.h

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    return self.init(dictionary: response)
  }

  required init(dictionary dict: [AnyHashable: Any]) {
    allResponseFields = dict
    let dict = (dict as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
    last4 = dict.stp_string(forKey: "last4")
    brand = STPCard.brand(from: dict.stp_string(forKey: "brand") ?? "")
    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Wdeprecated"
    // This is only intended to be deprecated publicly.
    // When removed from public header, can remove these pragmas
    funding = STPCard.funding(from: dict.stp_string(forKey: "funding") ?? "")
    //#pragma clang diagnostic pop
    country = dict.stp_string(forKey: "country")
    expMonth = UInt(dict.stp_int(forKey: "exp_month", or: 0))
    expYear = UInt(dict.stp_int(forKey: "exp_year", or: 0))
    isApplePayCard = dict.stp_string(forKey: "tokenization_method") == "apple_pay"
    super.init()
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPSourceCardDetails.self), self),
      // Basic card details
      "brand = \(STPCard.string(from: brand))",
      "last4 = \(last4 ?? "")",
      String(format: "expMonth = %lu", UInt(expMonth)),
      String(format: "expYear = %lu", UInt(expYear)),
      "funding = \((STPCard.string(fromFunding: funding)) ?? "unknown")",
      // Additional card details (alphabetical)
      "country = \(country ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }
}
