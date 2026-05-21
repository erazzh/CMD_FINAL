import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/test_drive_history_provider.dart';
import '../../router/app_router.dart';

class TestDriveHistoryScreen extends ConsumerWidget {
  const TestDriveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(testDriveHistoryProvider);

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
                  'MY REQUESTS',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Test Drive History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () =>
                    ref.invalidate(testDriveHistoryProvider),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Body: switch on async state with .when()
          historyAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37),
                  strokeWidth: 1.5,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(testDriveHistoryProvider),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyHistoryView(
                    onBookTap: () => context.go(AppRoutes.testDriveNew),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == 0) {
                      return _StatsBar(count: items.length);
                    }
                    final item = items[index - 1];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _HistoryCard(item: item),
                    );
                  },
                  childCount: items.length + 1,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.testDriveNew),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Request',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ─────────────────── STATS BAR ───────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Row(
          children: [
            _StatItem(
              label: 'Total Requests',
              value: '$count',
              icon: Icons.receipt_long_rounded,
            ),
            Container(
              width: 0.5,
              height: 36,
              color: const Color(0xFF2A2A2A),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _StatItem(
              label: 'Status',
              value: 'Pending',
              icon: Icons.pending_outlined,
              valueColor: const Color(0xFFD4AF37),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────── HISTORY CARD ────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final TestDriveHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final car = item.car;
    final date = request.preferredDate;
    final formatted =
        '${date.day} ${_monthName(date.month)} ${date.year}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Column(
        children: [
          // Car image + name header
          if (car != null) ...[
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 130,
                    child: car.imageUrl.isNotEmpty
                        ? Image.network(
                      car.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Color(0xFF333333),
                          size: 48,
                        ),
                      ),
                    )
                        : Container(
                      color: const Color(0xFF1E1E1E),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Color(0xFF333333),
                        size: 48,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF141414).withAlpha(200),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Car name bottom-left
                  Positioned(
                    bottom: 12,
                    left: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.brand.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          car.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Year badge top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${car.year}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // No car data fallback
            Container(
              width: double.infinity,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  'Car ID: ${request.carId}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],

          // Request details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value: request.userName,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.contact_phone_outlined,
                  label: 'Contact',
                  value: request.contactInfo,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date',
                  value: formatted,
                  valueColor: const Color(0xFFD4AF37),
                ),
                const SizedBox(height: 12),
                // Status chip
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withAlpha(20),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withAlpha(80),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pending_outlined,
                            size: 12,
                            color: Color(0xFFD4AF37),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Pending Review',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────── STATES ──────────────────────────────────

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView({required this.onBookTap});
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withAlpha(60),
                ),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 44,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Requests Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your submitted test drive\nrequests will appear here.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onBookTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Book Test Drive'),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Color(0xFF333333),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}