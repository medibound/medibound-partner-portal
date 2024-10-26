import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health/health.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:medibound_library/medibound_library.dart';
import 'package:mediboundbusiness/pages/OrganizationView.dart';
import 'package:mediboundbusiness/pages/device-profiles/components/VariableDialog.dart';


class CreateDeviceProfileForm extends StatefulWidget {
  final VoidCallback onSubmit;
  final MbUser user;

  
  CreateDeviceProfileForm({
    required this.onSubmit,
    required this.user,
  });

  @override
  _CreateDeviceProfileFormState createState() =>
      _CreateDeviceProfileFormState();
}

class _CreateDeviceProfileFormState extends State<CreateDeviceProfileForm> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  Uint8List? _imageData;
  String? _deviceType;
  String? _deviceTransferType;
  String? _deviceMode;
  String? _deviceOrganization;
  String? _organizationType;
  String? _privacyPolicy;
  String? _website;
  String? _address;

  Map<String, dynamic>? selectedBlockSearch;
  Map<String, Map<String, dynamic>> _variables = {};
  bool isLoading = false;
  final CropController _cropController = CropController();

  void _addVariable() async {
    await showDialog(
      context: context,
      builder: (context) => VariableDialog(
        type: "create",
        existingVariables: _variables,
        variable: {
          'name': '',
          'icon': '',
          'description': '',
          'value': '',
          'type': '',
          'blockType': '',
          'lowerLimit': '',
          'upperLimit': '',
          'unit': '',
        },
        onSave: (newVariable) {
          setState(() {
            _variables.addAll({newVariable['name']: newVariable});
          });
        },
      ),
    );
  }

  void _removeVariable(String key) {
    setState(() {
      if (selectedBlockSearch != null) {
        if (key == selectedBlockSearch!['name']) {
          selectedBlockSearch = null;
        }
      }

      _variables.remove(key);
    });
  }

  void _updateVariable(String key, Map<String, dynamic> updatedVariable) {
    print(key);
    setState(() {
      _variables[key] = updatedVariable;
    });
  }

  Future<void> _editVariableDialog(String key) async {
    await showDialog(
      context: context,
      builder: (context) => VariableDialog(
        type: "edit",
        existingVariables: _variables,
        variable: _variables[key]!,
        onSave: (updatedVariable) => _updateVariable(key, updatedVariable),
      ),
    );
  }

  IconData _getVariableIcon(String? type) {
    switch (type) {
      case 'STRG':
        return FontAwesomeIcons.font;
      case 'DECM':
        return FontAwesomeIcons.hashtag;
      case 'Decimal Array':
        return FontAwesomeIcons.listOl;
      default:
        return FontAwesomeIcons.questionCircle;
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
            text: "Back to Device Portal",
            icon: Icons.arrow_back,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          SizedBox(height: 10),
          MbTitle(text: "Create Device Profile"),
          SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MbSection(
                  title: "Device Information",
                  icon: FontAwesomeIcons.scroll,
                  desc: "Identification data regarding your device",
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: MbInput(
                              icon: FontAwesomeIcons.microchip,
                              labelText: 'Name',
                              hintText: "Delorean",
                              onSaved: (value) => _name = value,
                              required: true,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            flex: 1,
                            child: MbDropdown(
                              hintText: 'Select or search organization',
                              labelText: 'Organization',
                              description: true,
                              stream: fetchOrganizationsJson(widget.user.id),
                              height: 300,
                              onChanged: (value) {
                                //print(value);
                                setState(() {
                                  _deviceOrganization = value;
                                });
                              },
                              initialValue: _deviceOrganization,
                              required: true,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: MbInput(
                              icon: FontAwesomeIcons.globe,
                              labelText: 'Short Description',
                              hintText: "A Time Machine",
                              onSaved: (value) => _website = value,
                              required: true,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            flex: 1,
                            child: MbDropdown(
                              hintText: 'Select or search device type',
                              labelText: 'Profile Mode',
                              description: true,
                              codes: DeviceProfileMode.codes,
                              height: 300,
                              onChanged: (value) {
                                setState(() {
                                  _deviceMode = value;
                                });
                              },
                              required: true,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: MbInput(
                              icon: FontAwesomeIcons.userShield,
                              labelText: 'Manual Link',
                              hintText:
                                  "https://medibound.com/device/manual.pdf",
                              onSaved: (value) => _privacyPolicy = value,
                              required: true,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: MbDropdown(
                              hintText: 'Select or search device type',
                              labelText: 'Device Type',
                              description: true,
                              sorted: true,
                              codes: DeviceTypes.codes,
                              height: 300,
                              onChanged: (value) {
                                setState(() {
                                  print(value);
                                  _deviceType = value;
                                });
                              },
                              required: true,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: MbDropdown(
                              hintText: 'Select or search data transfer type',
                              labelText: 'Data Transfer Type',
                              codes: DeviceTransferType.codes,
                              description: true,
                              onChanged: (value) {
                                setState(() {
                                  _deviceTransferType = value;
                                });
                              },
                              required: true,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: MbInput(
                              icon: FontAwesomeIcons.solidEnvelope,
                              labelText: 'Model Number',
                              hintText: "Model Number",
                              onSaved: (value) => _email = value,
                              required: false,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: MbInput(
                              icon: FontAwesomeIcons.solidEnvelope,
                              labelText: 'Composite Unique Device Identifier',
                              hintText: "Unique Identifier",
                              onSaved: (value) => _email = value,
                              required: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                MbSection(
                  title: "Variables",
                  color: Colors.blue,
                  icon: FontAwesomeIcons.shapes,
                  desc: "Add and manage variables for your device",
                  buttonText: "Add Variable",
                  buttonIcon: FontAwesomeIcons.plus,
                  onPressed: _addVariable,
                  child: Table(
                    columnWidths: const <int, TableColumnWidth>{
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(4),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: <TableRow>[
                      TableRow(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.transparent),
                          ),
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                child: MbSubheading2(text: "Name")),
                            Container(
                                padding: EdgeInsets.all(10),
                                child: MbSubheading2(text: "Unit")),
                            Container(
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    MbSubheading2(text: "Actions"),
                                  ],
                                )),
                          ]),
                      ..._variables.entries.map((entry) {
                        String index = entry.key;
                        Map<String, dynamic> variable = entry.value;
                        TextEditingController controller =
                            TextEditingController(text: entry.value['name']);
                        print(_variables);
                        return TableRow(
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: MbColors(context)
                                          .grey
                                          .withOpacity(0.2),
                                      width: 0.5))),
                          children: [
                            Container(
                              padding: EdgeInsets.only(right: 10),
                              child: MbInput(
                                isSmall: true,
                                icon: DeviceVariableType
                                    .codes[entry.value['type']]!['icon'],
                                labelText: 'Variable Value',
                                hintText: "Variable Value",
                                initialValue: entry.value['name'],
                                enabled: false,
                              ),
                            ),
                            Container(
                              child: variable['type'] == 'DECM'
                                  ? MbInput(
                                      isSmall: true,
                                      icon: (entry.value['unit'] as UnitType).icon,
                                      labelText: 'Variable Value',
                                      hintText: "Unit Value",
                                      initialValue: UnitType.codes[((entry
                                          .value['unit'] as UnitType).code)]!['name'],
                                      enabled: false,
                                    )
                                  : SizedBox(width: 0),
                            ),
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons.solidPenToSquare,
                                      size: 18,
                                      color: MbColors(context).onPrimary,
                                    ),
                                    onPressed: () => _editVariableDialog(index),
                                  ),
                                  IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons.solidTrashCan,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeVariable(index),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          MbSection(
                            title: "Header",
                            color: Colors.deepPurple,
                            icon: FontAwesomeIcons.chartSimple,
                            desc:
                                "Add and manage the data header for your device",
                            child: Column(
                              children: [],
                            ),
                          ),
                          SizedBox(height: 20),
                          MbSection(
                            title: "Components",
                            color: Colors.purple,
                            icon: FontAwesomeIcons.cubesStacked,
                            desc:
                                "Add and manage data components for your device",
                            child: Column(
                              children: [],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: MbSection(
                        title: "Search UI Blocks",
                        color: Colors.grey,
                        icon: FontAwesomeIcons.search,
                        desc: "Search, drag & drop data blocks",
                        child: Column(
                          children: [
                            MbDropdown(
                              hintText: 'Select variable',
                              isSmall: true,
                              initialValue: selectedBlockSearch != null
                                  ? selectedBlockSearch!['name']
                                  : null,
                              labelText: 'Variable',
                              codes:
                                  _variables, // Assuming you have a list of interval units in UnitType
                              enableFilter: true,
                              height: 300,
                              description: true,
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {
                                    selectedBlockSearch = _variables[value];
                                    print(selectedBlockSearch);
                                  });
                                }
                              },
                              required: true,
                              // initialValue: selectedIntervalUnit,
                            ),
                          ],
                        ),
                        insetChild: Column(
                          children: [
                            if (selectedBlockSearch != null)
                              ...DataUITypes.get(
                                  BlockSize.SINGLE, selectedBlockSearch!['blockType'], {
                                ...selectedBlockSearch!,
                                'value': 85,
                                'color': Colors.blue
                                
                              }).values.map((value) {
                                return value['widget'] as Widget;
                              }).toList()
                            else
                              Text("No Variable Selected"),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20),
                MbFilledButton(
                  text: "Create Device Profile",
                  onPressed: () => {},
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
