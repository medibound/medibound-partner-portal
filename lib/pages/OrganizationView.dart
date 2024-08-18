import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_network/image_network.dart';
import 'package:mediboundbusiness/helper/fhir/Organization.dart';
import 'package:mediboundbusiness/helper/fhir/User.dart';
import 'package:mediboundbusiness/pages/organization/CreateOrganizationForm.dart';
import 'package:mediboundbusiness/pages/organization/ManageOrganizationForm.dart';
import 'package:mediboundbusiness/types/OrganizationTypes.dart';
import 'package:mediboundbusiness/res/MediboundBuilder.dart';
import 'package:mediboundbusiness/ui/Blurred.dart';
import 'package:mediboundbusiness/ui/Button.dart';
import 'package:mediboundbusiness/ui/Titles.dart';

class OrganizationView extends StatefulWidget {
  final MbUser user;

  OrganizationView({
    required this.user,
  });

  @override
  _OrganizationViewState createState() => _OrganizationViewState();
}

Stream<List<MbOrganization>> fetchOrganizations(search) async* {
  var snapshots = FirebaseFirestore.instance
      .collection('organizations')
      .where('membersIds', arrayContains: search)
      .snapshots();

  await for (var snapshot in snapshots) {
    List<MbOrganization> organizations = [];
    
    for (var doc in snapshot.docs) {
      var data = doc.data();
      data['id'] = doc.id;
      print('Organization ID: ${doc.id}'); // Debugging statement
      try {
        var organization = await MbOrganization.getStatic(id: doc.id);
        organizations.add(organization);
      } catch (e) {
        // Handle error appropriately, e.g., log it or ignore specific errors
        print('Error fetching organization data: $e');
      }
    }
    
    yield organizations;
  }
}

Stream<Map<String, Map<String, dynamic>>> fetchOrganizationsJson(search) async* {
  var snapshots = FirebaseFirestore.instance
      .collection('organizations')
      .where('membersIds', arrayContains: search)
      .snapshots();

  await for (var snapshot in snapshots) {
    Map<String, Map<String, dynamic>> organizations = {};
    
    for (var doc in snapshot.docs) {
      var data = doc.data();
      data['id'] = doc.id;
      //print('Organization ID: ${doc.id}'); // Debugging statement
      try {
        var organization = await MbOrganization.getStatic(id: doc.id);
        var organizationJson = organization.toJson("ADD");
        organizationJson.addAll({'description': OrganizationType.codes[organization.type]!['name']});
        organizations.addAll({doc.id : organizationJson});
      } catch (e) {
        // Handle error appropriately, e.g., log it or ignore specific errors
        print('Error fetching organization data: $e');
      }
    }
    //print(organizations);
    yield organizations;
  }
}

class _OrganizationViewState extends State<OrganizationView> {
  bool _showCreateOrganizationPage = false;
  bool _showManageOrganizationPage = false;
  MbOrganization? _currentOrganization;
  Map<String, bool> _loadingMap = {};

  void _toggleCreateOrganizationPage() {
    setState(() {
      _showCreateOrganizationPage = !_showCreateOrganizationPage;
    });
  }

  void _toggleManageOrganizationPage([MbOrganization? organization]) {
    fetchOrganizations(widget.user.id);
    if (organization == null) {
      setState(() {
        _showManageOrganizationPage = false;
        _currentOrganization = null;
      });
    } else {
      setState(() {
        _currentOrganization = organization;
        _showManageOrganizationPage = true;
      });
    }
  }

 


  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: StreamBuilder<List<MbOrganization>>(
          stream: fetchOrganizations(widget.user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading organizations: ${snapshot.error}'));
            }

            var organizations = snapshot.data!;
            var myOrganizations = organizations
                .where((org) => org.members.any((member) =>
                    member['userId'] == widget.user.id &&
                    member['role'] != 'invited'))
                .toList();
            var myInvitations = organizations
                .where((org) => org.members.any((member) =>
                    member['userId'] == widget.user.id &&
                    member['role'] == 'invited'))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (!_showCreateOrganizationPage &&
                              !_showManageOrganizationPage) ...[
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    MbTitle(text: "My Organizations"),
                                    Spacer(),
                                    MbOutlinedButton(
                                      onPressed: _toggleCreateOrganizationPage,
                                      text: "Create Organization",
                                      icon: Icons.add,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 20),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !snapshot.hasData)
                                  Center(child: CircularProgressIndicator()),
                                if (!snapshot.hasData || myOrganizations.isEmpty)
                                  Center(child: Text('No organizations found.')),
                                MbBlurred(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i < myOrganizations.length;
                                                i++) ...[
                                              _buildOrganizationListItem(
                                                  myOrganizations[i]),
                                              if (i != myOrganizations.length - 1)
                                                Divider(
                                                  color: MbColors(context)
                                                      .grey
                                                      .withOpacity(0.2),
                                                  thickness: 1,
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    MbTitle(text: "My Invitations"),
                                    Spacer(),
                                  ],
                                ),
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !snapshot.hasData)
                                  Center(child: CircularProgressIndicator()),
                                if (!snapshot.hasData || myInvitations.isEmpty)
                                  Center(child: Text('No invitations found.')),
                                MbBlurred(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i < myInvitations.length;
                                                i++) ...[
                                              _buildInviteOrganizationListItem(
                                                  myInvitations[i]),
                                              if (i != myInvitations.length - 1)
                                                Divider(
                                                  color: MbColors(context)
                                                      .grey
                                                      .withOpacity(0.2),
                                                  thickness: 1,
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else if (_showCreateOrganizationPage) ...[
                            CreateOrganizationForm(
                              onSubmit: _toggleCreateOrganizationPage,
                              user: widget.user,
                            )
                          ] else if (_showManageOrganizationPage &&
                              _currentOrganization != null) ...[
                            ManageOrganizationForm(
                              user: widget.user,
                              organization: _currentOrganization!,
                              onSubmit: () => _toggleManageOrganizationPage(null),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrganizationListItem(MbOrganization organization) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      height: 60,
      child: Row(
        children: [
          organization.pictureUrl != null && organization.pictureUrl != ""
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  clipBehavior: Clip.hardEdge,
                  child: ImageNetwork(
                      borderRadius: BorderRadius.circular(5),
                      image: organization.pictureUrl!,
                      width: 40,
                      height: 40))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image(
                    image: AssetImage('assets/image/default.jpg'),
                    width: 40,
                    height: 40,
                  ),
                ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MbTitle4(text: organization.name),
              Row(
                children: [
                  MbSubheading2(
                    icon: OrganizationType.codes[organization.type]!['icon'],
                      text: OrganizationType.codes[organization.type]!['name']),
                ],
              ),
            ],
          ),
          Spacer(),
          organization.members.any((member) =>
                  member['userId'] == widget.user.id &&
                  (member['role'] == 'admin' || member['role'] == 'owner'))
              ? MbOutlinedButton(
                  text: "Manage",
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  onPressed: () => _toggleManageOrganizationPage(organization),
                )
              : SizedBox(width: 0),
          MbTextButton(
            text: "Remove",
            isLoading: _loadingMap[organization.id] == true,
            color: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 20),
            onPressed: () async {
              setState(() {
                _loadingMap[organization.id!] = true;
              });
              await organization.delete().onError((error, stackTrace) => {
                    setState(() {
                      _loadingMap[organization.id!] = false;
                    })
                  });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInviteOrganizationListItem(MbOrganization organization) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      height: 50,
      child: Row(
        children: [
          organization.pictureUrl != null && organization.pictureUrl != ""
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  clipBehavior: Clip.hardEdge,
                  child: ImageNetwork(
                      borderRadius: BorderRadius.circular(5),
                      image: organization.pictureUrl!,
                      width: 40,
                      height: 40))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image(
                    image: AssetImage('assets/image/default.jpg'),
                    width: 40,
                    height: 40,
                  ),
                ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MbTitle4(text: organization.name),
              MbSubheading3(
                  text: OrganizationType.codes[organization.type]!['name']),
            ],
          ),
          Spacer(),
          MbOutlinedButton(
            text: "Accept",
            isLoading: _loadingMap[organization.id! + "accept"] == true,
            padding: EdgeInsets.symmetric(horizontal: 20),
            onPressed: () async {
              setState(() {
                _loadingMap[organization.id! + "accept"] = true;
              });
              List<Map<String, String>> updatedMembers =
                  organization.members!.map((member) {
                if (member['userId'] == widget.user.id) {
                  return {
                    'userId': widget.user.id!,
                    'role': 'member'
                  }; // Update the role from 'invited' to 'member'
                }
                
                return member;
              }).toList();
              await organization
                  .update(
                    members: updatedMembers,
                  )
                  .onError((error, stackTrace) => {
                        setState(() {
                          _loadingMap[organization.id! + "accept"] = false;
                        })
                      });
            },
          ),
          MbTextButton(
            text: "Reject",
            isLoading: _loadingMap[organization.id! + "deny"] == true,
            color: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 20),
            onPressed: () async {
              setState(() {
                _loadingMap[organization.id! + "deny"] = true;
              });
              List<Map<String, String>> updatedMembers = organization.members
                  .where((member) => member['userId'] != widget.user.id)
                  .toList();
              await organization
                  .update(
                    members: updatedMembers,
                  )
                  .onError((error, stackTrace) => {
                        setState(() {
                          _loadingMap[organization.id! + "reject"] = false;
                        })
                      });
            },
          ),
        ],
      ),
    );
  }
}
