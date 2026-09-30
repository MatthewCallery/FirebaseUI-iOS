// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FirebaseAuth
import Foundation
import SwiftUI

/// The built-in authentication flow that reported an error.
public enum AuthErrorOperation: Sendable, Equatable {
  case authentication
  case passwordReset
  case accountLinking
}

public struct AuthConfiguration {
  public let logo: ImageResource?
  public let languageCode: String?
  public let shouldHideCancelButton: Bool
  public let interactiveDismissEnabled: Bool
  public let shouldAutoUpgradeAnonymousUsers: Bool
  public let legacyFetchSignInWithEmail: Bool
  public let customStringsBundle: Bundle?
  public let tosUrl: URL?
  public let privacyPolicyUrl: URL?
  public let emailLinkSignInActionCodeSettings: ActionCodeSettings?
  public let verifyEmailActionCodeSettings: ActionCodeSettings?

  /// Observes errors handled by the built-in views without replacing their UI.
  /// The callback runs on the main actor and may receive expected failures or cancellation.
  /// Filter and sanitize errors before forwarding them to a diagnostics service.
  public let onError: (@MainActor (Error, AuthErrorOperation) -> Void)?

  // MARK: - MFA Configuration

  public let mfaEnabled: Bool
  public let allowedSecondFactors: Set<SecondFactorType>
  public let mfaIssuer: String

  public init(logo: ImageResource? = nil,
              languageCode: String? = nil,
              shouldHideCancelButton: Bool = false,
              interactiveDismissEnabled: Bool = true,
              shouldAutoUpgradeAnonymousUsers: Bool = false,
              legacyFetchSignInWithEmail: Bool = false,
              customStringsBundle: Bundle? = nil,
              tosUrl: URL? = nil,
              privacyPolicyUrl: URL? = nil,
              emailLinkSignInActionCodeSettings: ActionCodeSettings? = nil,
              verifyEmailActionCodeSettings: ActionCodeSettings? = nil,
              mfaEnabled: Bool = false,
              allowedSecondFactors: Set<SecondFactorType> = [.sms, .totp],
              mfaIssuer: String = "Firebase Auth",
              onError: (@MainActor (Error, AuthErrorOperation) -> Void)? = nil) {
    self.logo = logo
    self.shouldHideCancelButton = shouldHideCancelButton
    self.interactiveDismissEnabled = interactiveDismissEnabled
    self.shouldAutoUpgradeAnonymousUsers = shouldAutoUpgradeAnonymousUsers
    self.legacyFetchSignInWithEmail = legacyFetchSignInWithEmail
    self.customStringsBundle = customStringsBundle
    self.languageCode = languageCode
    self.tosUrl = tosUrl
    self.privacyPolicyUrl = privacyPolicyUrl
    self.emailLinkSignInActionCodeSettings = emailLinkSignInActionCodeSettings
    self.verifyEmailActionCodeSettings = verifyEmailActionCodeSettings
    self.mfaEnabled = mfaEnabled
    self.allowedSecondFactors = allowedSecondFactors
    self.mfaIssuer = mfaIssuer
    self.onError = onError
  }
}

extension AuthConfiguration {
  @MainActor
  func reportError(_ error: Error, operation: AuthErrorOperation) {
    // Reauthentication reports its original failure before cancelling the pending link.
    if operation == .accountLinking {
      if error is CancellationError {
        return
      }
      if case .signInCancelled = error as? AuthServiceError {
        return
      }
    }
    onError?(error, operation)
  }
}
