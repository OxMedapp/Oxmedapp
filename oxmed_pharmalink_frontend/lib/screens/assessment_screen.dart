// lib/screens/assessment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

// ---------- Custom Formatter ----------
class MaxWordCountFormatter extends TextInputFormatter {
  const MaxWordCountFormatter(this.maxWords);
  final int maxWords;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final words = newValue.text.trim().isEmpty
        ? <String>[]
        : newValue.text.trim().split(RegExp(r'\s+'));
    return words.length <= maxWords ? newValue : oldValue;
  }
}

// ---------- Common Complaints Chip Widget (Stateless) ----------
class CommonComplaints extends StatelessWidget {
  const CommonComplaints({
    required this.complaints,
    required this.selectedComplaints,
    required this.onSelectionChanged,
    super.key,
  });

  final List<String> complaints;
  final Set<String> selectedComplaints;
  final ValueChanged<String> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final complaint in complaints)
          FilterChip(
            key: ValueKey(complaint),
            label: Text(complaint),
            selected: selectedComplaints.contains(complaint),
            onSelected: (_) => onSelectionChanged(complaint),
            selectedColor: AppColors.oxfordNavy,
            checkmarkColor: AppColors.white,
            backgroundColor: AppColors.white,
            side: BorderSide(
              color: selectedComplaints.contains(complaint)
                  ? AppColors.oxfordNavy
                  : AppColors.royalBlue,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            labelStyle: TextStyle(
              color: selectedComplaints.contains(complaint) ? AppColors.white : AppColors.oxfordNavy,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

// ---------- Main Screen ----------
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _isLoading = false;

  // ---------- Patient Details ----------
  String patientName = '';
  String patientPhone = '';
  String patientAge = '';
  String? patientGender;
  bool consentConfirmed = true;

  // ---------- Main Complaint ----------
  String mainComplaint = '';
  final TextEditingController mainComplaintController = TextEditingController();
  final Set<String> selectedComplaints = {};
  final List<String> commonComplaints = const [
    'Fever', 'Headache', 'Body pains', 'Cough', 'Cold',
    'Abdominal pain', 'Vomiting', 'Diarrhea', 'Dizziness', 'Weakness',
    'Chills', 'Sore throat', 'Nausea', 'Heartburn', 'Urinary problem',
    'Skin problem', 'Eye problem', 'Joint pain', 'Loss of appetite',
    'Breathing difficulty',
  ];

  // ---------- History ----------
  String? historyDuration;
  String historyDurationDetail = '';
  String? historyTrend;
  int historySeverity = 0;
  String otherSymptoms = '';
  String triedTreatments = '';

  // ---------- Vitals ----------
  String systolicBP = '';
  String diastolicBP = '';
  String bloodGlucose = '';
  String temperature = '';
  String pulse = '';
  String respiratoryRate = '';
  String oxygenSaturation = '';
  String? malariaStatus;
  String? pregnancyStatus;

  // ---------- Clinical Background ----------
  final Set<String> currentMedicines = {};
  String currentMedicinesDetail = '';
  final Set<String> allergies = {};
  String allergiesDetail = '';
  final Set<String> conditions = {};
  String conditionsDetail = '';

  // ---------- Safety Flags ----------
  final Set<String> selectedSafetyFlags = {};
  final List<String> safetyFlags = const [
    'Unresponsive/confused',
    'Severe breathing difficulty',
    'Severe chest pain',
    'Sudden weakness/speech',
    'Seizure',
    'Severe bleeding',
    'Severe allergic reaction',
    'Pregnancy with severe pain',
    'Very abnormal vitals',
    'Other serious concern',
  ];

  // ---------- Disposition ----------
  String? disposition;

  // ---------- Controllers for text fields (to avoid setState on every keystroke) ----------
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController patientPhoneController = TextEditingController();
  final TextEditingController patientAgeController = TextEditingController();
  final TextEditingController systolicBPController = TextEditingController();
  final TextEditingController diastolicBPController = TextEditingController();
  final TextEditingController bloodGlucoseController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController respiratoryRateController = TextEditingController();
  final TextEditingController oxygenSaturationController = TextEditingController();
  final TextEditingController historyDurationDetailController = TextEditingController();
  final TextEditingController otherSymptomsController = TextEditingController();
  final TextEditingController triedTreatmentsController = TextEditingController();
  final TextEditingController currentMedicinesDetailController = TextEditingController();
  final TextEditingController allergiesDetailController = TextEditingController();
  final TextEditingController conditionsDetailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync controllers with state on change
    patientNameController.addListener(() => patientName = patientNameController.text);
    patientPhoneController.addListener(() => patientPhone = patientPhoneController.text);
    patientAgeController.addListener(() => patientAge = patientAgeController.text);
    systolicBPController.addListener(() => systolicBP = systolicBPController.text);
    diastolicBPController.addListener(() => diastolicBP = diastolicBPController.text);
    bloodGlucoseController.addListener(() => bloodGlucose = bloodGlucoseController.text);
    temperatureController.addListener(() => temperature = temperatureController.text);
    pulseController.addListener(() => pulse = pulseController.text);
    respiratoryRateController.addListener(() => respiratoryRate = respiratoryRateController.text);
    oxygenSaturationController.addListener(() => oxygenSaturation = oxygenSaturationController.text);
    historyDurationDetailController.addListener(() => historyDurationDetail = historyDurationDetailController.text);
    otherSymptomsController.addListener(() => otherSymptoms = otherSymptomsController.text);
    triedTreatmentsController.addListener(() => triedTreatments = triedTreatmentsController.text);
    currentMedicinesDetailController.addListener(() => currentMedicinesDetail = currentMedicinesDetailController.text);
    allergiesDetailController.addListener(() => allergiesDetail = allergiesDetailController.text);
    conditionsDetailController.addListener(() => conditionsDetail = conditionsDetailController.text);
  }

  @override
  void dispose() {
    patientNameController.dispose();
    patientPhoneController.dispose();
    patientAgeController.dispose();
    systolicBPController.dispose();
    diastolicBPController.dispose();
    bloodGlucoseController.dispose();
    temperatureController.dispose();
    pulseController.dispose();
    respiratoryRateController.dispose();
    oxygenSaturationController.dispose();
    historyDurationDetailController.dispose();
    otherSymptomsController.dispose();
    triedTreatmentsController.dispose();
    currentMedicinesDetailController.dispose();
    allergiesDetailController.dispose();
    conditionsDetailController.dispose();
    mainComplaintController.dispose();
    super.dispose();
  }

  // ---------- Methods ----------
  void selectComplaint(String complaint) {
    setState(() {
      if (selectedComplaints.contains(complaint)) {
        selectedComplaints.remove(complaint);
      } else {
        selectedComplaints.add(complaint);
      }
      mainComplaint = selectedComplaints.join(', ');
      mainComplaintController.text = mainComplaint;
      mainComplaintController.selection = TextSelection.fromPosition(
        TextPosition(offset: mainComplaint.length),
      );
    });
  }

  void backspaceMainComplaint() {
    if (selectedComplaints.isEmpty) return;
    setState(() {
      selectedComplaints.remove(selectedComplaints.last);
      final newText = selectedComplaints.join(', ');
      mainComplaint = newText;
      mainComplaintController.text = newText;
    });
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.redAccent),
            SizedBox(width: 8),
            Text('Emergency Identified'),
          ],
        ),
        content: const Text(
          'Begin the approved emergency/referral procedure now. '
          'AI must not delay this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Assessment', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveDraft,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Patient Details ----------
                const Text(
                  'Patient details',
                  style: TextStyle(color: AppColors.oxfordNavy, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildPatientDetails(),
                const SizedBox(height: 16),

                // ---------- Main Complaint ----------
                const Text(
                  'Main complaint',
                  style: TextStyle(color: AppColors.oxfordNavy, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildMainComplaint(),
                const SizedBox(height: 16),

                // ---------- Expandable Sections ----------
                _buildExpandableSection(
                  title: 'History & severity',
                  icon: Icons.history,
                  child: _buildHistory(),
                ),
                const SizedBox(height: 12),

                _buildExpandableSection(
                  title: 'Vitals & tests',
                  icon: Icons.monitor_heart,
                  child: _buildVitals(),
                ),
                const SizedBox(height: 12),

                _buildExpandableSection(
                  title: 'Clinical background',
                  icon: Icons.assignment_ind,
                  child: _buildClinicalBackground(),
                ),
                const SizedBox(height: 12),

                _buildExpandableSection(
                  title: 'Safety & red flags',
                  icon: Icons.warning_amber_rounded,
                  isHighlighted: true,
                  child: _buildSafetyFlags(),
                ),
                const SizedBox(height: 12),

                // ---------- Disposition ----------
                const Text(
                  'Disposition',
                  style: TextStyle(color: AppColors.oxfordNavy, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildDisposition(),
                const SizedBox(height: 24),

                // ---------- Buttons ----------
                AppButton(
                  label: 'Generate referral summary',
                  icon: Icons.auto_awesome,
                  onPressed: _isLoading ? null : _generateReferral,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saveDraft,
                    icon: const Icon(Icons.drafts_outlined),
                    label: const Text('Save draft'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.oxfordNavy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- UI Helpers ----------
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Widget child,
    bool isHighlighted = false,
  }) {
    return Material(
      type: MaterialType.card,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? BorderSide(color: AppColors.redAccent, width: 1.5)
            : BorderSide(color: AppColors.borderGrey, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.oxfordNavy),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.oxfordNavy),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.oxfordNavy, fontWeight: FontWeight.w600)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Patient Details ----------
  Widget _buildPatientDetails() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: patientNameController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
                decoration: const InputDecoration(
                  labelText: 'Patient name',
                  hintText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: patientPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '024...',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: patientAgeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Years',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: patientGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => patientGender = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  title: const Text('Consent confirmed'),
                  value: consentConfirmed,
                  onChanged: (v) => setState(() => consentConfirmed = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  // ---------- Main Complaint ----------
  Widget _buildMainComplaint() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            TextField(
              controller: mainComplaintController,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              minLines: 3,
              inputFormatters: const [MaxWordCountFormatter(200)],
              decoration: InputDecoration(
                labelText: 'Describe the main complaint',
                hintText: 'Be precise and concise',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.notes_outlined),
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 56, 40),
              ),
              onChanged: (v) {
                setState(() {
                  mainComplaint = v;
                  selectedComplaints.clear();
                });
              },
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: IconButton(
                tooltip: 'Delete previous character',
                onPressed: backspaceMainComplaint,
                icon: const Icon(Icons.backspace_outlined, color: AppColors.oxfordNavy),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Common complaints',
          style: TextStyle(color: AppColors.oxfordNavy, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        CommonComplaints(
          complaints: commonComplaints,
          selectedComplaints: selectedComplaints,
          onSelectionChanged: selectComplaint,
        ),
      ],
    );
  }

  // ---------- History ----------
  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: historyDuration,
                items: const ['Hours', 'Days', 'Weeks'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => historyDuration = v),
                decoration: const InputDecoration(labelText: 'Duration', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: historyDurationDetailController,
                decoration: const InputDecoration(
                  labelText: 'Details (e.g., 2 days)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['Improving', 'Worsening', 'Unchanged'].map((trend) {
            final isSelected = historyTrend == trend;
            return ChoiceChip(
              label: Text(trend),
              selected: isSelected,
              onSelected: (s) => setState(() => historyTrend = s ? trend : null),
              selectedColor: AppColors.royalBlue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.royalBlue : AppColors.darkText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Severity: 0  ', style: TextStyle(fontWeight: FontWeight.w500)),
            Expanded(
              child: Slider(
                min: 0,
                max: 10,
                divisions: 10,
                value: historySeverity.toDouble(),
                onChanged: (v) => setState(() => historySeverity = v.round()),
                activeColor: AppColors.royalBlue,
              ),
            ),
            Text('  ${historySeverity.toString()}'),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: otherSymptomsController,
          decoration: const InputDecoration(
            labelText: 'Other symptoms (comma separated)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: triedTreatmentsController,
          decoration: const InputDecoration(
            labelText: 'What has been tried and did it help?',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ---------- Vitals ----------
  Widget _buildVitals() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: systolicBPController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Systolic BP',
                  hintText: 'e.g., 120',
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: diastolicBPController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diastolic BP',
                  hintText: 'e.g., 80',
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: bloodGlucoseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Blood glucose',
                  hintText: 'mmol/L',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: malariaStatus,
                decoration: const InputDecoration(
                  labelText: 'Malaria RDT',
                  prefixIcon: Icon(Icons.bug_report_outlined),
                ),
                items: ['Positive', 'Negative', 'Not done'].map((e) =>
                    DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => malariaStatus = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: temperatureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  hintText: 'e.g., 37.5',
                  prefixIcon: Icon(Icons.thermostat_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: pulseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pulse (bpm)',
                  hintText: 'e.g., 72',
                  prefixIcon: Icon(Icons.favorite_outline),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: respiratoryRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Resp. rate (/min)',
                  hintText: 'e.g., 16',
                  prefixIcon: Icon(Icons.air_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: oxygenSaturationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SpO₂ (%)',
                  hintText: 'e.g., 98',
                  prefixIcon: Icon(Icons.bubble_chart_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: pregnancyStatus,
                decoration: const InputDecoration(
                  labelText: 'Pregnancy status',
                  prefixIcon: Icon(Icons.pregnant_woman_outlined),
                ),
                items: ['Pregnant', 'Not pregnant', 'Unknown'].map((e) =>
                    DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => pregnancyStatus = v),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  // ---------- Clinical Background ----------
  Widget _buildClinicalBackground() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectableList(
          title: 'Current medications',
          selected: currentMedicines,
          options: const ['Paracetamol', 'Ibuprofen', 'Aspirin', 'Amoxicillin', 'Metformin', 'Other'],
          detailController: currentMedicinesDetailController,
          onDetailChanged: (v) => currentMedicinesDetail = v,
        ),
        const SizedBox(height: 12),
        _buildSelectableList(
          title: 'Allergies',
          selected: allergies,
          options: const ['Penicillin', 'Sulfa', 'Latex', 'Food', 'Other'],
          detailController: allergiesDetailController,
          onDetailChanged: (v) => allergiesDetail = v,
        ),
        const SizedBox(height: 12),
        _buildSelectableList(
          title: 'Existing conditions',
          selected: conditions,
          options: const ['Diabetes', 'Hypertension', 'Asthma', 'HIV', 'Sickle cell', 'Other'],
          detailController: conditionsDetailController,
          onDetailChanged: (v) => conditionsDetail = v,
        ),
      ],
    );
  }

  Widget _buildSelectableList({
    required String title,
    required Set<String> selected,
    required List<String> options,
    required TextEditingController detailController,
    required ValueChanged<String> onDetailChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        Wrap(
          spacing: 4,
          children: options.map((opt) {
            return ChoiceChip(
              label: Text(opt),
              selected: selected.contains(opt),
              onSelected: (s) {
                setState(() {
                  if (s) selected.add(opt);
                  else selected.remove(opt);
                });
              },
              selectedColor: AppColors.royalBlue.withOpacity(0.2),
            );
          }).toList(),
        ),
        if (selected.contains('Other'))
          TextField(
            controller: detailController,
            decoration: const InputDecoration(labelText: 'Other details'),
            onChanged: onDetailChanged,
          ),
      ],
    );
  }

  // ---------- Safety Flags ----------
  Widget _buildSafetyFlags() {
    return Column(
      children: safetyFlags.map((flag) {
        return Material(
          type: MaterialType.transparency,
          child: CheckboxListTile(
            title: Text(flag, style: const TextStyle(fontSize: 14)),
            value: selectedSafetyFlags.contains(flag),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  selectedSafetyFlags.add(flag);
                  _showEmergencyDialog(context);
                } else {
                  selectedSafetyFlags.remove(flag);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.redAccent,
          ),
        );
      }).toList(),
    );
  }

  // ---------- Disposition ----------
  Widget _buildDisposition() {
    const options = [
      'Self-care advice',
      'Pharmacy treatment',
      'Routine follow-up',
      'Telemedicine consultation',
      'Referral to clinic/hospital',
      'Emergency escalation',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = disposition == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (s) => setState(() => disposition = s ? opt : null),
          selectedColor: AppColors.royalBlue.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.royalBlue : AppColors.darkText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // ---------- Data Collection ----------
  Map<String, dynamic> _collectData() {
    return {
      'chief_complaint': mainComplaint,
      'complaint_duration': historyDurationDetail,
      'symptom_severity': {
        'severity': historySeverity,
        'other_symptoms': otherSymptoms,
      },
      'bp_systolic': double.tryParse(systolicBP),
      'bp_diastolic': double.tryParse(diastolicBP),
      'blood_glucose': double.tryParse(bloodGlucose),
      'temperature': double.tryParse(temperature),
      'pulse': double.tryParse(pulse),
      'respiratory_rate': double.tryParse(respiratoryRate),
      'oxygen_saturation': double.tryParse(oxygenSaturation),
      'malaria_result': malariaStatus,
      'current_medication': currentMedicines.join(', ') +
          (currentMedicinesDetail.isNotEmpty ? ': $currentMedicinesDetail' : ''),
      'allergies': allergies.join(', ') +
          (allergiesDetail.isNotEmpty ? ': $allergiesDetail' : ''),
      'medical_history': conditions.join(', ') +
          (conditionsDetail.isNotEmpty ? ': $conditionsDetail' : ''),
      'is_pregnant': pregnancyStatus == 'Pregnant',
      'age_group': patientAge,
      'red_flags': selectedSafetyFlags.toList(),
      'missing_information': [],
      'pharmacist_notes': '',
      'final_decision': disposition,
      'images': [],
      'other_symptoms': otherSymptoms,
      'tried_treatments': triedTreatments,
    };
  }

  // ---------- Backend Integration ----------
  Future<void> _generateReferral() async {
    setState(() => _isLoading = true);

    try {
      final (encounterId, patientId) = await _getOrCreatePatientAndEncounter();
      final assessmentData = _collectData();
      assessmentData['patient_id'] = patientId;

      final saveResponse = await ApiClient.dio.post(
        '/api/assessments/encounters/$encounterId',
        data: assessmentData,
      );
      if (saveResponse.statusCode != 200 && saveResponse.statusCode != 201) {
        throw Exception('Failed to save assessment');
      }

      final aiResponse = await ApiClient.dio.post(
        '/api/ai-review/encounters/$encounterId',
      );
      if (aiResponse.statusCode != 200) {
        throw Exception('AI review generation failed');
      }
      final review = aiResponse.data['ai_review'];

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/ai-review',
          arguments: review,
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not generate referral: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<(String, String)> _getOrCreatePatientAndEncounter() async {
    final identifier = patientPhone.isNotEmpty ? patientPhone : patientName;
    String patientId;

    final searchResponse = await ApiClient.dio.get(
      '/api/patients/search?query=${Uri.encodeComponent(identifier)}',
    );
    if (searchResponse.statusCode == 200 &&
        (searchResponse.data['patients'] as List).isNotEmpty) {
      patientId = (searchResponse.data['patients'][0]['id'] as String);
    } else {
      final createPatientResponse = await ApiClient.dio.post(
        '/api/patients',
        data: {
          'phone': patientPhone.isNotEmpty ? patientPhone : null,
          'consent_status': consentConfirmed ? 'granted' : 'pending',
          'has_identifier': patientPhone.isNotEmpty || patientName.isNotEmpty,
        },
      );
      if (createPatientResponse.statusCode != 201) {
        throw Exception('Failed to create patient');
      }
      patientId = (createPatientResponse.data['patient']['id'] as String);
    }

    final createEncounterResponse = await ApiClient.dio.post(
      '/api/encounters',
      data: {
        'client_reference': 'Assessment-${DateTime.now().millisecondsSinceEpoch}',
        'age_group': patientAge,
        'sex': patientGender ?? 'Unknown',
        'consent_status': consentConfirmed ? 'granted' : 'pending',
      },
    );
    if (createEncounterResponse.statusCode != 201) {
      throw Exception('Failed to create encounter');
    }
    final encounter = createEncounterResponse.data['encounter'];
    final encounterId = encounter['id'] as String;

    return (encounterId, patientId);
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally')),
    );
  }
}