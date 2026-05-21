import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/car_entity.dart';
import '../../../providers/car_providers.dart';
import '../../../providers/compare_cars_provider.dart';
import '../../router/app_router.dart';

class CarCatalogScreen extends ConsumerStatefulWidget {
  const CarCatalogScreen({super.key});

  @override
  ConsumerState<CarCatalogScreen> createState() => _CarCatalogScreenState();
}

class _CarCatalogScreenState extends ConsumerState<CarCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carListProvider);
    final compareCars = ref.watch(compareCarsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, compareCars),
          _buildSearchBar(),
        ],
        body: carsAsync.when(
          loading: () => const _LoadingGrid(),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (cars) {
            final filtered = _applySearch(cars);
            if (filtered.isEmpty) {
              return const _EmptyView();
            }
            return _CarsGrid(
              cars: filtered,
              compareCars: compareCars,
              onCarTap: (car) => context.push(
                '/catalog/${car.id}',
                extra: CarDetailExtra(car: car),
              ),
              onCompareTap: (car) {
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
              onBookTap: (car) => context.push(
                '${AppRoutes.testDriveNew}?carId=${car.id}',
              ),
            );
          },
        ),
      ),
      floatingActionButton: compareCars.isNotEmpty
          ? _CompareButton(
        count: compareCars.length,
        onTap: () => context.go(AppRoutes.compare),
      )
          : null,
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context,
      List<CarEntity> compareCars,
      ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0A),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CAR',
                    style: TextStyle(
                      color: Colors.white.withAlpha(40),
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'CATALOGUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 2,
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      title: const Row(
        children: [
          Text(
            'AUTO',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 4,
            ),
          ),
          Text(
            'ELITE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: 18,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.testDriveHistory),
          icon: const Icon(Icons.history_rounded, color: Colors.white70),
          tooltip: 'Test Drive History',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFFD4AF37),
          decoration: InputDecoration(
            hintText: 'Search brand or model...',
            hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withAlpha(120),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            )
                : null,
            filled: true,
            fillColor: const Color(0xFF1C1C1C),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
      ),
    );
  }

  List<CarEntity> _applySearch(List<CarEntity> cars) {
    if (_searchQuery.isEmpty) return cars;
    return cars.where((c) {
      return c.brand.toLowerCase().contains(_searchQuery) ||
          c.model.toLowerCase().contains(_searchQuery);
    }).toList();
  }
}

// ─────────────────────────── GRID ────────────────────────────

class _CarsGrid extends StatelessWidget {
  const _CarsGrid({
    required this.cars,
    required this.compareCars,
    required this.onCarTap,
    required this.onCompareTap,
    required this.onBookTap,
  });

  final List<CarEntity> cars;
  final List<CarEntity> compareCars;
  final void Function(CarEntity) onCarTap;
  final void Function(CarEntity) onCompareTap;
  final void Function(CarEntity) onBookTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.67,
      ),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        final isInCompare = compareCars.any((c) => c.id == car.id);
        return _CarCard(
          car: car,
          isInCompare: isInCompare,
          onTap: () => onCarTap(car),
          onCompareTap: () => onCompareTap(car),
          onBookTap: () => onBookTap(car),
        );
      },
    );
  }
}

// ─────────────────────────── CARD ────────────────────────────

class _CarCard extends StatefulWidget {
  const _CarCard({
    required this.car,
    required this.isInCompare,
    required this.onTap,
    required this.onCompareTap,
    required this.onBookTap,
  });

  final CarEntity car;
  final bool isInCompare;
  final VoidCallback onTap;
  final VoidCallback onCompareTap;
  final VoidCallback onBookTap;

  @override
  State<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<_CarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scale = Tween<double>(begin: 1, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isInCompare
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFF252525),
              width: widget.isInCompare ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CarImage(imageUrl: widget.car.imageUrl),
                      // Gold overlay when in compare
                      if (widget.isInCompare)
                        Container(
                          color: const Color(0xFFD4AF37).withAlpha(30),
                        ),
                      // Compare badge top-left
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: widget.onCompareTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isInCompare
                                  ? const Color(0xFFD4AF37)
                                  : Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withAlpha(120),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isInCompare
                                      ? Icons.check_rounded
                                      : Icons.compare_arrows_rounded,
                                  size: 12,
                                  color: widget.isInCompare
                                      ? Colors.black
                                      : const Color(0xFFD4AF37),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.isInCompare ? 'Added' : 'Compare',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isInCompare
                                        ? Colors.black
                                        : const Color(0xFFD4AF37),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Year badge top-right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.car.year}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Info area
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.car.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD4AF37),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.car.model,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '\$${_formatPrice(widget.car.price)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: widget.onBookTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Book Drive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}

// ─────────────────── IMAGE WITH SHIMMER ──────────────────────

class _CarImage extends StatelessWidget {
  const _CarImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF1E1E1E),
        child: const Icon(
          Icons.directions_car_rounded,
          size: 48,
          color: Color(0xFF333333),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF1E1E1E),
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                  progress.expectedTotalBytes!
                  : null,
              strokeWidth: 1.5,
              color: const Color(0xFFD4AF37),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF1E1E1E),
        child: const Icon(
          Icons.broken_image_rounded,
          size: 40,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}

// ─────────────────── COMPARE FAB ─────────────────────────────

class _CompareButton extends StatelessWidget {
  const _CompareButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.compare_arrows_rounded,
              color: Colors.black,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Compare ($count)',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── STATES ──────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.67,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: const _Shimmer(),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                color: Color.lerp(
                  const Color(0xFF1A1A1A),
                  const Color(0xFF252525),
                  _ctrl.value,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFF1A1A1A),
                        const Color(0xFF2A2A2A),
                        _ctrl.value,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFF1A1A1A),
                        const Color(0xFF2A2A2A),
                        _ctrl.value,
                      ),
                      borderRadius: BorderRadius.circular(4),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Color(0xFF333333),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Color(0xFF333333),
          ),
          SizedBox(height: 16),
          Text(
            'No cars found',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}