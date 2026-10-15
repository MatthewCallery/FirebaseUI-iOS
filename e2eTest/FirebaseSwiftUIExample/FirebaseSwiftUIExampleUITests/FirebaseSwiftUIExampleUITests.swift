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

//
//  FirebaseSwiftUIExampleUITests.swift
//  FirebaseSwiftUIExampleUITests
//
//  Created by Russell Wheatley on 18/02/2025.
//

import XCTest

final class FirebaseSwiftUIExampleUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  override func tearDownWithError() throws {}

  @MainActor
  func testNoProvidersInitialized() throws {
    let app = XCUIApplication()
    app.launchArguments.append("--test-view-enabled")
    app.launchArguments.append("--no-providers")
    app.launch()

    // Verify email/password fields are NOT visible when no providers are initialized
    let emailField = app.textFields["email-field"]
    XCTAssertFalse(
      emailField.waitForExistence(timeout: 2),
      "Email field should NOT be visible when no providers are initialized"
    )

    // Verify email link button is NOT visible
    let emailLinkButton = app.buttons["sign-in-with-email-link-button"]
    XCTAssertFalse(
      emailLinkButton.waitForExistence(timeout: 2),
      "Email link button should NOT be visible when no providers are initialized"
    )

    // Verify provider buttons are NOT visible
    let googleButton = app.buttons["sign-in-with-google-button"]
    XCTAssertFalse(
      googleButton.waitForExistence(timeout: 2),
      "Google button should NOT be visible when no providers are initialized"
    )

    let facebookButton = app.buttons["sign-in-with-facebook-button"]
    XCTAssertFalse(
      facebookButton.waitForExistence(timeout: 2),
      "Facebook button should NOT be visible when no providers are initialized"
    )
  }

  @MainActor
  func testAllProvidersInitialized() throws {
    let app = XCUIApplication()
    app.launchArguments.append("--test-view-enabled")
    // No --no-providers flag means all providers are enabled by default
    app.launch()

    // Verify email/password fields are visible when withEmailSignIn() is enabled
    let emailField = app.textFields["email-field"]
    XCTAssertTrue(
      emailField.waitForExistence(timeout: 5),
      "Email field should be visible when withEmailSignIn() is enabled"
    )

    let passwordField = app.secureTextFields["password-field"]
    XCTAssertTrue(
      passwordField.waitForExistence(timeout: 5),
      "Password field should be visible when withEmailSignIn() is enabled"
    )

    let signInButton = app.buttons["sign-in-button"]
    XCTAssertTrue(
      signInButton.waitForExistence(timeout: 5),
      "Sign-in button should be visible when withEmailSignIn() is enabled"
    )

    // Verify email link button is visible when withEmailLinkSignIn() is enabled
    let emailLinkButton = app.buttons["sign-in-with-email-link-button"]
    XCTAssertTrue(
      emailLinkButton.waitForExistence(timeout: 5),
      "Email link button should be visible when withEmailLinkSignIn() is enabled"
    )

    // Tap the email link button and verify it navigates to email link view
    emailLinkButton.tap()
    let emailLinkText = app.staticTexts["Send a sign-in link to your email"].firstMatch
    XCTAssertTrue(
      emailLinkText.waitForExistence(timeout: 5),
      "Email link view should appear after tapping email link button"
    )

    // Go back to verify provider buttons
    let backButton = app.navigationBars.buttons.element(boundBy: 0)
    if backButton.exists {
      backButton.tap()
    }

    // Verify provider buttons are visible
    let googleButton = app.buttons["sign-in-with-google-button"]
    XCTAssertTrue(
      googleButton.waitForExistence(timeout: 5),
      "Google sign-in button should be visible when withGoogleSignIn() is enabled"
    )

    let facebookButton = app.buttons["sign-in-with-facebook-button"]
    XCTAssertTrue(
      facebookButton.waitForExistence(timeout: 5),
      "Facebook sign-in button should be visible when withFacebookSignIn() is enabled"
    )
  }

  @MainActor
  func testSignInDisplaysSignedInView() async throws {
    let email = createEmail()
    let password = "123456"

    // Create user in test runner BEFORE launching app
    // User will exist in emulator, but app starts unauthenticated
    try await createTestUser(email: email, password: password)

    // Now launch the app - it connects to emulator but isn't signed in
    let app = createTestApp()
    app.launch()

    let emailField = app.textFields["email-field"]
    XCTAssertTrue(emailField.waitForExistence(timeout: 6), "Email field should exist")
    try enterText(email, into: emailField, app: app)

    let passwordField = app.secureTextFields["password-field"]
    XCTAssertTrue(passwordField.exists, "Password field should exist")
    try enterText(password, into: passwordField, app: app)

    let signInButton = app.buttons["sign-in-button"]
    XCTAssertTrue(signInButton.exists, "Sign-In button should exist")
    signInButton.tap()

    // Wait for authentication to complete and signed-in view to appear
    let signedInText = app.staticTexts["signed-in-text"]
    XCTAssertTrue(
      signedInText.waitForExistence(timeout: 30),
      "SignedInView should be visible after login"
    )

    let mfaManagementButton = app.buttons["mfa-management-button"]
    XCTAssertFalse(
      mfaManagementButton.exists,
      "MFA management button should be hidden when MFA is disabled"
    )

    dismissAlert(app: app)
    // Check the Views are updated
    let signOutButton = app.buttons["sign-out-button"]
    XCTAssertTrue(
      signOutButton.waitForExistence(timeout: 10),
      "Sign-Out button should exist and be visible"
    )

    signOutButton.tap()
    XCTAssertTrue(
      signInButton.waitForExistence(timeout: 20),
      "Sign-In button should exist after logout"
    )

    let passwordRecoveryButton = app.buttons["password-recovery-button"]
    XCTAssertTrue(passwordRecoveryButton.exists, "Password recovery button should exist")
    passwordRecoveryButton.tap()
    let passwordRecoveryText = app.staticTexts["Send a password recovery link to your email"]
      .firstMatch
    XCTAssertTrue(
      passwordRecoveryText.waitForExistence(timeout: 10),
      "Password recovery text should exist after routing to PasswordRecoveryView"
    )

    let passwordRecoveryBackButton = app.navigationBars.buttons.element(boundBy: 0)
    XCTAssertTrue(passwordRecoveryBackButton.exists, "Password back button should exist")
    passwordRecoveryBackButton.tap()

    let signInButton2 = app.buttons["sign-in-button"]
    XCTAssertTrue(
      signInButton2.waitForExistence(timeout: 10),
      "Sign-In button should exist after pressing password recovery back button"
    )

    let emailLinkSignInButton = app.buttons["sign-in-with-email-link-button"]
    XCTAssertTrue(emailLinkSignInButton.exists, "Email link sign-in button should exist")
    emailLinkSignInButton.tap()

    let emailLinkText = app.staticTexts["Send a sign-in link to your email"].firstMatch

    XCTAssertTrue(
      emailLinkText.waitForExistence(timeout: 10),
      "Email link text should exist after pressing email link button in AuthPickerView"
    )

    let emailLinkBackButton = app.navigationBars.buttons.element(boundBy: 0)
    XCTAssertTrue(emailLinkBackButton.exists, "Email link back button should exist")
    emailLinkBackButton.tap()

    let signInButton3 = app.buttons["sign-in-button"]
    XCTAssertTrue(
      signInButton3.waitForExistence(timeout: 10),
      "Sign-In button should exist after pressing password recovery back button"
    )
  }

  @MainActor
  func testCreateUserDisplaysSignedInView() throws {
    let email = createEmail()
    let password = "qwerty321@"
    let app = createTestApp()
    app.launch()

    // Check the Views are updated
    let signOutButton = app.buttons["sign-out-button"]
    if signOutButton.exists {
      signOutButton.tap()
    }

    let switchFlowButton = app.buttons["switch-auth-flow"]
    switchFlowButton.tap()

    let emailField = app.textFields["email-field"]

    XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Email field should exist")
    try enterText(email, into: emailField, app: app)

    let passwordField = app.secureTextFields["password-field"]
    XCTAssertTrue(passwordField.exists, "Password field should exist")
    try enterText(password, into: passwordField, app: app)

    let confirmPasswordField = app.secureTextFields["confirm-password-field"]
    XCTAssertTrue(confirmPasswordField.exists, "Confirm password field should exist")
    try enterText(password, into: confirmPasswordField, app: app)

    // Create the user (sign up)
    let signUpButton = app
      .buttons["sign-in-button"] // This button changes context after switch-auth-flow
    XCTAssertTrue(signUpButton.exists, "Sign-Up button should exist")
    XCTAssertTrue(
      waitForElementToBecomeEnabled(signUpButton, timeout: 5),
      "Sign-up button should become enabled after entering credentials"
    )
    signUpButton.tap()

    // Wait for user creation and signed-in view to appear
    let signedInText = app.staticTexts["signed-in-text"]
    XCTAssertTrue(
      signedInText.waitForExistence(timeout: 30),
      "SignedInView should be visible after user creation"
    )
  }

  @MainActor
  func testUpdatePasswordFailureReachesErrorObserver() throws {
    let app = createTestApp()
    app.launchArguments.append("--update-password-error")
    app.launch()

    let password = app.secureTextFields["new-password-field"]
    XCTAssertTrue(password.waitForExistence(timeout: 6))
    try enterText("NewPassword321!", into: password, app: app)
    try enterText(
      "NewPassword321!",
      into: app.secureTextFields["confirm-new-password-field"],
      app: app
    )
    let update = app.buttons["update-password-button"]
    XCTAssertTrue(waitForElementToBecomeEnabled(update))
    update.tap()

    XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2))
    XCTAssertTrue(update.exists, "A failed update must keep the update form visible")
    XCTAssertEqual(app.textFields["new-password-field"].value as? String, "NewPassword321!")

    // Return to the picker, then close it to inspect the consumer's observation.
    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()
    let observation = app.staticTexts["observed-auth-error"]
    XCTAssertTrue(observation.waitForExistence(timeout: 5))
    XCTAssertEqual(
      observation.label,
      "1:true",
      "Report noCurrentUser as authentication exactly once"
    )
  }

  @MainActor
  func testSignUpPasswordReturnFocusesConfirmationWhenObscured() async throws {
    try await assertSignUpPasswordReturnFocusesConfirmation(obscured: true)
  }

  @MainActor
  func testSignUpPasswordReturnFocusesConfirmationWhenRevealed() async throws {
    try await assertSignUpPasswordReturnFocusesConfirmation(obscured: false)
  }

  @MainActor
  private func assertSignUpPasswordReturnFocusesConfirmation(obscured: Bool) async throws {
    let email = createEmail()
    let password = "QaReturn321!"
    // An existing emulator user makes an accidental sign-in observable.
    try await createTestUser(email: email, password: password)
    let app = createTestApp()
    app.launch()

    let switchFlow = app.buttons["switch-auth-flow"]
    XCTAssertTrue(switchFlow.waitForExistence(timeout: 6))
    switchFlow.tap()
    try enterText(email, into: app.textFields["email-field"], app: app)
    try enterText(password, into: app.secureTextFields["password-field"], app: app)
    if obscured {
      app.buttons["password-field"].tap()
      app.secureTextFields["password-field"].tap()
    }

    let signUp = app.buttons["sign-in-button"]
    XCTAssertFalse(signUp.isEnabled, "Confirmation is still required")
    let next = app.keyboards.buttons.matching(
      NSPredicate(format: "label ==[c] %@", "Next")
    ).firstMatch
    XCTAssertTrue(next.waitForExistence(timeout: 5), "Sign-up Password should show Next")
    next.tap()
    XCTAssertFalse(signUp.isEnabled, "Moving focus must not complete the form")

    // Do not tap Confirm Password: typing must go to the field focused by Return.
    app.typeText(password)
    let revealConfirmation = app.buttons["confirm-password-field"]
    XCTAssertTrue(
      revealConfirmation.waitForExistence(timeout: 5),
      "Return should focus Confirm Password so it receives subsequent typing"
    )
    revealConfirmation.tap()
    XCTAssertEqual(app.textFields["confirm-password-field"].value as? String, password)
    if obscured {
      app.buttons["password-field"].tap()
    }
    XCTAssertEqual(app.textFields["password-field"].value as? String, password)
    XCTAssertTrue(waitForElementToBecomeEnabled(signUp, timeout: 5))
    XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2))
    XCTAssertFalse(app.staticTexts["signed-in-text"].exists)
    XCTAssertTrue(switchFlow.exists, "The user should remain on the sign-up form")
  }

  @MainActor
  func testDuplicateEmailSignupDisplaysError() async throws {
    let email = createEmail()
    let password = "qwerty321@"
    try await createTestUser(email: email, password: password)
    let app = createTestApp()
    app.launch()

    let switchFlow = app.buttons["switch-auth-flow"]
    XCTAssertTrue(switchFlow.waitForExistence(timeout: 6))
    switchFlow.tap()
    try enterText(email, into: app.textFields["email-field"], app: app)
    try enterText(password, into: app.secureTextFields["password-field"], app: app)
    try enterText(password, into: app.secureTextFields["confirm-password-field"], app: app)
    let signUp = app.buttons["sign-in-button"]
    XCTAssertTrue(waitForElementToBecomeEnabled(signUp, timeout: 5))
    signUp.tap()

    let alert = app.alerts.firstMatch
    XCTAssertTrue(alert.waitForExistence(timeout: 10), "Duplicate signup must explain the failure")
    XCTAssertFalse(app.staticTexts["signed-in-text"].exists)
    alert.buttons["OK"].tap()
    XCTAssertTrue(switchFlow.exists, "The user must be able to switch to login after the error")
  }
}
