import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart'; // NEW for state management
import 'services/auth_service.dart';
import 'services/translation_service.dart';
import 'services/survey.dart';
import 'screens/home.dart';
import 'widgets/side_nav.dart';
import 'data/app_texts.dart'; // Import English texts from separate file

// ----------------- Localization -----------------
class AppLocalizations extends ChangeNotifier {
  bool isHindi = false;
  bool _isTranslating = false;
  final TranslationService _translationService = TranslationService();
  
  // Cache for Hindi translations
  final Map<String, String> _hindiTranslations = {};

  // Base English dictionary - imported from app_texts.dart for easy editing
  final Map<String, String> englishTexts = appEnglishTexts;

  AppLocalizations() {
    _loadCachedTranslations();
  }

  /// Load cached translations from SharedPreferences via the translation service
  Future<void> _loadCachedTranslations() async {
    await _translationService.loadCacheFromPrefs();
    // Sync cached translations from service to our cache
    final cachedTranslations = _translationService.getCache();
    // Only sync translations for texts that exist in our englishTexts
    for (final entry in cachedTranslations.entries) {
      if (englishTexts.values.contains(entry.key)) {
        _hindiTranslations[entry.key] = entry.value;
      }
    }
  }

  String getText(String key) {
    final englishText = englishTexts[key] ?? key;
    
    if (!isHindi) {
      return englishText;
    }
    
    // Check our cache first
    if (_hindiTranslations.containsKey(englishText)) {
      return _hindiTranslations[englishText]!;
    }
    
    // Try to get from translation service cache (may have been loaded from SharedPreferences)
    // Note: TranslationService cache is internal, so we'll fetch on-demand
    // Return English for now - it will be translated when toggleLanguage is called
    return englishText;
  }

  /// Translate a single text string dynamically
  Future<String> translate(String englishText) async {
    if (englishText.trim().isEmpty) return englishText;
    if (!isHindi) return englishText;
    
    // Check cache first
    if (_hindiTranslations.containsKey(englishText)) {
      return _hindiTranslations[englishText]!;
    }
    
    // Translate via backend
    final translated = await _translationService.translateText(englishText);
    _hindiTranslations[englishText] = translated;
    return translated;
  }

  /// Toggle language and translate all texts if switching to Hindi
  Future<void> toggleLanguage() async {
    if (isHindi) {
      // Switching back to English
      isHindi = false;
    notifyListeners();
      return;
    }
    
    // Switching to Hindi - need to translate
    isHindi = true;
    _isTranslating = true;
    notifyListeners();
    
    try {
      // Get all English texts that need translation
      final textsToTranslate = englishTexts.values.toList();
      print('Starting translation of ${textsToTranslate.length} texts...');
      
      // Translate in batch (more efficient) with timeout
      final translations = await _translationService.translateBatch(textsToTranslate).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print('Translation batch timed out, using cached translations');
          return <String, String>{}; // Return empty map, will use cached or fallback
        },
      );
      
      print('Translation completed, got ${translations.length} translations');
      
      // Update our cache with translations
      _hindiTranslations.addAll(translations);
      
      // Also ensure any texts that weren't translated are at least in cache as original
      for (final text in textsToTranslate) {
        if (!_hindiTranslations.containsKey(text)) {
          _hindiTranslations[text] = text; // Fallback to English if translation fails
        }
      }
      
      _isTranslating = false;
      notifyListeners();
      print('Translation UI updated');
    } catch (e, stackTrace) {
      print('Error translating: $e');
      print('Stack trace: $stackTrace');
      _isTranslating = false;
      isHindi = false; // Revert to English on error
      notifyListeners();
      // Show error message to user
      rethrow; // Let the caller handle the error display
    }
  }

  bool get isTranslating => _isTranslating;
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLocalizations()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: NyaayaVaaniApp(),
    ),
  );
}

class NyaayaVaaniApp extends StatelessWidget {
  const NyaayaVaaniApp({super.key});
  @override
  Widget build(BuildContext context) {
  final loc = context.read<AppLocalizations>();
    return MaterialApp(
      title: loc.getText("app_title"),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange,
        ),
      ),
  // Use AuthGate as the app root so authentication state (persisted in SharedPreferences)
  // determines which screen to show (HomePage when not logged in, Dashboard when logged in).
  home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Simple auth gate: shows login when not authenticated, otherwise shows the app
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Wait until SharedPreferences have been loaded. During app cold-start the
    // AuthService loads prefs asynchronously; show a small loading indicator
    // so the UI doesn't render a dashboard with missing user info.
    if (!auth.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If not logged in, show the HomePage (promo / entry) where user can login/register.
    if (!auth.isLoggedIn) {
      return const HomePage();
    }

    // Logged in -> show dashboard (dashboard now includes side nav + drawer)
    return const DashboardPage();
  }
}

// ----------------- Dashboard -----------------
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();

    final List<Map<String, dynamic>> modules = [
      {"title": loc.getText("legal_services"), "icon": FontAwesomeIcons.gavel, "page": LegalServicesPage()},
      {"title": loc.getText("nyaaya_whistle"), "icon": FontAwesomeIcons.triangleExclamation, "page": WhistlePage()},
      {"title": loc.getText("statistics"), "icon": FontAwesomeIcons.chartBar, "page": StatisticsPage()},
      {"title": loc.getText("youth"), "icon": FontAwesomeIcons.users, "page": YouthPage()},
      {"title": loc.getText("legal_library"), "icon": FontAwesomeIcons.book, "page": LegalLibraryPage()},
    ];

    // Dashboard wrapped with a narrow left-side nav and a drawer.
    final auth = context.watch<AuthService>();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text((auth.currentUser?['username'] ?? 'U').toString()[0].toUpperCase()),
                ),
                title: Text(auth.currentUser?['username'] ?? 'Unknown'),
                subtitle: Text(auth.isAdmin ? 'Admin' : 'User'),
              ),
              const Divider(),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.doorOpen),
                title: Text(loc.getText("logout")),
                onTap: () async {
                  // Close drawer first, then logout. AuthGate will react and show HomePage.
                  Navigator.pop(context);
                  await context.read<AuthService>().logout();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(loc.getText("app_title")),
        actions: [
          Builder(
            builder: (context) {
              final loc = context.watch<AppLocalizations>();
              return IconButton(
                icon: loc.isTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FaIcon(FontAwesomeIcons.globe),
                onPressed: loc.isTranslating
                    ? null
                    : () async {
                        try {
                          await context.read<AppLocalizations>().toggleLanguage();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Translation failed: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      },
              );
            },
          )
        ],
      ),
      body: Row(
        children: [
          const SideNav(),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => modules[index]["page"]),
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FaIcon(modules[index]["icon"], size: 48, color: Colors.blue),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              modules[index]["title"],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.chat),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AIAssistantPage()));
        },
      ),
    );
  }
}

// ----------------- Legal Services -----------------
class LegalServicesPage extends StatefulWidget {
  const LegalServicesPage({super.key});

  @override
  State<LegalServicesPage> createState() => _LegalServicesPageState();
}

class _LegalServicesPageState extends State<LegalServicesPage> {
  final List<Map<String, dynamic>> lawyers = [
    {
      "name": "Adv. Radhika Madhusoodhanan",
      "specialization": "Criminal Law",
      "enrollment": "KAR/2864/99",
      "rating": 4.5,
      "reviews": [
        {"user": "Rahul Mehta","comment": "Handled my case with complete professionalism. Truly impressive work!!","rating": 4.5},
        {"user": "Sneha D'Souza","comment": "Amazing lawyer who genuinely cares about clients. Strongly recommend!","rating": 4.5}
      ],
      "showReviews": false,
    },
    {
      "name": "Adv. Aravindan K",
      "specialization": "Civil Law",
      "enrollment": "KAR/3865/99",
      "rating": 4.6,
      "reviews": [
        {"user": "Anjali Sharma","comment": "Very knowledgeable and supportive throughout the process. Highly recommend!","rating": 4.6}
      ],
      "showReviews": false,
    },
    {
      "name": "Adv. D.CHELLAKANNAN",
      "specialization": "Criminal Law",
      "enrollment": "TN/1999/2016",
      "rating": 4.4,
      "reviews": [
        {"user": "Neha Patel","comment": "Extremely efficient and reliable. My legal matter was resolved smoothly.","rating": 4.4}
      ],
      "showReviews": false,
    },
    {
      "name": "Adv. K.RADHAKRISHNAN",
      "specialization": "Family Law",
      "enrollment": "TN/1094/1983",
      "rating": 4.3,
      "reviews": [
        {"user": "Sanjay Gupta","comment": "Quick, smart, and effective - one of the best legal experiences I've had.","rating": 4.3}
      ],
      "showReviews": false,
    },
    {
      "name": "Adv. R.VASANTHA",
      "specialization": "Contract Law",
      "enrollment": "TN/29/1988",
      "rating": 4.0,
      "reviews": [
        {"user": "CS.Suchindran","comment": "Good Service","rating": 4.0}
      ],
      "showReviews": false,
    },
  ];

  void _addReview(BuildContext context, Map<String, dynamic> lawyer) {
    final TextEditingController commentController = TextEditingController();
    double rating = 3.0;

    final loc = context.watch<AppLocalizations>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${loc.getText("add_review_for")} ${lawyer["name"]}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 3,
              minRating: 1,
              allowHalfRating: true,
              itemBuilder: (context, _) => const FaIcon(
                FontAwesomeIcons.solidStar,
                color: Colors.amber,
              ),
              onRatingUpdate: (val) => rating = val,
            ),
            TextField(
              controller: commentController,
              decoration: InputDecoration(labelText: loc.getText("add_review")),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.getText("cancel")),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                (lawyer["reviews"] as List).add({
                  "user": "Anonymous",
                  "rating": rating,
                  "comment": commentController.text,
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${loc.getText("review_added_for")} ${lawyer["name"]}")),
              );
            },
            child: Text(loc.getText("submit")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText("legal_services")),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.getText("available_advocates"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...lawyers.map((lawyer) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side: Name and Specialization
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lawyer["name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lawyer["specialization"],
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lawyer["enrollment"],
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right side: Stars + Buttons
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RatingBarIndicator(
                                  rating: lawyer["rating"],
                                  itemBuilder: (context, _) => const FaIcon(
                                    FontAwesomeIcons.solidStar,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 20,
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(120, 36),
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Help requested from ${lawyer['name']}"),
                                      ),
                                    );
                                  },
                                  child: Text(loc.getText("request_help"),
                                      textAlign: TextAlign.center),
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(120, 36),
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      lawyer["showReviews"] =
                                          !(lawyer["showReviews"] as bool);
                                    });
                                  },
                                  child: Text(
                                    lawyer["showReviews"] == true
                                        ? loc.getText("hide_reviews")
                                        : loc.getText("view_reviews"),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Reviews section (toggle)
                      if (lawyer["showReviews"] == true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((lawyer["reviews"] as List).isEmpty)
                              Text(loc.getText("no_reviews_yet")),
                            if ((lawyer["reviews"] as List).isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.getText("reviews"),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(height: 6),
                                  ...((lawyer["reviews"] as List).map((review) =>
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const FaIcon(
                                          FontAwesomeIcons.circleUser,
                                          size: 28,
                                        ),
                                        title: Text(review["user"]),
                                        subtitle: Text(review["comment"]),
                                        trailing: RatingBarIndicator(
                                          rating: review["rating"],
                                          itemBuilder: (context, _) =>
                                              const FaIcon(
                                            FontAwesomeIcons.solidStar,
                                            color: Colors.amber,
                                          ),
                                          itemCount: 5,
                                          itemSize: 18,
                                        ),
                                      ))),
                                ],
                              ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 36),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _addReview(context, lawyer),
                              child: Text(loc.getText("add_review"),
                                  textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}


// ----------------- Whistle Module -----------------
class WhistlePage extends StatefulWidget {
  const WhistlePage({super.key});
  @override
  State<WhistlePage> createState() => _WhistlePageState();
}

class _WhistlePageState extends State<WhistlePage> {
  final MapController _mapController = MapController();
  LatLng? _pickedLocation;
  LatLng? _currentLocation;

  StreamSubscription<Position>? _positionStream;
  bool _mapIsReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentLocation = LatLng(28.6139, 77.2090); // fallback Delhi
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = LatLng(28.6139, 77.2090);
        });
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      _currentLocation = LatLng(position.latitude, position.longitude);

      if (_mapIsReady) {
        _mapController.move(_currentLocation!, 15.0);
      }

      setState(() {});

      // Listen for continuous location updates with high accuracy
      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      );

      _positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position pos) {
        final updatedLocation = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentLocation = updatedLocation;
          if (_mapIsReady) {
            _mapController.move(_currentLocation!, _mapController.camera.zoom);
          }
        });
      });
    } catch (e) {
      setState(() {
        _currentLocation = LatLng(28.6139, 77.2090);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText("nyaaya_whistle")),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(loc.getText("submit_complaint"),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              decoration: InputDecoration(labelText: loc.getText("complaint_details")),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getText("upload_image_feature_coming_soon"))));
              },
              icon: FaIcon(FontAwesomeIcons.camera),
              label: Text(loc.getText("upload_image")),
            ),
            SizedBox(height: 20),
            Text(loc.getText("location_reporting")),
            SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: _currentLocation == null
                  ? Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 12.5,
                        onMapReady: () {
                          setState(() => _mapIsReady = true);
                          _mapController.move(_currentLocation!, 15.0);
                        },
                        onTap: (tapPosition, point) {
                          setState(() {
                            _pickedLocation = point;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Location marked at: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}"),
                            ),
                          );
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.nyaaya.vaani',
                        ),
                        if (_pickedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pickedLocation!,
                                width: 40,
                                height: 40,
                                child: FaIcon(FontAwesomeIcons.locationDot,
                                    color: Colors.red, size: 36),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
            SizedBox(height: 20),
            if (_pickedLocation != null)
              Text(
                "${loc.getText("selected_location")}:\nLat: ${_pickedLocation!.latitude}, Lng: ${_pickedLocation!.longitude}",
                style: TextStyle(fontSize: 14, color: Colors.blue[800]),
              ),
            SizedBox(height: 20),

            // 🔹 New Submit Button
            ElevatedButton.icon(
              onPressed: () async {
                // TODO: Replace with backend API call
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.getText("complaint_submitted_successfully"))),
                );
              },
              icon: FaIcon(FontAwesomeIcons.paperPlane),
              label: Text(loc.getText("complaint_submit")),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Statistics -----------------
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText("statistics")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              loc.getText("st_title"),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              loc.getText("st_description"),
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(loc.getText("poll_results")),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: _bottomTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: 45, color: Colors.orange, width: 30),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: 40, color: Colors.green, width: 30),
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(toY: 15, color: Colors.blueGrey, width: 30),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              loc.getText("sentiment_analysis"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      title: ("${loc.getText("nda")} ${('45%')}"),
                      value: 45,
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      title: ("${loc.getText("rjd+")} ${('40%')}"),
                      value: 40,
                      color: Colors.green,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      title: ("${loc.getText("others")} ${('15%')}"),
                      value: 15,
                      color: Colors.blueGrey,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.getText("ai_analysis"),
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const SurveyPage()),
                );
              },
              icon: const FaIcon(FontAwesomeIcons.list),
              label: Text(loc.getText('survey')),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bottomTitles(double value, TitleMeta meta) {
    switch (value.toInt()) {
      case 0:
        return Text("NDA");
      case 1:
        return Text("RJD+");
      case 2:
        return Text("Others");
      default:
        return const Text("");
    }
  }
}


// ----------------- Youth Association -----------------
class YouthPage extends StatelessWidget {
  YouthPage({super.key});
  // Separate lists for past and upcoming events. Past events use key 'old_title' to differentiate.
  final List<Map<String, String>> pastEvents = [
    {"old_title": "Online Youth Parliament", "date": "Oct 31, 2025", "Agenda": "Deliberating on the Delimitation of Lok Sabha Constituencies. Best Delegate was won by Shreyansu Mishra and received 80 points", "pdf_url": "https://ia601207.us.archive.org/20/items/nyaaya_vaani/Resolution.pdf"},
  ];

  final List<Map<String, String>> upcomingEvents = [
    {"title": "Clean City Drive", "date": "Nov 16, 2025", "Agenda": "Spreading awareness in your street by door to door campaigns. Best performer:40 points in gamification"},
    {"title": "Essay Writing Competition", "date": "Nov 26, 2025", "Agenda": "Integrating Sustainable development with rapid Industrial Growth. Best performer : 30 points"},
    {"title": "Online Civic Awareness Workshop", "date": "Nov 29, 2025", "Agenda": "Seminar by Pranav Suchindran on Role of MUN's and Debates in upskilling public speaking skills"},
  ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft), // FontAwesome back arrow
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText("youth")),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(loc.getText("past_events"),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...pastEvents.map((e) {
              final title = e['old_title'] ?? '';
              final pdf = e['pdf_url'];
              // local helper to open pdf; captures context and loc
              Future<void> open_pdf(String url) async {
                final Uri uri = Uri.parse(url);
                if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getText("could_not_open_pdf"))),
                  );
                }
              }

              return Card(
                child: ListTile(
                  leading: FaIcon(FontAwesomeIcons.calendarDay),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${loc.getText("date")} ${e["date"]}"),
                      SizedBox(height: 8),
                      Text(
                        "${loc.getText("Agenda")}: ${e["Agenda"]}",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: pdf != null
                      ? IconButton(
                          tooltip: loc.getText("open_pdf"),
                          icon: FaIcon(FontAwesomeIcons.download),
                          onPressed: () => open_pdf(pdf),
                        )
                      : null,
                ),
              );
            }),
            Text(loc.getText("upcoming_events"),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...upcomingEvents.map((e) {
              final title = e['title'] ?? '';
              return Card(
                child: ListTile(
                  leading: FaIcon(FontAwesomeIcons.calendarDay),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${loc.getText("date")} ${e["date"]}"),
                      SizedBox(height: 8),
                      Text(
                        "${loc.getText("Agenda")}: ${e["Agenda"]}",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${loc.getText("signed_up_for")} $title")));
                    },
                    child: Text(loc.getText("join")),
                  ),
                ),
              );
            }),
            SizedBox(height: 20),
            Text(loc.getText("gamification"), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Card(
              child: ListTile(
                leading: FaIcon(FontAwesomeIcons.medal, color: Colors.amber),
                title: Text("${loc.getText("points")}: 120"),
                subtitle: Text(loc.getText("badge")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Legal Library -----------------
class LegalLibraryPage extends StatefulWidget {
  const LegalLibraryPage({super.key});
  @override
  State<LegalLibraryPage> createState() => _LegalLibraryPageState();
}

class _LegalLibraryPageState extends State<LegalLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _pdfs = [
    {
      'title': 'Companies Act 2013',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Companies-Act-2013.pdf'
    },
    {
      'title': 'Consumer Protection Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Consumer-Protection-Act.pdf'
    },
    {
      'title': 'Contract Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Contract-Act.pdf'
    },
    {
      'title': 'Environment Protection Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Environment-Protection-Act.pdf'
    },
    {
      'title': 'Hindu Marriage Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Hindu-Marriage-Act.pdf'
    },
    {
      'title': 'Indian Contract Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Indian-Contract-Act.pdf'
    },
    {
      'title': 'IT Act 2000',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/IT-Act-2000.pdf'
    },
    {
      'title': 'Juvenile Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Juvenile-Act.pdf'
    },
    {
      'title': 'Labour Laws',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Labour-Laws.pdf'
    },
    {
      'title': 'Limited Liability Partnership Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Limited-Liability-Partnership-Act.pdf'
    },
    {
      'title': 'Motor Vehicles Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Motor-Vehicles-Act.pdf'
    },
    {
      'title': 'Muslim Personal Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Muslim-Personal-Act.pdf'
    },
    {
      'title': 'Narcotic Drugs Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Narcotic-Drugs-Act.pdf'
    },
    {
      'title': 'POSCO Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/POSCO-Act.pdf'
    },
    {
      'title': 'Prevention of Corruption Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Prevention-of-Corruption-Act.pdf'
    },
    {
      'title': 'Protection of Women From Domestic Violence Act 2005',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Protection-of-Women-From-Domestic-Violence-Act-2005.pdf'
    },
    {
      'title': 'Scheduled Castes And The Scheduled Tribes Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Scheduled-Castes-And-The-Scheduled-Tribes-Act.pdf'
    },
    {
      'title': 'Specific Relief Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Specific-Relief-Act.pdf'
    },
    {
      'title': 'The Arbitration and Conciliation Act of 1996',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Arbitration-and-Conciliation-Act-of-1996.pdf'
    },
    {
      'title': 'The Code of Civil Procedure 1908',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Code-of-Civil-Procedure-1908.pdf'
    },
    {
      'title': 'The Code of Criminal Procedure 1973',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Code-of-Criminal-Procedure-1973.pdf'
    },
    {
      'title': 'The Constitution of India 2024',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Constitution-of-India-2024.pdf'
    },
    {
      'title': 'The Forest Conservation Act 1980',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Forest-Conservation-Act-1980.pdf'
    },
    {
      'title': 'The Hindu Succession Act 1956',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Hindu-Succession-Act-1956.pdf'
    },
    {
      'title': 'The Indian Stamp Act 1899',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Indian-Stamp-Act-1899.pdf'
    },
    {
      'title': 'The Insolvency And Bankruptcy Code 2016',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Insolvency-And-Bankruptcy-Code-2016.pdf'
    },
    {
      'title': 'The Registration Act 1908',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Registration-Act-1908.pdf'
    },
    {
      'title': 'The Wild Life Protection Act 1972',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/The-Wild-Life-Protection-Act-1972.pdf'
    },
    {
      'title': 'Transfer of Property Act',
      'url': 'https://ia601602.us.archive.org/13/items/legal_files/Transfer-of-Property-Act.pdf'
    },
    // Add more legal resources here
  ];
  List<Map<String, String>> _filteredPdfs = [];

  @override
  void initState() {
    super.initState();
    _filteredPdfs = _pdfs;
    _searchController.addListener(_filterPdfs);
  }

  void _filterPdfs() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPdfs = _pdfs
          .where((pdf) => pdf['title']!.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      final loc = context.read<AppLocalizations>();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.getText("could_not_open_pdf"))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText("legal_library")),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              loc.getText("library_text"),
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: loc.getText("library_search"),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12), // tweak for proper height
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 12.0), // vertical centering of icon
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 20, // set icon size to fit well vertically
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredPdfs.isEmpty
                ? Center(child: Text(loc.getText("no_result")))
                : ListView.separated(
                    itemCount: _filteredPdfs.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, index) {
                      final pdf = _filteredPdfs[index];
                      return ListTile(
                        title: Text(pdf['title']!),
                        trailing: FaIcon(FontAwesomeIcons.download),
                        onTap: () => _launchUrl(pdf['url']!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ----------------- AI Assistant -----------------
class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    // seed welcome message
    _messages.add({"sender": "ai", "message": "Hi — I'm the Nyaaya Assistant. Ask me about the app, complaints, events, or legal help."});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({"sender": "user", "message": text});
      _controller.clear();
      _isThinking = true;
    });
    _scrollToBottomDelayed();

    // simulate thinking and generate reply
    Future.delayed(const Duration(milliseconds: 600), () {
      final reply = _generateResponse(text);
      if (!mounted) return;
      setState(() {
        _messages.add({"sender": "ai", "message": reply});
        _isThinking = false;
      });
      _scrollToBottomDelayed();
    });
  }

  String _generateResponse(String input) {
    final q = input.toLowerCase();
    // quick keyword-based intents
    if (q.contains('complaint') || q.contains('whistle') || q.contains('report')) {
      return 'To raise a complaint, open the Nyaaya Whistle module from the dashboard, fill details, mark location on the map and submit.';
    }
    if (q.contains('volunteer') || q.contains('event') || q.contains('join')) {
      return 'You can check the Youth Association section for upcoming events and tap Join to sign up.';
    }
    if (q.contains('lawyer') || q.contains('advocate')) {
      return 'Open Legal Services to see available advocates. You can request help or view reviews for each advocate.';
    }
    if (q.contains('admin') || q.contains('add lawyer') || q.contains('manage')) {
      return 'Admin features (like adding lawyers) are available only to admins. Login as an admin to access them.';
    }
    if (q.contains('help') || q.contains('how to')) {
      return 'I can guide you through using the app modules: Nyaaya Whistle (complaints), Legal Services, Youth Association, and Legal Library. Ask about any of them.';
    }

    // fallback: echo with suggestion
    return 'I can help with complaints, events, and legal services. For your question: "$input", try asking specifically about complaints, volunteers, or available advocates.';
  }

  void _scrollToBottomDelayed() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocalizations>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.getText("ai_assistant")),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  // typing indicator
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(loc.getText("typing")),
                    ),
                  );
                }
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['message'] ?? ''),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: loc.getText("type_your_question")),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(), // tweak these as needed
                    child: const FaIcon(FontAwesomeIcons.paperPlane, size: 20),)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
