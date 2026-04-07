# EngFriend — Feature Roadmap

> Last updated: 2026-04-07

## Implemented (v0.1.0)

- [x] Free conversation (text + voice, 4 AI providers)
- [x] 9 language pairs, first-launch language setup (auto-detect native)
- [x] Per-provider model selection (Gemini 2.5 Flash/Pro, GPT-4o/Mini, etc.)
- [x] 10-level system with auto-assessment (every 5 messages)
- [x] Conversation suggestions (immediate/delayed, context-aware)
- [x] TTS pipeline (gender, speed, native text stripping)
- [x] STT with barge-in
- [x] Daily streak + goals
- [x] Topic focus mode (8 categories, 24+ topics)
- [x] Role play missions (Easy/Medium/Hard, star rewards)
- [x] Vocabulary with spaced repetition
- [x] Weekly report (chart + stats)
- [x] Daily reminder notifications
- [x] Feedback email (Settings)
- [x] Onboarding (Welcome → Language → API Key → Level)

---

## Next Up

### High Priority
- [ ] **Pronunciation assessment** — tap AI sentence to "repeat after me", STT vs original comparison, AI-powered feedback (Korean speaker-specific: L/R, F/P, TH)
- [ ] **Level test expansion** — on-demand 4-skill test (listening, reading, speaking, writing), multi-skill radar chart
- [ ] **Talking avatar animation** — Lottie/Rive animated face in chat, synced with TTS state (idle/speaking)

### Medium Priority
- [ ] **Grammar correction report** — post-conversation grammar error summary
- [ ] **Conversation history browser** — past conversation list, resume past chats
- [ ] **Quiz mode** — fill-in-the-blank from learned expressions
- [ ] **Expression notes** — bookmark idioms/slang with examples

### Low Priority
- [ ] **Character selection** — different AI personalities (business mentor, humorous friend, etc.)
- [ ] **Home screen widget** — daily expression widget
- [ ] **Daily one-liner push** — useful expression via notification

---

## Future Phases

### Commercialization (see COMMERCIALIZATION_PLAN.md)
- [ ] Backend server (Firebase/Supabase) for auth + usage tracking
- [ ] Freemium subscription model
- [ ] Google Play Store / App Store release

### Advanced Features
- [ ] Azure Speech SDK for phoneme-level pronunciation
- [ ] Group conversation mode
- [ ] B2B licensing (schools, companies)
