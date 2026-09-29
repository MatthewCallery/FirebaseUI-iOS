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

import AuthenticationServices
@testable import FirebaseAppleSwiftUI
import FirebaseAuthSwiftUI
import Testing

@Test func appleCancellationUsesTheSharedSilentCancellationPath() {
  let error = NSError(domain: ASAuthorizationError.errorDomain,
                      code: ASAuthorizationError.canceled.rawValue)
  #expect(AppleProviderSwift.authenticationError(error) is CancellationError)
}

@Test func appleSignInPreservesOtherAuthorizationErrors() throws {
  let errors = [
    NSError(domain: ASAuthorizationError.errorDomain, code: ASAuthorizationError.failed.rawValue),
    NSError(domain: ASAuthorizationError.errorDomain, code: ASAuthorizationError.unknown.rawValue),
    NSError(domain: "OtherProvider", code: ASAuthorizationError.canceled.rawValue),
  ]
  for error in errors {
    let mappedError = try #require(
      AppleProviderSwift.authenticationError(error) as? AuthServiceError
    )
    guard case let .signInFailed(underlying) = mappedError else {
      Issue.record("Expected a sign-in failure")
      continue
    }
    #expect(underlying as NSError === error)
  }
}
