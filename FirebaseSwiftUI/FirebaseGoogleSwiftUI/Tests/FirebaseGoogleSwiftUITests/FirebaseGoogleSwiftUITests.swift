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

@testable import FirebaseGoogleSwiftUI
import GoogleSignIn
import Testing

@Test func googleCancellationUsesTheSharedSilentCancellationPath() {
  let error = NSError(domain: kGIDSignInErrorDomain, code: GIDSignInError.canceled.rawValue)
  #expect(GoogleProviderSwift.authenticationError(error) is CancellationError)
}

@Test func googleSignInPreservesOtherErrors() {
  let errors = [
    NSError(domain: kGIDSignInErrorDomain, code: GIDSignInError.keychain.rawValue),
    NSError(domain: "OtherProvider", code: GIDSignInError.canceled.rawValue),
  ]
  for error in errors {
    #expect(GoogleProviderSwift.authenticationError(error) as NSError === error)
  }
}
