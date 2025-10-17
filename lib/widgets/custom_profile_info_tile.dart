import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
class InfoTile extends StatefulWidget {
  final String title;
  final String value;
  final String fieldKey;
  final ValueChanged<dynamic>? onChanged;
  final ValueChanged<String?>? onItemChanged;
  final String? activeField;
  final ValueChanged<bool>? onFocusChange;
  final bool readOnly;
  final bool isDropdown;
  final bool isEmployeeType;
  final bool isExperience;
  final bool isDate;
  final bool isOfficeTime;
  final List<String>? dropdownItems;
  final bool isLocation;

  const InfoTile({
    super.key,
    required this.title,
    this.value = "",
    required this.fieldKey,
    this.onChanged,
    this.activeField,
    this.onFocusChange,
    this.readOnly = false,
    this.isDropdown = false,
    this.onItemChanged,
    this.isEmployeeType = false,
    this.isExperience = false,
    this.isOfficeTime = false,
    this.dropdownItems,
    this.isDate=false,  this.isLocation=false,
  });

  @override
  State<InfoTile> createState() => _InfoTileState();
}

class _InfoTileState extends State<InfoTile> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  final List<String> genderList = ['Male', 'Female', 'Others'];
  final List<String> employeeTypeList = ['Part Time', 'Full Time'];
  // final List<UserLocationModel>locationList=UserLocationModel.locationList;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _toggleEditing();
      }
    });
  }



  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing && widget.onChanged != null) {
        widget.onChanged!(_controller.text);
      }
    });
  }


  Future<void> _updateField(String key, dynamic value) async {
    await Provider.of<DatabaseHelperProvider>(context, listen: false)
        .updateUserField(key, value);
  }

  List<String> get currentDropdownList {
    if (widget.isEmployeeType) {
      return employeeTypeList;
    }  else {
      return genderList;
    }
  }


  String? get dropdownValue {
    return currentDropdownList.contains(_controller.text)
        ? _controller.text
        : null;
  }

  ///Date Picker
  Future<void> _pickDate() async {

    final now = DateTime.now();
    final DateTime? date = await showDatePicker(
      initialEntryMode: DatePickerEntryMode.input,
      helpText: "Select Joining Date",
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final formatted = "${date.day} ${_monthName(date.month)}, ${date.year}";
      setState(() {
        _controller.text = formatted;
      });
      widget.onChanged?.call(formatted);
      int years = now.year - date.year;
      int months = now.month - date.month;
      int days = now.day - date.day;

      if (days < 0) {
        months -= 1;
        days += DateTime(now.year, now.month, 0).day;// to find the current month before month days
      }
      if (months < 0) {
        years -= 1;
        months += 12;
      }
      _updateField('company_experience','$years Years $months Months $days Days');
      widget.onFocusChange?.call(false);
    }




  }





  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');// padLeft ensure that the digit will be 2digit string
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }


  ///Time Picker For office time selecting
  Future<void> _pickOfficeTime() async {
    try {
      if (!mounted) return;
      final TimeOfDay? start = await showTimePicker(
        context: context,
        helpText: "Select Your Office Start Time",
        initialTime: const TimeOfDay(hour: 4, minute: 0),
      );

      if (!mounted || start == null) return;
      final formattedStart = _formatTimeOfDay(start);
      final TimeOfDay? end = await showTimePicker(
        context: context,
        helpText: "Select Your Office End Time",
        initialTime: TimeOfDay(
          hour: (start.hour + 8) % 24,
          minute: start.minute,
        ),
      );

      if (!mounted || end == null) return;

      final formattedEnd = _formatTimeOfDay(end);
      final formatted = "${start.format(context)} to ${end.format(context)}";



      print(formatted);


      if (mounted) {
        setState(() {
          _controller.text = formatted;
        });
      }


      _updateField('end_time', formattedEnd);
      _updateField('start_time', formattedStart);


      widget.onChanged?.call(formatted);
      widget.onFocusChange?.call(false);
    } catch (e) {
      debugPrint("Error in _pickOfficeTime: $e");
    }
  }


  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    //return the index value  of the month list
    return months[month - 1];
  }


  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldEdit = widget.fieldKey == widget.activeField;

    return GestureDetector(
      onTap: () async {
        widget.onFocusChange?.call(true);

        if (widget.isDate) {
          await _pickDate();
        } else if (widget.isOfficeTime) {
          await _pickOfficeTime();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          (shouldEdit && !widget.readOnly)
              ? widget.isDropdown
              ? DropdownButtonHideUnderline(
            child:DropdownButton<String>(
              value: widget.isLocation
                  ? genderList.any((gender) => gender == _controller.text)
                  ? _controller.text
                  : null
                  : currentDropdownList.contains(_controller.text)
                  ? _controller.text
                  : null,
              items: widget.isLocation
                  ? genderList.map((location) {
                return DropdownMenuItem<String>(
                  value: genderList.first,
                  child: Text(
                    genderList.first,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList()
                  : currentDropdownList.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _controller.text = value;
                  });
                  widget.onItemChanged?.call(value);
                  widget.onFocusChange?.call(false);
                }
              },
              hint: Text(
                widget.isEmployeeType
                    ? "Add your Employee Type"
                    : widget.isLocation
                    ? "Add your work location here"
                    : "Select Gender",
              ),
              isExpanded: widget.isLocation ? true : false,
              isDense: true,
            ),
          )
              : TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            onSubmitted: (_) {
              widget.onFocusChange?.call(false);
              _toggleEditing();
            },
            readOnly: widget.readOnly,
            decoration: InputDecoration(
              hintText: "Enter your ${widget.title.toLowerCase()}",
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0x9B3386FE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness ==
                      Brightness.dark
                      ? const Color(0x2A3386FE)
                      : const Color(0x9B3386FE),
                  width: Theme.of(context).brightness ==
                      Brightness.dark
                      ? 2
                      : 1,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          )
              : (_controller.text.isEmpty && widget.isExperience)
              ? const Text(
            "Add your joining date",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          )
              : _controller.text.isEmpty
              ? Text(
            "Add your ${widget.title.toLowerCase()} here",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          )
              : Text(
            _controller.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
