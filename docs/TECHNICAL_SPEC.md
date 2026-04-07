# Language Friend — Technical Specification

## Overview

| Item | Detail |
|------|--------|
| App Name | Language Friend (eng_friend) |
| Version | 0.1.0+1 |
| Platform | Android (API 21+), iOS ready |
| Framework | Flutter 3.x, Dart 3.11+ |
| Architecture | Feature-first Clean Architecture + Riverpod |
| Concept | AI tutor "Alex" — a friendly native speaker who helps practice through natural conversation |

---

## Tech Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| State Management | Riverpod 2.x | Reactive DI, async state |
| Routing | go_router | Navigation, deep links |
| Networking | Dio 5.x | HTTP client with interceptors |
| Local DB | Drift (SQLite) | Conversation history, vocab, activity |
| Secure Storage | flutter_secure_storage | API key encryption |
| Preferences | shared_preferences | Settings persistence |
| TTS | flutter_tts | On-device text-to-speech |
| STT | speech_to_text | On-device speech recognition |
| Notifications | flutter_local_notifications | Daily reminders |
| Email | url_launcher | Feedback email |
| Models | freezed + json_serializable | Immutable data classes |

---

## Supported AI Providers & Models

Each provider supports multiple selectable models. Users choose in Settings > AI Model > Model Version.

| Provider | Available Models | Default | Pricing |
|----------|-----------------|---------|---------|
| Google Gemini | Gemini 2.5 Flash, 2.5 Pro, 2.0 Flash | 2.5 Flash | Free (1,500 req/day) |
| Groq | Llama 3.3 70B, Llama 3.1 8B, Gemma 2 9B | Llama 3.3 70B | Free (14,400 req/day) |
| Anthropic Claude | Sonnet 4, Haiku 4.5, 3.5 Sonnet | Sonnet 4 | Paid |
| OpenAI | GPT-4o, GPT-4o Mini, GPT-4.1 Nano | GPT-4o | Paid |

Model list is defined in `AiProviderType.availableModels`. To add a new model, add an `AiModelInfo` entry — no other code changes needed.

All providers implement a common `AiService` interface:
```dart
abstract class AiService {
  Future<String> sendMessage({...});
  Stream<String> streamMessage({...});
  Future<LevelAssessment> assessLevel({...});
  Future<List<Suggestion>> generateSuggestions({...});
}
```

Provider/model switching is handled by `AiServiceFactory` + Riverpod. Settings changes take effect on the next message (lazy getter pattern, no provider recreation).

---

## Supported Languages (9)

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

### First Launch
- Native language auto-detected from device system locale
- Target language selected by user during onboarding
- Saved to SharedPreferences; subsequent launches skip selection

### Language Compatibility
- Gemini, Claude, OpenAI: All 9 languages fully supported
- Groq (Llama 3.3): Warning for Cantonese, Mandarin, Italian

---

## Level System

| Config | Value |
|--------|-------|
| Range | 1–10 |
| Default | 1 (Absolute Beginner) |
| Auto-assessment | Every 5 user messages |
| Max change | ±1 per assessment |
| Manual override | Settings slider |

### Response Guidelines by Level

| Level | Length | Vocabulary | Native Hints |
|-------|--------|------------|--------------|
| 1 | 1 sentence | Most basic words | Every sentence |
| 2-3 | 1-2 sentences | Basic everyday | Key/new words |
| 4-5 | 2-3 sentences | Common idioms, natural | When needed |
| 6-7 | 3-4 sentences | Idioms, rich vocabulary | Minimal/cultural |
| 8-9 | 4-5 sentences | Advanced, native nuance | Almost none |
| 10 | ~5 sentences | Full native range | None |

---

## Real-time Conversation Pipeline

```
User Input (text/voice)
  → [On-device STT] (if voice)
    → [AI Streaming] (token by token)
      → [SentenceSplitter] (sentence boundaries, parenthesis-aware)
        → [UI Update] (display sentence)
        → [TTS Queue] (read aloud, native text stripped via regex)
          → [Audio Output]
```

### Key Components

| Component | File | Responsibility |
|-----------|------|---------------|
| ConversationPipeline | `services/pipeline/conversation_pipeline.dart` | Orchestrates full loop |
| SentenceSplitter | `services/pipeline/sentence_splitter.dart` | Token → sentence stream, parenthesis-aware |
| TtsQueue | `services/pipeline/tts_queue.dart` | Sequential TTS playback queue |
| PipelineEvent | `services/pipeline/pipeline_event.dart` | Typed events for UI updates |

### TTS Filtering
- Native translations wrapped in `(parentheses)` by AI (space before `(` enforced in prompt)
- TTS strips `\([^)]*\)` + unclosed parenthesis fragments before reading
- `nativeTtsEnabled = true`: keeps parenthetical text for TTS
- `targetTtsEnabled = false`: skips TTS entirely

### Latency Targets

| Stage | Target | Method |
|-------|--------|--------|
| Voice → Text | < 0.5s | On-device STT |
| Text → First AI token | < 1s | Connection pooling |
| First token → First sentence | < 1-2s | Streaming + sentence detection |
| First sentence → TTS start | < 0.3s | On-device TTS |
| **Total perceived** | **< 2-3s** | Pipeline parallelism |

---

## Settings Architecture

### Storage

| Type | Storage | Data |
|------|---------|------|
| API Keys | FlutterSecureStorage (encrypted) | claude, openai, gemini, groq keys |
| Model IDs | SharedPreferences | Per-provider selected model |
| All others | SharedPreferences | Language, TTS, suggestions, etc. |

### Settings Fields

| Field | Type | Default |
|-------|------|---------|
| aiProvider | AiProviderType | gemini |
| *Model IDs | String? | Provider default |
| nativeLanguage | AppLanguage | (device locale) |
| targetLanguage | AppLanguage | englishUS |
| showNativeHint | bool | true |
| nativeTtsEnabled | bool | false |
| showTargetText | bool | true |
| targetTtsEnabled | bool | true |
| suggestionMode | SuggestionMode | immediate |
| suggestionDelaySec | int | 5 |
| ttsSpeechRate | double | 0.5 |
| ttsVoiceGender | TtsVoiceGender | female |
| reminderEnabled | bool | false |
| reminderHour/Minute | int | 20:00 |

### Reactivity
- Settings changes propagated via Riverpod
- ChatProvider and SuggestionProvider use **lazy getter functions** (`ref.read`) instead of `ref.watch` for pipeline/AI service to avoid state loss on settings change
- Pipeline and AI service are recreated on demand, not eagerly

---

## Database Schema (Drift, version 5)

| Table | Key Fields |
|-------|-----------|
| Conversations | id, title, createdAt, updatedAt |
| Messages | id, conversationId, content, role, timestamp |
| LevelHistory | level, reasoning, assessedAt |
| DailyActivity | date (PK), messageCount, streakCount, goalReached |
| TopicSessions | topicId, topicTitle, category, turnCount, startedAt, endedAt |
| MissionCompletions | missionId, turnCount, starsEarned, completedAt |
| VocabularyItems | expression, meaning, example, correctCount, intervalDays, nextReviewAt |

---

## System Prompt Architecture

Dynamically built from: target language, native language, user level (1-10), showNativeHint flag, topic context.

### Critical Rules
- All native text in parentheses: `"sentence (translation)"`
- Space before `(` enforced
- Level controls response length, vocabulary, hint frequency
- Topic Focus Mode constrains conversation to specific scenario

---

## Project Structure

```
lib/
├── main.dart                    # Entry, SharedPreferences init
├── app.dart                     # MaterialApp, onboarding check
├── core/
│   ├── constants/               # app_constants, level_constants
│   └── error/                   # failures
├── di/
│   └── service_providers.dart   # Riverpod providers (AI, TTS, DB, Pipeline)
├── features/
│   ├── chat/                    # ChatNotifier, SuggestionNotifier, UI
│   ├── voice/                   # VoiceProvider (STT + barge-in)
│   ├── level/                   # LevelProvider, auto-assessment
│   ├── settings/                # UserSettings, SettingsNotifier, SettingsScreen
│   ├── onboarding/              # 4-step: Welcome → Language → API Key → Level
│   ├── streak/                  # Daily streak tracking
│   ├── topic/                   # Topic system + focus mode
│   ├── mission/                 # Role play missions
│   ├── report/                  # Weekly report
│   └── vocabulary/              # Vocabulary + spaced repetition
├── services/
│   ├── ai/                      # AiService interface + 4 implementations
│   │   ├── claude/openai/gemini/groq/
│   │   └── prompts/             # system_prompt, suggestion_prompt, level_prompts
│   ├── language/                # AppLanguage enum (9 languages)
│   ├── pipeline/                # ConversationPipeline, SentenceSplitter, TtsQueue
│   ├── feature_flags/           # Local feature flags
│   ├── local_db/                # Drift database + tables
│   └── notification/            # Daily reminder service
```

---

## Onboarding Flow

1. **Welcome** — Meet Alex
2. **Language Setup** — Native (auto-detected) + Target (user picks)
3. **API Key** — Link to Settings for key entry
4. **Level Selection** — Slider 1-10, start chatting

---

## Implemented Features

- Free conversation with AI (text + voice)
- 4 AI providers with per-provider model selection
- 9 language pairs (native + target)
- 10-level system with auto-assessment
- Conversation suggestions (immediate/delayed)
- TTS (gender, speed, selective reading)
- STT with barge-in
- Daily streak + goals
- Topic focus mode (8 categories)
- Role play missions (Easy/Medium/Hard)
- Vocabulary with spaced repetition
- Weekly report (chart + stats)
- Daily reminder notifications
- Feedback email

---

## Build & Deployment

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --release
flutter build apk --release    # → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release
```

- Release APK: ~55 MB
- Min SDK: Android API 21

---

## Design Principles

- **Modular architecture** — features as independent modules
- **AI abstraction layer** — swap providers/models without touching feature code
- **Lazy settings** — settings changes don't recreate stateful providers
- **Feature flags** — enable/disable features without code changes
- **Extensible DB** — Drift schema versioning for smooth migrations
