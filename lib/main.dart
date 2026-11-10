import 'dart:async';
import 'dart:typed_data';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var supabaseConfigured = false;
  String? initializationError;

  try {
    await Supabase.initialize(
      url: 'https://acihoqulcvgsibgmvrfj.supabase.co',
      anonKey: 'sb_publishable_lL5f8sscSAFX4R4mEpGo8A_zx95WKlM',
    );
    supabaseConfigured = true;
  } catch (error) {
    initializationError = 'Could not connect to Supabase: $error';
  }

  runApp(
    MyApp(
      supabaseConfigured: supabaseConfigured,
      initializationError: initializationError,
    ),
  );
}

const _ink = Color(0xFF1F1F1F);
const _muted = Color(0xFF77736D);
const _paper = Color(0xFFFBF9F5);
const _gold = Color(0xFF9E825E);
const _line = Color(0xFFE5E0D8);
const _freeShippingThreshold = 7000;

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.supabaseConfigured,
    this.initializationError,
  });

  final bool supabaseConfigured;
  final String? initializationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sillage — Fragrance, found.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          surface: _paper,
          onSurface: _ink,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: _ink, fontSize: 14, height: 1.55),
          bodySmall: TextStyle(color: _muted, fontSize: 12, height: 1.5),
        ),
      ),
      home: supabaseConfigured
          ? const _AuthenticationGate()
          : _SupabaseSetupPage(error: initializationError),
    );
  }
}

class _AuthenticationGate extends StatelessWidget {
  const _AuthenticationGate();

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) return const _AuthenticationPage();
        return _ProfileRoleGate(key: ValueKey(session.user.id));
      },
    );
  }
}

class _ProfileRoleGate extends StatefulWidget {
  const _ProfileRoleGate({super.key});

  @override
  State<_ProfileRoleGate> createState() => _ProfileRoleGateState();
}

class _ProfileRoleGateState extends State<_ProfileRoleGate> {
  late Future<String> _roleRequest;

  @override
  void initState() {
    super.initState();
    _roleRequest = _fetchRole();
  }

  Future<String> _fetchRole() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      debugPrint(
        'No authenticated user while loading profile role; defaulting to customer.',
      );
      return 'customer';
    }

    try {
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = profile?['role'];
      if (role is String && role.trim().isNotEmpty) {
        return role.trim();
      }

      debugPrint(
        'No valid profile role found for the authenticated user; defaulting to customer.',
      );
    } catch (error, stackTrace) {
      debugPrint('Could not load profile role; defaulting to customer: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return 'customer';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _roleRequest,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _paper,
            body: Center(child: CircularProgressIndicator(color: _gold)),
          );
        }
        if (snapshot.hasError) {
          debugPrint(
            'Unexpected profile role loading failure; defaulting to customer: '
            '${snapshot.error}',
          );
          debugPrintStack(stackTrace: snapshot.stackTrace);
        }
        return StorefrontPage(isAdmin: snapshot.data == 'admin');
      },
    );
  }
}

class _SupabaseSetupPage extends StatelessWidget {
  const _SupabaseSetupPage({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'S I L L A G E',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 26,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  error ?? 'Supabase authentication is unavailable. Please try again later.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check the Supabase project configuration and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _gold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Perfume {
  const Perfume({
    this.id,
    required this.name,
    required this.house,
    required this.price,
    required this.family,
    required this.image,
    required this.tint,
    required this.description,
    required this.notes,
    required this.longevity,
    this.label,
  });

  final String? id;
  final String name;
  final String house;
  final int price;
  final String family;
  final String image;
  final Color tint;
  final String description;
  final List<String> notes;
  final String longevity;
  final String? label;

  factory Perfume.fromRow(Map<String, dynamic> row) {
    final rawTint = row['tint'];
    final tintValue = rawTint is num
        ? rawTint.toInt()
        : int.parse(rawTint.toString(), radix: 16);
    final rawNotes = row['notes'];
    final notes = rawNotes is List
        ? rawNotes.map((note) => note.toString()).toList()
        : rawNotes is String
        ? rawNotes
              .split(',')
              .map((note) => note.trim())
              .where((note) => note.isNotEmpty)
              .toList()
        : throw const FormatException(
            'Product notes must be a list or string.',
          );

    return Perfume(
      id: row['id']?.toString(),
      name: row['name'].toString(),
      house: row['house'].toString(),
      price: (row['price'] as num).toInt(),
      family: row['family'].toString(),
      image: row['image'].toString(),
      tint: Color(tintValue),
      description: row['description'].toString(),
      notes: notes,
      longevity: row['longevity'].toString(),
      label: row['label']?.toString(),
    );
  }
}

const _defaultPerfumes = [
  Perfume(
    name: 'Santal 33',
    house: 'LE LABO',
    price: 9500,
    family: 'Woody',
    image: 'photo-1594035910387-fea47794261f',
    tint: Color(0xFFD5C9B7),
    description:
        'A smoky, leathery blend that feels like open air and warm skin.',
    notes: ['Cardamom', 'Australian sandalwood', 'Leather'],
    longevity: '8+ hours',
    label: 'BESTSELLER',
  ),
  Perfume(
    name: 'Rose of No Man’s Land',
    house: 'BYREDO',
    price: 9000,
    family: 'Floral',
    image: 'photo-1541643600914-78b084683601',
    tint: Color(0xFFE6D7D1),
    description: 'A tender tribute to the quiet strength of the Damask rose.',
    notes: ['Pink pepper', 'Turkish rose', 'White amber'],
    longevity: '6–8 hours',
  ),
  Perfume(
    name: 'Wood Sage & Sea Salt',
    house: 'JO MALONE LONDON',
    price: 6200,
    family: 'Fresh',
    image: 'photo-1592945403244-b3fbafd7f539',
    tint: Color(0xFFD8DED8),
    description:
        'A windswept escape, alive with mineral freshness and soft woods.',
    notes: ['Ambrette seeds', 'Sea salt', 'Sage'],
    longevity: '4–6 hours',
    label: 'NEW ARRIVAL',
  ),
  Perfume(
    name: 'Mojave Ghost',
    house: 'BYREDO',
    price: 8800,
    family: 'Fresh',
    image: 'photo-1615634260167-c8cdede054de',
    tint: Color(0xFFE1DCD1),
    description:
        'A luminous, soft-woody scent inspired by the desert in bloom.',
    notes: ['Nesberry', 'Magnolia', 'Cedarwood'],
    longevity: '6–8 hours',
  ),
  Perfume(
    name: 'Vanilla Powder',
    house: 'MATIÈRE PREMIÈRE',
    price: 8500,
    family: 'Amber',
    image: 'photo-1595425970377-c9703cf48b6d',
    tint: Color(0xFFE6DFD2),
    description: 'A modern, soft-focus vanilla wrapped in creamy palo santo.',
    notes: ['Almond', 'Vanilla', 'Palo santo'],
    longevity: '8+ hours',
    label: 'EDITOR’S PICK',
  ),
  Perfume(
    name: 'Libre',
    house: 'YVES SAINT LAURENT',
    price: 6500,
    family: 'Floral',
    image: 'photo-1587017539504-67cfbddac569',
    tint: Color(0xFFE7D9C7),
    description: 'A bold meeting of lavender and orange blossom, made for a free spirit.',
    notes: ['Mandarin', 'Orange blossom', 'Madagascar vanilla'],
    longevity: '8+ hours',
    label: 'ICONIC',
  ),
  Perfume(
    name: 'Black Orchid',
    house: 'TOM FORD',
    price: 7800,
    family: 'Amber',
    image: 'photo-1592945403244-b3fbafd7f539',
    tint: Color(0xFFD2C6B9),
    description:
        'A dark, sensual blend of black orchid and rich, warm accords.',
    notes: ['Black truffle', 'Black orchid', 'Patchouli'],
    longevity: '10+ hours',
  ),
  Perfume(
    name: 'Gypsy Water',
    house: 'BYREDO',
    price: 8700,
    family: 'Woody',
    image: 'photo-1615634260167-c8cdede054de',
    tint: Color(0xFFD9D4C8),
    description:
        'A dreamy woodland trail of fresh pine, soft smoke, and vanilla.',
    notes: ['Bergamot', 'Pine needles', 'Vanilla'],
    longevity: '6–8 hours',
  ),
  Perfume(
    name: 'English Pear & Freesia',
    house: 'JO MALONE LONDON',
    price: 5800,
    family: 'Floral',
    image: 'photo-1541643600914-78b084683601',
    tint: Color(0xFFE4DED2),
    description: 'The crisp sweetness of ripe pear softened by white freesia.',
    notes: ['King William pear', 'Freesia', 'Patchouli'],
    longevity: '4–6 hours',
  ),
  Perfume(
    name: 'Neroli Portofino',
    house: 'TOM FORD',
    price: 10000,
    family: 'Fresh',
    image: 'photo-1594035910387-fea47794261f',
    tint: Color(0xFFD8E0DA),
    description:
        'A sparkling Mediterranean escape with citrus and luminous neroli.',
    notes: ['Italian bergamot', 'Neroli', 'Amber'],
    longevity: '4–6 hours',
    label: 'CITRUS FAVORITE',
  ),
  Perfume(
    name: 'Chance Eau Tendre',
    house: 'CHANEL',
    price: 6800,
    family: 'Floral',
    image: 'photo-1596462502278-27bfdc403348',
    tint: Color(0xFFE8D9D7),
    description:
        'A delicate, joyful floral-fruity trail with a soft, luminous finish.',
    notes: ['Grapefruit', 'Jasmine', 'White musk'],
    longevity: '6–8 hours',
    label: 'SOFT FLORAL',
  ),
  Perfume(
    name: 'L’Interdit',
    house: 'GIVENCHY',
    price: 6900,
    family: 'Floral',
    image: 'photo-1585386959984-a4155224a1ad',
    tint: Color(0xFFE1D4C8),
    description:
        'White florals meet a daring, dark accord for an elegant contrast.',
    notes: ['Orange blossom', 'Tuberose', 'Vetiver'],
    longevity: '8+ hours',
  ),
  Perfume(
    name: 'My Way',
    house: 'GIORGIO ARMANI',
    price: 6400,
    family: 'Floral',
    image: 'photo-1608571423902-eed4a5ad8108',
    tint: Color(0xFFE6D9D5),
    description:
        'A bright bouquet of white flowers with a warm, embracing base.',
    notes: ['Bergamot', 'Tuberose', 'Vanilla'],
    longevity: '8+ hours',
    label: 'FLORAL FAVORITE',
  ),
  Perfume(
    name: 'Dylan Blue',
    house: 'VERSACE',
    price: 5000,
    family: 'Fresh',
    image: 'photo-1616949755610-8c9bbc08f138',
    tint: Color(0xFFD4DFE1),
    description:
        'A crisp, modern composition with fresh citrus and aromatic woods.',
    notes: ['Bergamot', 'Black pepper', 'Musk'],
    longevity: '6–8 hours',
  ),
  Perfume(
    name: 'Aqua Allegoria Mandarine Basilic',
    house: 'GUERLAIN',
    price: 6100,
    family: 'Fresh',
    image: 'photo-1563170351-be82bc888aa4',
    tint: Color(0xFFE8DFCC),
    description:
        'Juicy mandarin and aromatic basil evoke a sunlit garden in summer.',
    notes: ['Mandarin', 'Basil', 'Green tea'],
    longevity: '4–6 hours',
    label: 'CITRUS & FRESH',
  ),
];

class StorefrontPage extends StatefulWidget {
  const StorefrontPage({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  State<StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends State<StorefrontPage> {
  final _collectionKey = GlobalKey();
  final _searchController = TextEditingController();
  final Set<String> _favorites = {};
  final Map<String, int> _cart = {};
  List<Perfume> _perfumes = _defaultPerfumes;
  String _selectedFamily = 'All';
  String _searchQuery = '';
  bool _searchOpen = false;
  bool _isLoadingProducts = true;
  String? _productLoadError;

  bool get _isAdmin => widget.isAdmin;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  int get _cartCount => _cart.values.fold(0, (total, count) => total + count);

  String get _userFullName {
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = user?.userMetadata?['full_name'];
    final fullName = metadataName is String ? metadataName.trim() : '';
    return fullName.isNotEmpty ? fullName : user?.email ?? 'Fragrance lover';
  }

  String get _userFirstName => _userFullName.split(RegExp(r'\s+')).first;

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoadingProducts = true;
        _productLoadError = null;
      });
    }
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select()
          .order('name');
      final products = (rows as List<dynamic>)
          .map((row) => Perfume.fromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _perfumes = products;
        _cart.removeWhere(
          (name, quantity) => !products.any((product) => product.name == name),
        );
        _favorites.removeWhere(
          (name) => !products.any((product) => product.name == name),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _perfumes = [];
        _productLoadError = 'Unable to load products: $error';
      });
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _manageProducts() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => const _AdminProductsPage()),
    );
    if (mounted) await _loadProducts();
  }

  List<Perfume> get _visiblePerfumes {
    return _perfumes.where((perfume) {
      final matchesFamily =
          _selectedFamily == 'All' || perfume.family == _selectedFamily;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          perfume.name.toLowerCase().contains(query) ||
          perfume.house.toLowerCase().contains(query) ||
          perfume.family.toLowerCase().contains(query) ||
          perfume.notes.any((note) => note.toLowerCase().contains(query));
      return matchesFamily && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Perfume perfume) {
    setState(
      () => _cart.update(perfume.name, (count) => count + 1, ifAbsent: () => 1),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${perfume.name} added to your bag'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW BAG',
            onPressed: () {
              _showCart();
            },
          ),
        ),
      );
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to log out: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCart() async {
    final checkoutRequested = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final items = _perfumes
              .where((perfume) => _cart.containsKey(perfume.name))
              .toList();
          final subtotal = items.fold<int>(
            0,
            (total, perfume) => total + perfume.price * _cart[perfume.name]!,
          );
          final remainingForShipping = (_freeShippingThreshold - subtotal)
              .clamp(0, _freeShippingThreshold);

          void updateQuantity(Perfume perfume, int change) {
            final quantity = (_cart[perfume.name] ?? 0) + change;
            setState(() {
              if (quantity <= 0) {
                _cart.remove(perfume.name);
              } else {
                _cart[perfume.name] = quantity;
              }
            });
            setSheetState(() {});
          }

          return SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'YOUR BAG  ($_cartCount)',
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close bag',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(color: _line),
                      Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: _gold,
                                      size: 34,
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Your bag is waiting for something unforgettable.',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 18),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        _scrollToCollection();
                                      },
                                      child: const Text('DISCOVER FRAGRANCES'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: items.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(color: _line, height: 1),
                                itemBuilder: (context, index) {
                                  final perfume = items[index];
                                  final quantity = _cart[perfume.name]!;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 64,
                                          height: 76,
                                          child: _PerfumeImage(
                                            perfume: perfume,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                perfume.house,
                                                style: const TextStyle(
                                                  color: _muted,
                                                  fontSize: 9,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                perfume.name,
                                                style: const TextStyle(
                                                  fontFamily: 'Georgia',
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  _QuantityButton(
                                                    label: 'Decrease quantity',
                                                    icon: Icons.remove,
                                                    onPressed: () =>
                                                        updateQuantity(
                                                          perfume,
                                                          -1,
                                                        ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    child: Text('$quantity'),
                                                  ),
                                                  _QuantityButton(
                                                    label: 'Increase quantity',
                                                    icon: Icons.add,
                                                    onPressed: () =>
                                                        updateQuantity(
                                                          perfume,
                                                          1,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₱${perfume.price * quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Remove ${perfume.name}',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () => updateQuantity(
                                                perfume,
                                                -quantity,
                                              ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 19,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (items.isNotEmpty) ...[
                        const Divider(color: _line),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(
                              '₱$subtotal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          remainingForShipping == 0
                              ? 'Your order qualifies for complimentary shipping.'
                              : 'Add ₱$remainingForShipping more for complimentary shipping.',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            style: _primaryButtonStyle(),
                            child: const Text('CONTINUE TO CHECKOUT'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (checkoutRequested == true && mounted) _startCheckout();
  }

  void _startCheckout() {
    final items = _perfumes
        .where((perfume) => _cart.containsKey(perfume.name))
        .toList();
    if (items.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _CheckoutPage(
          perfumes: items,
          quantities: Map<String, int>.unmodifiable(_cart),
          onOrderPlaced: () => setState(_cart.clear),
        ),
      ),
    );
  }

  void _showProduct(Perfume perfume) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: _paper,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 560;
              final image = _PerfumeImage(perfume: perfume, height: 340);
              final details = Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfume.house,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      perfume.name,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(perfume.description),
                    const SizedBox(height: 20),
                    const Text(
                      'THE NOTES',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(perfume.notes.join('  ·  ')),
                    const SizedBox(height: 16),
                    Text(
                      'Eau de Parfum  ·  ${perfume.longevity}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₱${perfume.price}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _addToCart(perfume);
                          },
                          style: _primaryButtonStyle(),
                          child: const Text('ADD TO BAG'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: image),
                    Expanded(child: details),
                  ],
                );
              }
              return SingleChildScrollView(
                child: Column(children: [image, details]),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showScentFinder() {
    const scentFamilies = ['Floral', 'Woody', 'Fresh', 'Amber'];
    const occasions = ['Everyday', 'A special evening', 'A little escape'];
    var step = 0;
    var family = 'Floral';
    var occasion = 'Everyday';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isResult = step == 2;
          final matches = _perfumes
              .where((p) => p.family == family)
              .take(3)
              .toList();
          return AlertDialog(
            backgroundColor: _paper,
            insetPadding: const EdgeInsets.all(20),
            title: Text(
              isResult ? 'A scent, just for you' : 'Find your fragrance',
              style: const TextStyle(fontFamily: 'Georgia', fontSize: 26),
            ),
            content: SizedBox(
              width: 430,
              child: isResult
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your $occasion edit, chosen for its $family character.',
                        ),
                        const SizedBox(height: 14),
                        ...matches.map(
                          (perfume) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(perfume.name),
                            subtitle: Text(
                              '${perfume.house}  ·  ${perfume.notes.first}',
                            ),
                            trailing: Text('₱${perfume.price}'),
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _showProduct(perfume);
                            },
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step == 0
                              ? 'Which scent family feels like you?'
                              : 'When will you wear your new scent?',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option
                                in step == 0 ? scentFamilies : occasions)
                              ChoiceChip(
                                label: Text(option),
                                selected:
                                    (step == 0 ? family : occasion) == option,
                                selectedColor: const Color(0xFFE8E0D2),
                                onSelected: (_) {
                                  setDialogState(() {
                                    if (step == 0) {
                                      family = option;
                                    } else {
                                      occasion = option;
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(isResult ? 'CLOSE' : 'NOT NOW'),
              ),
              if (!isResult)
                FilledButton(
                  onPressed: () => setDialogState(() => step++),
                  style: _primaryButtonStyle(),
                  child: Text(step == 0 ? 'NEXT' : 'SEE MY EDIT'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _scrollToCollection() {
    Scrollable.ensureVisible(
      _collectionKey.currentContext!,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            final horizontalPadding = constraints.maxWidth >= 1200
                ? (constraints.maxWidth - 1160) / 2
                : isWide
                ? 44.0
                : 20.0;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _AnnouncementBar(horizontalPadding: horizontalPadding),
                ),
                SliverToBoxAdapter(
                  child: _buildHeader(isWide, horizontalPadding),
                ),
                SliverToBoxAdapter(
                  child: _buildHero(isWide, horizontalPadding),
                ),
                SliverToBoxAdapter(
                  child: _buildPromises(horizontalPadding, isWide),
                ),
                SliverToBoxAdapter(
                  child: _buildCollection(horizontalPadding, isWide),
                ),
                SliverToBoxAdapter(
                  child: _buildFinderBanner(horizontalPadding, isWide),
                ),
                SliverToBoxAdapter(
                  child: _buildFooter(horizontalPadding, isWide),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildHeader(bool isWide, double horizontalPadding) {
    return Container(
      color: _paper,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          SizedBox(
            height: 82,
            child: Row(
              children: [
                if (!isWide)
                  IconButton(
                    tooltip: 'Shop collection',
                    onPressed: _scrollToCollection,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                if (isWide) const SizedBox(width: 46),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedFamily = 'All';
                        _searchQuery = '';
                        _searchController.clear();
                      }),
                      child: const Text(
                        'S I L L A G E',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 21,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isAdmin && isWide)
                  IconButton(
                    tooltip: 'Manage products',
                    onPressed: _manageProducts,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                  ),
                IconButton(
                  tooltip: _searchOpen ? 'Close search' : 'Search fragrances',
                  onPressed: () => setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  }),
                  icon: Icon(_searchOpen ? Icons.close : Icons.search_rounded),
                ),
                const SizedBox(width: 4),
                if (isWide) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      _userFullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('LOG OUT'),
                    style: TextButton.styleFrom(
                      foregroundColor: _ink,
                      textStyle: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else
                  IconButton(
                    tooltip: 'Log out ($_userFirstName)',
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                  ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _showCart,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 19),
                  label: Text('BAG ($_cartCount)'),
                  style: TextButton.styleFrom(
                    foregroundColor: _ink,
                    textStyle: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AppExplainerVideo(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('WATCH STORY'),
                ),
              ],
            ),
          ),
          if (_isAdmin && !isWide)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _manageProducts,
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('MANAGE PRODUCTS'),
                style: TextButton.styleFrom(
                  foregroundColor: _ink,
                  textStyle: const TextStyle(fontSize: 9, letterSpacing: 0.8),
                ),
              ),
            ),
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by fragrance, house or note',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          if (isWide)
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavLink(label: 'SHOP ALL', onTap: _scrollToCollection),
                  _NavLink(
                    label: 'WOMEN',
                    onTap: () {
                      setState(() => _selectedFamily = 'Floral');
                      _scrollToCollection();
                    },
                  ),
                  _NavLink(
                    label: 'MEN',
                    onTap: () {
                      setState(() => _selectedFamily = 'Woody');
                      _scrollToCollection();
                    },
                  ),
                  _NavLink(label: 'DISCOVER', onTap: _showScentFinder),
                  _NavLink(
                    label: 'OUR WORLD',
                    onTap: () => _showInfo(
                      'A more considered way to discover fragrance.',
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: _line),
        ],
      ),
    );
  }

  Widget _buildHero(bool isWide, double horizontalPadding) {
    final copy = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 0 : 22,
        vertical: isWide ? 48 : 34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WELCOME BACK, $_userFirstName',
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.8,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'THE ART OF SCENT',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              color: _gold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Find the one\nthat feels like you.',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 48,
              height: 1.12,
              letterSpacing: -1.7,
              color: _ink,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'A thoughtful collection of fine fragrances,\nchosen to become part of your story.',
            style: TextStyle(color: _muted, fontSize: 14, height: 1.8),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _scrollToCollection,
                style: _primaryButtonStyle(),
                child: const Text('EXPLORE THE COLLECTION'),
              ),
              OutlinedButton(
                onPressed: _showScentFinder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _ink),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  textStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
                ),
                child: const Text('FIND YOUR SCENT'),
              ),
            ],
          ),
        ],
      ),
    );

    final visual = SizedBox(
      height: isWide ? 500 : 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&w=1500&q=85',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => const _HeroFallback(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  const Color(0xFF1E1A16).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: _paper.withValues(alpha: 0.92),
              child: const Text(
                'A SCENT IS A MEMORY, MADE VISIBLE.',
                style: TextStyle(fontSize: 9, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: isWide
          ? SizedBox(
              height: 500,
              child: Row(
                children: [
                  Expanded(flex: 5, child: copy),
                  const SizedBox(width: 28),
                  Expanded(flex: 6, child: visual),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, visual],
            ),
    );
  }

  Widget _buildPromises(double horizontalPadding, bool isWide) {
    final items = [
      (
        Icons.spa_outlined,
        'Curated with care',
        'Only the exceptional, always.',
      ),
      (
        Icons.card_giftcard_outlined,
        'A gift from us',
        'Two samples with every order.',
      ),
      (
        Icons.local_shipping_outlined,
        'Complimentary delivery',
        'On orders over ₱$_freeShippingThreshold.',
      ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        28,
        horizontalPadding,
        28,
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: _line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: isWide
            ? Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      const SizedBox(
                        height: 32,
                        child: VerticalDivider(color: _line, width: 1),
                      ),
                    Expanded(
                      child: _PromiseItem(
                        icon: items[i].$1,
                        title: items[i].$2,
                        subtitle: items[i].$3,
                      ),
                    ),
                  ],
                ],
              )
            : Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _PromiseItem(
                        icon: item.$1,
                        title: item.$2,
                        subtitle: item.$3,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCollection(double horizontalPadding, bool isWide) {
    final products = _visiblePerfumes;
    return Container(
      key: _collectionKey,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        52,
        horizontalPadding,
        70,
      ),
      color: const Color(0xFFF4F2ED),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: const [
                Text(
                  'A COLLECTION TO COME BACK TO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.3,
                    color: _gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Considered, never ordinary.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 34,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildFilters(isWide),
          const SizedBox(height: 22),
          if (_isLoadingProducts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 54),
              child: Center(child: CircularProgressIndicator(color: _gold)),
            )
          else if (_productLoadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _productLoadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadProducts,
                      child: const Text('TRY AGAIN'),
                    ),
                  ],
                ),
              ),
            )
          else if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 54),
              child: Center(
                child: Text(
                  'No fragrances match that search. Try another note.',
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1050
                    ? 4
                    : constraints.maxWidth >= 700
                    ? 3
                    : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: isWide ? 20 : 12,
                    mainAxisSpacing: 24,
                    childAspectRatio: columns == 2 ? 0.58 : 0.67,
                  ),
                  itemBuilder: (context, index) {
                    final perfume = products[index];
                    return _ProductCard(
                      perfume: perfume,
                      isFavorite: _favorites.contains(perfume.name),
                      onFavorite: () => setState(() {
                        if (!_favorites.add(perfume.name)) {
                          _favorites.remove(perfume.name);
                        }
                      }),
                      onTap: () => _showProduct(perfume),
                      onAdd: () => _addToCart(perfume),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 38),
          Center(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedFamily = 'All';
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _ink),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 17,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                textStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
              ),
              child: const Text('VIEW ALL FRAGRANCES'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isWide) {
    const families = ['All', 'Floral', 'Woody', 'Fresh', 'Amber'];
    return Row(
      children: [
        if (isWide)
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Text(
              'EXPLORE BY FAMILY',
              style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: _muted),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final family in families)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(family),
                      selected: _selectedFamily == family,
                      onSelected: (_) =>
                          setState(() => _selectedFamily = family),
                      selectedColor: _ink,
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: _selectedFamily == family ? _ink : _line,
                      ),
                      labelStyle: TextStyle(
                        color: _selectedFamily == family ? _paper : _ink,
                        fontSize: 11,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isWide)
          Text(
            '${_visiblePerfumes.length} FRAGRANCES',
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildFinderBanner(double horizontalPadding, bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        64,
        horizontalPadding,
        64,
      ),
      child: Container(
        color: const Color(0xFF312E29),
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 56 : 24,
          vertical: isWide ? 44 : 32,
        ),
        child: isWide
            ? Row(
                children: [
                  const Expanded(child: _FinderCopy()),
                  const SizedBox(width: 28),
                  OutlinedButton(
                    onPressed: _showScentFinder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _paper,
                      side: const BorderSide(color: Color(0xFFB8A17A)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    child: const Text('TAKE THE SCENT QUIZ'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FinderCopy(),
                  const SizedBox(height: 22),
                  OutlinedButton(
                    onPressed: _showScentFinder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _paper,
                      side: const BorderSide(color: Color(0xFFB8A17A)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('TAKE THE SCENT QUIZ'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter(double horizontalPadding, bool isWide) {
    return Container(
      color: const Color(0xFFEEECE6),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        34,
        horizontalPadding,
        26,
      ),
      child: Column(
        children: [
          if (isWide)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'S I L L A G E',
                  style: TextStyle(fontFamily: 'Georgia', letterSpacing: 1.4),
                ),
                const Text(
                  'A considered collection of fine fragrance.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                TextButton(
                  onPressed: () => _showInfo(
                    'Our fragrance specialists are here to help you discover something lasting.',
                  ),
                  child: const Text('CONTACT'),
                ),
              ],
            )
          else
            const Column(
              children: [
                Text(
                  'S I L L A G E',
                  style: TextStyle(fontFamily: 'Georgia', letterSpacing: 1.4),
                ),
                SizedBox(height: 8),
                Text(
                  'A considered collection of fine fragrance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          const Divider(height: 30, color: _line),
          const Text(
            '© 2025 SILLAGE  ·  FRAGRANCE, FOUND.',
            style: TextStyle(fontSize: 9, letterSpacing: 1, color: _muted),
          ),
        ],
      ),
    );
  }

  void _showInfo(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutPage extends StatefulWidget {
  const _CheckoutPage({
    required this.perfumes,
    required this.quantities,
    required this.onOrderPlaced,
  });

  final List<Perfume> perfumes;
  final Map<String, int> quantities;
  final VoidCallback onOrderPlaced;

  @override
  State<_CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _giftMessageController = TextEditingController();
  String _delivery = 'Standard';
  String _paymentMethod = 'Xendit';
  bool _giftWrap = false;
  String? _orderNumber;
  bool _showingPaymentQr = false;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _paymentLinkSubscription;
  String? _xenditExternalId;
  String? _xenditInvoiceUrl;
  int? _xenditInvoiceAmount;
  String _xenditPaymentStatus = 'Not started';
  String? _xenditError;
  bool _creatingXenditInvoice = false;
  bool _checkingXenditPayment = false;

  int get _subtotal => widget.perfumes.fold(
    0,
    (total, perfume) =>
        total + perfume.price * widget.quantities[perfume.name]!,
  );

  int get _shipping {
    if (_delivery == 'Express') return 25;
    return _subtotal >= _freeShippingThreshold ? 0 : 12;
  }

  int get _total => _subtotal + _shipping + (_giftWrap ? 8 : 0);
  bool get _xenditInvoiceIsTerminal =>
      _xenditPaymentStatus == 'EXPIRED' || _xenditPaymentStatus == 'FAILED';
  bool get _hasActiveXenditInvoice =>
      _xenditExternalId != null && !_xenditInvoiceIsTerminal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();
    _paymentLinkSubscription = _appLinks.uriLinkStream.listen(
      _handlePaymentLink,
      onError: (Object error) {
        if (mounted) {
          setState(
            () => _xenditError = 'Unable to receive payment return: $error',
          );
        }
      },
    );
    unawaited(_readInitialPaymentLink());
  }

  Future<void> _readInitialPaymentLink() async {
    try {
      final link = await _appLinks.getInitialLink();
      if (link != null) _handlePaymentLink(link);
    } catch (error) {
      if (mounted) {
        setState(() => _xenditError = 'Unable to read payment return: $error');
      }
    }
  }

  void _handlePaymentLink(Uri uri) {
    final isSupportedAppLink =
        uri.scheme == 'sillage' &&
        ((uri.host == 'payment' && uri.path == '/return') ||
            uri.host == 'dashboard');
    if (!isSupportedAppLink) return;

    final externalId = uri.queryParameters['external_id'];
    final result = uri.queryParameters['result'];
    if (externalId == null || externalId.isEmpty || !mounted) return;

    if (result == 'success' || result == 'failure') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      });
    }

    setState(() {
      _xenditExternalId = externalId;
      _xenditPaymentStatus = 'Checking';
      _xenditError = null;
    });
    unawaited(_checkXenditPayment(externalId: externalId));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _xenditExternalId != null) {
      unawaited(_checkXenditPayment());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_paymentLinkSubscription?.cancel());
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_paymentMethod == 'Xendit') {
      if (_xenditInvoiceIsTerminal) {
        setState(() {
          _xenditExternalId = null;
          _xenditInvoiceUrl = null;
          _xenditInvoiceAmount = null;
          _xenditError = null;
        });
      }
      unawaited(_createXenditInvoice());
      return;
    }
    if (_paymentMethod == 'GCash' && !_showingPaymentQr) {
      setState(() => _showingPaymentQr = true);
      return;
    }
    if (_showingPaymentQr) {
      setState(() => _showingPaymentQr = false);
    }
    final orderNumber = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .substring(0, 8)
        .toUpperCase();
    widget.onOrderPlaced();
    setState(() => _orderNumber = orderNumber);
  }

  Future<void> _createXenditInvoice() async {
    if (_creatingXenditInvoice) return;
    if (widget.perfumes.isEmpty || widget.perfumes.length > 30) {
      setState(
        () => _xenditError = 'Your cart has an invalid number of items.',
      );
      return;
    }
    final products = <Map<String, dynamic>>[];
    final productIds = <String>{};
    var subtotal = 0;
    const maxSafeInteger = 9007199254740991;
    final String delivery = _delivery;
    final bool giftWrap = _giftWrap;
    for (final perfume in widget.perfumes) {
      final id = perfume.id;
      if (id == null || id.isEmpty || !productIds.add(id)) {
        setState(
          () => _xenditError = 'A product is missing a valid database ID. Refresh the catalog and try again.',
        );
        return;
      }
      final rawQuantity = widget.quantities[perfume.name] ?? 0;
      final quantityText = rawQuantity.toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final quantity = int.tryParse(quantityText);
      final priceText = perfume.price.toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final price = int.tryParse(priceText);
      if (rawQuantity < 1 ||
          perfume.price < 1 ||
          quantity == null ||
          quantity < 1 ||
          quantity > 20 ||
          price == null ||
          price < 1 ||
          price > maxSafeInteger) {
        setState(
          () => _xenditError = 'A checkout product has invalid pricing.',
        );
        return;
      }
      final int lineTotal = price * quantity;
      if (lineTotal > maxSafeInteger || subtotal > maxSafeInteger - lineTotal) {
        setState(() => _xenditError = 'The checkout total is too large.');
        return;
      }
      subtotal += lineTotal;
      products.add({'id': id, 'quantity': quantity, 'price': price});
    }
    if (products.isEmpty || (delivery != 'Standard' && delivery != 'Express')) {
      setState(() => _xenditError = 'Your checkout details are invalid.');
      return;
    }
    final int shippingFee = delivery == 'Express'
        ? 25
        : subtotal >= _freeShippingThreshold
        ? 0
        : 12;
    final int giftWrapFee = giftWrap ? 8 : 0;
    final int amount = subtotal + shippingFee + giftWrapFee;
    if (amount < 1 || amount > maxSafeInteger) {
      setState(() => _xenditError = 'A checkout product has invalid pricing.');
      return;
    }

    setState(() {
      _creatingXenditInvoice = true;
      _xenditError = null;
      _xenditPaymentStatus = 'Creating invoice';
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'xendit-payment',
        body: {
          'action': 'create',
          'items': products,
          'amount': amount,
          'delivery': delivery,
          'gift_wrap': giftWrap,
          'payer_name': _nameController.text.trim(),
          'payer_email': _emailController.text.trim(),
          'payer_phone': _phoneController.text.trim(),
        },
      );
      final data = response.data;
      if (data is! Map ||
          data['external_id'] is! String ||
          data['invoice_url'] is! String ||
          data['amount'] is! num) {
        throw const FormatException(
          'The payment service returned an invalid invoice.',
        );
      }
      if (!mounted) return;
      setState(() {
        _xenditExternalId = data['external_id'] as String;
        _xenditInvoiceUrl = data['invoice_url'] as String;
        _xenditInvoiceAmount = (data['amount'] as num).toInt();
        _xenditPaymentStatus = 'PENDING';
      });
      await _openXenditInvoice();
    } catch (error) {
      if (mounted) {
        setState(() {
          _xenditPaymentStatus = 'Not started';
          _xenditError = 'Unable to create Xendit payment: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _creatingXenditInvoice = false);
    }
  }

  Future<void> _openXenditInvoice() async {
    final invoiceUrl = _xenditInvoiceUrl;
    final uri = invoiceUrl == null ? null : Uri.tryParse(invoiceUrl);
    if (uri == null || uri.scheme != 'https') {
      setState(
        () => _xenditError =
            'The payment service returned an invalid checkout URL.',
      );
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No browser app could open the Xendit checkout.');
      }
      if (mounted) setState(() => _xenditError = null);
    } catch (error) {
      if (mounted) {
        setState(() => _xenditError = 'Unable to open Xendit checkout: $error');
      }
    }
  }

  Future<void> _checkXenditPayment({String? externalId}) async {
    final invoiceExternalId = externalId ?? _xenditExternalId;
    if (invoiceExternalId == null || _checkingXenditPayment) return;
    setState(() {
      _checkingXenditPayment = true;
      _xenditError = null;
      _xenditPaymentStatus = 'Checking';
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'xendit-payment',
        body: {'action': 'status', 'external_id': invoiceExternalId},
      );
      final data = response.data;
      if (data is! Map || data['status'] is! String) {
        throw const FormatException(
          'The payment service returned an invalid status.',
        );
      }
      final status = (data['status'] as String).toUpperCase();
      if (status == 'PAID' || status == 'SETTLED') {
        if (_orderNumber == null) {
          final suffix = invoiceExternalId.substring(
            invoiceExternalId.length > 8 ? invoiceExternalId.length - 8 : 0,
          );
          widget.onOrderPlaced();
          setState(() {
            _xenditPaymentStatus = status;
            _orderNumber = suffix.toUpperCase();
            _paymentMethod = 'Xendit';
          });
        } else {
          setState(() => _xenditPaymentStatus = status);
        }
      } else {
        setState(() => _xenditPaymentStatus = status);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _xenditPaymentStatus = 'Unable to verify';
          _xenditError = 'Unable to verify Xendit payment: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _checkingXenditPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = _orderNumber;
    final showingPaymentQr = orderNumber == null && _showingPaymentQr;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        title: Text(
          orderNumber != null
              ? 'ORDER CONFIRMED'
              : showingPaymentQr
              ? 'GCASH PAYMENT'
              : 'CHECKOUT',
          style: const TextStyle(fontSize: 12, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: orderNumber != null
          ? _buildConfirmation(orderNumber)
          : showingPaymentQr
          ? _buildDemoPaymentQr()
          : _buildCheckout(),
      bottomNavigationBar: orderNumber == null
          ? SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: _paper,
                  border: Border(top: BorderSide(color: _line)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 712),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _paymentMethod == 'Xendit' &&
                              _xenditExternalId != null
                          ? _xenditInvoiceIsTerminal
                                ? _placeOrder
                                : _checkingXenditPayment
                                ? null
                                : () => unawaited(_checkXenditPayment())
                          : _creatingXenditInvoice
                          ? null
                          : _placeOrder,
                      style: _primaryButtonStyle(),
                      child: Text(
                        _paymentMethod == 'Xendit'
                            ? _creatingXenditInvoice
                                  ? 'CREATING PAYMENT...'
                                  : _xenditExternalId != null
                                  ? _xenditInvoiceIsTerminal
                                        ? 'TRY PAYMENT AGAIN · ₱$_total'
                                        : 'CHECK PAYMENT · ₱${_xenditInvoiceAmount ?? _total}'
                                  : 'PAY WITH XENDIT · ₱$_total'
                            : showingPaymentQr
                            ? 'CONTINUE · ₱$_total'
                            : _paymentMethod == 'GCash'
                            ? 'SHOW QR · ₱$_total'
                            : 'PLACE ORDER · ₱$_total',
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCheckout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Form(
          key: _formKey,
          child: ListView(
            primary: false,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              const Text(
                'A few details, then it’s yours.',
                style: TextStyle(fontFamily: 'Georgia', fontSize: 30),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your delivery details to place your order.',
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 26),
              _checkoutSectionTitle('1. DELIVERY DETAILS'),
              const SizedBox(height: 14),
              _textField(
                controller: _nameController,
                label: 'Full name',
                textCapitalization: TextCapitalization.words,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _emailController,
                label: 'Email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final requiredError = _requiredValidator(value);
                  if (requiredError != null) return requiredError;
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(value!.trim())) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _phoneController,
                label: 'Phone (optional)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _addressController,
                label: 'Street address',
                textCapitalization: TextCapitalization.words,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 480) {
                    return Column(
                      children: [
                        _textField(
                          controller: _cityController,
                          label: 'City',
                          textCapitalization: TextCapitalization.words,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _postalController,
                          label: 'Postal code',
                          validator: _requiredValidator,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _textField(
                          controller: _cityController,
                          label: 'City',
                          textCapitalization: TextCapitalization.words,
                          validator: _requiredValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(
                          controller: _postalController,
                          label: 'Postal code',
                          validator: _requiredValidator,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              _checkoutSectionTitle('2. DELIVERY METHOD'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _delivery,
                isExpanded: true,
                decoration: _inputDecoration('Select delivery'),
                items: const [
                  DropdownMenuItem(
                    value: 'Standard',
                    child: Text('Standard · 3–5 business days'),
                  ),
                  DropdownMenuItem(
                    value: 'Express',
                    child: Text('Express · 1–2 business days (+₱25)'),
                  ),
                ],
                onChanged: _hasActiveXenditInvoice
                    ? null
                    : (value) {
                        if (value != null) setState(() => _delivery = value);
                      },
              ),
              const SizedBox(height: 22),
              _checkoutSectionTitle('3. PAYMENT METHOD'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _line),
                  color: const Color(0xFFF7F3EE),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18, color: _gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Xendit · Secure online payment',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                                         const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: const Color(0xFFF0EEE8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 17, color: _gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pay securely through Xendit. You will return here to verify your payment status.',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (_xenditExternalId != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: Border.all(color: _line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYMENT STATUS · $_xenditPaymentStatus',
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_xenditInvoiceAmount != null) ...[
                        const SizedBox(height: 6),
                        Text('INVOICE TOTAL · ₱$_xenditInvoiceAmount'),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _xenditInvoiceIsTerminal
                                ? null
                                : _openXenditInvoice,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('OPEN PAYMENT PAGE'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _checkingXenditPayment
                                ? null
                                : () => unawaited(_checkXenditPayment()),
                            icon: _checkingXenditPayment
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: const Text('CHECK STATUS'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (_xenditError != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _xenditError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _checkoutSectionTitle('4. MAKE IT A GIFT'),
              const SizedBox(height: 6),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _ink,
                title: const Text('Add gift wrapping · ₱8'),
                subtitle: const Text('A thoughtful finishing touch.'),
                value: _giftWrap,
                onChanged: _hasActiveXenditInvoice
                    ? null
                    : (value) => setState(() => _giftWrap = value ?? false),
              ),
              if (_giftWrap) ...[
                const SizedBox(height: 8),
                _textField(
                  controller: _giftMessageController,
                  label: 'Gift message (optional)',
                  maxLines: 3,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
              const SizedBox(height: 26),
              _checkoutSectionTitle('5. ORDER SUMMARY'),
              const SizedBox(height: 12),
              for (final perfume in widget.perfumes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${perfume.name}  ×  ${widget.quantities[perfume.name]}',
                        ),
                      ),
                      Text(
                        '₱${perfume.price * widget.quantities[perfume.name]!}',
                      ),
                    ],
                  ),
                ),
              const Divider(color: _line, height: 24),
              _priceRow('Subtotal', _subtotal),
              const SizedBox(height: 8),
              _priceRow(
                'Shipping',
                _shipping,
                detail: _shipping == 0 ? 'Complimentary' : _delivery,
              ),
              if (_giftWrap) ...[
                const SizedBox(height: 8),
                _priceRow('Gift wrap', 8),
              ],
              const Divider(color: _line, height: 24),
              _priceRow('Total', _total, isTotal: true),
              const SizedBox(height: 18),
              if (_paymentMethod != 'Xendit')
                Container(
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFFF0EEE8),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 17, color: _gold),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Checkout preview only. Placing this order will show a confirmation, but no payment is collected.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoPaymentQr() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              const Text(
                'GCash payment',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Georgia', fontSize: 32),
              ),
              const SizedBox(height: 10),
              const Text(
                'GCash payments are not available yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                color: Colors.white,
                child: const CustomPaint(
                  size: Size.square(240),
                  painter: _DemoQrPainter(),
                  child: SizedBox(width: 240, height: 240),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'ORDER TOTAL  ₱$_total',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Continue to place the order. No payment will be collected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showingPaymentQr = false),
                child: const Text('BACK TO CHECKOUT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation(String orderNumber) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8E0D2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: _ink, size: 32),
              ),
              const SizedBox(height: 24),
              const Text(
                'A beautiful choice.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Georgia', fontSize: 34),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your order has been placed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: const Color(0xFFF0EEE8),
                child: Column(
                  children: [
                    const Text(
                      'ORDER REFERENCE',
                      style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SIL-$orderNumber',
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'PAYMENT METHOD',
                      style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _paymentMethod,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A confirmation${_emailController.text.trim().isEmpty ? '' : ' will be sent to ${_emailController.text.trim()}'} (preview only).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _paymentMethod == 'Xendit'
                    ? 'Payment was verified with Xendit. Keep your order reference for support.'
                    : 'No payment was collected, and the order was not sent to a fulfillment service.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: _primaryButtonStyle(),
                  child: const Text('BACK TO THE BOUTIQUE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    return null;
  }

  Widget _checkoutSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: _line),
        borderRadius: BorderRadius.zero,
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _line),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _gold),
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  Widget _priceRow(
    String label,
    int amount, {
    String? detail,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? _ink : _muted,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (detail != null) ...[
          Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(width: 12),
        ],
        Text(
          '₱$amount',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _DemoQrPainter extends CustomPainter {
  const _DemoQrPainter();

  static const _modules = 29;

  @override
  void paint(Canvas canvas, Size size) {
    final moduleSize = size.width / _modules;
    final darkPaint = Paint()..color = _ink;
    final lightPaint = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, lightPaint);
    for (var row = 0; row < _modules; row++) {
      for (var column = 0; column < _modules; column++) {
        final finder = _finderValue(row, column);
        final value =
            finder ??
            ((row * 17 + column * 31 + row * column * 7 + (row ^ column) * 13) %
                    11 <
                5);
        if (value) {
          canvas.drawRect(
            Rect.fromLTWH(
              column * moduleSize,
              row * moduleSize,
              moduleSize,
              moduleSize,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  bool? _finderValue(int row, int column) {
    for (final position in const [(0, 0), (0, 22), (22, 0)]) {
      final startRow = position.$1;
      final startColumn = position.$2;
      final localRow = row - startRow;
      final localColumn = column - startColumn;
      if (localRow < 0 ||
          localRow >= 7 ||
          localColumn < 0 ||
          localColumn >= 7) {
        continue;
      }
      final isOuter =
          localRow == 0 ||
          localRow == 6 ||
          localColumn == 0 ||
          localColumn == 6;
      final isCenter =
          localRow >= 2 &&
          localRow <= 4 &&
          localColumn >= 2 &&
          localColumn <= 4;
      return isOuter || isCenter;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _DemoQrPainter oldDelegate) => false;
}

class _AuthenticationPage extends StatefulWidget {
  const _AuthenticationPage();

  @override
  State<_AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<_AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _rememberMe = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _passwordHasMinLength => _passwordController.text.length >= 8;
  bool get _passwordHasUppercase =>
      RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _passwordHasNumber =>
      RegExp(r'\d').hasMatch(_passwordController.text);
  bool get _passwordHasSpecial =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (!_passwordHasMinLength ||
        !_passwordHasUppercase ||
        !_passwordHasNumber ||
        !_passwordHasSpecial) {
      return 'Password does not meet all requirements.';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_isLogin) {
        await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'full_name': _fullNameController.text.trim()},
        );
        if (response.session == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Check your email to confirm your SILLAGE account.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Authentication failed: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final emailError = _emailValidator(_emailController.text);
    if (emailError != null) {
      setState(() => _errorMessage = 'Enter your email address first.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists, a password reset link is on its way.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to send reset email: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Google sign-in failed: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 860;

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        centerTitle: true,
        title: const Text(
          'ACCOUNT',
          style: TextStyle(fontSize: 11, letterSpacing: 2.2),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 1280,
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 36 : 20,
                      vertical: isWide ? 18 : 12,
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: _buildFormPanel()),
                              const SizedBox(width: 28),
                              Expanded(flex: 5, child: _buildEditorialVisual()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildFormPanel(),
                              const SizedBox(height: 20),
                              _buildEditorialVisual(),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'S I L L A G E',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A considered fragrance ritual.',
              style: TextStyle(color: _muted, fontSize: 12, letterSpacing: 1.2),
            ),
            const SizedBox(height: 26),
            ToggleButtons(
              isSelected: [_isLogin, !_isLogin],
              onPressed: _isLoading
                  ? null
                  : (index) => setState(() {
                      _isLogin = index == 0;
                      _errorMessage = null;
                    }),
              borderRadius: BorderRadius.circular(0),
              borderColor: _line,
              selectedBorderColor: _ink,
              fillColor: _ink,
              selectedColor: _paper,
              color: _ink,
              renderBorder: true,
              constraints: const BoxConstraints(minHeight: 42, minWidth: 120),
              children: const [
                Text(
                  'LOG IN',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                ),
                Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.1),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_isLogin)
              _authField(
                controller: _fullNameController,
                hintText: 'Full name',
                validator: _requiredValidator,
                textCapitalization: TextCapitalization.words,
              ),
            if (!_isLogin) const SizedBox(height: 12),
            _authField(
              controller: _emailController,
              hintText: 'Email address',
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: 12),
            _authField(
              controller: _passwordController,
              hintText: 'Password',
              obscureText: !_showPassword,
              validator: _isLogin ? _requiredValidator : _passwordValidator,
              onChanged: (_) {
                if (!_isLogin) setState(() {});
              },
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                color: _muted,
                splashRadius: 18,
              ),
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 12),
              _authField(
                controller: _confirmPasswordController,
                hintText: 'Confirm password',
                obscureText: !_showConfirmPassword,
                validator: _confirmPasswordValidator,
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  color: _muted,
                  splashRadius: 18,
                ),
              ),
            ],
            if (_isLogin) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: _ink,
                    onChanged: (value) =>
                        setState(() => _rememberMe = value ?? true),
                  ),
                  const Text('Remember me', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: _gold,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              _buildPasswordRequirements(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFF9E3B3B), fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: _primaryButtonStyle(),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _paper,
                        ),
                      )
                    : Text(_isLogin ? 'LOG IN' : 'CREATE ACCOUNT'),
              ),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'or continue with',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: const Text('SIGN IN WITH GOOGLE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _ink),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  textStyle: const TextStyle(fontSize: 10, letterSpacing: 1.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final checks = [
      (_passwordHasMinLength, 'Minimum 8 characters'),
      (_passwordHasUppercase, 'One uppercase letter'),
      (_passwordHasNumber, 'One number'),
      (_passwordHasSpecial, 'One special character'),
    ];

    return Column(
      children: [
        const Text(
          'Password requirements',
          style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        ...checks.map(
          (check) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: check.$1 ? const Color(0xFF2E4F42) : _muted,
                ),
                const SizedBox(width: 8),
                Text(
                  check.$2,
                  style: TextStyle(
                    color: check.$1 ? _ink : _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorialVisual() {
    final isWide = MediaQuery.sizeOf(context).width >= 860;
    return Container(
      height: isWide ? 760 : 340,
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(border: Border.all(color: _line)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1523293182086-7651a899d37f?auto=format&fit=crop&w=1200&q=80',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0xFFE8E0D7),
              child: Center(
                child: Icon(Icons.spa_outlined, size: 60, color: _ink),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF1A1715).withValues(alpha: 0.62),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'THE ART OF SCENT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.2,
                    color: Color(0xFFD0B98F),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'A little ritual. A lasting memory.',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 30,
                    height: 1.15,
                    color: _paper,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _authField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      enabled: !_isLoading,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _line),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _gold),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF9E3B3B)),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF9E3B3B)),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF302D28),
      height: 32,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: const Text(
        'COMPLIMENTARY SHIPPING ON ORDERS OVER ₱$_freeShippingThreshold',
        style: TextStyle(
          color: _paper,
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _ink,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: const TextStyle(fontSize: 9, letterSpacing: 1.1),
      ),
      child: Text(label),
    );
  }
}

class _PromiseItem extends StatelessWidget {
  const _PromiseItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _gold, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _FinderCopy extends StatelessWidget {
  const _FinderCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A LITTLE GUIDANCE, A LOT MORE YOU',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.8,
            color: Color(0xFFD0B98F),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Your next signature scent\nis closer than you think.',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 28,
            height: 1.25,
            color: _paper,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Three small questions. One lovely place to start.',
          style: TextStyle(color: Color(0xFFCCC7BD), fontSize: 12),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 15,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: _line),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.perfume,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
    required this.onAdd,
  });

  final Perfume perfume;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Material(
                color: perfume.tint,
                child: InkWell(
                  onTap: onTap,
                  child: _PerfumeImage(perfume: perfume),
                ),
              ),
              if (perfume.label != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    color: _paper.withValues(alpha: 0.94),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      perfume.label!,
                      style: const TextStyle(fontSize: 8, letterSpacing: 0.8),
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 19,
                    color: isFavorite ? const Color(0xFF8E554B) : _ink,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _paper.withValues(alpha: 0.82),
                    minimumSize: const Size(34, 34),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: IconButton(
                  tooltip: 'Quick add ${perfume.name}',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 19),
                  style: IconButton.styleFrom(
                    backgroundColor: _paper.withValues(alpha: 0.94),
                    foregroundColor: _ink,
                    minimumSize: const Size(38, 38),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          perfume.house,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Text(
            perfume.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Georgia', fontSize: 16),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: Text(
                '${perfume.family}  ·  50 ml',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
            ),
            Text(
              '₱${perfume.price}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _PerfumeImage extends StatelessWidget {
  const _PerfumeImage({required this.perfume, this.height});

  final Perfume perfume;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = _productImageUrl(perfume.image);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: perfume.tint,
          child: Center(
            child: Icon(
              Icons.spa_outlined,
              color: _ink.withValues(alpha: 0.32),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

String _productImageUrl(String image) {
  final uri = Uri.tryParse(image);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return image;
  }
  return 'https://images.unsplash.com/$image?auto=format&fit=crop&w=900&q=80';
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC8B7A1), Color(0xFF655547)],
        ),
      ),
      child: Center(
        child: Icon(Icons.spa_outlined, size: 72, color: Color(0x99FFFFFF)),
      ),
    );
  }
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _ink,
    foregroundColor: _paper,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    textStyle: const TextStyle(
      fontSize: 10,
      letterSpacing: 1,
      fontWeight: FontWeight.w500,
    ),
  );
}

class AppExplainerVideo extends StatefulWidget {
  const AppExplainerVideo({super.key});

  @override
  State<AppExplainerVideo> createState() => _AppExplainerVideoState();
}

class _AppExplainerVideoState extends State<AppExplainerVideo> {
  late final Timer _videoTimer;
  int _currentChapter = 0;
  bool _isPlaying = true;

  final List<Map<String, String>> _chapters = [
    {
      'title': 'S I L L A G E',
      'subtitle': 'Fragrance, found.',
      'tag': '01 / THE BRAND',
      'image': 'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Curated Collections',
      'subtitle':
          'Considered, never ordinary. Explore Le Labo, Byredo, and more.',
      'tag': '02 / DISCOVERY',
      'image': 'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'The Scent Quiz',
      'subtitle':
          'Three small questions to match your exact mood and occasion.',
      'tag': '03 / PERSONALIZATION',
      'image': 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Effortless Ritual',
      'subtitle':
          'Complimentary delivery, secure checkout, and a gift in every box.',
      'tag': '04 / EXPERIENCE',
      'image': 'https://images.unsplash.com/photo-1587017539504-67cfbddac569?auto=format&fit=crop&w=900&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _videoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isPlaying) {
        setState(() {
          _currentChapter = (_currentChapter + 1) % _chapters.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _chapters[_currentChapter];

    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Image.network(
              chapter['image']!,
              key: ValueKey<String>(chapter['image']!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(_chapters.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index == _currentChapter
                                ? Colors.white
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    color: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      chapter['tag']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      key: ValueKey<int>(_currentChapter),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter['title']!,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 42,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          chapter['subtitle']!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFE5E0D8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                          });
                        },
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text(
                          'ENTER BOUTIQUE',
                          style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                        ),
                      ),
                    ],
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

class _AdminProductsPage extends StatefulWidget {
  const _AdminProductsPage();

  @override
  State<_AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<_AdminProductsPage> {
  List<Perfume> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select()
          .order('name');
      final products = (rows as List<dynamic>)
          .map((row) => Perfume.fromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
      if (mounted) setState(() => _products = products);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to load products: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProduct() async {
    final product = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _ProductEditorDialog(),
    );
    if (product == null || !mounted) return;

    try {
      final row = await Supabase.instance.client
          .from('products')
          .insert(product)
          .select()
          .single();
      final added = Perfume.fromRow(Map<String, dynamic>.from(row));
      if (mounted) {
        setState(() {
          _products = [..._products, added]
            ..sort((first, second) => first.name.compareTo(second.name));
        });
        _showMessage('${added.name} added to the collection.');
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to add product: $error');
    }
  }

  Future<void> _editProduct(Perfume existing) async {
    final changes = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ProductEditorDialog(product: existing),
    );
    if (changes == null || !mounted) return;

    try {
      final row = await Supabase.instance.client
          .from('products')
          .update(changes)
          .eq('id', existing.id!)
          .select()
          .single();
      final updated = Perfume.fromRow(Map<String, dynamic>.from(row));
      if (mounted) {
        setState(() {
          _products = [
            for (final product in _products)
              if (product.id == updated.id) updated else product,
          ]..sort((first, second) => first.name.compareTo(second.name));
        });
        _showMessage('${updated.name} updated.');
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to update product: $error');
    }
  }

  Future<void> _removeProduct(Perfume product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        title: const Text('Remove product?'),
        content: Text('Remove ${product.name} from the collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: _primaryButtonStyle(),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', product.id!);
      if (mounted) {
        setState(() => _products.removeWhere((item) => item.id == product.id));
        _showMessage('${product.name} removed from the collection.');
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to remove product: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        title: const Text(
          'MANAGE PRODUCTS',
          style: TextStyle(fontSize: 12, letterSpacing: 1.8),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: _ink,
        foregroundColor: _paper,
        icon: const Icon(Icons.add),
        label: const Text('ADD PRODUCT'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadProducts,
                      child: const Text('TRY AGAIN'),
                    ),
                  ],
                ),
              ),
            )
          : _products.isEmpty
          ? const Center(
              child: Text('No products yet. Add your first product.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
              itemCount: _products.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: _line, height: 1),
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: SizedBox(
                    width: 52,
                    height: 64,
                    child: _PerfumeImage(perfume: product),
                  ),
                  title: Text(product.name),
                  subtitle: Text('${product.house}  ·  ₱${product.price}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit ${product.name}',
                        onPressed: () => _editProduct(product),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Remove ${product.name}',
                        onPressed: () => _removeProduct(product),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({this.product});

  final Perfume? product;

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _longevityController = TextEditingController();
  final _labelController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _imageUrl;
  String? _imageError;
  bool _isUploadingImage = false;
  String _family = 'Floral';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) return;
    _nameController.text = product.name;
    _houseController.text = product.house;
    _priceController.text = product.price.toString();
    _imageUrl = product.image;
    _descriptionController.text = product.description;
    _notesController.text = product.notes.join(', ');
    _longevityController.text = product.longevity;
    _labelController.text = product.label ?? '';
    _family = product.family;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _houseController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _longevityController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Future<void> _pickImage() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (pickedImage == null || !mounted) return;

      final bytes = await pickedImage.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _imageUrl = null;
        _imageError = null;
        _isUploadingImage = true;
      });

      final nameParts = pickedImage.name.split('.');
      final suppliedExtension = nameParts.length > 1
          ? nameParts.last.toLowerCase()
          : '';
      final extension = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(suppliedExtension)
          ? suppliedExtension
          : 'jpg';
      final originalName = nameParts.length > 1
          ? nameParts.sublist(0, nameParts.length - 1).join('.')
          : pickedImage.name;
      final safeName = originalName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path =
          '${DateTime.now().microsecondsSinceEpoch}_$safeName.$extension';
      final bucket = Supabase.instance.client.storage.from('products');
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: pickedImage.mimeType ?? _imageMimeType(extension),
        ),
      );
      final publicUrl = bucket.getPublicUrl(path);
      if (mounted) {
        setState(() {
          _imageUrl = publicUrl;
          _imageError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _imageError = 'Image upload failed: $error');
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  String _imageMimeType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  void _submit() {
    if (_isUploadingImage) return;
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null || _imageUrl!.trim().isEmpty) {
      setState(
        () =>
            _imageError = 'Select an image and wait for its upload to finish.',
      );
      return;
    }
    final label = _labelController.text.trim();
    Navigator.pop(context, <String, dynamic>{
      'name': _nameController.text.trim(),
      'house': _houseController.text.trim(),
      'price': int.parse(_priceController.text.trim()),
      'family': _family,
      'image': _imageUrl,
      'tint':
          widget.product?.tint
              .toARGB32()
              .toRadixString(16)
              .padLeft(8, '0')
              .toUpperCase() ??
          'FFE6DFD2',
      'description': _descriptionController.text.trim(),
      'notes': _notesController.text
          .split(',')
          .map((note) => note.trim())
          .where((note) => note.isNotEmpty)
          .toList(),
      'longevity': _longevityController.text.trim(),
      'label': label.isEmpty ? null : label,
    });
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ?? _required,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _paper,
      title: Text(widget.product == null ? 'Add product' : 'Edit product'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(_nameController, 'Product name'),
                _textField(_houseController, 'Brand / house'),
                _textField(
                  _priceController,
                  'Price (₱)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final price = int.tryParse(value?.trim() ?? '');
                    if (price == null || price <= 0) {
                      return 'Enter a price greater than zero.';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _family,
                    decoration: const InputDecoration(
                      labelText: 'Scent family',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Floral', 'Woody', 'Fresh', 'Amber'].map((
                      family,
                    ) {
                      return DropdownMenuItem(
                        value: family,
                        child: Text(family),
                      );
                    }).toList(),
                    onChanged: (family) {
                      if (family != null) setState(() => _family = family);
                    },
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 160,
                      margin: const EdgeInsets.only(bottom: 8),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: _line,
                        border: Border.all(color: _line),
                      ),
                      child: _selectedImageBytes != null
                          ? Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : _imageUrl != null
                          ? Image.network(
                              _productImageUrl(_imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, size: 40),
                            ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickImage,
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _isUploadingImage
                            ? 'UPLOADING IMAGE...'
                            : _imageUrl == null
                            ? 'SELECT PRODUCT IMAGE'
                            : 'CHANGE PRODUCT IMAGE',
                      ),
                    ),
                    if (_imageError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _imageError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                  ],
                ),
                _textField(_descriptionController, 'Description', maxLines: 3),
                _textField(
                  _notesController,
                  'Notes',
                  hint: 'Bergamot, rose, musk',
                ),
                _textField(_longevityController, 'Longevity'),
                _textField(
                  _labelController,
                  'Badge (optional)',
                  validator: (value) => null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _isUploadingImage ? null : _submit,
          style: _primaryButtonStyle(),
          child: Text(widget.product == null ? 'ADD PRODUCT' : 'SAVE CHANGES'),
        ),
      ],
    );
  }
}
