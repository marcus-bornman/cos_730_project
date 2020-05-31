import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:invite_only_repo/src/errors/auth_failure.dart';
import 'package:invite_only_repo/src/errors/conflict.dart';
import 'package:invite_only_repo/src/errors/invalid_invite.dart';
import 'package:invite_only_repo/src/errors/not_found.dart';
import 'package:invite_only_repo/src/errors/uknown_error.dart';
import 'package:invite_only_repo/src/errors/unauthenticated.dart';
import 'package:invite_only_repo/src/errors/unauthorized.dart';
import 'package:invite_only_repo/src/models/entry/entry.dart';
import 'package:invite_only_repo/src/models/id_document/id_document.dart';
import 'package:invite_only_repo/src/models/invite/invite.dart';
import 'package:invite_only_repo/src/models/space/space.dart';

import 'invite_only_repo.dart';

class InviteOnlyRepoImpl implements InviteOnlyRepo {
  /// The url to use for requests to the core API.
  static String _coreUrl = 'https://core.inviteonly.co.za';

  /// The singleton instance of this class
  static InviteOnlyRepoImpl _instance;

  /// The provider for authentication services.
  final FirebaseAuth _fireAuth;

  /// The internally visible constructor for this class - singleton.
  InviteOnlyRepoImpl._internal({FirebaseAuth fireAuth})
      : _fireAuth = fireAuth != null ? fireAuth : FirebaseAuth.instance;

  /// The method to retrieve the singleton instance of this class
  ///
  /// The optional parameters should only be necessary for testing purposes.
  static InviteOnlyRepoImpl getInstance({FirebaseAuth firebaseAuth}) {
    if (_instance == null) {
      _instance = InviteOnlyRepoImpl._internal(fireAuth: firebaseAuth);
    }

    return _instance;
  }

  @override
  Future<void> verifyPhoneNumber({
    @required String phoneNumber,
    @required Duration retrievalTimeout,
    @required Function(InviteOnlyCredential) verificationCompleted,
    @required Function(AuthFailure) verificationFailed,
    @required Function(String) codeSent,
  }) async {
    await _fireAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: retrievalTimeout,
      verificationCompleted: (credential) {
        verificationCompleted(InviteOnlyCredential(credential));
      },
      verificationFailed: (e) => AuthFailure(e.message),
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (verificationId) {
        //do nothing
      },
    );
  }

  @override
  InviteOnlyCredential getAuthCredential(
      String phoneVerificationId, String smsCode) {
    return InviteOnlyCredential(
      PhoneAuthProvider.getCredential(
        verificationId: phoneVerificationId,
        smsCode: smsCode,
      ),
    );
  }

  @override
  Future<void> signInWithCredential(
      InviteOnlyCredential inviteOnlyCredential) async {
    try {
      await _fireAuth.signInWithCredential(inviteOnlyCredential.credential);
    } catch (e) {
      throw AuthFailure('Credential could not be used to sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _fireAuth.signOut();
  }

  @override
  Future<Entry> addEntry(Space space, IdDocument idDocument,
      [String code]) async {
    final token = await _authToken();
    String url = "$_coreUrl/spaces/${space.id}/entries";
    if (code != null) url += "?inviteCode=$code";
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(idDocument.toJson()),
    );

    switch (response.statusCode) {
      case HttpStatus.created:
        return Entry.fromJson(json.decode(response.body));
      case HttpStatus.notFound:
        throw NotFound();
      case HttpStatus.forbidden:
        throw Unauthorized(response.reasonPhrase);
      case HttpStatus.notAcceptable:
        throw InvalidInvite();
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<IdDocument> addIdDocument(IdDocument idDocument) async {
    final token = await _authToken();
    String url = "$_coreUrl/docs";
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(idDocument.toJson()),
    );

    switch (response.statusCode) {
      case HttpStatus.created:
        return IdDocument.fromJson(json.decode(response.body));
      case HttpStatus.conflict:
        throw Conflict();
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<Space> addSpace(Space space) async {
    final token = await _authToken();
    String url = "$_coreUrl/spaces";
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(space.toJson()),
    );

    switch (response.statusCode) {
      case HttpStatus.created:
        return Space.fromJson(json.decode(response.body));
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<Invite> createInvite(Space space) async {
    final token = await _authToken();
    String url = "$_coreUrl/spaces/${space.id}/invites";
    final response =
        await http.post(url, headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case HttpStatus.created:
        return Invite.fromJson(json.decode(response.body));
      case HttpStatus.notFound:
        throw NotFound();
      case HttpStatus.forbidden:
        throw Unauthorized(response.reasonPhrase);
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<void> deleteIdDocument(IdDocument idDocument) async {
    final token = await _authToken();
    String url = "$_coreUrl/docs/${idDocument.id}";
    final response =
        await http.delete(url, headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case HttpStatus.ok:
        return Entry.fromJson(json.decode(response.body));
      case HttpStatus.notFound:
        throw NotFound();
      case HttpStatus.forbidden:
        throw Unauthorized(response.reasonPhrase);
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<void> deleteSpace(Space space) async {
    final token = await _authToken();
    String url = "$_coreUrl/spaces/${space.id}";
    final response =
        await http.delete(url, headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case HttpStatus.ok:
        return Entry.fromJson(json.decode(response.body));
      case HttpStatus.notFound:
        throw NotFound();
      case HttpStatus.forbidden:
        throw Unauthorized(response.reasonPhrase);
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<List<Entry>> fetchEntries(
      Space space, int pageSize, int pageNum) async {
    final token = await _authToken();
    String url =
        "$_coreUrl/spaces/${space.id}/entries?page=$pageNum&size=$pageSize";
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case HttpStatus.ok:
        List<dynamic> list = json.decode(response.body)['content'];
        return list.map((e) => Entry.fromJson(e)).toList();
      case HttpStatus.notFound:
        throw NotFound();
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<List<IdDocument>> fetchIdDocuments() async {
    final token = await _authToken();
    String url = "$_coreUrl/docs";
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case HttpStatus.ok:
        List<dynamic> list = json.decode(response.body);
        return list.map((e) => IdDocument.fromJson(e)).toList();
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<List<Space>> fetchSpaces() async {
    final token = await _authToken();
    String url = "$_coreUrl/spaces";
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case HttpStatus.ok:
        List<dynamic> list = json.decode(response.body);
        return list.map((e) => Space.fromJson(e)).toList();
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  @override
  Future<Space> updateSpace(Space space) async {
    final token = await _authToken();
    String url = "$_coreUrl/spaces/${space.id.toString()}";
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(space.toJson()),
    );
    switch (response.statusCode) {
      case HttpStatus.ok:
        return Space.fromJson(json.decode(response.body));
      case HttpStatus.notFound:
        throw NotFound();
      case HttpStatus.forbidden:
        throw Unauthorized(response.reasonPhrase);
      default:
        throw UnknownError(response.reasonPhrase);
    }
  }

  Future<String> _authToken() async {
    final user = await _fireAuth.currentUser();
    if (user == null) throw Unauthenticated();
    IdTokenResult tokenResult = await user.getIdToken();
    if (tokenResult.expirationTime.isBefore(DateTime.now())) {
      tokenResult = await user.getIdToken(refresh: true);
    }
    return tokenResult.token;
  }

  @override
  Future<String> currentUser() async {
    final user = await _fireAuth.currentUser();

    if (user == null) return null;

    return user.phoneNumber;
  }
}