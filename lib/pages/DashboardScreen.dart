import 'dart:html';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grain/grain.dart';
import 'package:medibound_library/medibound_library.dart';
import 'package:mediboundbusiness/pages/DevicePortalView.dart';
import 'package:mediboundbusiness/pages/OrganizationView.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_network/image_network.dart';


class DashboardScreen extends StatefulWidget {

  final FirebaseAuth auth;

  DashboardScreen({required this.auth});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedTile = 'Record Creator';

  MbUser? user;
  User? fUser;

  @override
  void initState() {
    super.initState();
    widget.auth..authStateChanges().listen((User? fUser) async {
      print('change');
      this.fUser = fUser;
      if (fUser != null) {
        user = await MbUser.getStatic(id: fUser.uid);
        setState(() {});
      }
    });
    
   
    

  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (fUser == null) {
          return LoginScreen(auth: widget.auth);
        }
        else if(user == null) {
          return Text("loading...");
        }
        else {
          
          if (constraints.maxWidth > 600) {
            // Desktop view with anchored sidebar
            return Container(
              child: BackgroundWidget(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Row(
                    children: [
                      _buildSidebar(user: user),
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Container(
                                child: MbSearch(hintText: "Search Devices, Organizations, Accounts, or Other Issues...",),
                              ),
                            ),
                            Expanded(
                                child: Row(children: [
                              Expanded(child: _getBody(_selectedTile)),
                              
                              //_buildMenu()
                            ])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // Mobile view with drawer
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    SvgPicture.asset('assets/image/vectorizedcolor.svg',
                        height: 25, width: 25),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('medibound',
                            style: GoogleFonts.rubik(
                                textStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    height: 0.8,
                                    fontSize: 14))),
                        Text('partners',
                            style: GoogleFonts.rubik(
                                textStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    height: 0.9,
                                    color: MbColors(context).primary))),
                      ],
                    ),
                  ],
                ),
              ),
              drawer: Drawer(
                child: _buildSidebar(user: user),
              ),
              body: _getBody(_selectedTile),
            );
          }
        }
      },
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.only(right: 15, bottom: 15,),
      child: MbDarkBlurred(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              Container(width: 250, child: Text("hello")),
            ],
          )),
    );
  }

  Widget _buildSidebar({ MbUser? user}) {
    return MbDarkBlurred(
      child: Container(
        width: 275,
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/image/vectorizedcolor.svg',
                          height: 32),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('medibound',
                              style: GoogleFonts.rubik(
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      height: 0.7,
                                      fontSize: 16,
                                      color: MbColors(context).onPrimary))),
                          Text('partners',
                              style: GoogleFonts.rubik(
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      height: 0.9,
                                      fontSize: 28,
                                      color: MbColors(context).secondary))),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                _buildSidebarItem('My Organizations', FontAwesomeIcons.buildingUser),
                SizedBox(height: 5),
                _buildSidebarItem('Device Portal', FontAwesomeIcons.microchip),
                SizedBox(height: 5),
                _buildSidebarItem('Record Creator', Icons.person_rounded),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                                width: 1,
                                color: MbColors(context).onPrimary.withOpacity(0.1))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            child: user?.familyName != null  ?Column(
                              children: [
                                Row(
                                children: [
                                 ClipOval(child: user!.pictureUrl != null ? ImageNetwork(image: user!.pictureUrl!, width: 30, height: 30) : SizedBox(height: 0)),
                                 SizedBox(width: 10),
                                   Expanded(
                                    flex: 1,
                                     child: Container(
                                       child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(( user!.givenNames![0] + " " + user.familyName!) , style: TextStyle(fontWeight: FontWeight.w700, height:1.1, fontSize: 16, color: MbColors(context).onPrimary),),
                                          Text("Enterprise User" , style: TextStyle(fontWeight: FontWeight.w500, height: 1.1, fontSize: 12,  color: MbColors(context).onPrimary.withOpacity(0.5)),),
                                        ],
                                                               ),
                                     ),
                                   ) ,
                                ],
                                            ),
                                SizedBox(height: 10,),
                                MbTextButton(text: "Account Settings", icon: Icons.settings, fontSize: 14)
                              ],
                            ) : Text("Loading..."),
                          ),
                        ),
                      ],
                    )),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: MbTextButton(
                        text: "Log Out",
                        color: Colors.red,
                        icon: FontAwesomeIcons.rightFromBracket,
                        size: MainAxisSize.max,
                        onPressed: () => _signOut())),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon) {
    bool isSelected = _selectedTile == title;
    return MbTonalButton(
        icon: icon,
        text: title,
        size: MainAxisSize.max,
        isSelected: isSelected,
        onPressed: () {
          setState(() {
            _selectedTile = title;
          });
          if (MediaQuery.of(context).size.width <= 600) {
            Navigator.pop(context);
          }
        });
  }

  Widget _getBody(String selectedTile) {
    switch (selectedTile) {
      case 'My Organizations':
        return OrganizationView(user: user!);
      case 'Device Portal':
        return DevicePortalView(user: user!);
      case 'Record Creator':
        return DashboardBody();
      default:
        return DashboardBody();
    }
  }

  void _signOut() async {
    await widget.auth.signOut();
    setState(() {
      user = null;
    });
  }
}

class LoginScreen extends StatefulWidget {
  final FirebaseAuth auth;

  LoginScreen({required this.auth});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 80,
          titleSpacing: 20,
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
          title: Row(
            children: [
              SvgPicture.asset('assets/image/vectorizedcolor.svg',
                          height: 32),
                      SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('medibound',
                              style: GoogleFonts.rubik(
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      height: 0.7,
                                      fontSize: 16,
                                      color: MbColors(context).onPrimary))),
                          Text('partners',
                              style: GoogleFonts.rubik(
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      height: 0.9,
                                      fontSize: 28,
                                      color: MbColors(context).secondary))),
                ],
              ),
            ],
          ),
        ),
        body: Center(
          child: Container(
            width: 350,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome Partners!",
                    style: GoogleFonts.rubik(
                        textStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 0.8,
                            fontSize: 30)),
                  ),
                  Text(
                    "Log In With Your Personal Account",
                    style: GoogleFonts.rubik(
                        textStyle: TextStyle(
                            color: Colors.grey, fontSize: 16, height: 2)),
                  ),
                  SizedBox(height: 20),
                  MbInput(
                    icon: FontAwesomeIcons.solidEnvelope,
                    
                    controller: _emailController,
                    labelText: "Email",
                    hintText: "marty@mcfly.com",
                  ),
                  MbInput(
                    icon: FontAwesomeIcons.lock,
                    controller: _passwordController,
                    labelText: "Password",
                    hintText: "hoverboard123",
                    obscured: true,
                  ),
                  Text(
                    "Don't Have An Account? Create One in the App",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  SizedBox(height: 20),
                  MbFilledButton(
                    isLoading: isLoading,
                    onPressed: () async {

                      try {
                        setState(() {
                          isLoading = true;
                        });
                        final response = await MbUser.login(auth: widget.auth, email: _emailController.text, password: _passwordController.text);
                        setState(() {
                          isLoading = false;
                        });
                        print(widget.auth.currentUser!.displayName);
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });
                        
                        print(e);
                      }
                    },
                    text: 'Sign In',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            FullRing(data: {
              'upperLimit': 120,
              'lowerLimit': 40,
              'value': 85,
              'color': Colors.blue,
              'unit': UnitType(code: "L"),
              'name': "water",
            }),

            MbFilledButton(
              icon: Icons.medical_information,
              text: "Filled Button",
              onPressed: () {},
            ),
            SizedBox(height: 10),
            MbOutlinedButton(
              icon: Icons.handshake,
              text: "Outlined Button",
              onPressed: () {},
            ),
            SizedBox(height: 10),
            MbTextButton(
              icon: Icons.handshake,
              text: "Text Button",
              onPressed: () {},
            ),
            MbTonalButton(
              icon: Icons.handshake,
              text: "Tonal Button",
              onPressed: () {},
            ),
            SizedBox(height: 10),
            MbInput(
              required: true,
              hintText: "martymcfly@gmail.com",
              labelText: "Email",
            ),
            SizedBox(height: 10),
            MbInput(
              hintText: "hoverboard123",
              labelText: "Password",
              obscured: true,
            ),
            SizedBox(height: 10),
            MbDropdown(
              hintText: "Select an option",
              labelText: "Dropdown",
              codes: OrganizationType.codes,
              onChanged: (value) {
                print("Selected value: $value");
              },
            ),
            MbBlurred(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      width: 300,
                      child: Column(
                        children: [
                          Text(
                            "Example Form",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          MbInput(
                            hintText: "martymcfly@gmail.com",
                            labelText: "Email",
                          ),
                          SizedBox(height: 10),
                          MbInput(
                            hintText: "hoverboard123",
                            labelText: "Password",
                            obscured: true,
                          ),
                          SizedBox(height: 10),
                          MbDropdown(
                            hintText: "Select an option",
                            labelText: "Dropdown",
                            codes: OrganizationType.codes,
                            onChanged: (value) {
                              print("Selected value: $value");
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Item 2'),
                subtitle: Text('Description of item 2'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Settings Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class ProfileBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
