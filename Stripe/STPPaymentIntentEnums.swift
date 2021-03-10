//
//  STPPaymentIntentEnums.swift
//  Stripe
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// Status types for an STPPaymentIntent
@objc public enum STPPaymentIntentStatus: Int {
  /// Unknown status
  case unknown
  /// This PaymentIntent requires a PaymentMethod or Source
  case requiresPaymentMethod
  /// This PaymentIntent needs to be confirmed
  case requiresConfirmation
  /// The selected PaymentMethod or Source requires additional authentication steps.
  /// Additional actions found via `next_action`
  case requiresAction
    /// Stripe is processing this PaymentIntent
  case processing
  /// The payment has succeeded
  case succeeded
  /// Indicates the payment must be captured, for STPPaymentIntentCaptureMethodManual
  case requiresCapture
  /// This PaymentIntent was canceled and cannot be changed.
  case canceled
}
