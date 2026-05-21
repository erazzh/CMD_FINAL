import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/car_entity.dart';
import '../../../providers/compare_cars_provider.dart';
import '../../router/app_router.dart';

class CarCompareScreen extends ConsumerWidget {
  const CarCompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(compareCarsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
                  'COMPARISON',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Side by Side',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              if (cars.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(compareCarsProvider.notifier).clearComparison();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          if (cars.isEmpty)
            const SliverFillRemaining(child: _EmptyCompareView())
          else
            SliverList(
              delegate: SliverChildListDelegate([
                // Car image headers
                _CompareImageHeader(cars: cars),
                const SizedBox(height: 8),
                // Comparison table rows
                _CompareTable(cars: cars),
                const SizedBox(height: 24),
                // Action buttons
                _CompareActions(cars: cars),
                const SizedBox(height: 40),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─────────────────── IMAGE HEADERS ───────────────────────────

class _CompareImageHeader extends StatelessWidget {
  const _CompareImageHeader({required this.cars});
  final List<CarEntity> cars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Labels column
          SizedBox(
            width: 90,
            child: Column(
              children: [
                const SizedBox(height: 100),
                Container(
                  height: 1,
                  color: const Color(0xFF2A2A2A),
                ),
              ],
            ),
          ),
          // Car columns
          ...cars.map(
                (car) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF252525)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: car.imageUrl.isNotEmpty
                            ? Image.network(
                          car.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_rounded,
                            color: Color(0xFF333333),
                            size: 40,
                          ),
                        )
                            : const Icon(
                          Icons.directions_car_rounded,
                          color: Color(0xFF333333),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      car.brand,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      car.model,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

// ─────────────────── COMPARISON TABLE ────────────────────────

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.cars});
  final List<CarEntity> cars;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _TableRow(
        label: 'Year',
        values: cars.map((c) => '${c.year}').toList(),
        icon: Icons.calendar_today_rounded,
      ),
      _TableRow(
        label: 'Price',
        values: cars.map((c) => '\$${_fmt(c.price)}').toList(),
        icon: Icons.attach_money_rounded,
        highlight: true,
      ),
      _TableRow(
        label: 'Brand',
        values: cars.map((c) => c.brand).toList(),
        icon: Icons.verified_rounded,
      ),
      _TableRow(
        label: 'Model',
        values: cars.map((c) => c.model).toList(),
        icon: Icons.directions_car_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Column(
          children: rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            final row = entry.value;
            return _CompareRow(row: row, cars: cars, isLast: isLast);
          }).toList(),
        ),
      ),
    );
  }

  String _fmt(double price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}

class _TableRow {
  const _TableRow({
    required this.label,
    required this.values,
    required this.icon,
    this.highlight = false,
  });
  final String label;
  final List<String> values;
  final IconData icon;
  final bool highlight;
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.row,
    required this.cars,
    required this.isLast,
  });
  final _TableRow row;
  final List<CarEntity> cars;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 90,
            child: Row(
              children: [
                Icon(row.icon, size: 14, color: const Color(0xFFD4AF37)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    row.label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Values for each car
          ...row.values.asMap().entries.map(
                (entry) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: row.highlight
                        ? const Color(0xFFD4AF37)
                        : Colors.white,
                    fontSize: row.highlight ? 14 : 12,
                    fontWeight: row.highlight ? FontWeight.w800 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── ACTIONS ─────────────────────────────────

class _CompareActions extends ConsumerWidget {
  const _CompareActions({required this.cars});
  final List<CarEntity> cars;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'BOOK A TEST DRIVE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          ...cars.map(
                (car) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.brand.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 9,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          car.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => context.go(
                      '${AppRoutes.testDriveNew}?carId=${car.id}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Book Drive',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── EMPTY VIEW ──────────────────────────────

class _EmptyCompareView extends StatelessWidget {
  const _EmptyCompareView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withAlpha(60),
                ),
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 48,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Cars Selected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to the catalogue and tap\n"Compare" on up to 3 cars',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.catalog),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Browse Catalogue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}