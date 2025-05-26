// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get mainAppBarTitle => 'Choose Action:';

  @override
  String get preferencesAppBarTitle => 'Preferences';

  @override
  String get preferencesFastLlmModeLabel => 'Fast LLM Mode';

  @override
  String get preferencesAlphaVantageAccessKeyLabel =>
      'Alpha Vantage Access Key';

  @override
  String get preferencesTavilyApiKeyLabel => 'Tavily API Key';

  @override
  String get preferencesImportApiKeysTitle => 'Import API Keys';

  @override
  String get preferencesSpeechServicesNativeLabel => 'Speech Services Native?';

  @override
  String get preferencesNativeSpeechServicesLocalLabel =>
      'Local Native Speech Services?';

  @override
  String get preferencesVolumeLabel => 'Volume';

  @override
  String get preferencesUnitSystemLabel => 'Unit System';

  @override
  String get preferencesUnitSystemDescription =>
      'On: metric (Celsius, km/h, meters), Off: imperial (Fahrenheit, mp/h, miles).';

  @override
  String get preferencesInputLocaleLabel => 'Input Locale';

  @override
  String get preferencesInputLocaleSubLabel =>
      'For native TTS or translation language #1';

  @override
  String get preferencesOutputLocaleLabel => 'Output Locale';

  @override
  String get preferencesOutputLocaleSubLabel =>
      'For native STT or translation language #2';

  @override
  String get interactionAppBarTitleStart => 'Press to start recording:';

  @override
  String get interactionAppBarTitleStop => 'Press to stop recording:';

  @override
  String get interactionAppBarTitleProcessing => 'Processing...';

  @override
  String get interactionAppBarTitleResult => 'Result:';

  @override
  String get interactionAppBarTitleError => 'Error';

  @override
  String get legendDialogTitle => 'Legend';

  @override
  String get uniModalButtonDescription => 'Voice chat';

  @override
  String get multiModalButtonDescription => 'Image chat';

  @override
  String get translateButtonDescription => 'Translation';

  @override
  String get personalizationButtonDescription => 'Personalization';

  @override
  String get preferencesButtonDescription => 'Settings';

  @override
  String get preferencesLlmDebugModeLabel => 'LLM Debug Mode';

  @override
  String get personalizationButtonLabel => 'Personalization';

  @override
  String get historyButtonLabel => 'Chat History';

  @override
  String get areYouSureText => 'Are you sure?';

  @override
  String get okLabel => 'OK';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get personalizationAppBarTitle => 'Personalization';

  @override
  String get historyAppBarTitle => 'History';

  @override
  String get captureAppBarTitle => 'Tap to capture';

  @override
  String get themeSelectionLabel => 'Theme Selection:';

  @override
  String get themeSelectionSystemLabel => 'System\'s theme';

  @override
  String get themeSelectionLightLabel => 'Light theme';

  @override
  String get themeSelectionDarkLabel => 'Dark theme';

  @override
  String get personalizationRagThresholdLabel =>
      'Personalization RAG Threshold';

  @override
  String get historyRagThresholdLabel => 'History RAG Threshold';

  @override
  String get preferencesApiKeysLabel => 'API Keys';

  @override
  String get preferencesAiRagLabel => 'AI + RAG';

  @override
  String get preferencesSpeechServicesLabel => 'Speech Services';

  @override
  String get preferencesSystemLabel => 'System';

  @override
  String get localeSelectionLabel => 'Language Selection:';

  @override
  String get harmBlockThresholdLowLabel => 'Low';

  @override
  String get harmBlockThresholdMediumLabel => 'Medium';

  @override
  String get harmBlockThresholdHighLabel => 'High';

  @override
  String get harmBlockThresholdNoneLabel => 'None';

  @override
  String get modelSafetySettingsLabel => 'Model Safety';

  @override
  String get harmCategoryHarassmentLabel => 'Harassment';

  @override
  String get harmCategoryHateSpeechLabel => 'Hate Speech';

  @override
  String get harmCategorySexuallyExplicitLabel => 'Sexually Explicit';

  @override
  String get harmCategoryDangerousContentLabel => 'Dangerous Content';

  @override
  String get classicGoogleTranslateLabel => 'Classic Google Translation';

  @override
  String get cameraSelectionInstruction => 'Tap a camera';

  @override
  String get cameraResolutionLabel => 'Camera Resolution';

  @override
  String get cameraResolutionLowLabel => 'Low (240p)';

  @override
  String get cameraResolutionMediumLabel => 'Medium (480p)';

  @override
  String get cameraResolutionHighLabel => 'High (720p)';

  @override
  String get cameraResolutionVeryHighLabel => 'Very High (1080p)';

  @override
  String get preferencesMeasureHeartRateLabel => 'Measure Heart Rate?';
}
