//
//  STPSourceParams.swift
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Source object.
/// - seealso: https://stripe.com/docs/api#create_source
public class STPSourceParams: NSObject, STPFormEncodable, NSCopying {
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
  var redirectMerchantName: String?

  /// The type of the source to create. Required.

  @objc public var type: STPSourceType {
    get {
      return STPSource.type(from: rawTypeString ?? "")
    }
    set(type) {
      // If setting unknown and we're already unknown, don't want to override raw value
      if type != self.type {
        rawTypeString = STPSource.string(from: type)
      }
    }
  }
  /// The raw underlying type string sent to the server.
  /// Generally you should use `type` instead unless you have a reason not to.
  /// You can use this if you want to create a param of a type not yet supported
  /// by the current version of the SDK's `STPSourceType` enum.
  /// Setting this to a value not known by the SDK causes `type` to
  /// return `STPSourceTypeUnknown`
  @objc public var rawTypeString: String?
  /// A positive integer in the smallest currency unit representing the
  /// amount to charge the customer (e.g., @1099 for a €10.99 payment).
  /// Required for `single_use` sources.
  @objc public var amount: NSNumber?
  /// The currency associated with the source. This is the currency for which the source
  /// will be chargeable once ready.
  @objc public var currency: String?
  /// The authentication flow of the source to create. `flow` may be "redirect",
  /// "receiver", "verification", or "none". It is generally inferred unless a type
  /// supports multiple flows.
  @objc public var flow: STPSourceFlow
  /// A set of key/value pairs that you can attach to a source object.
  @objc public var metadata: [AnyHashable: Any]?
  /// Information about the owner of the payment instrument. May be used or required
  /// by particular source types.
  @objc public var owner: [AnyHashable: Any]?
  /// Parameters required for the redirect flow. Required if the source is
  /// authenticated by a redirect (`flow` is "redirect").
  @objc public var redirect: [AnyHashable: Any]?
  /// An optional token used to create the source. When passed, token properties will
  /// override source parameters.
  @objc public var token: String?
  /// Whether this source should be reusable or not. `usage` may be "reusable" or
  /// "single_use". Some source types may or may not be reusable by construction,
  /// while other may leave the option at creation.
  @objc public var usage: STPSourceUsage

  /// Initializes an empty STPSourceParams.
  override public required init() {
    rawTypeString = ""
    flow = .unknown
    usage = .unknown
    additionalAPIParameters = [:]
    super.init()
  }
}

// MARK: - Constructors
extension STPSourceParams {
  /// Creates params for a Bancontact source.
  /// - seealso: https://stripe.com/docs/bancontact#create-source
  /// - Parameters:
  ///   - amount:               The amount to charge the customer in EUR.
  ///   - name:                 The full name of the account holder.
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - statementDescriptor:  (Optional) A custom statement descriptor for
  /// the payment.
  /// @note The currency for Bancontact must be "eur". This will be set automatically
  /// for you.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @objc
  public class func bancontactParams(
    withAmount amount: Int,
    name: String,
    returnURL: String,
    statementDescriptor: String?
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .bancontact
    params.amount = NSNumber(value: amount)
    params.currency = "eur"  // Bancontact must always use eur
    params.owner = [
      "name": name
    ]
    params.redirect = [
      "return_url": returnURL
    ]
    if let statementDescriptor = statementDescriptor {
      params.additionalAPIParameters = [
        "bancontact": [
          "statement_descriptor": statementDescriptor
        ]
      ]
    }
    return params
  }

  /// Creates params for a Card source.
  /// - seealso: https://stripe.com/docs/sources/cards#create-source
  /// - Parameter card:        An object containing the user's card details
  /// - Returns: an STPSourceParams object populated with the provided card details.
  @objc
  public class func cardParams(withCard card: STPCardParams) -> STPSourceParams {
    let params = self.init()
    params.type = .card
    let keyPairs = STPFormEncoder.dictionary(forObject: card)["card"] as? [AnyHashable: Any]
    var cardDict: [AnyHashable: Any] = [:]
    let cardKeys = ["number", "cvc", "exp_month", "exp_year"]
    for key in cardKeys {
      if let keyPair = keyPairs?[key] {
        cardDict[key] = keyPair
      }
    }
    params.additionalAPIParameters = [
      "card": cardDict
    ]
    var addressDict: [AnyHashable: Any] = [:]
    let addressKeyMapping = [
      "address_line1": "line1",
      "address_line2": "line2",
      "address_city": "city",
      "address_state": "state",
      "address_zip": "postal_code",
      "address_country": "country",
    ]
    for key in addressKeyMapping.keys {
      if let newKey = addressKeyMapping[key],
        let keyPair = keyPairs?[key]
      {
        addressDict[newKey] = keyPair
      }
    }
    var ownerDict: [AnyHashable: Any] = [:]
    ownerDict["address"] = addressDict
    ownerDict["name"] = card.name
    params.owner = ownerDict
    return params
  }

  /// Creates params for a P24 source
  /// - seealso: https://stripe.com/docs/sources/p24#create-source
  /// - Parameters:
  ///   - amount:      The amount to charge the customer.
  ///   - currency:    The currency the payment is being created in (this must be
  /// EUR or PLN)
  ///   - email:       The email address of the account holder.
  ///   - name:        The full name of the account holder (optional).
  ///   - returnURL:   The URL the customer should be redirected to after they have
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func p24Params(
    withAmount amount: Int,
    currency: String,
    email: String,
    name: String?,
    returnURL: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .P24
    params.amount = NSNumber(value: amount)
    params.currency = currency

    var ownerDict = [
      "email": email
    ]
    if let name = name {
      ownerDict["name"] = name
    }
    params.owner = ownerDict
    params.redirect = [
      "return_url": returnURL
    ]
    return params
  }

  /// Creates params for a card source created from Visa Checkout.
  /// - seealso: https://stripe.com/docs/visa-checkout
  /// @note Creating an STPSource with these params will give you a
  /// source with type == STPSourceTypeCard
  /// - Parameter callId: The callId property from a `VisaCheckoutResult` object.
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func visaCheckoutParams(withCallId callId: String) -> STPSourceParams {
    let params = self.init()
    params.type = .card
    params.additionalAPIParameters = [
      "card": [
        "visa_checkout": [
          "callid": callId
        ]
      ]
    ]
    return params
  }

  /// Creates params for a card source created from Masterpass.
  /// - seealso: https://stripe.com/docs/masterpass
  /// @note Creating an STPSource with these params will give you a
  /// source with type == STPSourceTypeCard
  /// - Parameters:
  ///   - cartId: The cartId from a `MCCCheckoutResponse` object.
  ///   - transactionId: The transactionid from a `MCCCheckoutResponse` object.
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func masterpassParams(
    withCartId cartId: String,
    transactionId: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .card
    params.additionalAPIParameters = [
      "card": [
        "masterpass": [
          "cart_id": cartId,
          "transaction_id": transactionId,
        ]
      ]
    ]
    return params
  }

  /// Create params for a Multibanco source
  /// - seealso: https://stripe.com/docs/sources/multibanco
  /// - Parameters:
  ///   - amount:      The amount to charge the customer.
  ///   - returnURL:   The URL the customer should be redirected to after the
  /// authorization process.
  ///   - email:       The full email address of the customer.
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func multibancoParams(
    withAmount amount: Int,
    returnURL: String,
    email: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .multibanco
    params.currency = "eur"  // Multibanco must always use eur
    params.amount = NSNumber(value: amount)
    params.redirect = [
      "return_url": returnURL
    ]
    params.owner = [
      "email": email
    ]
    return params
  }

  @objc func flowString() -> String? {
    return STPSource.string(from: flow)
  }

  @objc func usageString() -> String? {
    return STPSource.string(from: usage)
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPSourceParams.self), self),
      // Basic source details
      "type = \((STPSource.string(from: type)) ?? "unknown")",
      "rawTypeString = \(rawTypeString ?? "")",
      // Additional source details (alphabetical)
      "amount = \(amount ?? 0)",
      "currency = \(currency ?? "")",
      "flow = \((STPSource.string(from: flow)) ?? "unknown")",
      "metadata = \(((metadata) != nil ? "<redacted>" : nil) ?? "")",
      "owner = \(((owner) != nil ? "<redacted>" : nil) ?? "")",
      "redirect = \(redirect ?? [:])",
      "token = \(token ?? "")",
      "usage = \((STPSource.string(from: usage)) ?? "unknown")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - Redirect Dictionary

  /// Private setter allows for setting the name of the app in the returnURL so
  /// that it can be displayed on hooks.stripe.com if the automatic redirect back
  /// to the app fails.
  /// We intercept the reading of redirect dictionary from STPFormEncoder and replace
  /// the value of return_url if necessary
  @objc
  public func redirectDictionaryWithMerchantNameIfNecessary() -> [AnyHashable: Any] {
    if (redirectMerchantName != nil) && redirect?["return_url"] != nil {

      let url = URL(string: redirect?["return_url"] as? String ?? "")
      if let url = url {
        let urlComponents = NSURLComponents(
          url: url,
          resolvingAgainstBaseURL: false)

        if let urlComponents = urlComponents {

          for item in urlComponents.queryItems ?? [] {
            if item.name == "redirect_merchant_name" {
              // Just return, don't replace their value
              return redirect ?? [:]
            }
          }

          // If we get here, there was no existing redirect name

          var queryItems: [URLQueryItem] = urlComponents.queryItems ?? [URLQueryItem]()

          queryItems.append(
            URLQueryItem(
              name: "redirect_merchant_name",
              value: redirectMerchantName))
          urlComponents.queryItems = queryItems as [URLQueryItem]?

          var redirectCopy = redirect
          redirectCopy?["return_url"] = urlComponents.url?.absoluteString

          return redirectCopy ?? [:]
        }
      }
    }

    return redirect ?? [:]

  }

  // MARK: - STPFormEncodable
  public class func rootObjectName() -> String? {
    return nil
  }

  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:rawTypeString)): "type",
      NSStringFromSelector(#selector(getter:amount)): "amount",
      NSStringFromSelector(#selector(getter:currency)): "currency",
      NSStringFromSelector(#selector(flowString)): "flow",
      NSStringFromSelector(#selector(getter:metadata)): "metadata",
      NSStringFromSelector(#selector(getter:owner)): "owner",
      NSStringFromSelector(#selector(redirectDictionaryWithMerchantNameIfNecessary)): "redirect",
      NSStringFromSelector(#selector(getter:token)): "token",
      NSStringFromSelector(#selector(usageString)): "usage",
    ]
  }

  // MARK: - NSCopying
  /// :nodoc:
  public func copy(with zone: NSZone? = nil) -> Any {
    let copy = Swift.type(of: self).init()
    copy.type = type
    copy.amount = amount
    copy.currency = currency
    copy.flow = flow
    copy.metadata = metadata
    copy.owner = owner
    copy.redirect = redirect
    copy.token = token
    copy.usage = usage
    return copy
  }
}
