//
//  STPPaymentConfiguration.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

/// An `STPPaymentConfiguration` represents all the options you can set or change
/// around a payment.
/// You provide an `STPPaymentConfiguration` object to your `STPPaymentContext`
/// when making a charge. The configuration generally has settings that
/// will not change from payment to payment and thus is reusable, while the context
/// is specific to a single particular payment instance.
public class STPPaymentConfiguration: NSObject, NSCopying {
  /// This is a convenience singleton configuration that uses the default values for
  /// every property
  @objc(sharedConfiguration) public static var shared = STPPaymentConfiguration()

  private var _applePayEnabled = true
  /// The user is allowed to pay with Apple Pay if it's configured and available on their device.
  @objc public var applePayEnabled: Bool {
    get {
      return appleMerchantIdentifier != nil && _applePayEnabled
        && StripeAPI.deviceSupportsApplePay()
    }
    set {
      _applePayEnabled = newValue
    }
  }

  /// The user is allowed to pay with FPX.
  @objc public var fpxEnabled = false
  /// The set of countries supported when entering an address. This property accepts
  /// a set of ISO 2-character country codes.
  /// The default value is all known countries. Setting this property will limit
  /// the available countries to your selected set.
  @objc public var availableCountries: Set<String> = Set<String>(NSLocale.isoCountryCodes)

  /// The name of your company, for displaying to the user during payment flows. For
  /// example, when using Apple Pay, the payment sheet's final line item will read
  /// "PAY {companyName}".
  /// The default value is the name of your iOS application which is derived from the
  /// `kCFBundleNameKey` of `Bundle.main`.
  @objc public var companyName = Bundle.stp_applicationName() ?? ""
  /// The Apple Merchant Identifier to use during Apple Pay transactions. To create
  /// one of these, see our guide at https://stripe.com/docs/mobile/apple-pay . You
  /// must set this to a valid identifier in order to automatically enable Apple Pay.
  @objc public var appleMerchantIdentifier: String?
  /// Determines whether or not the user is able to delete payment options
  /// This is only relevant to the `STPPaymentOptionsViewController` which, if
  /// enabled, will allow the user to delete payment options by tapping the "Edit"
  /// button in the navigation bar or by swiping left on a payment option and tapping
  /// "Delete". Currently, the user is not allowed to delete the selected payment
  /// option but this may change in the future.
  /// Default value is YES but will only work if `STPPaymentOptionsViewController` is
  /// initialized with a `STPCustomerContext` either through the `STPPaymentContext`
  /// or directly as an init parameter.
  @objc public var canDeletePaymentOptions = true
  /// Determines whether STPAddCardViewController allows the user to
  /// scan cards using the camera on devices running iOS 13 or later.
  /// To use this feature, you must also set the `NSCameraUsageDescription`
  /// value in your app's Info.plist.
  /// @note This feature is currently in beta. Please file bugs at
  /// https://github.com/stripe/stripe-ios/issues
  /// The default value is currently NO. This will be changed in a future update.
  @objc public var cardScanningEnabled = false

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    var additionalPaymentOptionsDescription: String?

    var paymentOptions: [String] = []

    if _applePayEnabled {
      paymentOptions.append("STPPaymentOptionTypeApplePay")
    }

    if fpxEnabled {
      paymentOptions.append("STPPaymentOptionTypeFPX")
    }

    additionalPaymentOptionsDescription = paymentOptions.joined(separator: "|")

    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentConfiguration.self), self),
      // Basic configuration
      "additionalPaymentOptions = \(additionalPaymentOptionsDescription ?? "")",
      "availableCountries = \(availableCountries )",
      // Additional configuration
      "companyName = \(companyName )",
      "appleMerchantIdentifier = \(appleMerchantIdentifier ?? "")",
      "canDeletePaymentOptions = \((canDeletePaymentOptions) ? "YES" : "NO")",
      "cardScanningEnabled = \((cardScanningEnabled) ? "YES" : "NO")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - NSCopying
  /// :nodoc:
  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    let copy = STPPaymentConfiguration()
    copy.applePayEnabled = _applePayEnabled
    copy.fpxEnabled = fpxEnabled
    copy.companyName = companyName
    copy.appleMerchantIdentifier = appleMerchantIdentifier
    copy.canDeletePaymentOptions = canDeletePaymentOptions
    copy.cardScanningEnabled = cardScanningEnabled
    copy.availableCountries = availableCountries
    return copy
  }
}
