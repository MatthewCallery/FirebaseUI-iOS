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

@testable import FirebaseAuthSwiftUI
import Foundation
import Testing

@MainActor
@Suite("Auth error reporting")
struct AuthErrorReportingTests {
  @Test(arguments: [AuthErrorOperation.authentication, .passwordReset, .accountLinking])
  func preservesOriginalErrorAndOperationExactlyOnce(operation: AuthErrorOperation) {
    let expected = NSError(domain: "TestProvider", code: 42)
    var reportedErrors: [NSError] = []
    var reportedOperations: [AuthErrorOperation] = []
    let configuration = AuthConfiguration(onError: { error, operation in
      reportedErrors.append(error as NSError)
      reportedOperations.append(operation)
    })

    configuration.reportError(expected, operation: operation)

    #expect(reportedErrors.count == 1)
    #expect(reportedErrors.first === expected)
    #expect(reportedOperations == [operation])
  }

  @Test(arguments: [AuthErrorOperation.authentication, .passwordReset, .accountLinking])
  func cancellationIsAvailableForTheConsumerToFilter(operation: AuthErrorOperation) {
    var receivedCancellation = false
    let configuration = AuthConfiguration(onError: { error, _ in
      receivedCancellation = error is CancellationError
    })

    configuration.reportError(CancellationError(), operation: operation)

    #expect(receivedCancellation)
  }

  @Test(arguments: [AuthErrorOperation.authentication, .accountLinking])
  func oauthReauthenticationFailureIsReportedOnce(operation: AuthErrorOperation) async {
    let failure = NSError(domain: "TestOAuthProvider", code: 42, userInfo: [
      NSLocalizedDescriptionKey: "OAuth provider unavailable",
      "providerDetail": "Synthetic retry detail",
    ])
    let coordinator = ReauthenticationCoordinator()
    var reportedErrors: [NSError] = []
    var reportedOperations: [AuthErrorOperation] = []
    let configuration = AuthConfiguration(onError: { error, operation in
      reportedErrors.append(error as NSError)
      reportedOperations.append(operation)
    })

    // This task runs on the main actor after requestReauth suspends below.
    let providerFailure = Task { @MainActor in
      #expect(coordinator.isReauthenticating)
      coordinator.reauthFailed(with: failure)
      // A late duplicate completion must not resume or report the request again.
      coordinator.reauthFailed(with: failure)
    }
    do {
      try await coordinator.requestReauth(context: .oauth(
        OAuthReauthContext(providerId: "test.oauth", providerName: "Test OAuth")
      ))
      Issue.record("Failed reauthentication must not resume the operation successfully")
    } catch {
      configuration.reportError(error, operation: operation)
    }
    await providerFailure.value

    #expect(reportedErrors.count == 1)
    #expect(reportedErrors.first?.domain == failure.domain)
    #expect(reportedErrors.first?.code == failure.code)
    #expect(reportedErrors.first?.userInfo as NSDictionary? == failure.userInfo as NSDictionary)
    #expect(reportedOperations == [operation])
    #expect(!coordinator.isReauthenticating)
    #expect(coordinator.reauthContext == nil)
  }

  @Test
  func explicitReauthenticationCancellationRemainsCancellation() async {
    let coordinator = ReauthenticationCoordinator()
    let cancellation = Task { @MainActor in
      #expect(coordinator.isReauthenticating)
      coordinator.reauthCancelled()
    }
    do {
      try await coordinator.requestReauth(context: .oauth(
        OAuthReauthContext(providerId: "test.oauth", providerName: "Test OAuth")
      ))
      Issue.record("Cancelling reauthentication must not resume the operation successfully")
    } catch {
      guard case .signInCancelled = error as? AuthServiceError else {
        Issue.record("Expected signInCancelled, received \(error)")
        return
      }
    }
    await cancellation.value
    #expect(!coordinator.isReauthenticating)
    #expect(coordinator.reauthContext == nil)
  }

  @Test
  func optionalObserverDoesNotRequireConsumerChanges() {
    let configuration = AuthConfiguration()
    configuration.reportError(NSError(domain: "TestProvider", code: 42), operation: .passwordReset)
    #expect(configuration.onError == nil)
  }
}
