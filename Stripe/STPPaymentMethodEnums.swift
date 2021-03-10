//
//  STPPaymentMethodEnums.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/12/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of the PaymentMethod.
@objc public enum STPPaymentMethodType: Int {
  /// A card payment method.
  case card
  /// An unknown type.
  case unknown
}
