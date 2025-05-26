// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get mainAppBarTitle => 'Elige Acción:';

  @override
  String get preferencesAppBarTitle => 'Preferencias';

  @override
  String get preferencesFastLlmModeLabel => 'Modo LLM rápido';

  @override
  String get preferencesAlphaVantageAccessKeyLabel =>
      'Clave de acceso Alpha Vantage';

  @override
  String get preferencesTavilyApiKeyLabel => 'Clave API de Tavily';

  @override
  String get preferencesImportApiKeysTitle => 'Importar claves API';

  @override
  String get preferencesSpeechServicesNativeLabel =>
      '¿Servicios de habla Nativo?';

  @override
  String get preferencesNativeSpeechServicesLocalLabel =>
      '¿Servicios de habla nativa local?';

  @override
  String get preferencesVolumeLabel => 'Volumen';

  @override
  String get preferencesUnitSystemLabel => 'Unidad de sistema';

  @override
  String get preferencesUnitSystemDescription =>
      'Activado: métrico (Celsius, km/h, metros), Apagado: imperial (Fahrenheit, mp/h, millas).';

  @override
  String get preferencesInputLocaleLabel => 'Configuración regional de entrada';

  @override
  String get preferencesInputLocaleSubLabel =>
      'Para TTS nativo o idioma de traducción n.° 1';

  @override
  String get preferencesOutputLocaleLabel => 'Configuración regional de salida';

  @override
  String get preferencesOutputLocaleSubLabel =>
      'Para STT nativo o idioma de traducción n.° 2';

  @override
  String get interactionAppBarTitleStart =>
      'Presione para iniciar la grabación:';

  @override
  String get interactionAppBarTitleStop =>
      'Presione para detener la grabación:';

  @override
  String get interactionAppBarTitleProcessing => 'Tratamiento...';

  @override
  String get interactionAppBarTitleResult => 'Resultado:';

  @override
  String get interactionAppBarTitleError => 'Error';

  @override
  String get legendDialogTitle => 'Leyenda';

  @override
  String get uniModalButtonDescription => 'Chat de voz';

  @override
  String get multiModalButtonDescription => 'Chat de imagen';

  @override
  String get translateButtonDescription => 'Traducción';

  @override
  String get personalizationButtonDescription => 'Personalización';

  @override
  String get preferencesButtonDescription => 'Ajustes';

  @override
  String get preferencesLlmDebugModeLabel => 'LLM Debug Mode';

  @override
  String get personalizationButtonLabel => 'Personalización';

  @override
  String get historyButtonLabel => 'Historial de chat';

  @override
  String get areYouSureText => '¿Está seguro?';

  @override
  String get okLabel => 'Aceptar';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get personalizationAppBarTitle => 'Personalización';

  @override
  String get historyAppBarTitle => 'Historia';

  @override
  String get captureAppBarTitle => 'Tap to capture';

  @override
  String get themeSelectionLabel => 'Selección de tema:';

  @override
  String get themeSelectionSystemLabel => 'Tema del sistema';

  @override
  String get themeSelectionLightLabel => 'Tema claro';

  @override
  String get themeSelectionDarkLabel => 'Tema oscuro';

  @override
  String get personalizationRagThresholdLabel =>
      'Umbral de personalización RAG';

  @override
  String get historyRagThresholdLabel => 'Historial Umbral RAG';

  @override
  String get preferencesApiKeysLabel => 'Claves API';

  @override
  String get preferencesAiRagLabel => 'AI + RAG';

  @override
  String get preferencesSpeechServicesLabel => 'Servicios de habla';

  @override
  String get preferencesSystemLabel => 'Sistema';

  @override
  String get localeSelectionLabel => 'Selección de idioma:';

  @override
  String get harmBlockThresholdLowLabel => 'Bajo';

  @override
  String get harmBlockThresholdMediumLabel => 'Medio';

  @override
  String get harmBlockThresholdHighLabel => 'Alto';

  @override
  String get harmBlockThresholdNoneLabel => 'Ninguno';

  @override
  String get modelSafetySettingsLabel => 'Seguridad del modelo';

  @override
  String get harmCategoryHarassmentLabel => 'Acoso';

  @override
  String get harmCategoryHateSpeechLabel => 'Discurso de odio';

  @override
  String get harmCategorySexuallyExplicitLabel => 'Sexualmente explícito';

  @override
  String get harmCategoryDangerousContentLabel => 'Contenido peligroso';

  @override
  String get classicGoogleTranslateLabel => 'Traducción clásica de Google';

  @override
  String get cameraSelectionInstruction => 'Toca una cámara';

  @override
  String get cameraResolutionLabel => 'Resolución de la cámara';

  @override
  String get cameraResolutionLowLabel => 'Bajo (240p)';

  @override
  String get cameraResolutionMediumLabel => 'Mediano (480p)';

  @override
  String get cameraResolutionHighLabel => 'Alta (720p)';

  @override
  String get cameraResolutionVeryHighLabel => 'Muy alta (1080p)';

  @override
  String get preferencesMeasureHeartRateLabel =>
      '¿Medir la frecuencia cardíaca?';
}
