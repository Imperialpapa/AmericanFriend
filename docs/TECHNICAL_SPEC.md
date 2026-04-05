# Language Friend - Technical Specification

## Overview

| Item | Detail |
|------|--------|
| App Name | Language Friend (eng_friend) |
| Version | 0.1.0+1 (MVP) |
| Platform | Android (API 21+), iOS ready |
| Framework | Flutter 3.x, Dart 3.11+ |
| Architecture | Feature-first Clean Architecture + Riverpod |
| Codebase | ~50 Dart files, ~6,000 lines |

---

## Tech Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| State Management | Riverpod 2.x | Reactive DI, async state |
| Routing | go_router | Navigation, deep links |
| Networking | Dio 5.x | HTTP client with interceptors |
| Local DB | Drift (SQLite) | Conversation history |
| Secure Storage | flutter_secure_storage | API key encryption |
| Preferences | shared_preferences | Settings persistence |
| TTS | flutter_tts | On-device text-to-speech |
| STT | speech_to_text | On-device speech recognition |
| Models | freezed + json_serializable | Immutable data classes |

---

## Supported AI Providers

| Provider | Model | API Base URL | Pricing |
|----------|-------|-------------|---------|
| Google Gemini | gemini-2.5-flash | generativelanguage.googleapis.com | Free (1,500 req/day) |
| Groq | llama-3.3-70b-versatile | api.groq.com/openai/v1 | Free (14,400 req/day) |
| Anthropic Claude | claude-sonnet-4-20250514 | api.anthropic.com/v1 | Paid |
| OpenAI | gpt-4o | api.openai.com/v1 | Paid |

All providers implement a common `AiService` interface:
```
AiService
  +sendMessage()      -> Future<String>
  +streamMessage()    -> Stream<String>
  +assessLevel()      -> Future<LevelAssessment>
  +generateSuggestions() -> Future<List<Suggestion>>
```

Provider switching is handled by `AiServiceFactory` + Riverpod. Changing the provider in Settings instantly recreates the service instance.

---

## Supported Languages

| Language | Code | TTS/STT | AI Name |
|----------|------|---------|---------|
| English (US) | en-US | en-US | American English |
| English (UK) | en-GB | en-GB | British English |
| Chinese (Mandarin) | zh-CN | zh-CN | Mandarin Chinese |
| Chinese (Cantonese) | zh-HK | zh-HK | Cantonese Chinese |
| Korean | ko-KR | ko-KR | Korean |
| Japanese | ja-JP | ja-JP | Japanese |
| Spanish | es-ES | es-ES | Spanish |
| French | fr-FR | fr-FR | French |
| Italian | it-IT | it-IT | Italian |

### Language Compatibility Matrix

| Provider | Full Support | Limited (warning shown) |
|----------|-------------|------------------------|
| Gemini | All 9 | - |
| Claude | All 9 | - |
| OpenAI | All 9 | - |
| Groq | 6 languages | Cantonese, Mandarin, Italian |

---

## Level System

### Configuration
- Range: 1-10
- Default: 1 (Absolute Beginner)
- Auto-assessment: Every 5 user messages
- Max change per assessment: +/- 1 level
- Manual override: Available in Settings

### Level Response Guidelines

| Level | Response Length | Vocabulary | Native Hints |
|-------|---------------|------------|--------------|
| 1 | 1 sentence | Most basic words | Every sentence |
| 2 | 1-2 sentences | Basic everyday | Key words |
| 3 | 2 sentences | Simple phrases | New words |
| 4 | 2-3 sentences | Common idioms | New expressions |
| 5 | 2-3 sentences | Natural varied | When needed |
| 6 | 3-4 sentences | Idioms freely | Minimal |
| 7 | 3-4 sentences | Rich vocabulary | Cultural only |
| 8 | 4-5 sentences | Advanced + slang | Almost none |
| 9 | 4-5 sentences | Native-level nuance | Only if asked |
| 10 | ~5 sentences | Full native range | None |

---

## Real-time Conversation Pipeline

```
User Input (text/voice)
  -> [On-device STT] (if voice)
    -> [AI Streaming] (token by token)
      -> [SentenceSplitter] (detect sentence boundaries)
        -> [UI Update] (display sentence)
        -> [TTS Queue] (read aloud if enabled)
          -> [Audio Output]
```

### Latency Targets

| Stage | Target | Method |
|-------|--------|--------|
| Voice -> Text | < 0.5s | On-device STT |
| Text -> First AI token | < 1s | Connection pooling |
| First token -> First sentence | < 1-2s | Streaming + sentence detection |
| First sentence -> TTS start | < 0.3s | On-device TTS |
| **Total perceived latency** | **< 2-3s** | Pipeline parallelism |

### Key Components

| Component | File | Responsibility |
|-----------|------|---------------|
| ConversationPipeline | `services/pipeline/conversation_pipeline.dart` | Orchestrates the full loop |
| SentenceSplitter | `services/pipeline/sentence_splitter.dart` | Splits token stream into sentences |
| TtsQueue | `services/pipeline/tts_queue.dart` | Sequential TTS playback queue |
| PipelineEvent | `services/pipeline/pipeline_event.dart` | Typed events for UI updates |

### TTS Filtering Logic
- Native language translations always wrapped in `(parentheses)` by AI
- TTS strips `\([^)]*\)` pattern before reading (target language only)
- If `nativeTtsEnabled = true`, parentheses are kept for TTS
- If `targetTtsEnabled = false`, TTS is skipped entirely

---

## Settings Architecture

### Storage

| Type | Storage | Data |
|------|---------|------|
| API Keys | FlutterSecureStorage (encrypted) | claude, openai, gemini, groq keys |
| Preferences | SharedPreferences | All other settings |

### Settings Fields

| Field | Type | Default | Storage Key |
|-------|------|---------|-------------|
| aiProvider | AiProviderType | gemini | `ai_provider` |
| nativeLanguage | AppLanguage | korean | `native_language` |
| targetLanguage | AppLanguage | englishUS | `target_language` |
| showNativeHint | bool | true | `show_native_hint` |
| nativeTtsEnabled | bool | false | `native_tts_enabled` |
| showTargetText | bool | true | `show_target_text` |
| targetTtsEnabled | bool | true | `target_tts_enabled` |
| suggestionMode | SuggestionMode | immediate | `suggestion_mode` |
| suggestionDelaySec | int | 5 | `suggestion_delay` |
| ttsSpeechRate | double | 0.5 | `tts_speech_rate` |
| ttsVoiceGender | TtsVoiceGender | female | `tts_voice_gender` |

### Reactivity
Settings changes are propagated via Riverpod `ref.watch(settingsProvider)`. Any widget or provider watching settings automatically rebuilds when values change.

---

## Project Structure

```
lib/
├── main.dart                              # Entry point, ProviderScope setup
├── core/
│   ├── constants/
│   │   ├── app_constants.dart             # AI character name, etc.
│   │   └── level_constants.dart           # Level range, names, assessment config
│   └── error/
│       └── failures.dart                  # Error types
│
├── di/
│   └── service_providers.dart             # Riverpod providers (AI, TTS, DB, Pipeline)
│
├── features/
│   ├── chat/
│   │   ├── domain/entities/               # Message, Suggestion
│   │   └── presentation/
│   │       ├── providers/                 # ChatNotifier, SuggestionNotifier
│   │       ├── screens/chat_screen.dart   # Main chat UI
│   │       └── widgets/                   # MessageBubble, ChatInputBar, SuggestionChips
│   │
│   ├── voice/
│   │   ├── domain/entities/voice_state.dart
│   │   └── presentation/providers/voice_provider.dart
│   │
│   ├── level/
│   │   ├── domain/entities/level_assessment.dart
│   │   └── presentation/providers/level_provider.dart
│   │
│   ├── settings/
│   │   ├── domain/entities/user_settings.dart
│   │   └── presentation/
│   │       ├── providers/settings_provider.dart
│   │       └── screens/settings_screen.dart
│   │
│   └── onboarding/
│       └── presentation/screens/onboarding_screen.dart
│
├── services/
│   ├── ai/
│   │   ├── ai_service.dart                # Abstract interface
│   │   ├── ai_service_factory.dart        # Factory pattern
│   │   ├── ai_provider_type.dart          # Enum + language support info
│   │   ├── claude/claude_service.dart
│   │   ├── openai/openai_service.dart
│   │   ├── gemini/gemini_service.dart
│   │   ├── groq/groq_service.dart
│   │   └── prompts/
│   │       ├── system_prompt.dart         # Dynamic prompt builder (level + languages)
│   │       ├── suggestion_prompt.dart
│   │       └── level_prompts.dart
│   │
│   ├── language/
│   │   └── app_language.dart              # 9-language enum with TTS/STT codes
│   │
│   ├── pipeline/
│   │   ├── conversation_pipeline.dart     # Streaming orchestrator
│   │   ├── pipeline_event.dart            # Typed events
│   │   ├── sentence_splitter.dart         # Token -> sentence stream
│   │   └── tts_queue.dart                 # Sequential TTS queue
│   │
│   ├── feature_flags/
│   │   ├── feature_flag_service.dart
│   │   └── local_feature_flags.dart
│   │
│   └── local_db/
│       └── app_database.dart              # Drift SQLite (conversations, messages)
│
└── docs/                                  # Documentation
```

---

## System Prompt Architecture

The system prompt is dynamically built from:
1. **Target language** - determines the primary language of responses
2. **Native language** - determines translation language
3. **User level** (1-10) - controls vocabulary, response length, hint frequency
4. **showNativeHint** - whether to include translations

### Critical Format Rule
All native language text MUST be in parentheses. This enables:
- TTS to strip translations via regex `\([^)]*\)`
- UI to color-code translations (grey) vs target text (white)
- Toggle visibility of translations without re-prompting

---

## Data Flow

```
[Settings] --watch--> [AiServiceFactory] --creates--> [AiService instance]
                              |
[Settings] --read--> [SystemPrompt.build()] --passes--> [ConversationPipeline]
                              |
[ChatNotifier] --controls--> [ConversationPipeline] --emits--> [PipelineEvent]
                              |
[PipelineEvent] --updates--> [ChatState] --rebuilds--> [ChatScreen UI]
                              |
[SuggestionNotifier] --listens--> [ChatState.isAiTyping] --triggers--> [AI.generateSuggestions()]
                              |
[LevelNotifier] --counts--> [user messages] --every 5--> [AI.assessLevel()]
```

---

## Build & Deployment

| Command | Output |
|---------|--------|
| `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| `flutter run --release` | Install on connected device |

### APK Size
- Release APK: ~55 MB (includes all TTS/STT assets)

### Min SDK
- Android API 21 (Android 5.0 Lollipop)
