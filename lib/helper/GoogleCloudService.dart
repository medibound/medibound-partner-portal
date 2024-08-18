import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as jsonDart;
/*import 'package:medibound_flutter/helpers/fhir-functions/DeviceFunctions.dart';
import 'package:medibound_flutter/helpers/fhir-functions/DeviceDefinitionFunctions.dart';
import 'package:medibound_flutter/helpers/fhir-functions/ObservationFunctions.dart';
import 'package:medibound_flutter/helpers/fhir-functions/ObservationDefinitionFunctions.dart';
import 'package:medibound_flutter/helpers/fhir-functions/OrganizationFunctions.dart';
import 'package:medibound_flutter/helpers/fhir/Device.dart';
import 'package:medibound_flutter/helpers/fhir/Observation.dart';
import 'package:medibound_flutter/helpers/fhir/Organization.dart';*/
import 'package:pointycastle/asymmetric/api.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:jose/jose.dart';
import "package:googleapis_auth/auth_io.dart";
import "package:http/http.dart" as http;

import 'package:asn1lib/asn1lib.dart' as asn;
import 'package:pointycastle/pointycastle.dart';

class GoogleServiceAccountCredentials {
  final String type;
  final String projectId;
  final String privateKeyId;
  final String privateKey;
  final String clientEmail;
  final String clientId;
  final String authUri;
  final String tokenUri;
  final String authProviderX509CertUrl;
  final String clientX509CertUrl;

  GoogleServiceAccountCredentials({
    required this.type,
    required this.projectId,
    required this.privateKeyId,
    required this.privateKey,
    required this.clientEmail,
    required this.clientId,
    required this.authUri,
    required this.tokenUri,
    required this.authProviderX509CertUrl,
    required this.clientX509CertUrl,
  });

  factory GoogleServiceAccountCredentials.fromJson(Map<String, dynamic> json) {
    return GoogleServiceAccountCredentials(
      type: json['type'],
      projectId: json['project_id'],
      privateKeyId: json['private_key_id'],
      privateKey: json['private_key'],
      clientEmail: json['client_email'],
      clientId: json['client_id'],
      authUri: json['auth_uri'],
      tokenUri: json['token_uri'],
      authProviderX509CertUrl: json['auth_provider_x509_cert_url'],
      clientX509CertUrl: json['client_x509_cert_url'],
    );
  }
}

class FHIRFunctions {
  /*final OrganizationFunctions organization;
  final ObservationFunctions observation;
  final ObservationDefinitionFunctions observationDefinition;
  final DeviceFunctions device;
  final DeviceDefinitionFunctions deviceDefinition;*/

  final String token;
  final String identityToken;

  FHIRFunctions({
    /*required this.organization,
    required this.observation,
    required this.observationDefinition,
    required this.device,
    required this.deviceDefinition,*/
    required this.token,
    required this.identityToken
  });
}


class GoogleCloudService {

  
  GoogleCloudService() {}

  Future<FHIRFunctions> init() async {
    var token = await getAccessTokenFromServiceAccount();
    var identityToken = await getIdentityTokenFromServiceAccount() ?? "";

    /*OrganizationFunctions organization = OrganizationFunctions(token: token);
    ObservationFunctions observation = ObservationFunctions(token: token);
    ObservationDefinitionFunctions observationDefinition = ObservationDefinitionFunctions(token: token);
    DeviceFunctions device = DeviceFunctions(token: token);
    DeviceDefinitionFunctions deviceDefinition = DeviceDefinitionFunctions(token: identityToken);*/

    return FHIRFunctions(/*organization: organization, observation: observation, observationDefinition: observationDefinition, device: device, deviceDefinition: deviceDefinition,*/ token: token, identityToken: identityToken);
  }

  Future<Map<String, dynamic>> getServiceAccountDetails(String filePath) async {
    final jsonString = await rootBundle
        .loadString('medibound-420121-1c078e16b1ed.json');
    final json = jsonDecode(jsonString);
    return json;
  }

  String createJwt(ServiceAccountCredentials serviceAccountDetails, String audience) {
    final clientEmail = serviceAccountDetails.email;
    final privateKey = serviceAccountDetails.privateKey;
    final now = DateTime.now();
    final expiry = now.add(Duration(hours: 1));

    final claimSet = JsonWebTokenClaims.fromJson({
      'iss': clientEmail,
      'target_audience': audience,
      'aud': 'https://www.googleapis.com/oauth2/v4/token',
      'iat': (now.millisecondsSinceEpoch / 1000).floor(),
      'exp': (expiry.millisecondsSinceEpoch / 1000).floor(),
    });

    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claimSet.toJson()
      ..addRecipient(
        JsonWebKey.fromPem(privateKey),
        algorithm: 'RS256',
      );

    final jws = builder.build();
    return jws.toCompactSerialization();
  }

  Future<String> getAccessToken(String jwt) async {
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': jwt,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['id_token'];
    } else {
      throw Exception('Failed to obtain access token: ${response.body}');
    }
  }

  Future<String> getAccessTokenFromServiceAccount() async {
    var accountCredentials = ServiceAccountCredentials.fromJson(await getServiceAccountDetails(
        "lib/assets/medibound-420121-1c078e16b1ed.json"));
    final scope = ['https://www.googleapis.com/auth/cloud-healthcare','https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/devstorage.read_write'];
    
    var client = http.Client();
    
    AccessCredentials credentials = await obtainAccessCredentialsViaServiceAccount(accountCredentials, scope, client);
    
    client.close();
    return credentials.accessToken.data;
  }

  Future<String> getIdentityTokenFromServiceAccount() async {
    var accountCredentials = ServiceAccountCredentials.fromJson(await getServiceAccountDetails(
        "lib/assets/medibound-420121-1c078e16b1ed.json"));
    final scope = ['https://www.googleapis.com/auth/cloud-healthcare','https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/devstorage.read_write'];
    

    var jwt = createJwt(accountCredentials, "https://us-central1-medibound-420121.cloudfunctions.net/getResource");
      var idToken = await getAccessToken(jwt);


    return idToken ?? "";
  }

  

  /*Future<String?> getAccessToken3() async {
    if (credentials == null) {
      return null;
    }
    

    final jwt = jsonDart.JWT(
      {
        'iss': credentials!.clientEmail,
        'scope': 'https://www.googleapis.com/auth/cloud-healthcare https://www.googleapis.com/auth/devstorage.read_write',
        'aud': credentials!.tokenUri,
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    );
//print(credentials!.privateKey);
    final privateKey = parsePrivateKeyFromPem(credentials!.privateKey);
    
    final token = jwt.sign(jsonDart.SecretKey(privateKey.toString()), algorithm: jsonDart.JWTAlgorithm.RS256);

    final response = await http.post(
      Uri.parse(credentials!.tokenUri),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$token',
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['access_token'];
    }

    return null;
  }*/

  Future<void> linkGoogleUserToFHIR(
    String token,
    String userId,
    String email,
    String password,
    String firstName,
    String lastName,
    String middleName,
    String gender,
    DateTime birthdate,
  ) async {
    final fhirServerUrl = Uri.parse(
        'https://healthcare.googleapis.com/v1/projects/medibound-420121/locations/us-east4/datasets/Medibound/fhirStores/Medibound-Test/fhir/Patient?identifier:contains=$userId');
    final response = await http.get(
      fhirServerUrl,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['total'] > 0) {
        print('Patient record already exists for userId: $userId');
      } else {
        await fetchHealthcareData(userId, token, email, password, firstName,
            lastName, middleName, gender, birthdate);
      }
    } else {
      print('Error during HTTP request: ${response.body}');
    }
  }

  Future<void> fetchHealthcareData(
    String userId,
    String token,
    String email,
    String password,
    String firstName,
    String lastName,
    String middleName,
    String gender,
    DateTime birthdate,
  ) async {
    final fhirServerUrl = Uri.parse(
        'https://healthcare.googleapis.com/v1/projects/medibound-420121/locations/us-east4/datasets/Medibound/fhirStores/Medibound-Test/fhir/Patient');

    final birthdateString = birthdate.toIso8601String().split('T').first;

    final patientData = {
      'resourceType': 'Patient',
      'identifier': [
        {
          'system': 'https://www.googleapis.com/oauth2/v3/userinfo',
          'value': userId
        }
      ],
      'id': userId,
      'name': [
        {
          'use': 'official',
          'family': lastName,
          'given': [firstName, middleName]
        }
      ],
      'telecom': [
        {'system': 'email', 'value': email, 'use': 'home'}
      ],
      'gender': gender.toLowerCase(),
      'birthDate': birthdateString,
    };

    print(patientData);

    final response = await http.post(
      fhirServerUrl,
      headers: {
        'Content-Type': 'application/fhir+json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(patientData),
    );

    if (response.statusCode == 200) {
      print('Patient data uploaded successfully.');
    } else {
      print('Error uploading FHIR data: ${response.body}');
    }
  }

  

  
}









