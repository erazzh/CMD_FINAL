import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/car_entity.dart';
import '../../../providers/car_providers.dart';
import '../../../providers/compare_cars_provider.dart';
import '../../router/app_router.dart';

class CarDetailScreen extends ConsumerWidget {
  const CarDetailScreen({
    super.key,
    required this.carId,
    this.car,
  });

  final String carId;
  final CarEntity? car;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use passed car or fall back to fetching from the list provider
    final carsAsync = ref.watch(carListProvider);
    final resolvedCar = car ??
        carsAsync.whenOrNull(
          data: (cars) => cars.where((c) => c.id == carId).firstOrNull,
        );

    if (resolvedCar == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4AF37),
            strokeWidth: 1.5,
          ),
        ),
      );
    }

    return _CarDetailView(car: resolvedCar);
  }
}

class _CarDetailView extends ConsumerWidget {
  const _CarDetailView({required this.car});
  final CarEntity car;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compareCars = ref.watch(compareCarsProvider);
    final isInCompare = compareCars.any((c) => c.id == car.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SLIVER APP BAR WITH HERO IMAGE ──
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0A),
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            actions: [
              // Compare toggle button
              GestureDetector(
                onTap: () {
                  try {
                    ref
                        .read(compareCarsProvider.notifier)
                        .toggleCarForComparison(car);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Maximum 3 cars can be compared'),
                        backgroundColor: const Color(0xFF1A1A1A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isInCompare
                        ? const Color(0xFFD4AF37)
                        : Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isInCompare
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInCompare
                            ? Icons.check_rounded
                            : Icons.compare_arrows_rounded,
                        size: 14,
                        color: isInCompare ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isInCompare ? 'Added' : 'Compare',
                        style: TextStyle(
                          color: isInCompare ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Car image
                  _HeroImage(imageUrl: car.imageUrl),
                  // Dark gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.3, 0.7, 1.0],
                        colors: [
                          const Color(0xFF0A0A0A).withAlpha(120),
                          Colors.transparent,
                          Colors.transparent,
                          const Color(0xFF0A0A0A),
                        ],
                      ),
                    ),
                  ),
                  // Brand + model overlay at bottom
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.brand.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          car.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SLIVER LIST: ALL DETAIL SECTIONS ──
          SliverList(
            delegate: SliverChildListDelegate([
              // Price & year row
              _PriceYearRow(car: car),

              // Gold divider
              const _GoldDivider(),

              // Specs section
              const _SectionTitle(title: 'SPECIFICATIONS'),
              _SpecsGrid(car: car),

              const _GoldDivider(),

              // Features section
              const _SectionTitle(title: 'KEY FEATURES'),
              const _FeaturesList(),

              const _GoldDivider(),

              // Test drive CTA
              _TestDriveCTA(car: car),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── IMAGE ───────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF141414),
        child: const Icon(
          Icons.directions_car_rounded,
          size: 80,
          color: Color(0xFF2A2A2A),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF141414),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD4AF37),
              strokeWidth: 1.5,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF141414),
        child: const Icon(
          Icons.broken_image_rounded,
          size: 80,
          color: Color(0xFF2A2A2A),
        ),
      ),
    );
  }
}

// ─────────────────── PRICE & YEAR ────────────────────────────

class _PriceYearRow extends StatelessWidget {
  const _PriceYearRow({required this.car});
  final CarEntity car;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STARTING PRICE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${_formatPrice(car.price)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37).withAlpha(100)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '${car.year}',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M';
    }
    if (price >= 1000) {
      final formatted = (price / 1000).toStringAsFixed(0);
      return '${formatted}K';
    }
    return price.toStringAsFixed(0);
  }
}

// ─────────────────── SPECS GRID ──────────────────────────────

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.car});
  final CarEntity car;

  @override
  Widget build(BuildContext context) {
    final specs = [
      _SpecItem(label: 'Brand', value: car.brand, icon: Icons.verified_rounded),
      _SpecItem(label: 'Model', value: car.model, icon: Icons.directions_car_rounded),
      _SpecItem(
        label: 'Year',
        value: '${car.year}',
        icon: Icons.calendar_today_rounded,
      ),
      _SpecItem(
        label: 'Price',
        value: '\$${car.price.toStringAsFixed(0)}',
        icon: Icons.attach_money_rounded,
      ),
      _SpecItem(label: 'ID', value: '#${car.id}', icon: Icons.tag_rounded),
      _SpecItem(
        label: 'Status',
        value: 'Available',
        icon: Icons.check_circle_outline_rounded,
        valueColor: const Color(0xFF4CAF50),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: specs
            .map(
              (spec) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF252525)),
            ),
            child: Row(
              children: [
                Icon(spec.icon, size: 16, color: const Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        spec.label,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.value,
                        style: TextStyle(
                          color: spec.valueColor ?? Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _SpecItem {
  const _SpecItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
}

// ─────────────────── FEATURES LIST ───────────────────────────

class _FeaturesList extends StatelessWidget {
  const _FeaturesList();

  static const List<(IconData, String, String)> _features = [
    (Icons.shield_rounded, 'Advanced Safety', 'Lane assist, AEB, blind spot monitoring'),
    (Icons.electric_bolt_rounded, 'Hybrid Engine', 'Optimised fuel efficiency technology'),
    (Icons.wifi_rounded, 'Connected Car', 'Remote access via smartphone app'),
    (Icons.ac_unit_rounded, 'Climate Control', 'Dual-zone automatic air conditioning'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _features.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final (icon, title, subtitle) = _features[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF252525)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withAlpha(60),
                  ),
                ),
                child: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white24,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────── TEST DRIVE CTA ──────────────────────────

class _TestDriveCTA extends StatelessWidget {
  const _TestDriveCTA({required this.car});
  final CarEntity car;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EXPERIENCE IT',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Book a Test Drive',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Schedule a personalised driving experience\nand feel the power of ${car.brand} ${car.model}.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go(
                  '${AppRoutes.testDriveNew}?carId=${car.id}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Book Test Drive',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── HELPERS ─────────────────────────────────

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withAlpha(10), thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFD4AF37),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.white.withAlpha(10), thickness: 0.5)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}