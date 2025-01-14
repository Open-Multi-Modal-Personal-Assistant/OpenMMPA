![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

# Open Multi-Modal Personal Assistant, a Generative AI Companion application

## Unleash the Power of Generative AI on Your Devices

You don't necessarily need an AI pin:
1. Your smartphone or smartwatch already has the potential to be your personal AI powerhouse.
2. AI pins so far turned out to run Android apks on Android operating systems.

This open-source project harnesses the full might of generative AI, multi-modal capabilities,
and RAG (Retrieval Augmented Generation) to turn your existing devices into intelligent companions.

## Key Features:
* **Multi-Platform**: Experience seamless AI assistance on iOS and Android, thanks to the versatility of Flutter.
* **Voice Mastery**: Communicate effortlessly with native Android STT/TTS or unlock even more languages with Google Chirp's advanced speech recognition.
* **Personalized to You**: Your AI remembers your preferences and past conversations, providing tailored recommendations and assistance through on-device RAG technology.
* **Versatile Modes**:
  - **Natural Voice Chat**: Engage in dynamic conversations like you would with a friend.
  - **Translation Mode**: Break down language barriers with real-time translation powered by Chirp.
  - **Multi-modal Exploration**: Ask questions about anything you see through your camera, unlocking a new dimension of interaction.

## Advanced Capabilities:

* **Leverage the Gemini 1.5 Flash & Pro Models**: Experience cutting-edge AI language understanding and generation.
* **Tap into Powerful Tools**:
  - Location-aware responses
  - Real-time weather forecasts
  - Sunrise and sunset information
  - Web research through Tavily (API key required)
  - Up-to-date fiat and crypto currency exchange rates

### On the Horizon:
* Web search via DuckDuckGo Assist
* Business insights with Alpha Vantage (API key required)

### Future Possibilities:
* Expand your AI's toolkit with SerpAPI integration
* Calendar integration
* Email integration
* SMS / Text message, call, and Contacts integration

## Join the AI Revolution:

Transform your mobile device into a personalized AI assistant.
Contribute to this open-source project and shape the future of AI on your terms!

**Remember**: API keys for Tavily and Alpha Vantage are required to access their respective features.

*Let's build a smarter, more connected future together!*

---

Notes:
1. A demo video of the app: https://www.youtube.com/watch?v=kCtHH6XG5as
2. This project was submitted to the [Gemini API Developer Competition](https://ai.google.dev/competition).
3. The cloud functions needed for the backend are in the functions subfolder of the repository(after).
   (after transitioning from AI Studio (ex MakerSuite) Gemini API to Firebase Vertex AI driven Gemini)
5. After the [Made By Google '24](https://store.google.com/intl/en/ideas/articles/made-by-google-recap/)
someone may compare Open MMPA to Gemini Live, however we must notice that:
   - Open MMPA targets embedded form factors
   - Open MMPA also features a local Vector Database for history and personal RAG
   - Open MMPA may lack some multi modal capabilities and integrations, but those are all planned
   - Open MMPA is open source

Initial application source code scaffold was generated by the [Very Good CLI][very_good_cli_link] 🤖

---

[coverage_badge]: coverage_badge.svg
[flutter_localizations_link]: https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
