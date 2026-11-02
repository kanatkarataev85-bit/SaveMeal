import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_copy.dart';
import 'models/food_listing.dart';
import 'services/supabase_auth_service.dart';

const _green = Color(0xFF287A4B);
const _greenDark = Color(0xFF195A37);
const _greenLight = Color(0xFFE8F2E9);
const _ink = Color(0xFF202821);
const _muted = Color(0xFF777E77);
const _canvas = Color(0xFFFAFAF7);

enum FulfillmentMethod { pickup, delivery }

class SaveMealApp extends StatefulWidget {
  const SaveMealApp({super.key});

  @override
  State<SaveMealApp> createState() => _SaveMealAppState();
}

class _SaveMealAppState extends State<SaveMealApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveMeal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          primary: _green,
          surface: _canvas,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: _muted, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE9ECE7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
        ),
      ),
      home: _showSplash
          ? const SplashScreen()
          : const MainShell(language: 'ru'),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: .96,
    upperBound: 1.04,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _animation,
              child: const BrandMark(size: 82),
            ),
            const SizedBox(height: 18),
            const Text(
              'SaveMeal',
              style: TextStyle(
                color: _greenDark,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 3,
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({required this.language, super.key});

  final String language;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final Map<String, int> _basket = {};

  List<FoodListing> get _visibleListings =>
      previewListings.where((listing) => listing.portions > 0).toList();

  List<BasketLine> get _orderLines => _basket.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) => BasketLine(
          listing: previewListings.firstWhere(
            (listing) => listing.id == entry.key,
          ),
          quantity: entry.value,
        ),
      )
      .toList();

  int get _selectedPortions =>
      _basket.values.fold(0, (total, quantity) => total + quantity);

  int get _basketTotal =>
      _orderLines.fold(0, (total, line) => total + line.total);

  void _changeQuantity(FoodListing listing, int delta) {
    final current = _basket[listing.id] ?? 0;
    final next = current == 0
        ? 1
        : (current + delta).clamp(1, listing.portions).toInt();
    setState(() => _basket[listing.id] = next);
  }

  String get _basketCountLabel {
    final remainder100 = _selectedPortions % 100;
    if (remainder100 >= 11 && remainder100 <= 14) return 'порций';
    return switch (_selectedPortions % 10) {
      1 => 'порция',
      2 || 3 || 4 => 'порции',
      _ => 'порций',
    };
  }

  void _openCheckout() {
    final orderLines = _orderLines;
    if (orderLines.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(
          language: widget.language,
          orderLines: orderLines,
          initialRegister: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _buildFoodPage()),
      bottomNavigationBar: _selectedPortions == 0
          ? null
          : SafeArea(
              top: false,
              child: Container(
                key: const ValueKey('catalog-buy-panel'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 18,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_selectedPortions $_basketCountLabel',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$_basketTotal ${copy(widget.language, 'som')}',
                            style: const TextStyle(
                              color: _greenDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        key: const ValueKey('catalog-buy'),
                        onPressed: _openCheckout,
                        child: Text(copy(widget.language, 'buy')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFoodPage() {
    final items = _visibleListings;
    final featuredItems = items.where((item) => item.isFeatured).toList();
    final regularItems = items.where((item) => !item.isFeatured).toList();
    return CustomScrollView(
      key: const PageStorageKey('food-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  const BrandMark(size: 36),
                  const SizedBox(width: 8),
                  Text(
                    copy(widget.language, 'brand'),
                    style: const TextStyle(
                      color: _greenDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                EmptyResults(
                  title: copy(widget.language, 'empty_results'),
                  body: copy(widget.language, 'empty_results_body'),
                )
              else ...[
                for (final listing in featuredItems) ...[
                  FoodCard(
                    listing: listing,
                    language: widget.language,
                    basketCount: _basket[listing.id] ?? 0,
                    featured: true,
                    onQuantityChanged: (delta) =>
                        _changeQuantity(listing, delta),
                  ),
                  const SizedBox(height: 14),
                ],
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: regularItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 13,
                    mainAxisExtent:
                        regularItems.any(
                          (listing) => (_basket[listing.id] ?? 0) > 0,
                        )
                        ? 320
                        : 280,
                  ),
                  itemBuilder: (context, index) {
                    final listing = regularItems[index];
                    return FoodCard(
                      listing: listing,
                      language: widget.language,
                      basketCount: _basket[listing.id] ?? 0,
                      onQuantityChanged: (delta) =>
                          _changeQuantity(listing, delta),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

class FoodCard extends StatelessWidget {
  const FoodCard({
    required this.listing,
    required this.language,
    required this.basketCount,
    required this.onQuantityChanged,
    this.featured = false,
    super.key,
  });

  final FoodListing listing;
  final String language;
  final int basketCount;
  final ValueChanged<int> onQuantityChanged;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: featured
            ? (basketCount > 0 ? 350 : 320)
            : (basketCount > 0 ? 320 : 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: featured ? 140 : 104,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FoodPhoto(url: listing.imageUrl),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        '-${listing.discountPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 9,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${listing.portions} ${copy(language, 'portions_left')}',
                        style: const TextStyle(
                          color: _greenDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.localizedTitle(language),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: featured ? 17 : 14,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: _muted,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${copy(language, 'pickup')} · ${listing.pickupWindow}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${listing.price} ${copy(language, 'som')}',
                                style: TextStyle(
                                  color: _greenDark,
                                  fontSize: featured ? 19 : 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${listing.originalPrice} ${copy(language, 'som')}',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              if (basketCount > 0) ...[
                                const SizedBox(height: 2),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: Text(
                                    '${copy(language, 'total')}: '
                                    '${listing.price * basketCount} '
                                    '${copy(language, 'som')}',
                                    key: ValueKey(
                                      'listing-total-${listing.id}-'
                                      '$basketCount',
                                    ),
                                    style: const TextStyle(
                                      color: _green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _QuantityButton(
                          icon: Icons.remove_rounded,
                          key: ValueKey('quantity-minus-${listing.id}'),
                          onTap: basketCount == 0
                              ? null
                              : () => onQuantityChanged(-1),
                          size: 44,
                        ),
                        Expanded(
                          child: Text(
                            '$basketCount',
                            key: ValueKey('quantity-value-${listing.id}'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.add_rounded,
                          key: ValueKey('quantity-plus-${listing.id}'),
                          onTap: basketCount >= listing.portions
                              ? null
                              : () => onQuantityChanged(1),
                          size: 44,
                        ),
                      ],
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

class ListingDetailsSheet extends StatelessWidget {
  const ListingDetailsSheet({
    required this.listing,
    required this.language,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAdd,
    super.key,
  });

  final FoodListing listing;
  final String language;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    String t(String key) => copy(language, key);
    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .62,
      maxChildSize: .96,
      builder: (context, scrollController) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: _canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: FoodPhoto(url: listing.imageUrl),
                  ),
                  Positioned(
                    top: 16,
                    left: 18,
                    child: RoundIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 18,
                    child: RoundIconButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.redAccent : _ink,
                      onTap: onFavorite,
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 16,
                    child: PreviewPill(language: language),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.localizedTitle(language),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1E3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${listing.discountPercent}%',
                          style: const TextStyle(
                            color: Color(0xFFB46321),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        size: 17,
                        color: _green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        listing.restaurant,
                        style: const TextStyle(color: _muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Text(
                        '${listing.price} ${t('som')}',
                        style: const TextStyle(
                          color: _greenDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '${listing.originalPrice} ${t('som')}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 15,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoPill(
                        icon: Icons.inventory_2_outlined,
                        label:
                            '${listing.portions} ${t('basket_count')} ${t('available').toLowerCase()}',
                      ),
                      InfoPill(
                        icon: Icons.schedule_rounded,
                        label: '${t('pickup_time')} · ${listing.pickupWindow}',
                      ),
                      InfoPill(
                        icon: Icons.store_mall_directory_outlined,
                        label: t('pickup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('details_about'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.localizedDescription(language),
                    style: const TextStyle(
                      color: _muted,
                      height: 1.55,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('ingredients'),
                    style: const TextStyle(color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: Text(t('add_to_cart')),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.language,
    required this.orderLines,
    required this.initialRegister,
    super.key,
  });

  final String language;
  final List<BasketLine> orderLines;
  final bool initialRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _register;
  bool _hidePassword = true;
  FulfillmentMethod? _fulfillmentMethod;
  bool _showFulfillmentError = false;
  bool _isSubmitting = false;
  bool _awaitingPhoneVerification = false;
  final _addressController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  String t(String key) => copy(widget.language, key);

  int get _orderTotal =>
      widget.orderLines.fold(0, (total, line) => total + line.total);

  @override
  void initState() {
    super.initState();
    _register = widget.initialRegister;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _showAuthMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _showAuthError(Object error) {
    final message = switch (error) {
      AuthException() => error.message,
      PostgrestException() => error.message,
      ProfileNotFoundException() => t('profile_not_found'),
      StateError() => error.message,
      Exception() => error.toString(),
      _ => t('auth_error'),
    };
    _showAuthMessage(message, isError: true);
  }

  Future<void> _resendPhoneVerification() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await SupabaseAuthService().resendPhoneVerification(
        _phoneController.text,
      );
      if (mounted) _showAuthMessage(t('verification_code_sent'));
    } on AuthException catch (error) {
      if (mounted) _showAuthError(error);
    } on Exception catch (error) {
      if (mounted) _showAuthError(error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitAuth() async {
    final accountIsValid = _formKey.currentState!.validate();
    final fulfillmentIsValid =
        _fulfillmentMethod != null &&
        (_fulfillmentMethod != FulfillmentMethod.delivery ||
            _addressController.text.trim().isNotEmpty);
    setState(() => _showFulfillmentError = !fulfillmentIsValid);
    if (!accountIsValid || !fulfillmentIsValid) return;

    if (!isSupabaseConfigured) {
      _showAuthMessage(t('supabase_not_configured'), isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = SupabaseAuthService();
      if (_awaitingPhoneVerification) {
        final response = await auth.verifyPhone(
          phone: _phoneController.text,
          token: _verificationCodeController.text.trim(),
        );
        final userId = response.user?.id;
        if (userId == null) throw StateError(t('auth_error'));
        await auth.requireProfile(userId);
        if (!mounted) return;
        setState(() => _awaitingPhoneVerification = false);
        _showAuthMessage(t('account_created_order_pending'));
        return;
      }

      if (_register) {
        final response = await auth.register(
          phone: _phoneController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          address: _addressController.text,
        );
        final userId = response.user?.id;
        if (userId == null) throw StateError(t('auth_error'));
        if (response.session == null) {
          if (!mounted) return;
          setState(() => _awaitingPhoneVerification = true);
          _showAuthMessage(t('verification_code_sent'));
          return;
        }
        await auth.requireProfile(userId);
        if (!mounted) return;
        _showAuthMessage(t('account_created_order_pending'));
      } else {
        final response = await auth.signIn(
          phone: _phoneController.text,
          password: _passwordController.text,
        );
        final userId = response.user?.id;
        if (userId == null) throw StateError(t('auth_error'));
        await auth.requireProfile(userId);
        if (!mounted) return;
        _showAuthMessage(t('login_success_order_pending'));
      }
    } on AuthException catch (error) {
      if (mounted) _showAuthError(error);
    } on PostgrestException catch (error) {
      if (mounted) _showAuthError(error);
    } on ProfileNotFoundException catch (error) {
      if (mounted) _showAuthError(error);
    } on StateError catch (error) {
      if (mounted) _showAuthError(error);
    } on Exception catch (error) {
      if (mounted) _showAuthError(error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildOrderSummary() {
    final pickupLocations = <String, Set<String>>{};
    for (final line in widget.orderLines) {
      pickupLocations
          .putIfAbsent(line.listing.restaurant, () => <String>{})
          .add(line.listing.pickupAddress);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEEE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('order_items'),
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in widget.orderLines) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${line.listing.localizedTitle(widget.language)}'
                      ' × ${line.quantity}',
                      style: const TextStyle(color: _ink, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${line.total} ${t('som')}',
                    style: const TextStyle(
                      color: _greenDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  t('total'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$_orderTotal ${t('som')}',
                style: const TextStyle(
                  color: _greenDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (_fulfillmentMethod == FulfillmentMethod.pickup) ...[
            const SizedBox(height: 12),
            for (final location in pickupLocations.entries)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _green,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${location.key}\n${location.value.join('\n')}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 5),
            Text(
              t('demo_pickup_address_notice'),
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFulfillmentChoice({
    required FulfillmentMethod method,
    required String title,
    required IconData icon,
  }) {
    final selected = _fulfillmentMethod == method;
    return Material(
      color: selected ? _greenLight : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          _fulfillmentMethod = method;
          _showFulfillmentError = false;
          _formKey.currentState?.validate();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _green : const Color(0xFFE5E9E3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: _greenDark, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _green : _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 16),
                    SizedBox(
                      height: compact ? 150 : 190,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FoodPhoto(url: welcomeImage),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xA9000000),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              bottom: 14,
                              child: PreviewPill(language: widget.language),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t('order_title'),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t('order_subtitle'),
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 18),
                    _buildOrderSummary(),
                    const SizedBox(height: 20),
                    _FormLabel(text: t('fulfillment_method')),
                    _buildFulfillmentChoice(
                      method: FulfillmentMethod.pickup,
                      title: t('pickup'),
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 9),
                    _buildFulfillmentChoice(
                      method: FulfillmentMethod.delivery,
                      title: t('delivery'),
                      icon: Icons.delivery_dining_rounded,
                    ),
                    if (_showFulfillmentError &&
                        _fulfillmentMethod == null) ...[
                      const SizedBox(height: 6),
                      Text(
                        t('fulfillment_required'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 19),
                    Text(
                      _awaitingPhoneVerification
                          ? t('verify_phone')
                          : _register
                          ? t('register')
                          : t('login'),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    if (!_awaitingPhoneVerification)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF0EB),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            _AuthModeButton(
                              title: t('login'),
                              selected: !_register,
                              onTap: () => setState(() => _register = false),
                            ),
                            _AuthModeButton(
                              title: t('register'),
                              selected: _register,
                              onTap: () => setState(() => _register = true),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 17),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_fulfillmentMethod ==
                              FulfillmentMethod.delivery) ...[
                            _FormLabel(text: t('delivery_address')),
                            TextFormField(
                              key: const ValueKey('delivery-address'),
                              controller: _addressController,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: t('delivery_address_hint'),
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                              ),
                              validator: (value) =>
                                  _fulfillmentMethod ==
                                          FulfillmentMethod.delivery &&
                                      (value == null || value.trim().isEmpty)
                                  ? t('address_required')
                                  : null,
                            ),
                            const SizedBox(height: 15),
                          ],
                          if (_awaitingPhoneVerification) ...[
                            _FormLabel(text: t('verification_code')),
                            TextFormField(
                              key: const ValueKey('phone-verification-code'),
                              controller: _verificationCodeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 6,
                              decoration: InputDecoration(
                                hintText: t('verification_code'),
                                counterText: '',
                                prefixIcon: const Icon(Icons.sms_outlined),
                              ),
                              validator: (value) =>
                                  value == null ||
                                      !RegExp(r'^\d{6}$').hasMatch(value.trim())
                                  ? t('verification_code_invalid')
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _resendPhoneVerification,
                                child: Text(t('resend_code')),
                              ),
                            ),
                          ] else ...[
                            if (_register) ...[
                              _FormLabel(text: t('name')),
                              TextFormField(
                                key: const ValueKey('registration-name'),
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: t('name'),
                                ),
                                validator: (value) =>
                                    _register &&
                                        (value == null || value.trim().isEmpty)
                                    ? t('name_required')
                                    : null,
                              ),
                              const SizedBox(height: 13),
                            ],
                            _FormLabel(text: t('phone')),
                            TextFormField(
                              key: const ValueKey('registration-phone'),
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              decoration: InputDecoration(
                                hintText: t('phone_hint'),
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              validator: (value) {
                                final digits = (value ?? '').replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                return digits.length >= 9 && digits.length <= 15
                                    ? null
                                    : t('phone_invalid');
                              },
                            ),
                            const SizedBox(height: 13),
                            _FormLabel(text: t('password')),
                            TextFormField(
                              key: const ValueKey('registration-password'),
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              autofillHints: [
                                _register
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                hintText: t('password'),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => (value?.length ?? 0) >= 8
                                  ? null
                                  : t('password_short'),
                            ),
                            if (!_register)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      _showAuthMessage(t('auth_notice')),
                                  child: Text(t('forgot_password')),
                                ),
                              )
                            else
                              const SizedBox(height: 12),
                          ],
                          SizedBox(
                            height: 53,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submitAuth,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _awaitingPhoneVerification
                                          ? t('verify_phone')
                                          : _register
                                          ? t('create_account')
                                          : t('login'),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSupabaseConfigured
                          ? t('auth_notice')
                          : t('supabase_not_configured'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _showTermsNotice(context, t),
                          child: Text(
                            t('terms'),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showTermsNotice(context, t),
                          child: Text(
                            t('privacy'),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showTermsNotice(BuildContext context, String Function(String) t) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t('terms_notice'))));
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 170),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _greenDark : _muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.size = 26,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFFF1F3F0) : _greenLight,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: _greenDark, size: size * .46),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -.25,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(size * .34),
      ),
      child: Icon(Icons.eco_rounded, color: Colors.white, size: size * .62),
    );
  }
}

class PreviewPill extends StatelessWidget {
  const PreviewPill({this.language = 'ru', super.key});

  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _greenLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_outlined, color: _green, size: 14),
          const SizedBox(width: 5),
          Text(
            copy(language, 'demo_menu'),
            style: const TextStyle(
              color: _greenDark,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class FoodPhoto extends StatelessWidget {
  const FoodPhoto({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      placeholder: (context, url) => const ColoredBox(
        color: Color(0xFFE4EBE1),
        child: Center(
          child: Icon(Icons.restaurant_rounded, color: _green, size: 30),
        ),
      ),
      errorWidget: (context, url, error) => const ColoredBox(
        color: Color(0xFFE4EBE1),
        child: Center(
          child: Icon(Icons.restaurant_rounded, color: _green, size: 30),
        ),
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _green),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _ink, fontSize: 11)),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.onTap,
    this.color = _ink,
    super.key,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .93),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD7DCD5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class EmptyResults extends StatelessWidget {
  const EmptyResults({
    required this.title,
    required this.body,
    this.icon = Icons.search_off_rounded,
    this.buttonLabel,
    this.onButton,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: _greenLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _green, size: 26),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.45, fontSize: 13),
          ),
          if (buttonLabel != null && onButton != null) ...[
            const SizedBox(height: 17),
            OutlinedButton(onPressed: onButton, child: Text(buttonLabel!)),
          ],
        ],
      ),
    );
  }
}
