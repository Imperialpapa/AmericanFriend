# Language Friend - User Manual

AI tutor Alex와 자연스러운 대화를 통해 외국어를 배우는 앱입니다.
9개 언어를 지원하며, 모국어와 대상 언어를 자유롭게 선택할 수 있습니다.

---

## Getting Started

### 1. API Key Setup
1. Launch the app and tap the **Settings (gear icon)** in the top right
2. Select an AI Model (default: Google Gemini)
3. Enter the API key for the selected model:
   - **Gemini**: Free at aistudio.google.com/apikey (1,500 req/day)
   - **Groq**: Free at console.groq.com/keys (14,400 req/day, ultra fast)
   - **Claude**: Paid at console.anthropic.com (highest quality)
   - **OpenAI**: Paid at platform.openai.com/api-keys

### 2. Language Setup
1. In Settings, choose your **Native Language** (default: Korean)
2. Choose your **Target Language** (default: English US)
3. Available languages:
   - English (US), English (UK)
   - Chinese (Mandarin), Chinese (Cantonese)
   - Korean, Japanese
   - Spanish, French, Italian

> Native and target language cannot be the same.

### 3. Start Chatting
- Type a message in the target language at the bottom input bar
- Or tap the microphone button to speak

---

## Main Features

### Natural Conversation
- Alex talks like a friendly native speaker, not a textbook
- Grammar mistakes are naturally corrected through rephrasing
- Difficulty adjusts to your level (1-10)

### Level System (1-10)
Adjustable in Settings. Controls vocabulary difficulty and response length.

| Level | Name | Response Length | Vocabulary |
|-------|------|----------------|------------|
| 1 | Absolute Beginner | 1 sentence | Basic words (hi, yes, good) |
| 2 | Beginner | 1-2 sentences | Everyday words |
| 3 | Elementary | 2 sentences | Simple phrases |
| 4 | Pre-Intermediate | 2-3 sentences | Common idioms |
| 5 | Intermediate | 2-3 sentences | Natural conversation |
| 6 | Upper Intermediate | 3-4 sentences | Idioms & phrasal verbs |
| 7 | Pre-Advanced | 3-4 sentences | Rich vocabulary |
| 8 | Advanced | 4-5 sentences | Advanced expressions |
| 9 | Upper Advanced | 4-5 sentences | Near-native nuance |
| 10 | Native-like | ~5 sentences | Full native level |

The level also auto-adjusts based on your conversation (every 5 messages).

### Native Language Translation
- AI responses include (native translation) in parentheses
- Target language text is white, translations are shown in grey
- Controllable in Settings (see Display Options below)

### Conversation Suggestions
- After AI responds, suggestion chips appear: "Try saying..."
- Target language text in yellow, native hints in blue
- Tap a suggestion to send it immediately
- Mode: Immediate (instant) or Delayed (1-15 seconds)

### Voice (TTS)
- AI responses are automatically read aloud in the target language
- Tap the speaker button on any AI message to replay
- Adjustable: voice gender (Female/Male) and speed (Slow/Normal/Fast)

### Speech Input (STT)
- Tap the microphone button to speak in the target language
- Real-time partial recognition shown while speaking
- Final result is automatically sent as a message

---

## Display & Audio Options

### Target Language
| Option | Default | Description |
|--------|---------|-------------|
| Show text | ON | Display AI response text on screen. OFF = "Tap to reveal" mode (listening practice) |
| Read aloud | ON | TTS playback. Turn OFF in quiet environments |

### Native Language
| Option | Default | Description |
|--------|---------|-------------|
| Show translation | ON | Show (native) translation hints in responses. OFF = target language only |
| Read translation aloud | OFF | Include native translations in TTS playback |

---

## Settings Reference

| Section | Item | Description |
|---------|------|-------------|
| **Language** | Native Language | Your mother tongue (default: Korean) |
| | Target Language | The language you're learning (default: English US) |
| **Level** | Level slider (1-10) | Controls AI response difficulty and length |
| **AI Model** | Model selection | Gemini, Groq (Llama 3.3), Claude (Sonnet), OpenAI (GPT-4o) |
| **API Key** | Key input | API key for the selected model |
| **Target Language** | Show text | Display AI response text ON/OFF |
| | Read aloud | TTS for target language ON/OFF |
| **Native Language** | Show translation | Display native hints ON/OFF |
| | Read translation aloud | TTS for native language ON/OFF |
| **Suggestions** | Mode | Immediate or Delayed (1-15s) |
| **Voice** | Gender | Female / Male |
| | Speed | Slow / Normal / Fast |

### AI Model + Language Compatibility
- Gemini, Claude, OpenAI: All 9 languages fully supported
- Groq (Llama 3.3): Warning shown for Cantonese, Mandarin, Italian (quality may be lower)

---

## Usage Tips

- **Beginner (Lv.1-3)**: Enable native translations, set speech speed to Slow
- **Intermediate (Lv.4-6)**: Disable native translations, use suggestions as hints
- **Advanced (Lv.7-10)**: Try complex topics, use "Tap to reveal" mode for listening practice

---

## Troubleshooting

| Symptom | Solution |
|---------|----------|
| 429 error (rate limit) | Wait and retry. Auto-retry (2-8s backoff) is built in |
| Invalid API key error | Check your key in Settings |
| Suggestions not showing | Wait for AI response to complete |
| No audio | Check device volume, verify "Read aloud" is ON in Settings |
| Native language not shown | Verify "Show translation" is ON in Settings |
| AI reads native language | Ensure "Read translation aloud" is OFF (default) |

---

## Build & Run (Developers)

### Requirements
- Flutter SDK 3.x+
- Android SDK (API 21+)
- Android device with USB debugging or emulator

### Commands
```bash
# Install dependencies
flutter pub get

# Debug mode
flutter run

# Release mode (USB device)
flutter run --release

# Build APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Note
- Samsung Galaxy devices: Disable **Auto Blocker** for USB debugging
  - Settings > Security and privacy > Auto Blocker > OFF
