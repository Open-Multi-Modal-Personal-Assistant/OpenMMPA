import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('es'),
  ];

  /// Text shown in the AppBar of the Main Page
  ///
  /// In en, this message translates to:
  /// **'Choose Action:'**
  String get mainAppBarTitle;

  /// Text shown in the AppBar of the Preferences Page
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesAppBarTitle;

  /// Text shown in the preferences settings for Fast LLM Mode
  ///
  /// In en, this message translates to:
  /// **'Fast LLM Mode'**
  String get preferencesFastLlmModeLabel;

  /// Text shown in the preferences settings for Alpha Vantage Access Key
  ///
  /// In en, this message translates to:
  /// **'Alpha Vantage Access Key'**
  String get preferencesAlphaVantageAccessKeyLabel;

  /// Text shown in the preferences settings for Tavily API Key
  ///
  /// In en, this message translates to:
  /// **'Tavily API Key'**
  String get preferencesTavilyApiKeyLabel;

  /// Text shown in the preferences settings for the Import API Key button
  ///
  /// In en, this message translates to:
  /// **'Import API Keys'**
  String get preferencesImportApiKeysTitle;

  /// Text shown in the preferences settings for Speech Services Native?
  ///
  /// In en, this message translates to:
  /// **'Speech Services Native?'**
  String get preferencesSpeechServicesNativeLabel;

  /// Text shown in the preferences settings for Local Native Speech Services?
  ///
  /// In en, this message translates to:
  /// **'Local Native Speech Services?'**
  String get preferencesNativeSpeechServicesLocalLabel;

  /// Text shown in the preferences settings for Volume
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get preferencesVolumeLabel;

  /// Text shown in the preferences settings for Unit System
  ///
  /// In en, this message translates to:
  /// **'Unit System'**
  String get preferencesUnitSystemLabel;

  /// Text shown in the preferences settings for Unit System Description
  ///
  /// In en, this message translates to:
  /// **'On: metric (Celsius, km/h, meters), Off: imperial (Fahrenheit, mp/h, miles).'**
  String get preferencesUnitSystemDescription;

  /// Text shown in the preferences settings for Input Locale
  ///
  /// In en, this message translates to:
  /// **'Input Locale'**
  String get preferencesInputLocaleLabel;

  /// Text shown in the preferences settings subtitle for Input Locale
  ///
  /// In en, this message translates to:
  /// **'For native TTS or translation language #1'**
  String get preferencesInputLocaleSubLabel;

  /// Text shown in the preferences settings for Output Locale
  ///
  /// In en, this message translates to:
  /// **'Output Locale'**
  String get preferencesOutputLocaleLabel;

  /// Text shown in the preferences settings subtitle for Output Locale
  ///
  /// In en, this message translates to:
  /// **'For native STT or translation language #2'**
  String get preferencesOutputLocaleSubLabel;

  /// Text shown in the AppBar of the Interaction Page before a session
  ///
  /// In en, this message translates to:
  /// **'Press to start recording:'**
  String get interactionAppBarTitleStart;

  /// Text shown in the AppBar of the Interaction Page during recording
  ///
  /// In en, this message translates to:
  /// **'Press to stop recording:'**
  String get interactionAppBarTitleStop;

  /// Text shown in the AppBar of the Interaction Page during processing
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get interactionAppBarTitleProcessing;

  /// Text shown in the AppBar of the Interaction Page after processing
  ///
  /// In en, this message translates to:
  /// **'Result:'**
  String get interactionAppBarTitleResult;

  /// Text shown in the AppBar of the Interaction Page in case of error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get interactionAppBarTitleError;

  /// Text shown on the legend dialog title
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legendDialogTitle;

  /// Text shown on the legend dialog for Uni Modal Button
  ///
  /// In en, this message translates to:
  /// **'Voice chat'**
  String get uniModalButtonDescription;

  /// Text shown on the legend dialog for Multi Modal Button
  ///
  /// In en, this message translates to:
  /// **'Image chat'**
  String get multiModalButtonDescription;

  /// Text shown on the legend dialog for Translate Button
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translateButtonDescription;

  /// Text shown on the legend dialog for Personalization Button
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalizationButtonDescription;

  /// Text shown on the button to navigate to Chat History
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get preferencesButtonDescription;

  /// Text shown in the preferences settings for LLM Debug Mode
  ///
  /// In en, this message translates to:
  /// **'LLM Debug Mode'**
  String get preferencesLlmDebugModeLabel;

  /// No description provided for @personalizationButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalizationButtonLabel;

  /// No description provided for @historyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get historyButtonLabel;

  /// Text shown in OK / Cancel alert dialogs' body: Are you sure?
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSureText;

  /// Text shown in OK / Cancel alert dialogs' OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// Text shown in OK / Cancel alert dialogs' Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// Text shown in the AppBar of the Personalization Page
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalizationAppBarTitle;

  /// Text shown in the AppBar of the History Page
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyAppBarTitle;

  /// Text shown in the AppBar of the Image Capture Page
  ///
  /// In en, this message translates to:
  /// **'Tap to capture'**
  String get captureAppBarTitle;

  /// Text shown in the Preferences for Theme Selection lead label
  ///
  /// In en, this message translates to:
  /// **'Theme Selection:'**
  String get themeSelectionLabel;

  /// Text shown in the Preferences for Dark theme selection checkbox
  ///
  /// In en, this message translates to:
  /// **'System\'s theme'**
  String get themeSelectionSystemLabel;

  /// No description provided for @themeSelectionLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeSelectionLightLabel;

  /// No description provided for @themeSelectionDarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeSelectionDarkLabel;

  /// Text shown in the Preferences for Personalization RAG Threshold slider and spinner
  ///
  /// In en, this message translates to:
  /// **'Personalization RAG Threshold'**
  String get personalizationRagThresholdLabel;

  /// Text shown in the Preferences for History RAG Threshold slider and spinner
  ///
  /// In en, this message translates to:
  /// **'History RAG Threshold'**
  String get historyRagThresholdLabel;

  /// Text shown on the preferences settings button and page for API Keys
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get preferencesApiKeysLabel;

  /// Text shown on the preferences settings button and page for AI + RAG
  ///
  /// In en, this message translates to:
  /// **'AI + RAG'**
  String get preferencesAiRagLabel;

  /// Text shown on the preferences settings button and page for Speech Services
  ///
  /// In en, this message translates to:
  /// **'Speech Services'**
  String get preferencesSpeechServicesLabel;

  /// Text shown on the preferences settings button and page for System
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get preferencesSystemLabel;

  /// Text shown in the Preferences for application Language Selection lead label
  ///
  /// In en, this message translates to:
  /// **'Language Selection:'**
  String get localeSelectionLabel;

  /// Text shown in the Model Safety Settings for Low Harm Block Threshold (meaning: Block when low probability of unsafe content)
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get harmBlockThresholdLowLabel;

  /// Text shown in the Model Safety Settings for Medium Harm Block Threshold (meaning: Block when medium probability of unsafe content)
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get harmBlockThresholdMediumLabel;

  /// Text shown in the Model Safety Settings for High Harm Block Threshold (meaning: Block when high probability of unsafe content)
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get harmBlockThresholdHighLabel;

  /// Text shown in the Model Safety Settings for None Harm Block Threshold (Meaning: Always show regardless of probability of unsafe content)
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get harmBlockThresholdNoneLabel;

  /// Text shown in the Preferences for heading the Model Safety selections for various harm categories
  ///
  /// In en, this message translates to:
  /// **'Model Safety'**
  String get modelSafetySettingsLabel;

  /// Text shown in the Preferences for the safety settings of the Harassment harm category
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get harmCategoryHarassmentLabel;

  /// Text shown in the Preferences for the safety settings of the Hate Speech harm category
  ///
  /// In en, this message translates to:
  /// **'Hate Speech'**
  String get harmCategoryHateSpeechLabel;

  /// Text shown in the Preferences for the safety settings of the Sexually Explicit harm category
  ///
  /// In en, this message translates to:
  /// **'Sexually Explicit'**
  String get harmCategorySexuallyExplicitLabel;

  /// Text shown in the Preferences for the safety settings of the Dangerous Content harm category
  ///
  /// In en, this message translates to:
  /// **'Dangerous Content'**
  String get harmCategoryDangerousContentLabel;

  /// Text shown in the Preferences for the Classic Google Translation
  ///
  /// In en, this message translates to:
  /// **'Classic Google Translation'**
  String get classicGoogleTranslateLabel;

  /// Text shown in the camera capture page when no camera is selected
  ///
  /// In en, this message translates to:
  /// **'Tap a camera'**
  String get cameraSelectionInstruction;

  /// Text shown in the preferences settings for Camera Resolution selector
  ///
  /// In en, this message translates to:
  /// **'Camera Resolution'**
  String get cameraResolutionLabel;

  /// Text shown in the preferences settings for Low Camera Resolution selection
  ///
  /// In en, this message translates to:
  /// **'Low (240p)'**
  String get cameraResolutionLowLabel;

  /// Text shown in the preferences settings Medium Camera Resolution selection
  ///
  /// In en, this message translates to:
  /// **'Medium (480p)'**
  String get cameraResolutionMediumLabel;

  /// Text shown in the preferences settings High Camera Resolution selection
  ///
  /// In en, this message translates to:
  /// **'High (720p)'**
  String get cameraResolutionHighLabel;

  /// Text shown in the preferences settings Very High Camera Resolution selection
  ///
  /// In en, this message translates to:
  /// **'Very High (1080p)'**
  String get cameraResolutionVeryHighLabel;

  /// Text shown in the preferences settings for Measure Heart Rate?
  ///
  /// In en, this message translates to:
  /// **'Measure Heart Rate?'**
  String get preferencesMeasureHeartRateLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
