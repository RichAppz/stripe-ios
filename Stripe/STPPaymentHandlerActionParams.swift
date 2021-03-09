//
//  STPPaymentHandlerActionParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
internal protocol STPPaymentHandlerActionParams: AnyObject {
  var authenticationContext: STPAuthenticationContext { get }
  var apiClient: STPAPIClient { get }
  var returnURLString: String? { get }
  var intentStripeID: String? { get }
  /// Returns the payment or setup intent's next action
  func nextAction() -> STPIntentAction?
  func complete(with status: STPPaymentHandlerActionStatus, error: NSError?)
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
internal class STPPaymentHandlerPaymentIntentActionParams: NSObject, STPPaymentHandlerActionParams {

  private var serviceInitialized = false

  let authenticationContext: STPAuthenticationContext
  let apiClient: STPAPIClient
  let paymentIntentCompletion: STPPaymentHandlerActionPaymentIntentCompletionBlock
  let returnURLString: String?
  var paymentIntent: STPPaymentIntent?

  var intentStripeID: String? {
    return paymentIntent?.stripeId
  }

  init(
    apiClient: STPAPIClient,
    authenticationContext: STPAuthenticationContext,
    paymentIntent: STPPaymentIntent,
    returnURL returnURLString: String?,
    completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
  ) {
    self.apiClient = apiClient
    self.authenticationContext = authenticationContext
    self.returnURLString = returnURLString
    self.paymentIntent = paymentIntent
    self.paymentIntentCompletion = completion
    super.init()
  }

  func nextAction() -> STPIntentAction? {
    return paymentIntent?.nextAction
  }

  func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
    paymentIntentCompletion(status, paymentIntent, error)
  }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
internal class STPPaymentHandlerSetupIntentActionParams: NSObject, STPPaymentHandlerActionParams {
  private var serviceInitialized = false

  let authenticationContext: STPAuthenticationContext
  let apiClient: STPAPIClient
  let setupIntentCompletion: STPPaymentHandlerActionSetupIntentCompletionBlock
  let returnURLString: String?
  var setupIntent: STPSetupIntent?

  var intentStripeID: String? {
    return setupIntent?.stripeID
  }

  init(
    apiClient: STPAPIClient,
    authenticationContext: STPAuthenticationContext,
    setupIntent: STPSetupIntent,
    returnURL returnURLString: String?,
    completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
  ) {
    self.apiClient = apiClient
    self.authenticationContext = authenticationContext
    self.returnURLString = returnURLString
    self.setupIntent = setupIntent
    self.setupIntentCompletion = completion
    super.init()
  }

  func nextAction() -> STPIntentAction? {
    return setupIntent?.nextAction
  }

  func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
    setupIntentCompletion(status, setupIntent, error)
  }
}
