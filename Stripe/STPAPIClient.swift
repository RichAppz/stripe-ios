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

// MARK: Bank Accounts

/// STPAPIClient extensions to create Stripe tokens from bank accounts.
extension STPAPIClient {
  /// Converts an STPBankAccount object into a Stripe token using the Stripe API.
  /// - Parameters:
  ///   - bankAccount: The user's bank account details. Cannot be nil. - seealso: https://stripe.com/docs/api#create_bank_account_token
  ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
  @objc
  public func createToken(
    withBankAccount bankAccount: STPBankAccountParams,
    completion: @escaping STPTokenCompletionBlock
  ) {
    var params = STPFormEncoder.dictionary(forObject: bankAccount)
    STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
    createToken(withParameters: params, completion: completion)
    STPTelemetryClient.shared.sendTelemetryData()
  }
}

// MARK: Personally Identifiable Information

/// STPAPIClient extensions to create Stripe tokens from a personal identification number.
extension STPAPIClient {
  /// Converts a personal identification number into a Stripe token using the Stripe API.
  /// - Parameters:
  ///   - pii: The user's personal identification number. Cannot be nil. - seealso: https://stripe.com/docs/api#create_pii_token
  ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
  @objc
  public func createToken(
    withPersonalIDNumber pii: String, completion: STPTokenCompletionBlock?
  ) {
    var params: [String: Any] = [
      "pii": [
        "personal_id_number": pii
      ]
    ]
    STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
    if let completion = completion {
      createToken(withParameters: params, completion: completion)
    }
    STPTelemetryClient.shared.sendTelemetryData()
  }

  /// Converts the last 4 SSN digits into a Stripe token using the Stripe API.
  /// - Parameters:
  ///   - ssnLast4: The last 4 digits of the user's SSN. Cannot be nil.
  ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
  @objc
  public func createToken(
    withSSNLast4 ssnLast4: String, completion: @escaping STPTokenCompletionBlock
  ) {
    var params: [String: Any] = [
      "pii": [
        "ssn_last_4": ssnLast4
      ]
    ]
    STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
    createToken(withParameters: params, completion: completion)
    STPTelemetryClient.shared.sendTelemetryData()
  }
}

// MARK: Credit Cards

/// STPAPIClient extensions to create Stripe tokens from credit or debit cards.
extension STPAPIClient {
  /// Converts an STPCardParams object into a Stripe token using the Stripe API.
  /// - Parameters:
  ///   - cardParams:  The user's card details. Cannot be nil. - seealso: https://stripe.com/docs/api#create_card_token
  ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
  @objc
  public func createToken(
    withCard cardParams: STPCardParams, completion: @escaping STPTokenCompletionBlock
  ) {
    var params = STPFormEncoder.dictionary(forObject: cardParams)
    STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
    createToken(withParameters: params, completion: completion)
    STPTelemetryClient.shared.sendTelemetryData()
  }

  /// Converts a CVC string into a Stripe token using the Stripe API.
  /// - Parameters:
  ///   - cvc:         The CVC/CVV number used to create the token. Cannot be nil.
  ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
  @objc
  public func createToken(forCVCUpdate cvc: String, completion: STPTokenCompletionBlock? = nil) {
    var params: [String: Any] = [
      "cvc_update": [
        "cvc": cvc
      ]
    ]
    STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
    if let completion = completion {
      createToken(withParameters: params, completion: completion)
    }
    STPTelemetryClient.shared.sendTelemetryData()
  }
}

// MARK: Sources

/// STPAPIClient extensions for working with Source objects
extension STPAPIClient {
  /// Creates a Source object using the provided details.
  /// Note: in order to create a source on a connected account, you can set your
  /// API client's `stripeAccount` property to the ID of the account.
  /// - seealso: https://stripe.com/docs/sources/connect#creating-direct-charges
  /// - Parameters:
  ///   - sourceParams: The details of the source to create. Cannot be nil. - seealso: https://stripe.com/docs/api#create_source
  ///   - completion:   The callback to run with the returned Source object, or an error.
  @objc(createSourceWithParams:completion:)
  public func createSource(
    with sourceParams: STPSourceParams, completion: @escaping STPSourceCompletionBlock
  ) {
    let sourceType = STPSource.string(from: sourceParams.type)
    STPAnalyticsClient.sharedClient.logSourceCreationAttempt(
      with: configuration,
      sourceType: sourceType)
    sourceParams.redirectMerchantName = configuration.companyName
    var params = STPFormEncoder.dictionary(forObject: sourceParams)
    STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
    APIRequest<STPSource>.post(
      with: self,
      endpoint: APIEndpointSources,
      parameters: params
    ) { object, _, error in
      completion(object, error)
    }
    STPTelemetryClient.shared.sendTelemetryData()
  }

  /// Retrieves the Source object with the given ID. - seealso: https://stripe.com/docs/api#retrieve_source
  /// - Parameters:
  ///   - identifier:  The identifier of the source to be retrieved. Cannot be nil.
  ///   - secret:      The client secret of the source. Cannot be nil.
  ///   - completion:  The callback to run with the returned Source object, or an error.
  @objc
  public func retrieveSource(
    withId identifier: String, clientSecret secret: String,
    completion: @escaping STPSourceCompletionBlock
  ) {
    retrieveSource(
      withId: identifier, clientSecret: secret,
      responseCompletion: { object, _, error in
        completion(object, error)
      })
  }

  @discardableResult
  func retrieveSource(
    withId identifier: String,
    clientSecret secret: String,
    responseCompletion completion: @escaping (STPSource?, HTTPURLResponse?, Error?) -> Void
  ) -> URLSessionDataTask {
    let endpoint = "\(APIEndpointSources)/\(identifier)"
    let parameters = [
      "client_secret": secret
    ]
    return
      (APIRequest<STPSource>.getWith(
        self,
        endpoint: endpoint,
        parameters: parameters,
        completion: completion))
  }

  /// Starts polling the Source object with the given ID. For payment methods that require
  /// additional customer action (e.g. authorizing a payment with their bank), polling
  /// allows you to determine if the action was successful. Polling will stop and the
  /// provided callback will be called once the source's status is no longer `pending`,
  /// or if the given timeout is reached and the source is still `pending`. If polling
  /// stops due to an error, the callback will be fired with the latest retrieved
  /// source and the error.
  /// Note that if a poll is already running for a source, subsequent calls to `startPolling`
  /// with the same source ID will do nothing.
  /// - Parameters:
  ///   - identifier:  The identifier of the source to be retrieved. Cannot be nil.
  ///   - secret:      The client secret of the source. Cannot be nil.
  ///   - timeout:     The timeout for the polling operation, in seconds. Timeouts are capped at 5 minutes.
  ///   - completion:  The callback to run with the returned Source object, or an error.
  @available(iOSApplicationExtension, unavailable)
  @available(macCatalystApplicationExtension, unavailable)
  @objc
  public func startPollingSource(
    withId identifier: String, clientSecret secret: String, timeout: TimeInterval,
    completion: @escaping STPSourceCompletionBlock
  ) {
    stopPollingSource(withId: identifier)
    let poller = STPSourcePoller(
      apiClient: self,
      clientSecret: secret,
      sourceID: identifier,
      timeout: timeout,
      completion: completion)
    sourcePollersQueue?.async(execute: {
      self.sourcePollers?[identifier] = poller
    })
  }

  /// Stops polling the Source object with the given ID. Note that the completion block passed to
  /// `startPolling` will not be fired when `stopPolling` is called.
  /// - Parameter identifier:  The identifier of the source to be retrieved. Cannot be nil.
  @available(iOSApplicationExtension, unavailable)
  @available(macCatalystApplicationExtension, unavailable)
  @objc
  public func stopPollingSource(withId identifier: String) {
    sourcePollersQueue?.async(execute: {
      let poller = self.sourcePollers?[identifier] as? STPSourcePoller
      if let poller = poller {
        poller.stopPolling()
        self.sourcePollers?[identifier] = nil
      }
    })
  }
}

// MARK: Payment Intents

/// STPAPIClient extensions for working with PaymentIntent objects.
extension STPAPIClient {
  /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
  /// - Parameters:
  ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
  ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
  @objc
  public func retrievePaymentIntent(
    withClientSecret secret: String,
    completion: @escaping STPPaymentIntentCompletionBlock
  ) {
    retrievePaymentIntent(
      withClientSecret: secret,
      expand: nil,
      completion: completion)
  }

  /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
  /// - Parameters:
  ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
  ///   - expand:  An array of string keys to expand on the returned PaymentIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/payment_intents/object
  ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
  @objc
  public func retrievePaymentIntent(
    withClientSecret secret: String,
    expand: [String]?,
    completion: @escaping STPPaymentIntentCompletionBlock
  ) {
    assert(
      STPPaymentIntentParams.isClientSecretValid(secret),
      "`secret` format does not match expected client secret formatting.")
    let identifier = STPPaymentIntent.id(fromClientSecret: secret) ?? ""
    let endpoint = "\(APIEndpointPaymentIntents)/\(identifier)"

    var parameters: [String: Any] = [:]
    parameters["client_secret"] = secret
    if (expand?.count ?? 0) > 0 {
      if let expand = expand {
        parameters["expand"] = expand
      }
    }

    APIRequest<STPPaymentIntent>.getWith(
      self,
      endpoint: endpoint,
      parameters: parameters
    ) { paymentIntent, _, error in
      completion(paymentIntent, error)
    }
  }

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
      ?? paymentIntentParams.sourceParams?.rawTypeString
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

  /// Endpoint to call to indicate that the web-based challenge flow for 3DS authentication was canceled.
  func cancel3DSAuthentication(
    forPaymentIntent paymentIntentID: String,
    withSource sourceID: String,
    completion: @escaping STPPaymentIntentCompletionBlock
  ) {
    APIRequest<STPPaymentIntent>.post(
      with: self,
      endpoint: "\(APIEndpointPaymentIntents)/\(paymentIntentID)/source_cancel",
      parameters: [
        "source": sourceID
      ]
    ) { paymentIntent, _, responseError in
      completion(paymentIntent, responseError)
    }
  }
}

// MARK: Setup Intents

/// STPAPIClient extensions for working with SetupIntent objects.
extension STPAPIClient {
  /// Retrieves the SetupIntent object using the given secret. - seealso: https://stripe.com/docs/api/setup_intents/retrieve
  /// - Parameters:
  ///   - secret:      The client secret of the SetupIntent to be retrieved. Cannot be nil.
  ///   - completion:  The callback to run with the returned SetupIntent object, or an error.
  @objc
  public func retrieveSetupIntent(
    withClientSecret secret: String,
    completion: @escaping STPSetupIntentCompletionBlock
  ) {
    assert(
      STPSetupIntentConfirmParams.isClientSecretValid(secret),
      "`secret` format does not match expected client secret formatting.")
    let identifier = STPSetupIntent.id(fromClientSecret: secret) ?? ""

    let endpoint = "\(APIEndpointSetupIntents)/\(identifier)"

    APIRequest<STPSetupIntent>.getWith(
      self,
      endpoint: endpoint,
      parameters: [
        "client_secret": secret
      ]
    ) { setupIntent, _, error in
      completion(setupIntent, error)
    }
  }

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

  func cancel3DSAuthentication(
    forSetupIntent setupIntentID: String,
    withSource sourceID: String,
    completion: @escaping STPSetupIntentCompletionBlock
  ) {
    APIRequest<STPSetupIntent>.post(
      with: self,
      endpoint: "\(APIEndpointSetupIntents)/\(setupIntentID)/source_cancel",
      parameters: [
        "source": sourceID
      ]
    ) { setupIntent, _, responseError in
      completion(setupIntent, responseError)
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

// MARK: - Customers
extension STPAPIClient {
  /// Retrieve a customer
  /// - seealso: https://stripe.com/docs/api#retrieve_customer
  @objc(retrieveCustomerUsingKey:completion:) func retrieveCustomer(
    using ephemeralKey: STPEphemeralKey, completion: @escaping STPCustomerCompletionBlock
  ) {
    let endpoint = "\(APIEndpointCustomers)/\(ephemeralKey.customerID ?? "")"
    APIRequest<STPCustomer>.getWith(
      self,
      endpoint: endpoint,
      additionalHeaders: authorizationHeader(using: ephemeralKey),
      parameters: [:]
    ) { object, _, error in
      completion(object, error)
    }
  }

  /// Update a customer with parameters
  /// - seealso: https://stripe.com/docs/api#update_customer
  @objc(updateCustomerWithParameters:usingKey:completion:) func updateCustomer(
    withParameters parameters: [String: Any],
    using ephemeralKey: STPEphemeralKey,
    completion: @escaping STPCustomerCompletionBlock
  ) {
    let endpoint = "\(APIEndpointCustomers)/\(ephemeralKey.customerID ?? "")"
    APIRequest<STPCustomer>.post(
      with: self,
      endpoint: endpoint,
      additionalHeaders: authorizationHeader(using: ephemeralKey),
      parameters: parameters
    ) { object, _, error in
      completion(object, error)
    }
  }

  /// Attach a Payment Method to a customer
  /// - seealso: https://stripe.com/docs/api/payment_methods/attach
  @objc(attachPaymentMethod:toCustomerUsingKey:completion:) func attachPaymentMethod(
    _ paymentMethodID: String, toCustomerUsing ephemeralKey: STPEphemeralKey,
    completion: @escaping STPErrorBlock
  ) {
    let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/attach"
    APIRequest<STPPaymentMethod>.post(
      with: self,
      endpoint: endpoint,
      additionalHeaders: authorizationHeader(using: ephemeralKey),
      parameters: [
        "customer": ephemeralKey.customerID ?? ""
      ]
    ) { _, _, error in
      completion(error)
    }
  }

  /// Detach a Payment Method from a customer
  /// - seealso: https://stripe.com/docs/api/payment_methods/detach
  @objc(detachPaymentMethod:fromCustomerUsingKey:completion:) func detachPaymentMethod(
    _ paymentMethodID: String, fromCustomerUsing ephemeralKey: STPEphemeralKey,
    completion: @escaping STPErrorBlock
  ) {
    let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/detach"
    APIRequest<STPPaymentMethod>.post(
      with: self,
      endpoint: endpoint,
      additionalHeaders: authorizationHeader(using: ephemeralKey),
      parameters: [:]
    ) { _, _, error in
      completion(error)
    }
  }

  /// Retrieves a list of Payment Methods attached to a customer.
  /// @note This only fetches card type Payment Methods
  @objc(listPaymentMethodsForCustomerUsingKey:completion:) func listPaymentMethodsForCustomer(
    using ephemeralKey: STPEphemeralKey, completion: @escaping STPPaymentMethodsCompletionBlock
  ) {
    let params = [
      "customer": ephemeralKey.customerID,
      "type": STPPaymentMethod.string(from: .card),
    ]
    APIRequest<STPPaymentMethodListDeserializer>.getWith(
      self,
      endpoint: APIEndpointPaymentMethods,
      additionalHeaders: authorizationHeader(using: ephemeralKey),
      parameters: params as [String: Any]
    ) { deserializer, _, error in
      completion(deserializer?.paymentMethods, error)
    }
  }
}

private let APIVersion = "2020-08-27"
private let APIBaseURL = "https://api.stripe.com/v1"
private let APIEndpointToken = "tokens"
private let APIEndpointSources = "sources"
private let APIEndpointCustomers = "customers"
private let FileUploadURL = "https://uploads.stripe.com/v1/files"
private let APIEndpointPaymentIntents = "payment_intents"
private let APIEndpointSetupIntents = "setup_intents"
private let APIEndpointPaymentMethods = "payment_methods"
private let APIEndpoint3DS2 = "3ds2"
private let APIEndpointFPXStatus = "fpx/bank_statuses"
private let CardMetadataURL = "https://api.stripe.com/edge-internal/card-metadata"
