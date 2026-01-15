import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Custom time picker with auto-select text fields for better UX
class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePicker({
    super.key,
    required this.initialTime,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();

  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => CustomTimePicker(initialTime: initialTime),
    );
  }
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late bool _isPM;
  final _hourFocusNode = FocusNode();
  final _minuteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final hour12 = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _hourController = TextEditingController(text: hour12.toString());
    _minuteController = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
    _isPM = widget.initialTime.period == DayPeriod.pm;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  void _selectAllOnTap(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  TimeOfDay? _getTimeOfDay() {
    final hourText = _hourController.text;
    final minuteText = _minuteController.text;

    if (hourText.isEmpty || minuteText.isEmpty) return null;

    final hour12 = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);

    if (hour12 == null || minute == null) return null;
    if (hour12 < 1 || hour12 > 12) return null;
    if (minute < 0 || minute > 59) return null;

    // Convert 12-hour to 24-hour
    int hour24;
    if (_isPM) {
      hour24 = hour12 == 12 ? 12 : hour12 + 12;
    } else {
      hour24 = hour12 == 12 ? 0 : hour12;
    }

    return TimeOfDay(hour: hour24, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Select Time',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Time Input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour Field
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _hourController,
                    focusNode: _hourFocusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    style: AppTheme.headlineLarge.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppTheme.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onTap: () => _selectAllOnTap(_hourController),
                    onChanged: (value) {
                      if (value.length == 2) {
                        _minuteFocusNode.requestFocus();
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ':',
                    style: AppTheme.headlineLarge.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Minute Field
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _minuteController,
                    focusNode: _minuteFocusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    style: AppTheme.headlineLarge.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppTheme.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onTap: () => _selectAllOnTap(_minuteController),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // AM/PM Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPeriodButton('AM', !_isPM),
                const SizedBox(width: 8),
                _buildPeriodButton('PM', _isPM),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final time = _getTimeOfDay();
                    if (time != null) {
                      Navigator.pop(context, time);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Please enter a valid time (Hour: 1-12, Minute: 0-59)',
                          ),
                          backgroundColor: AppTheme.dangerColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPM = label == 'PM';
        });
      },
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primaryGreen : AppTheme.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
