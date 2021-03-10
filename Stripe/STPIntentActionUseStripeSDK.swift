//
//  STPIntentActionUseStripeSDK.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 5/15/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

@objc
enum STPIntentActionUseStripeSDKType: Int {
  case unknown = 0
}

class STPIntentActionUseStripeSDK: NSObject {

  let allResponseFields: [AnyHashable: Any]

  let type: STPIntentActionUseStripeSDKType

  // MARK: - 3DS2 Fingerprint
  let directoryServerName: String?
  let directoryServerID: String?

  /// PEM encoded DS certificate
  let directoryServerCertificate: String?
  let rootCertificateStrings: [String]?

  /// A Visa-specific field
  let directoryServerKeyID: String?
  let serverTransactionID: String?

  // MARK: - 3DS2 Redirect
  let redirectURL: URL?

  private init(
    type: STPIntentActionUseStripeSDKType,
    directoryServerName: String?,
    directoryServerID: String?,
    directoryServerCertificate: String?,
    rootCertificateStrings: [String]?,
    directoryServerKeyID: String?,
    serverTransactionID: String?,
    redirectURL: URL?,
    allResponseFields: [AnyHashable: Any]
  ) {
    self.type = type
    self.directoryServerName = directoryServerName
    self.directoryServerID = directoryServerID
    self.directoryServerCertificate = directoryServerCertificate
    self.rootCertificateStrings = rootCertificateStrings
    self.directoryServerKeyID = directoryServerKeyID
    self.serverTransactionID = serverTransactionID
    self.redirectURL = redirectURL
    self.allResponseFields = allResponseFields
    super.init()
  }

  convenience init?(
    encryptionInfo: [AnyHashable: Any],
    directoryServerName: String?,
    directoryServerKeyID: String?,
    serverTransactionID: String?,
    allResponseFields: [AnyHashable: Any]
  ) {
    guard let certificate = encryptionInfo["certificate"] as? String,
      !certificate.isEmpty,
      let directoryServerID = encryptionInfo["directory_server_id"] as? String,
      !directoryServerID.isEmpty,
      let rootCertificates = encryptionInfo["root_certificate_authorities"] as? [String],
      !rootCertificates.isEmpty
    else {
      return nil
    }
    self.init(
      type: .unknown,
      directoryServerName: directoryServerName,
      directoryServerID: directoryServerID,
      directoryServerCertificate: certificate,
      rootCertificateStrings: rootCertificates,
      directoryServerKeyID: directoryServerKeyID,
      serverTransactionID: serverTransactionID,
      redirectURL: nil,
      allResponseFields: allResponseFields)
  }

  convenience init(redirectURL: URL, allResponseFields: [AnyHashable: Any]) {
    self.init(
      type: .unknown,
      directoryServerName: nil,
      directoryServerID: nil,
      directoryServerCertificate: nil,
      rootCertificateStrings: nil,
      directoryServerKeyID: nil,
      serverTransactionID: nil,
      redirectURL: redirectURL,
      allResponseFields: allResponseFields)
  }

  convenience override init() {
    self.init(
      type: .unknown,
      directoryServerName: nil,
      directoryServerID: nil,
      directoryServerCertificate: nil,
      rootCertificateStrings: nil,
      directoryServerKeyID: nil,
      serverTransactionID: nil,
      redirectURL: nil,
      allResponseFields: [:])
  }

  @objc override var description: String {
    let props: [String] = [
      // Object
      String(format: "%@: %p", String(describing: STPIntentActionUseStripeSDK.self), self),
      // IntentActionUseStripeSDK details (alphabetical)
      "directoryServer = \(String(describing: directoryServerName))",
      "directoryServerID = \(String(describing: directoryServerID))",
      "directoryServerKeyID = \(String(describing: directoryServerKeyID))",
      "serverTransactionID = \(String(describing: serverTransactionID))",
      "directoryServerCertificate = \(String(describing: (directoryServerCertificate?.count ?? 0 > 0 ? "<redacted>" : nil)))",
      "rootCertificateStrings = \(String(describing: (rootCertificateStrings?.count ?? 0 > 0 ? "<redacted>" : nil)))",
      "type = \(String(describing: allResponseFields["type"]))",
      "redirectURL = \(String(describing: redirectURL))",
    ]

    return "<\(props.joined(separator: "; "))>"
  }
}

/// :nodoc:
extension STPIntentActionUseStripeSDK: STPAPIResponseDecodable {
  class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = response,
      let typeString = dict["type"] as? String
    else {
      return nil
    }

    switch typeString {
    default:
      return STPIntentActionUseStripeSDK(
        type: .unknown,
        directoryServerName: nil,
        directoryServerID: nil,
        directoryServerCertificate: nil,
        rootCertificateStrings: nil,
        directoryServerKeyID: nil,
        serverTransactionID: nil,
        redirectURL: nil,
        allResponseFields: dict) as? Self
    }
  }
}
