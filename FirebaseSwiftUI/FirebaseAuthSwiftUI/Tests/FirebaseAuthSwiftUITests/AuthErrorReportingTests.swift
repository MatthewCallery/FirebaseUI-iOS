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

  @Test
  func cancellationIsAvailableForTheConsumerToFilter() {
    var receivedCancellation = false
    let configuration = AuthConfiguration(onError: { error, _ in
      receivedCancellation = error is CancellationError
    })

    configuration.reportError(CancellationError(), operation: .authentication)

    #expect(receivedCancellation)
  }

  @Test
  func reauthenticationFailureIsNotReportedAgainWhenPendingLinkIsCancelled() {
    let failure = NSError(domain: "TestProvider", code: 42)
    var reportedErrors: [NSError] = []
    let configuration = AuthConfiguration(onError: { error, _ in
      reportedErrors.append(error as NSError)
    })

    configuration.reportError(failure, operation: .authentication)
    configuration.reportError(
      AuthServiceError.signInCancelled("Reauthentication cancelled"),
      operation: .accountLinking
    )
    configuration.reportError(CancellationError(), operation: .accountLinking)

    #expect(reportedErrors.count == 1)
    #expect(reportedErrors.first === failure)
  }

  @Test
  func optionalObserverDoesNotRequireConsumerChanges() {
    let configuration = AuthConfiguration()
    configuration.reportError(NSError(domain: "TestProvider", code: 42), operation: .passwordReset)
    #expect(configuration.onError == nil)
  }
}
