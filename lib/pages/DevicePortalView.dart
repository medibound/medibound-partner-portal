import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_network/image_network.dart';
import 'package:medibound_library/medibound_library.dart';
import 'package:mediboundbusiness/pages/device-profiles/CreateDeviceProfileForm.dart';

class DevicePortalView extends StatefulWidget {
  final MbUser user;

  DevicePortalView({
    required this.user,
  });

  @override
  _DevicePortalViewState createState() => _DevicePortalViewState();
}

class _DevicePortalViewState extends State<DevicePortalView> {
  bool _showCreateDeviceTemplatePage = false;
  bool _showManageDeviceTemplatePage = false;
  MbOrganization? _currentOrganization;
  Map<String, bool> _loadingMap = {};

  void _toggleCreateDeviceTemplatePage() {
    setState(() {
      _showCreateDeviceTemplatePage = !_showCreateDeviceTemplatePage;
    });
  }

  /*void _toggleManageDeviceTemplatePage([MbOrganization? organization]) {
    _fetchOrganizations();
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
  }*/

  Stream<List<MbOrganization>> _fetchOrganizations() async* {
    var snapshots = FirebaseFirestore.instance
        .collection('organizations')
        .where('membersIds', arrayContains: widget.user.id)
        .snapshots();
    await for (var snapshot in snapshots) {
      List<MbOrganization> organizations = await Future.wait(snapshot.docs.map((doc) async {
        var data = doc.data();
        data['id'] = doc.id;
        print('Organization ID: ${doc.id}'); // Debugging statement
        var org = await MbOrganization.fromJsonStatic(data);
        return org;
      }).toList());
      yield organizations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: StreamBuilder<List<MbOrganization>>(
          stream: _fetchOrganizations(),
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
                    member.id == widget.user.id &&
                    member.role != 'invited'))
                .toList();
            var myInvitations = organizations
                .where((org) => org.members.any((member) =>
                    member.id == widget.user.id &&
                    member.role == 'invited'))
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
                          if (!_showCreateDeviceTemplatePage &&
                              !_showManageDeviceTemplatePage) ...[
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    MbTitle(text: "Device Portal"),
                                    Spacer(),
                                    MbOutlinedButton(
                                      onPressed: _toggleCreateDeviceTemplatePage,
                                      text: "Create Device Profile",
                                      icon: Icons.add,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 20),
                                    ),
                                  ],
                                ),
                                /*SizedBox(height: 20),
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
                                ),*/
                                SizedBox(height: 20),
                                
                              ],
                            ),
                          ] else if (_showCreateDeviceTemplatePage) ...[
                            CreateDeviceProfileForm(
                              onSubmit: _toggleCreateDeviceTemplatePage,
                              user: widget.user,
                            )
                          ] /*else if (_showManageOrganizationPage &&
                              _currentOrganization != null) ...[
                            ManageOrganizationForm(
                              user: widget.user,
                              organization: _currentOrganization!,
                              onSubmit: () => _toggleManageOrganizationPage(null),
                            )
                          ]*/
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
          /*organization.members.any((member) =>
                  member['userId'] == widget.user.id &&
                  (member['role'] == 'admin' || member['role'] == 'owner'))
              ? MbOutlinedButton(
                  text: "Manage",
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  onPressed: () => _toggleManageOrganizationPage(organization),
                )
              : SizedBox(width: 0),*/
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

}
