import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medibound_library/medibound_library.dart';

class VariableDialog extends StatefulWidget {
  final Map<String, dynamic> variable;
  final Map<String, Map<String, dynamic>> existingVariables;
  final String type;
  final ValueChanged<Map<String, dynamic>> onSave;
  final int? index;

  VariableDialog({
    required this.variable,
    required this.existingVariables,
    required this.onSave,
    this.type = "create",
    this.index,
  });

  @override
  _VariableDialogState createState() => _VariableDialogState();
}

class _VariableDialogState extends State<VariableDialog> {
  late TextEditingController nameController;
  late TextEditingController valueController;
  late TextEditingController originController;
  late TextEditingController lowerLimitController;
  late TextEditingController upperLimitController;
  late TextEditingController intervalLengthController;

  String? selectedType;
  String? selectedUnit;
  String? selectedProfile;
  String? selectedLowerLimit;
  String? selectedUpperLimit;

  @override
  void initState() {
    super.initState();
    
    selectedType = widget.variable['type'];
    selectedProfile = widget.variable['profile'];
    selectedUnit = (widget.variable['unit'] != "" && widget.variable['unit'] != null && widget.variable['unit'] != {}) ? (widget.variable['unit'] as UnitType).code : '';
    selectedUpperLimit = widget.variable['upperLimit'].toString();
    selectedLowerLimit = widget.variable['lowerLimit'].toString();
    initializeControllers();
  }

  void initializeControllers() {
    nameController = TextEditingController(text: widget.variable['name']);
    valueController = TextEditingController(text: widget.variable['value']);
    originController = TextEditingController(text: widget.variable['origin']);
    lowerLimitController =
        TextEditingController(text: selectedLowerLimit);
    upperLimitController =
        TextEditingController(text: selectedUpperLimit);
    intervalLengthController =
        TextEditingController(text: widget.variable['intervalLength']);
  }

  void updateControllers() {
    valueController = TextEditingController(text: widget.variable['value']);
    originController = TextEditingController(text: widget.variable['origin']);
    lowerLimitController =
        TextEditingController(text: selectedLowerLimit);
    upperLimitController =
        TextEditingController(text: selectedUpperLimit);
    intervalLengthController =
        TextEditingController(text: widget.variable['intervalLength']);
  }

  void disposeControllers() {
    nameController.dispose();
    valueController.dispose();
    originController.dispose();
    lowerLimitController.dispose();
    upperLimitController.dispose();
    intervalLengthController.dispose();
  }

  @override
  void dispose() {
    //disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.type == "create"
          ? Text('Add Variable')
          : Text('Edit Variable'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Container(
            width: 600,
            child: Column(
              children: [
                MbInput(
                  icon: FontAwesomeIcons.tag,
                  labelText: 'Variable Name',
                  hintText: "Variable Name",
                  controller: nameController,
                  enabled: widget.type != "edit",
                  required: true,
                ),
                MbDropdown(
                  hintText: 'Select or search type',
                  labelText: 'Type',
                  codes: DeviceVariableType.codes,
                  description: true,
                  enabled: widget.type != "edit",
                  onChanged: (value) {
                    print(value);
                    if (mounted) {
                      setState(() {
                        if (value != selectedType) {
                          selectedProfile = "";
                          selectedUnit = "";
                          selectedUpperLimit = "";
                          selectedLowerLimit = "";
                        }
                        selectedType = value;
                        updateControllers();
                      });
                    }
                  },
                  required: true,
                  initialValue: selectedType,
                ),
                Visibility(
                  visible: selectedType == 'DECM' || selectedType == 'ADEC',
                  child: Column(
                    children: [
                      MbDropdown(
                        hintText: 'Select or search health profiles',
                        labelText: 'Health Profile',
                        codes: DeviceVariableNumberType.codes,
                        enableFilter: false,
                        sorted: true,
                        height: 300,
                        description: true,
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              print(value);
                              selectedProfile = value;
                              selectedUnit = 
                                  (DeviceVariableNumberType
                                      .allCodes()[value]!['unit']! as UnitType).code;
                              
                              selectedLowerLimit = DeviceVariableNumberType
                                          .allCodes()[value]!['lowerLimit'] !=
                                      null
                                  ? DeviceVariableNumberType
                                      .allCodes()[value]!['lowerLimit']
                                      .toString()
                                  : '';
                              selectedUpperLimit = DeviceVariableNumberType
                                          .allCodes()[value]!['upperLimit'] !=
                                      null
                                  ? DeviceVariableNumberType
                                      .allCodes()[value]!['upperLimit']
                                      .toString()
                                  : '';
                                updateControllers();
                              
                            });
                          }
                        },
                        required: true,
                        initialValue: selectedProfile,
                      ),
                      Visibility(
                        visible: selectedProfile != null,
                        child: Column(
                          children: [
                            MbBullet(
                              child: MbDropdown(
                                hintText: 'Select or search unit',
                                labelText: 'Unit',
                                codes: UnitType.codes,
                                enableFilter: false,
                                height: 300,
                                enabled: selectedProfile == "CUSTOM_PROFILE"
                                    ? true
                                    : false,
                                description: true,
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      print(value);
                                      selectedUnit = value;
                                    });
                                  }
                                },
                                required: true,
                                initialValue: selectedUnit,
                              ),
                            ),
                            Visibility(
                              visible: selectedProfile == "CUSTOM_PROFILE" || (selectedUpperLimit != null && selectedUpperLimit != ""),
                              child: Column(
                                children: [
                                  MbBullet(
                                    spaces: 2,
                                    child: MbInput(
                                      icon: FontAwesomeIcons.arrowDown,
                                      labelText: 'Lower Limit',
                                      hintText: "Lower Limit",
                                      controller: lowerLimitController,
                                      required:
                                          selectedProfile == "CUSTOM_PROFILE",
                                      initialValue: selectedLowerLimit,
                                      enabled:
                                          selectedProfile == "CUSTOM_PROFILE",
                                    ),
                                  ),
                                  MbBullet(
                                    spaces: 2,
                                    child: MbInput(
                                      icon: FontAwesomeIcons.arrowUp,
                                      labelText: 'Upper Limit',
                                      hintText: "Upper Limit",
                                      controller: upperLimitController,
                                      initialValue: selectedUpperLimit,
                                      enabled: selectedProfile == "CUSTOM_PROFILE"
                                          ? true
                                          : false,
                                      required:
                                          selectedProfile == "CUSTOM_PROFILE",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: selectedType == 'Decimal Array',
                  child: Column(
                    children: [
                      MbBullet(
                        spaces: 2,
                        child: MbInput(
                          icon: FontAwesomeIcons.mapMarkerAlt,
                          labelText: 'Origin',
                          hintText: "Origin",
                          controller: originController,
                          required: true,
                        ),
                      ),
                      MbBullet(
                        child: MbInput(
                          icon: FontAwesomeIcons.clock,
                          labelText: 'Interval Length',
                          hintText: "Interval Length",
                          controller: intervalLengthController,
                          required: true,
                        ),
                      ),
                      MbBullet(
                        spaces: 2,
                        child: MbDropdown(
                          hintText: 'Select interval unit',
                          labelText: 'Interval Unit',
                              codes: UnitType.codes, // Assuming you have a list of interval units in UnitType
                          enableFilter: true,
                          height: 300,
                          description: true,
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                //selectedIntervalUnit = value;
                              });
                            }
                          },
                          required: true,
                         // initialValue: selectedIntervalUnit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        MbTextButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        MbOutlinedButton(
          text: widget.type == "create" ? 'Add' : 'Save',
          onPressed: () {
            if (mounted) {
              BlockType blockType;

              if (selectedType == "STRG") {
                blockType = BlockType.CHARACTERISITIC;
              } else if (lowerLimitController.text == "" ||  upperLimitController.text == "") {
                blockType = BlockType.NUMBER;
              } else {
                blockType = BlockType.NUMBERRANGE;
              }

              if (widget.existingVariables[nameController.text] == null || widget.type == 'edit') {
                widget.onSave({
                'name': nameController.text,
                'description': DeviceVariableType.codes[selectedType]!['description'] ?? '',
                'icon': DeviceVariableType.codes[selectedType]!['icon'] ?? '',
                'type': selectedType,
                'blockType': blockType,
                'profile': selectedProfile,
                'unit': (selectedUnit != null && selectedUnit != "") ? UnitType(code: selectedUnit!) : '',
                'lowerLimit': (lowerLimitController.text != null && lowerLimitController.text != "") ? double.parse(lowerLimitController.text) : "",
                'upperLimit': (upperLimitController.text != null && upperLimitController.text != "") ? double.parse(upperLimitController.text) : "",
                
              });
              Navigator.pop(context);
              }
              
            }
          },
        ),
      ],
    );
  }
}

class MbBullet extends StatelessWidget {
  const MbBullet({
    super.key,
    required this.child,
    this.spaces = 1,
  });

  final Widget child;
  final double spaces;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: (30 * spaces),
            padding: EdgeInsets.only(right: 15),
            alignment: Alignment.centerRight,
            child: Container(
                width: 10,
                child: Transform.rotate(
                    angle: 3 * pi / 4,
                    child: FaIcon(FontAwesomeIcons.angleRight,
                        color: Colors.grey)))),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
