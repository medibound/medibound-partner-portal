import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:mediboundbusiness/helper/fhir/Organization.dart';
import 'package:mediboundbusiness/types/OrganizationTypes.dart';
import 'package:mediboundbusiness/res/MediboundBuilder.dart';
import 'package:mediboundbusiness/ui/Input.dart';
import 'package:mediboundbusiness/ui/Button.dart';
import 'package:mediboundbusiness/ui/Section.dart';
import 'package:mediboundbusiness/helper/fhir/User.dart';
import 'package:mediboundbusiness/ui/SuggestedInput.dart';
import 'package:mediboundbusiness/ui/Titles.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CreateOrganizationForm extends StatefulWidget {
  final VoidCallback onSubmit;
  final MbUser user;

  CreateOrganizationForm({
    required this.onSubmit,
    required this.user,
  });

  @override
  _CreateOrganizationFormState createState() => _CreateOrganizationFormState();
}

class _CreateOrganizationFormState extends State<CreateOrganizationForm> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  Uint8List? _imageData;
  String? _organizationType;
  String? _privacyPolicy;
  String? _website;
  String? _address;
  List<Map<String, String>> _users = [];
  bool isLoading = false;
  final CropController _cropController = CropController();



  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      var users = _users.where((member) => member['userId']!.isNotEmpty).toList();

      // Build the members array
      List<Map<String, String>> members = [
        {
          'userId': widget.user.id!,
          'role': 'owner',
        },
        ...users,
      ];

      try {
        // Call the Firebase function
        setState(() {
          isLoading = true;
        });
        final organization = MbOrganization(
          name: _name!,
          email: _email!,
          type: _organizationType!,
          privacyPolicy: _privacyPolicy!,
          website: _website!,
          address: _address!,
          members: members,
        );
        print(organization.toJson("create"));
        await organization.create(imageData: _imageData);
        setState(() {
          isLoading = false;
        });
        widget.onSubmit();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error calling function: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePickerWeb.getImageAsBytes();
    if (pickedImage != null) {
      setState(() {
        _imageData = pickedImage;
      });
      _cropController.crop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MbOutlinedButton(
            onPressed: widget.onSubmit,
            text: "Back to My Organizations",
            icon: Icons.arrow_back,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          SizedBox(height: 10),
          MbTitle(text: "Create Organization"),
          SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MbSection(
                  title: "Basic Information",
                  icon: FontAwesomeIcons.scroll,
                  desc: "Identification data regarding your business",
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _imageData != null
                                    ? Image.memory(
                                        _imageData!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/image/default.jpg',
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      MbInput(
                                        icon: FontAwesomeIcons.buildingUser,
                                        labelText: 'Name',
                                        hintText: "Delorean Motors",
                                        onSaved: (value) => _name = value,
                                        required: true,
                                      ),
                                      MbInput(
                                        icon: FontAwesomeIcons.globe,
                                        labelText: 'Website',
                                        hintText: "https://medibound.com",
                                        onSaved: (value) => _website = value,
                                        required: true,
                                      ),
                                      MbInput(
                                        icon: FontAwesomeIcons.solidEnvelope,
                                        labelText: 'Support Email (Public)',
                                        hintText: "support@medibound.com",
                                        onSaved: (value) => _email = value,
                                        required: true,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      MbDropdown(
                                        hintText: 'Select organization type',
                                        labelText: 'Organization Type',
                                        codes: OrganizationType.codes,
                                        onChanged: (value) {
                                          setState(() {
                                            _organizationType =
                                                value;
                                          });
                                        },
                                        required: true,
                                      ),
                                      MbInput(
                                        icon: FontAwesomeIcons.userShield,
                                        labelText: 'Privacy Policy Link',
                                        hintText:
                                            "https://medibound.com/privacy-policy",
                                        onSaved: (value) =>
                                            _privacyPolicy = value,
                                        required: true,
                                      ),
                                      MbInput(
                                        icon: FontAwesomeIcons.mapMarkerAlt,
                                        labelText: 'Address',
                                        hintText: "123 Main St, Anytown, USA",
                                        onSaved: (value) => _address = value,
                                        required: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                MbFilledButton(
                  text: "Create Organization",
                  onPressed: _submitForm,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
