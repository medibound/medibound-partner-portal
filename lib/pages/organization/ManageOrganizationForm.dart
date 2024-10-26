import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_network/image_network.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:medibound_library/medibound_library.dart';


class ManageOrganizationForm extends StatefulWidget {
  final MbOrganization organization;
  final MbUser user;
  final VoidCallback onSubmit;

  ManageOrganizationForm({
    required this.organization,
    required this.user,
    required this.onSubmit,
  });

  @override
  _ManageOrganizationFormState createState() => _ManageOrganizationFormState();
}

class _ManageOrganizationFormState extends State<ManageOrganizationForm> {
  final _formKey = GlobalKey<FormState>();
  late String? _name;
  late String? _email;
  late String? _website;
  late String? _privacyPolicy;
  late String? _address;
  late String? _organizationType;
  late String? _searchParms;
  late String _currentUserRole;
  late Map<String, MbRoledUser> _users;
  bool isLoading = false;
  bool isLoadingUsers = true; // Added loading flag for users
  Uint8List? _imageData;
  final CropController _cropController = CropController();

  @override
  void initState() {
    super.initState();
    _name = widget.organization.name;
    _email = widget.organization.email;
    _website = widget.organization.website;
    _privacyPolicy = widget.organization.privacyPolicy;
    _address = widget.organization.address;
    _organizationType = widget.organization.type;
    _searchParms = '';
    _currentUserRole = _determineUserRole();
    _users = {};
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    for (var user in widget.organization.members) {
      _addUser(user);
    
    }
    setState(() {
      isLoadingUsers = false; // Set loading flag to false after loading users
    });
  }

  String _determineUserRole() {
    for (var member in widget.organization.members) {
      if (member.id == widget.user.id) {
        return member.role ?? 'member';
      }
    }
    return 'member';
  }

  void _addUser(MbRoledUser user) {
    setState(() {
      _users.addAll({user.id!: user});
    });
  }

  void _removeUser(MbRoledUser user) {
    setState(() {
      _users.remove(user.id);
    });
  }


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.organization.name = _name!;
      widget.organization.email = _email!;
      widget.organization.website = _website!;
      widget.organization.privacyPolicy = _privacyPolicy!;
      widget.organization.address = _address!;
      widget.organization.type = _organizationType!;
      widget.organization.members = _users.entries.map((e) => e.value).toList().cast<MbRoledUser>();
      setState(() {
        isLoading = true;
      });
      // Update organization
      await widget.organization.update(
        imageData: _imageData,
      );
      setState(() {
        isLoading = false;
      });
      widget.onSubmit();
    }
  }

  Future<List<MbRoledUser>> _fetchUsersSuggestions(
      String query, List<String> excludedValues) async {
    if (query.isEmpty) {
      return [];
    }

    print('Fetching suggestions for query: $query');

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    List<Future<MbRoledUser>> futureSuggestions = querySnapshot.docs
        .where((doc) => !excludedValues.contains(doc['id']))
        .map((doc) async {
      var user = await MbUser.getStatic(id: doc['id']);
      return MbRoledUser(user: user, role: 'invited'); // Assuming default role as 'member'
    }).toList();

    List<MbRoledUser> suggestions = await Future.wait(futureSuggestions);

    print('Suggestions fetched: $suggestions');

    return suggestions;
  }

  bool _canRemoveUser(String userRole) {
    // Only allow removing users if the current user is an admin or owner
    return _currentUserRole == 'owner' ||
        (_currentUserRole == 'admin' &&
            userRole != 'admin' &&
            userRole != 'owner');
  }

  bool _canEditRole(String userRole) {
    // Allow editing roles if current user is owner, or admin (but not for other admins or owners)
    return _currentUserRole == 'owner' ||
        (_currentUserRole == 'admin' &&
            userRole != 'admin' &&
            userRole != 'owner');
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
          MbTitle(text: "Manage Organization"),
          SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MbSection(
                  title: "Basic Information",
                  icon: Icons.work,
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
                                    ? Image.memory(_imageData!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover)
                                    : (widget.organization.pictureUrl != null &&
                                            widget.organization.pictureUrl !=
                                                "")
                                        ? ImageNetwork(
                                            image:
                                                widget.organization.pictureUrl!,
                                            height: 100,
                                            width: 100)
                                        : Image.asset(
                                            'assets/image/default.jpg',
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover),
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
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      MbInput(
                                        labelText: 'Name',
                                        hintText: "Delorean Motors",
                                        initialValue: _name,
                                        onSaved: (String? value) =>
                                            _name = value,
                                      ),
                                      MbInput(
                                        labelText: 'Website',
                                        hintText: "www.delorean.com",
                                        initialValue: _website,
                                        onSaved: (String? value) =>
                                            _website = value,
                                      ),
                                      MbInput(
                                        labelText: 'Support Email (Public)',
                                        hintText: "delorean@motors.com",
                                        initialValue: _email,
                                        onSaved: (String? value) =>
                                            _email = value,
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
                                        initialValue: _organizationType,
                                        onChanged: (String? value) {
                                          print(value);
                                          setState(() {
                                            _organizationType = value!;
                                          });
                                        },
                                        onSaved: (String? value) =>
                                            _organizationType = value!,
                                      ),
                                      MbInput(
                                        labelText: 'Privacy Policy',
                                        hintText: "Privacy Policy URL",
                                        initialValue: _privacyPolicy,
                                        onSaved: (String? value) =>
                                            _privacyPolicy = value,
                                      ),
                                      MbInput(
                                        labelText: 'Address',
                                        hintText: "1234 Main St, Anytown, USA",
                                        initialValue: _address,
                                        onSaved: (String? value) =>
                                            _address = value,
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
                MbSection(
                  title: "Add Users",
                  desc: "Establish your team and assign the proper roles",
                  icon: Icons.people,
                  color: MbColors(context).third,
                  trailing: [
                    Expanded(
                      child: MbSuggestedSearch(
                        isSearch: true,
                        hintText: "Search To Invite Members By Email...",
                        labelText: 'Member',
                        shownValue: 'name',
                        initialValue: '',
                        excludedValues: [
                          ..._users.entries.map((u) => u.key)
                        ],
                        onChanged: (String? value) => _privacyPolicy = value,
                        onSelected: (value) => {},
                        searchCallback: _fetchUsersSuggestions,
                        suggestionButtonText: "Tap to Invite",
                        suggestionButtonPress: (user) => _addUser(user),
                      ),
                    ),
                  ],
                  child: Column(
                    children: isLoadingUsers // Show loading icon if users are still being loaded
                        ? [
                            Center(child: CircularProgressIndicator()),
                          ]
                        : _users.entries.map((entry) {
                            return Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 10),
                                    child: Row(children: [
                                      ImageNetwork(
                                        image: entry.value.pictureUrl!,
                                        height: 40,
                                        width: 40,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          MbTitle4(
                                              text: entry.value.givenNames[0] +
                                                  " " +
                                                  entry.value.familyName),
                                          MbSubheading2(
                                              text: entry.value.email)
                                        ],
                                      ),
                                    ]),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: MbDropdown(
                                    hintText: 'Select Role',
                                    labelText: 'Role',
                                    codes: OrganizationRole.codes,
                                    initialValue: entry.value.role,
                                    onChanged: (String? value) {
                                      setState(() {
                                        entry.value.role = value!;
                                      });
                                    },
                                    onSaved: (String? value) {
                                      entry.value.role = value!;
                                    },
                                    enabled: entry.value.role != 'invited' &&
                                        entry.value.role != 'owner',
                                  ),
                                ),
                                if (_canRemoveUser(entry.value.role!))
                                  IconButton(
                                    icon: Icon(Icons.remove_circle),
                                    onPressed: () => _removeUser(entry.value),
                                  ),
                              ],
                            );
                          }).toList(),
                  ),
                ),
                SizedBox(height: 20),
                MbFilledButton(
                  text: "Update Organization",
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submitForm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
