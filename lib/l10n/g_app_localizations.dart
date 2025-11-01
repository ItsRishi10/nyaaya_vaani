import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'g_app_localizations_en.dart';
import 'g_app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GAppLocalizations
/// returned by `GAppLocalizations.of(context)`.
///
/// Applications need to include `GAppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/g_app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GAppLocalizations.localizationsDelegates,
///   supportedLocales: GAppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GAppLocalizations.supportedLocales
/// property.
abstract class GAppLocalizations {
  GAppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GAppLocalizations? of(BuildContext context) {
    return Localizations.of<GAppLocalizations>(context, GAppLocalizations);
  }

  static const LocalizationsDelegate<GAppLocalizations> delegate =
      _GAppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Nyaaya Vaani'**
  String get app_title;

  /// Module title: Legal Services
  ///
  /// In en, this message translates to:
  /// **'Legal Services'**
  String get legal_services;

  /// Module title: Nyaaya Whistle (complaints)
  ///
  /// In en, this message translates to:
  /// **'Nyaaya Whistle'**
  String get nyaaya_whistle;

  /// Module title: Statistics & Strategy
  ///
  /// In en, this message translates to:
  /// **'Statistics & Strategy'**
  String get statistics;

  /// Module title: Youth Association
  ///
  /// In en, this message translates to:
  /// **'Youth Association'**
  String get youth;

  /// Module title: Legal Library
  ///
  /// In en, this message translates to:
  /// **'Legal Library'**
  String get legal_library;

  /// Button label: Upload Image
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get upload_image;

  /// Heading: Available Advocates
  ///
  /// In en, this message translates to:
  /// **'Available Advocates'**
  String get available_advocates;

  /// Button label: Request Help
  ///
  /// In en, this message translates to:
  /// **'Request Help'**
  String get request_help;

  /// Label for complaint details
  ///
  /// In en, this message translates to:
  /// **'Complaint Details'**
  String get complaint_details;

  /// Label showing selected location
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selected_location;

  /// Helper text for map
  ///
  /// In en, this message translates to:
  /// **'Location Reporting (tap map to mark location)'**
  String get location_reporting;

  /// Title for complaint submission screen
  ///
  /// In en, this message translates to:
  /// **'Submit a Complaint'**
  String get submit_complaint;

  /// Button label to submit complaint
  ///
  /// In en, this message translates to:
  /// **'Submit Complaint'**
  String get complaint_submit;

  /// Statistics label
  ///
  /// In en, this message translates to:
  /// **'Poll Results'**
  String get poll_results;

  /// Statistics label
  ///
  /// In en, this message translates to:
  /// **'Sentiment Analysis'**
  String get sentiment_analysis;

  /// Heading for events
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcoming_events;

  /// Heading for gamification section
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get gamification;

  /// AI assistant screen title
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get ai_assistant;

  /// Sample AI text
  ///
  /// In en, this message translates to:
  /// **'AI Prediction: Public opinion likely to shift towards SUPPORT.'**
  String get ai_prediction;

  /// Short label
  ///
  /// In en, this message translates to:
  /// **'Oppose'**
  String get oppose;

  /// Short label
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Action label
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Label for points
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// Badge text
  ///
  /// In en, this message translates to:
  /// **'Badges: Civic Star, Volunteer Hero'**
  String get badge;

  /// Intro text for legal library
  ///
  /// In en, this message translates to:
  /// **'A simplified repository of key Indian legal resources for awareness and learning'**
  String get library_text;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search legal resources'**
  String get library_search;

  /// No results message
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get no_result;
}

class _GAppLocalizationsDelegate
    extends LocalizationsDelegate<GAppLocalizations> {
  const _GAppLocalizationsDelegate();

  @override
  Future<GAppLocalizations> load(Locale locale) {
    return SynchronousFuture<GAppLocalizations>(
        lookupGAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_GAppLocalizationsDelegate old) => false;
}

GAppLocalizations lookupGAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return GAppLocalizationsEn();
    case 'hi':
      return GAppLocalizationsHi();
  }

  throw FlutterError(
      'GAppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
