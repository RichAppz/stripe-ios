//
//  STPCard.swift
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

import Foundation
import UIKit

/// The various funding sources for a payment card.
@objc
public enum STPCardFundingType: Int {
  /// Debit card funding
  case debit
  /// Credit card funding
  case credit
  /// Prepaid card funding
  case prepaid
  /// An other or unknown type of funding source.
  case other
}

/// Representation of a user's credit card details that have been tokenized with
/// the Stripe API
/// - seealso: https://stripe.com/docs/api#cards
public class STPCard: NSObject, STPAPIResponseDecodable, STPPaymentOption {
  /// The last 4 digits of the card.
  @objc public internal(set) var last4: String
  /// For cards made with Apple Pay, this refers to the last 4 digits of the
  /// "Device Account Number" for the tokenized card. For regular cards, it will
  /// be nil.
  @objc public internal(set) var dynamicLast4: String?
  /// Whether or not the card originated from Apple Pay.

  @objc public var isApplePayCard: Bool {
    return (allResponseFields["tokenization_method"] as? String) == "apple_pay"
  }
  /// The card's expiration month. 1-indexed (i.e. 1 == January)
  @objc public internal(set) var expMonth = 0
  /// The card's expiration year.
  @objc public internal(set) var expYear = 0
  /// The cardholder's name.
  @objc public internal(set) var name: String?
  /// The issuer of the card.
  @objc public internal(set) var brand: STPCardBrand = .unknown
  /// The funding source for the card (credit, debit, prepaid, or other)
  @objc public internal(set) var funding: STPCardFundingType = .other
  /// Two-letter ISO code representing the issuing country of the card.
  @objc public internal(set) var country: String?
  /// This is only applicable when tokenizing debit cards to issue payouts to managed
  /// accounts. You should not set it otherwise. The card can then be used as a
  /// transfer destination for funds in this currency.
  @objc public internal(set) var currency: String?

  /// Returns a string representation for the provided card brand;
  /// i.e. `STPCard.string(from brand: .visa) == "Visa"`.
  /// - Parameter brand: the brand you want to convert to a string
  /// - Returns: A string representing the brand, suitable for displaying to a user.
  @objc(stringFromBrand:)
  public class func string(from brand: STPCardBrand) -> String {
    return STPCardBrandUtilities.stringFrom(brand) ?? ""
  }

  /// This parses a string representing a card's brand into the appropriate
  /// STPCardBrand enum value,
  /// i.e. `STPCard.brand(from string: "American Express") == .amex`.
  /// The string values themselves are specific to Stripe as listed in the Stripe API
  /// documentation.
  /// - seealso: https://stripe.com/docs/api#card_object-brand
  /// - Parameter string: a string representing the card's brand as returned from
  /// the Stripe API
  /// - Returns: an enum value mapped to that string. If the string is unrecognized,
  /// returns STPCardBrandUnknown.
  @objc(brandFromString:)
  public class func brand(from string: String) -> STPCardBrand {
    // Documentation: https://stripe.com/docs/api#card_object-brand
    let brand = string.lowercased()
    if brand == "visa" {
      return .visa
    } else if (brand == "american express") || (brand == "american_express") {
      return .amex
    } else if brand == "mastercard" {
      return .mastercard
    } else if brand == "discover" {
      return .discover
    } else if brand == "jcb" {
      return .JCB
    } else if (brand == "diners club") || (brand == "diners_club") {
      return .dinersClub
    } else if brand == "unionpay" {
      return .unionPay
    } else {
      return .unknown
    }
  }

  /// This parses a string representing a card's funding type into the appropriate
  /// `STPCardFundingType` enum value,
  /// i.e. `STPCard.funding(from string:"prepaid") == .prepaid`.
  /// - Parameter string: a string representing the card's funding type as returned from
  /// the Stripe API
  /// - Returns: an enum value mapped to that string. If the string is unrecognized,
  /// returns `STPCardFundingTypeOther`.
  @objc(fundingFromString:)
  public class func funding(from string: String) -> STPCardFundingType {
    let key = string.lowercased()
    let fundingNumber = self.stringToFundingMapping()[key]

    if let fundingNumber = fundingNumber {
      return (STPCardFundingType(rawValue: fundingNumber.intValue))!
    }

    return .other
  }

  @objc public var stripeID: String
  internal(set) public var allResponseFields: [AnyHashable: Any] = [:]

  // See STPCard+Private.h

  // MARK: - STPCardBrand

  // MARK: - STPCardFundingType
  class func stringToFundingMapping() -> [String: NSNumber] {
    return [
      "credit": NSNumber(value: STPCardFundingType.credit.rawValue),
      "debit": NSNumber(value: STPCardFundingType.debit.rawValue),
      "prepaid": NSNumber(value: STPCardFundingType.prepaid.rawValue),
    ]
  }

  class func string(fromFunding funding: STPCardFundingType) -> String? {
    return
      (self.stringToFundingMapping() as NSDictionary).allKeys(
        for: NSNumber(value: funding.rawValue)
      ).first as? String
  }

  // MARK: -

  // MARK: - Equality
  /// :nodoc:
  @objc
  public override func isEqual(_ other: Any?) -> Bool {
    return isEqual(to: other as? STPCard)
  }

  /// :nodoc:
  @objc public override var hash: Int {
    return stripeID.hash
  }

  func isEqual(to other: STPCard?) -> Bool {
    if self === other {
      return true
    }

    if other == nil || !(other != nil) {
      return false
    }

    return stripeID == other?.stripeID
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPCard.self), self),
      // Identifier
      "stripeID = \(stripeID )",
      // Basic card details
      "brand = \(STPCard.string(from: brand))",
      "last4 = \(last4 )",
      String(format: "expMonth = %lu", UInt(expMonth)),
      String(format: "expYear = %lu", UInt(expYear)),
      "funding = \((STPCard.string(fromFunding: funding)) ?? "unknown")",
      // Additional card details (alphabetical)
      "country = \(country ?? "")",
      "currency = \(currency ?? "")",
      "dynamicLast4 = \(dynamicLast4 ?? "")",
      "isApplePayCard = \((isApplePayCard) ? "YES" : "NO")",
      // Cardholder details
      "name = \(((name) != nil ? "<redacted>" : nil) ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPAPIResponseDecodable
  @objc func stripeObject() -> String {
    return "card"
  }

  required init(stripeID: String, last4: String) {
    self.stripeID = stripeID
    self.last4 = last4
    super.init()
  }

  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    // required fields
    guard let stripeId = dict.stp_string(forKey: "id"),
      let last4 = dict.stp_string(forKey: "last4"),
      let rawBrand = dict.stp_string(forKey: "brand"),
      dict.stp_number(forKey: "exp_month") != nil,
      dict.stp_number(forKey: "exp_year") != nil
    else {
      return nil
    }

    let card = self.init(stripeID: stripeId, last4: last4)

    card.stripeID = stripeId
    card.name = dict.stp_string(forKey: "name")
    card.last4 = last4
    card.dynamicLast4 = dict.stp_string(forKey: "dynamic_last4")
    card.brand = self.brand(from: rawBrand)
    let rawFunding = dict.stp_string(forKey: "funding")
    card.funding = self.funding(from: rawFunding ?? "")

    card.country = dict.stp_string(forKey: "country")
    card.currency = dict.stp_string(forKey: "currency")
    card.expMonth = dict.stp_int(forKey: "exp_month", or: 0)
    card.expYear = dict.stp_int(forKey: "exp_year", or: 0)

    card.allResponseFields = response
    return card
  }

  @objc public var label: String {
    let brand = STPCard.string(from: self.brand)
    return "\(brand) \(last4 )"
  }

  @objc public var isReusable: Bool {
    return true
  }
    
}
