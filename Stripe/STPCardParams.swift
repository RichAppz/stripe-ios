//
//  STPCardParams.swift
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation

/// Representation of a user's credit card details. You can assemble these with
/// information that your user enters and then create Stripe tokens with them using
/// an STPAPIClient.
/// - seealso: https://stripe.com/docs/api#cards
public class STPCardParams: NSObject, STPFormEncodable, NSCopying {
  public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// The card's number.
  @objc public var number: String?

  /// The last 4 digits of the card's number, if it's been set, otherwise nil.
  @objc
  public func last4() -> String? {
    if number != nil && (number?.count ?? 0) >= 4 {
      return (number as NSString?)?.substring(from: (number?.count ?? 0) - 4)
    } else {
      return nil
    }
  }

  /// The card's expiration month.
  @objc public var expMonth: UInt = 0
  /// The card's expiration year.
  @objc public var expYear: UInt = 0
  /// The card's security code, found on the back.
  @objc public var cvc: String?
  
  /// The cardholder's name.
  /// @note Changing this property will also changing the name of the
  /// param's `address` property.
  @objc public var name: String? {
    didSet {
      
    }
  }
  
  /// Three-letter ISO currency code representing the currency paid out to the bank
  /// account. This is only applicable when tokenizing debit cards to issue payouts
  /// to managed accounts. You should not set it otherwise. The card can then be
  /// used as a transfer destination for funds in this currency.
  @objc public var currency: String?

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPCardParams.self), self),
      // Basic card details
      "last4 = \(last4() ?? "")",
      String(format: "expMonth = %lu", UInt(expMonth)),
      String(format: "expYear = %lu", UInt(expYear)),
      "cvc = \(((cvc) != nil ? "<redacted>" : nil) ?? "")",
      // Additional card details (alphabetical)
      "currency = \(currency ?? "")",
      // Cardholder details
      "name = \(((name) != nil ? "<redacted>" : nil) ?? "")",
      "address = <redcated>",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPFormEncodable
  public class func rootObjectName() -> String? {
    return "card"
  }

  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:number)): "number",
      NSStringFromSelector(#selector(getter:cvc)): "cvc",
      NSStringFromSelector(#selector(getter:name)): "name",
      NSStringFromSelector(#selector(getter:expMonth)): "exp_month",
      NSStringFromSelector(#selector(getter:expYear)): "exp_year",
      NSStringFromSelector(#selector(getter:currency)): "currency",
    ]
  }

  // MARK: - NSCopying
  /// :nodoc:
  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    let copyCardParams = STPCardParams()

    copyCardParams.number = number
    copyCardParams.expMonth = expMonth
    copyCardParams.expYear = expYear
    copyCardParams.cvc = cvc

    // Use ivar to avoid setName:/setAddress: behavior that'd possibly overwrite name/address.name
    copyCardParams.name = name

    copyCardParams.currency = currency
    copyCardParams.additionalAPIParameters = additionalAPIParameters

    return copyCardParams
  }
}
