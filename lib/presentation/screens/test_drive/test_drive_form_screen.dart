import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/car_entity.dart';
import '../../../domain/entities/test_drive_entity.dart';
import '../../../providers/car_providers.dart';
import '../../../providers/test_drive_providers.dart';
import '../../router/app_router.dart';

class TestDriveFormScreen extends ConsumerStatefulWidget {
  const TestDriveFormScreen({super.key, this.preselectedCarId});
  final String? preselectedCarId;

  @override
  ConsumerState<TestDriveFormScreen> createState() =>
      _TestDriveFormScreenState();
}

class _TestDriveFormScreenState extends ConsumerState<TestDriveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedCarId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _selectedCarId = widget.preselectedCarId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF141414),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit(List<CarEntity> cars) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('Please select a car', isError: true),
      );
      return;
    }

    // Build the domain entity
    final request = TestDriveEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      carId: _selectedCarId!,
      userName: _nameCtrl.text.trim(),
      contactInfo: _contactCtrl.text.trim(),
      preferredDate: _selectedDate,
    );

    // Submit via AsyncNotifier
    await ref
        .read(testDriveNotifierProvider.notifier)
        .submitRequest(request);

    // Check state after submission
    final state = ref.read(testDriveNotifierProvider);
    if (!mounted) return;

    state.when(
      data: (_) {
        setState(() => _submitted = true);
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Submission failed: $e', isError: true),
        );
      },
      loading: () {},
    );
  }

  SnackBar _buildSnackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFF2A1010) : const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carListProvider);
    final testDriveState = ref.watch(testDriveNotifierProvider);
    final isLoading = testDriveState.isLoading;

    if (_submitted) {
      return _SuccessScreen(
        onViewHistory: () => context.push(AppRoutes.testDriveHistory),
        onCatalog: () => context.go(AppRoutes.catalog),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0A),
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEST DRIVE',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Book Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Form
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero banner
                    _HeroBanner(),

                    const SizedBox(height: 28),

                    // Car selection
                    _SectionLabel(label: 'Select Vehicle'),
                    const SizedBox(height: 10),
                    carsAsync.when(
                      loading: () => const _FieldSkeleton(height: 56),
                      error: (_, __) => _ErrorField(
                        message: 'Failed to load cars. Please go back and retry.',
                      ),
                      data: (cars) => _CarSelector(
                        cars: cars,
                        selectedId: _selectedCarId,
                        onChanged: (id) => setState(() => _selectedCarId = id),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name
                    _SectionLabel(label: 'Full Name'),
                    const SizedBox(height: 10),
                    _PremiumTextField(
                      controller: _nameCtrl,
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (v.trim().length < 2) return 'Name is too short';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Contact
                    _SectionLabel(label: 'Contact Information'),
                    const SizedBox(height: 10),
                    _PremiumTextField(
                      controller: _contactCtrl,
                      hint: 'Email or phone number',
                      icon: Icons.contact_phone_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Contact info is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Date picker
                    _SectionLabel(label: 'Preferred Date'),
                    const SizedBox(height: 10),
                    _DatePickerField(
                      selectedDate: _selectedDate,
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 32),

                    // Submit button — handles loading state with .when()
                    testDriveState.when(
                      loading: () => const _LoadingSubmitButton(),
                      error: (e, _) => Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1010),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.withAlpha(60),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Error: $e',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SubmitButton(
                            onPressed: () => _submit(
                              carsAsync.value ?? [],
                            ),
                          ),
                        ],
                      ),
                      data: (_) => _SubmitButton(
                        onPressed: isLoading
                            ? null
                            : () => _submit(carsAsync.value ?? []),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── HERO BANNER ─────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1500), Color(0xFF0F0F00)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Test Drive\nExperience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Our team will contact you\nwithin 24 hours.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4AF37).withAlpha(80),
              ),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Color(0xFFD4AF37),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── CAR SELECTOR ────────────────────────────

class _CarSelector extends StatelessWidget {
  const _CarSelector({
    required this.cars,
    required this.selectedId,
    required this.onChanged,
  });

  final List<CarEntity> cars;
  final String? selectedId;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedId != null
              ? const Color(0xFFD4AF37).withAlpha(120)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          hint: const Text(
            'Choose a vehicle',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFD4AF37),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: cars
              .map(
                (car) => DropdownMenuItem<String>(
              value: car.id,
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 16,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${car.brand} ${car.model} (${car.year})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────── TEXT FIELD ───────────────────────────────

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFFD4AF37),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        filled: true,
        fillColor: const Color(0xFF141414),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

// ─────────────────── DATE PICKER FIELD ───────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.onTap,
  });
  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

// ─────────────────── SUBMIT BUTTONS ──────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF3A3A3A),
          disabledForegroundColor: Colors.white38,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Submit Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSubmitButton extends StatelessWidget {
  const _LoadingSubmitButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withAlpha(60),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFD4AF37),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── SUCCESS SCREEN ──────────────────────────

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({
    required this.onViewHistory,
    required this.onCatalog,
  });
  final VoidCallback onViewHistory;
  final VoidCallback onCatalog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withAlpha(20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withAlpha(100),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 52,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Request Submitted!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Our team will contact you\nwithin 24 hours to confirm\nyour test drive.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onViewHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'View My Requests',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onCatalog,
                  child: const Text(
                    'Back to Catalogue',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
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
}

// ─────────────────── HELPERS ─────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
    );
  }
}

class _ErrorField extends StatelessWidget {
  const _ErrorField({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}