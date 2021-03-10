//
//  STPAPIClient.swift
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

import Foundation
import PassKit
import UIKit

/// A client for making connections to the Stripe API.
public class STPAPIClient: NSObject {
  /// The current version of this library.
  @objc public static let STPSDKVersion = "21.3.1"

  /// A shared singleton API client.
  /// By default, the SDK uses this instance to make API requests
  /// eg in STPPaymentHandler, STPPaymentContext, STPCustomerContext, etc.
  @objc(sharedClient)
  public static let shared: STPAPIClient = STPAPIClient()

  /// The client's publishable key.
  /// The default value is `StripeAPI.defaultPublishableKey`.
  @objc public var publishableKey: String? = StripeAPI.defaultPublishableKey {
    didSet {
      Self.validateKey(publishableKey)
    }
  }

  /// The client's configuration.
  /// Defaults to `STPPaymentConfiguration.shared`.
  @objc public var configuration: STPPaymentConfiguration = .shared

  /// In order to perform API requests on behalf of a connected account, e.g. to
  /// create a Source or Payment Method on a connected account, set this property to the ID of the
  /// account for which this request is being made.
  /// - seealso: https://stripe.com/docs/connect/authentication#authentication-via-the-stripe-account-header
  @objc public var stripeAccount: String?

  /// Libraries wrapping the Stripe SDK should set this, so that Stripe can contact you about future issues or critical updates.
  /// - seealso: https://stripe.com/docs/building-plugins#setappinfo
  @objc public var appInfo: STPAppInfo?

  /// The API version used to communicate with Stripe.
  @objc public static let apiVersion = APIVersion

  // MARK: Internal/private properties
  static let sharedUrlSessionConfiguration = URLSessionConfiguration.default
  var apiURL: URL! = URL(string: APIBaseURL)
  let urlSession = URLSession(configuration: STPAPIClient.sharedUrlSessionConfiguration)

  private var sourcePollers: [String: NSObject]?
  private var sourcePollersQueue: DispatchQueue?
  /// A set of beta headers to add to Stripe API requests e.g. `Set(["alipay_beta=v1"])`
  var betas: Set<String>?

  // MARK: Initializers
  override init() {
    super.init()
    configuration = STPPaymentConfiguration.shared
    sourcePollers = [:]
    sourcePollersQueue = DispatchQueue(label: "com.stripe.sourcepollers")
  }

  /// Initializes an API client with the given publishable key.
  /// - Parameter publishableKey: The publishable key to use.
  /// - Returns: An instance of STPAPIClient.
  @objc
  public convenience init(publishableKey: String) {
    self.init()
    self.publishableKey = publishableKey
  }

  @objc(configuredRequestForURL:additionalHeaders:)
  func configuredRequest(for url: URL, additionalHeaders: [String: String] = [:])
    -> NSMutableURLRequest
  {
    let request = NSMutableURLRequest(url: url)
    var headers = defaultHeaders()
    for (k, v) in additionalHeaders { headers[k] = v }  // additionalHeaders can overwrite defaultHeaders
    headers.forEach { key, value in
      request.setValue(value, forHTTPHeaderField: key)
    }
    return request
  }

  /// Headers common to all API requests for a given API Client.
  @objc func defaultHeaders() -> [String: String] {
    var defaultHeaders: [String: String] = [:]
    defaultHeaders["X-Stripe-User-Agent"] = STPAPIClient.stripeUserAgentDetails(with: appInfo)
    var stripeVersion = APIVersion
    if betas != nil && (betas?.count ?? 0) > 0 {
      for betaHeader in betas ?? [] {
        stripeVersion = stripeVersion + "; \(betaHeader)"
      }
    }
    defaultHeaders["Stripe-Version"] = stripeVersion
    defaultHeaders["Stripe-Account"] = stripeAccount
    for (k, v) in authorizationHeader() { defaultHeaders[k] = v }
    return defaultHeaders
  }

  func createToken(
    withParameters parameters: [String: Any],
    completion: @escaping STPTokenCompletionBlock
  ) {
    let tokenType = STPAnalyticsClient.tokenType(fromParameters: parameters)
    STPAnalyticsClient.sharedClient.logTokenCreationAttempt(
      with: configuration,
      tokenType: tokenType)
    APIRequest<STPToken>.post(
      with: self,
      endpoint: APIEndpointToken,
      parameters: parameters
    ) { object, _, error in
      completion(object, error)
    }
  }

  // MARK: Helpers

  static var didShowTestmodeKeyWarning = false
  class func validateKey(_ publishableKey: String?) {
    guard let publishableKey = publishableKey, !publishableKey.isEmpty else {
      assertionFailure(
        "You must use a valid publishable key. For more info, see https://stripe.com/docs/keys")
      return
    }
    let secretKey = publishableKey.hasPrefix("sk_")
    assert(
      !secretKey,
      "You are using a secret key. Use a publishable key instead. For more info, see https://stripe.com/docs/keys"
    )
    #if !DEBUG
      if publishableKey.lowercased().hasPrefix("pk_test") && !didShowTestmodeKeyWarning {
        print(
          "ℹ️ You're using your Stripe testmode key. Make sure to use your livemode key when submitting to the App Store!"
        )
        didShowTestmodeKeyWarning = true
      }
    #endif
  }

  class func stripeUserAgentDetails(with appInfo: STPAppInfo?) -> String {
    var details: [String: String] = [
      "lang": "objective-c",
      "bindings_version": STPSDKVersion,
    ]
    let version = UIDevice.current.systemVersion
    if version != "" {
      details["os_version"] = version
    }
    var systemInfo = utsname()
    uname(&systemInfo)

    // Thanks to https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let deviceType = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    details["type"] = deviceType
    let model = UIDevice.current.localizedModel
    if model != "" {
      details["model"] = model
    }

    let vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString
    if let vendorIdentifier = vendorIdentifier {
      details["vendor_identifier"] = vendorIdentifier
    }
    if let appInfo = appInfo {
      details["name"] = appInfo.name
      details["partner_id"] = appInfo.partnerId
      if appInfo.version != nil {
        details["version"] = appInfo.version
      }
      if appInfo.url != nil {
        details["url"] = appInfo.url
      }
    }
    let data = try? JSONSerialization.data(withJSONObject: details, options: [])
    return String(data: data ?? Data(), encoding: .utf8) ?? ""
  }

  /// A helper method that returns the Authorization header to use for API requests. If ephemeralKey is nil, uses self.publishableKey instead.
  @objc(authorizationHeaderUsingEphemeralKey:)
  func authorizationHeader(using ephemeralKey: STPEphemeralKey? = nil) -> [String: String] {
    var authorizationBearer = publishableKey ?? ""
    if let ephemeralKey = ephemeralKey {
      authorizationBearer = ephemeralKey.secret
    }
    return [
      "Authorization": "Bearer " + authorizationBearer
    ]
  }
}

// MARK: Payment Intents

/// STPAPIClient extensions for working with PaymentIntent objects.
extension STPAPIClient {
  /// Confirms the PaymentIntent object with the provided params object.
  /// At a minimum, the params object must include the `clientSecret`.
  /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
  /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
  /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
  /// - Parameters:
  ///   - paymentIntentParams:  The `STPPaymentIntentParams` to pass to `/confirm`
  ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
  @objc(confirmPaymentIntentWithParams:completion:)
  public func confirmPaymentIntent(
    with paymentIntentParams: STPPaymentIntentParams,
    completion: @escaping STPPaymentIntentCompletionBlock
  ) {
    confirmPaymentIntent(
      with: paymentIntentParams,
      expand: nil,
      completion: completion)
  }

  /// Confirms the PaymentIntent object with the provided params object.
  /// At a minimum, the params object must include the `clientSecret`.
  /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
  /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
  /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
  /// - Parameters:
  ///   - paymentIntentParams:  The `STPPaymentIntentParams` to pass to `/confirm`
  ///   - expand:  An array of string keys to expand on the returned PaymentIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/payment_intents/object
  ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
  @objc(confirmPaymentIntentWithParams:expand:completion:)
  public func confirmPaymentIntent(
    with paymentIntentParams: STPPaymentIntentParams,
    expand: [String]?,
    completion: @escaping STPPaymentIntentCompletionBlock
  ) {
    assert(
      STPPaymentIntentParams.isClientSecretValid(paymentIntentParams.clientSecret),
      "`paymentIntentParams.clientSecret` format does not match expected client secret formatting.")

    let identifier = paymentIntentParams.stripeId ?? ""
    let type =
      paymentIntentParams.paymentMethodParams?.rawTypeString
    STPAnalyticsClient.sharedClient.logPaymentIntentConfirmationAttempt(
      with: configuration,
      paymentMethodType: type)

    let endpoint = "\(APIEndpointPaymentIntents)/\(identifier)/confirm"

    var params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
    if var sourceParamsDict = params["source_data"] as? [String: Any] {
      STPTelemetryClient.shared.addTelemetryFields(toParams: &sourceParamsDict)
      params["source_data"] = sourceParamsDict
    }
    if (expand?.count ?? 0) > 0 {
      if let expand = expand {
        params["expand"] = expand
      }
    }

    APIRequest<STPPaymentIntent>.post(
      with: self,
      endpoint: endpoint,
      parameters: params
    ) { paymentIntent, _, error in
      completion(paymentIntent, error)
    }
  }

}

// MARK: Setup Intents

/// STPAPIClient extensions for working with SetupIntent objects.
extension STPAPIClient {
  /// Confirms the SetupIntent object with the provided params object.
  /// At a minimum, the params object must include the `clientSecret`.
  /// - seealso: https://stripe.com/docs/api/setup_intents/confirm
  /// @note Use the `confirmSetupIntent:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
  /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
  /// - Parameters:
  ///   - setupIntentParams:    The `STPSetupIntentConfirmParams` to pass to `/confirm`
  ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
  @objc(confirmSetupIntentWithParams:completion:)
  public func confirmSetupIntent(
    with setupIntentParams: STPSetupIntentConfirmParams,
    completion: @escaping STPSetupIntentCompletionBlock
  ) {
    assert(
      STPSetupIntentConfirmParams.isClientSecretValid(setupIntentParams.clientSecret),
      "`setupIntentParams.clientSecret` format does not match expected client secret formatting.")

    STPAnalyticsClient.sharedClient.logSetupIntentConfirmationAttempt(
      with: configuration,
      paymentMethodType: setupIntentParams.paymentMethodParams?.rawTypeString)

    let identifier = STPSetupIntent.id(fromClientSecret: setupIntentParams.clientSecret) ?? ""
    let endpoint = "\(APIEndpointSetupIntents)/\(identifier)/confirm"
    let params = STPFormEncoder.dictionary(forObject: setupIntentParams)
    APIRequest<STPSetupIntent>.post(
      with: self,
      endpoint: endpoint,
      parameters: params
    ) { setupIntent, _, error in
      completion(setupIntent, error)
    }
  }
}

// MARK: Payment Methods

/// STPAPIClient extensions for working with PaymentMethod objects.
extension STPAPIClient {
  /// Creates a PaymentMethod object with the provided params object.
  /// - seealso: https://stripe.com/docs/api/payment_methods/create
  /// - Parameters:
  ///   - paymentMethodParams:  The `STPPaymentMethodParams` to pass to `/v1/payment_methods`.  Cannot be nil.
  ///   - completion:           The callback to run with the returned PaymentMethod object, or an error.
  @objc(createPaymentMethodWithParams:completion:)
  public func createPaymentMethod(
    with paymentMethodParams: STPPaymentMethodParams,
    completion: @escaping STPPaymentMethodCompletionBlock
  ) {
    STPAnalyticsClient.sharedClient.logPaymentMethodCreationAttempt(
      with: configuration, paymentMethodType: paymentMethodParams.rawTypeString)

    APIRequest<STPPaymentMethod>.post(
      with: self,
      endpoint: APIEndpointPaymentMethods,
      parameters: STPFormEncoder.dictionary(forObject: paymentMethodParams)
    ) { paymentMethod, _, error in
      completion(paymentMethod, error)
    }

  }
}

private let APIVersion = "2020-08-27"
private let APIBaseURL = "https://api.stripe.com/v1"
private let APIEndpointToken = "tokens"
private let APIEndpointPaymentIntents = "payment_intents"
private let APIEndpointSetupIntents = "setup_intents"
private let APIEndpointPaymentMethods = "payment_methods"
private let APIEndpointFPXStatus = "fpx/bank_statuses"
private let CardMetadataURL = "https://api.stripe.com/edge-internal/card-metadata"
