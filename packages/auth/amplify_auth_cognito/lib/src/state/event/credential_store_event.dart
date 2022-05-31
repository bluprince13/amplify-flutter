// Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_auth_cognito/src/model/cognito_device_secrets.dart';
import 'package:amplify_core/amplify_core.dart';

/// {@template amplify_auth_cognito.credential_store_event_type}
/// Discrete event types of the credential store state machine.
/// {@endtemplate}
enum CredentialStoreEventType {
  /// {@macro amplify_auth_cognito.credential_store_load}
  loadCredentialStore,

  /// {@macro amplify_auth_cognito.migrate_legacy_credential_store}
  migrateLegacyCredentialStore,

  /// {@macro amplify_auth_cognito.store_credentials}
  storeCredentials,

  /// {@macro amplify_auth_cognito.clear_credentials}
  clearCredentials,

  /// {@macro amplify_auth_cognito.credential_store_succeeded}
  succeeded,

  /// {@macro amplify_auth_cognito.credential_store_failed}
  failed,
}

/// {@template amplify_auth_cognito.credential_store_event}
/// Discrete events of the credential store state machine.
/// {@endtemplate}
abstract class CredentialStoreEvent
    extends StateMachineEvent<CredentialStoreEventType> {
  /// {@macro amplify_auth_cognito.credential_store_event}
  const CredentialStoreEvent._();

  /// {@macro amplify_auth_cognito.credential_store_load}
  const factory CredentialStoreEvent.loadCredentialStore() =
      CredentialStoreLoadCredentialStore;

  /// {@macro amplify_auth_cognito.migrate_legacy_credential_store}
  const factory CredentialStoreEvent.migrateLegacyCredentialStore() =
      CredentialStoreMigrateLegacyCredentialStore;

  /// {@macro amplify_auth_cognito.store_credentials}
  const factory CredentialStoreEvent.storeCredentials({
    String? identityId,
    AWSCredentials? awsCredentials,
    CognitoUserPoolTokens? userPoolTokens,
    CognitoDeviceSecrets? deviceSecrets,
  }) = CredentialStoreStoreCredentials;

  /// {@macro amplify_auth_cognito.clear_credentials}
  const factory CredentialStoreEvent.clearCredentials([
    Iterable<String> keys,
  ]) = CredentialStoreClearCredentials;

  /// {@macro amplify_auth_cognito.credential_store_succeeded}
  const factory CredentialStoreEvent.succeeded({
    String? identityId,
    AWSCredentials? awsCredentials,
    CognitoUserPoolTokens? userPoolTokens,
    CognitoDeviceSecrets? deviceSecrets,
  }) = CredentialStoreSucceeded;

  /// {@macro amplify_auth_cognito.credential_store_failed}
  const factory CredentialStoreEvent.failed(Exception exception) =
      CredentialStoreFailed;

  @override
  String? checkPrecondition(CredentialStoreState currentState) => null;

  @override
  String get runtimeTypeName => 'CredentialStoreEvent';
}

/// {@template amplify_auth_cognito.credential_store_load}
/// Initates loading of previously-stored credentials.
/// {@endtemplate}
class CredentialStoreLoadCredentialStore extends CredentialStoreEvent {
  /// {@macro amplify_auth_cognito.credential_store_load}
  const CredentialStoreLoadCredentialStore() : super._();

  @override
  CredentialStoreEventType get type =>
      CredentialStoreEventType.loadCredentialStore;

  @override
  List<Object?> get props => [type];

  @override
  String? checkPrecondition(CredentialStoreState currentState) {
    if (currentState.type != CredentialStoreStateType.notConfigured &&
        currentState.type != CredentialStoreStateType.failure) {
      return 'Credential store already configured';
    }
    return null;
  }
}

/// {@template amplify_auth_cognito.migrate_legacy_credential_store}
/// Initiates migration of a legacy credential store (pre-vNext) to the updated
/// structure.
/// {@endtemplate}
class CredentialStoreMigrateLegacyCredentialStore extends CredentialStoreEvent {
  /// {@macro amplify_auth_cognito.migrate_legacy_credential_store}
  const CredentialStoreMigrateLegacyCredentialStore() : super._();

  @override
  CredentialStoreEventType get type =>
      CredentialStoreEventType.migrateLegacyCredentialStore;

  @override
  List<Object?> get props => [type];

  @override
  String? checkPrecondition(CredentialStoreState currentState) {
    if (currentState.type !=
        CredentialStoreStateType.loadingStoredCredentials) {
      return 'Credential store cannot be migrated in current state';
    }
    return null;
  }
}

/// {@template amplify_auth_cognito.store_credentials}
/// Initiates storing of user credentials.
/// {@endtemplate}
class CredentialStoreStoreCredentials extends CredentialStoreEvent {
  /// {@macro amplify_auth_cognito.store_credentials}
  const CredentialStoreStoreCredentials({
    this.identityId,
    this.awsCredentials,
    this.userPoolTokens,
    this.deviceSecrets,
  }) : super._();

  /// AWS Identity ID
  final String? identityId;

  /// AWS Identity Pool credentials
  final AWSCredentials? awsCredentials;

  /// Cognito User Pool tokens
  final CognitoUserPoolTokens? userPoolTokens;

  /// Registered device secrets
  final CognitoDeviceSecrets? deviceSecrets;

  @override
  CredentialStoreEventType get type =>
      CredentialStoreEventType.storeCredentials;

  @override
  List<Object?> get props => [
        type,
        identityId,
        awsCredentials,
        userPoolTokens,
        deviceSecrets,
      ];

  @override
  String? checkPrecondition(CredentialStoreState currentState) {
    if (currentState.type == CredentialStoreStateType.notConfigured) {
      return 'Credential store is not configured';
    }
    if (currentState.type == CredentialStoreStateType.failure) {
      return 'Credential store has error. Re-load before continuing.';
    }
    if (currentState.type != CredentialStoreStateType.success) {
      return 'Credential store is busy';
    }
    return null;
  }
}

/// {@template amplify_auth_cognito.clear_credentials}
/// Initiates clearing of the credential store.
/// {@endtemplate}
class CredentialStoreClearCredentials extends CredentialStoreEvent {
  /// {@macro amplify_auth_cognito.clear_credentials}
  const CredentialStoreClearCredentials([this.keys = const []]) : super._();

  /// When set, only these keys will be cleared from the store. Otherwise,
  /// all keys are cleared.
  final Iterable<String> keys;

  @override
  CredentialStoreEventType get type =>
      CredentialStoreEventType.clearCredentials;

  @override
  List<Object?> get props => [type, keys];

  @override
  String? checkPrecondition(CredentialStoreState currentState) {
    if (currentState.type == CredentialStoreStateType.notConfigured) {
      return 'Credential store is not configured';
    }
    if (currentState.type == CredentialStoreStateType.failure) {
      return 'Credential store has error. Re-load before continuing.';
    }
    if (currentState.type != CredentialStoreStateType.success) {
      return 'Credential store is busy';
    }
    return null;
  }
}

/// {@template amplify_auth_cognito.credential_store_succeeded}
/// Successful completion of a credential store task.
/// {@endtemplate}
class CredentialStoreSucceeded extends CredentialStoreEvent {
  /// {@macro amplify_auth_cognito.credential_store_succeeded}
  const CredentialStoreSucceeded({
    this.identityId,
    this.awsCredentials,
    this.userPoolTokens,
    this.deviceSecrets,
  }) : super._();

  /// AWS Identity ID
  final String? identityId;

  /// AWS Identity Pool credentials
  final AWSCredentials? awsCredentials;

  /// Cognito User Pool tokens
  final CognitoUserPoolTokens? userPoolTokens;

  /// Registered device secrets
  final CognitoDeviceSecrets? deviceSecrets;

  @override
  CredentialStoreEventType get type => CredentialStoreEventType.succeeded;

  @override
  List<Object?> get props => [
        type,
        identityId,
        awsCredentials,
        userPoolTokens,
        deviceSecrets,
      ];

  @override
  String? checkPrecondition(CredentialStoreState currentState) {
    if (currentState.type == CredentialStoreStateType.notConfigured) {
      return 'Credential store is not configured';
    }
    return null;
  }
}

/// {@template amplify_auth_cognito.credential_store_failed}
/// Failure in a credential store task.
/// {@endtemplate}
class CredentialStoreFailed extends CredentialStoreEvent with ErrorEvent {
  /// {@macro amplify_auth_cognito.credential_store_failed}
  const CredentialStoreFailed(this.exception) : super._();

  /// The credential store exception.
  @override
  final Exception exception;

  @override
  CredentialStoreEventType get type => CredentialStoreEventType.failed;

  @override
  List<Object?> get props => [type, exception];

  @override
  String? checkPrecondition(CredentialStoreState currentState) {
    return null;
  }
}