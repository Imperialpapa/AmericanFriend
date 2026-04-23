# Claude Design Prompt — Korean Friend Redesign

> claude.ai/labs의 Claude Design에 붙여넣을 통합 프롬프트
> 작성일: 2026-04-23
> 사용법: 이 문서 전체를 복사해서 Claude Design 새 프로젝트에 붙여넣기

---

## 🎯 Project Brief

I'm redesigning **Korean Friend**, a mobile language learning app where users chat with an AI character named **"Alex"** to practice English (or other languages). Currently built with Flutter Material 3, the design feels generic and lacks brand identity. I want a **warm, playful, trendy modern** redesign that feels like a friendly conversation partner, not a sterile AI tool.

### Target users
- Korean adults (20-40s) learning English casually
- Mobile-first, used in short sessions (commute, before bed, lunch break)

### Goals
1. Strong brand presence — Alex feels like a real warm friend, not just a chatbot
2. Make learning feel rewarding & visual — gamification (streaks, levels, missions) shines
3. Reduce visual clutter in dense screens (Settings, AppBar)
4. Keep it modern 2026 — confident, not childish; playful, not sterile

### Tone keywords
`warm` + `playful` + `trendy modern` + `confident`

### What to AVOID
- Generic AI app vibes (single-color gradients, all-purple, dark sterile)
- Cold tech feel (blue + grey only, B2B serious)
- Childish (overly cartoonish characters, novelty fonts)
- Designs that clash with bottom banner ads (AdMob ads stay)

### Reference inspiration
- **Duolingo** — character-led, rewarding, but less cartoony
- **Cake** — Korean English-learning mobile UX
- **ChatGPT mobile** — clean message bubbles
- **Linear** — confident minimal, beautiful dark mode
- **Headspace** — warm + playful illustration style
- **Anthropic Claude** — warm minimal, beige/orange tonality

---

## 🎨 Color Palette — please propose 3 options

Current palette is just a single Material 3 seed (`#4A90D9` cool blue) — too plain.
Please propose **three** distinct directions:
- **Option A — Warm Coral**: coral/orange primary, cream secondary, indigo accent
- **Option B — Modern Sage**: sage green primary, beige secondary, mustard accent
- **Option C — Trendy Lavender**: soft lavender primary, peach secondary, deep navy accent

Each should:
- Work in both light and dark mode (provide both)
- Define: primary, primaryContainer, secondary, accent, surface, surfaceVariant, error, success, warning
- Include rationale (why this palette fits the brand)

---

## ✍️ Typography & Tokens

Please define a complete token system:
- **Type scale**: display / headline (L/M/S) / title (L/M/S) / body (L/M/S) / label (L/M/S)
- **Font recommendation**: trendy but readable on mobile, supports Korean characters (e.g., Pretendard, Inter, Noto Sans KR)
- **Border radius scale**: xs/sm/md/lg/xl/full (currently inconsistent: 4, 8, 12, 16, 24 used arbitrarily)
- **Spacing scale**: 4/8/12/16/24/32/48 (8pt grid recommended)
- **Elevation/shadow scale**: subtle to prominent, mobile-appropriate
- **Motion**: standard easing curves, durations for micro-interactions

---

## 🐻 Character "Alex" — illustration direction

Currently Alex is just a `CircleAvatar` with the letter "A" — no actual character.
Please propose 2-3 visual directions for an Alex mascot:
- Gender-neutral (or provide both male/female variants)
- Modern friendly illustration style (Memoji/Notion/Figma-illustration vibe)
- Need variants: small (AppBar 32px), medium (Welcome 80px), large (Onboarding 120px)
- Need expressions: happy / thinking / celebrating / listening
- If full character is too complex, propose a simplified avatar/badge approach

---

## 📱 Screens to redesign (in priority order)

### Screen 1: Chat Screen (the main hub)

**Current structure**:
- AppBar: small avatar + character name "Alex" + level "Lv.5 · Intermediate" + Streak badge + 3 action icons (Topics, Missions, Settings)
- Body: optional Lottie avatar (120x120) + chat message list + suggestion chips + input bar
- Bottom: input bar with mic button, text field, send button + AdMob banner

**Current problems**:
- AppBar is overcrowded (5+ elements)
- No brand presence — "A" text avatar is bland
- Avatar widget invades message space when shown
- Topic activation indicator squeezed into AppBar

**Message bubble specs**:
- User messages: right-aligned, primaryContainer background, bottom-right corner sharper
- AI messages: left-aligned, surfaceVariant background, bottom-left corner sharper
- AI bubbles include mic (repeat-after-me) + speaker (TTS) buttons
- AI corrections shown in amber box: `"wrong" → "right" (explanation)`
- Korean translation hints in parentheses, dimmer color

**Suggestion chips** (shown after AI response):
- Label "Try saying..."
- Each chip: English text (yellow `#FFD54F`) + Korean hint (blue `#64B5F6`, smaller) + speaker icon
- Currently looks like a plain bordered card — make these feel inviting/clickable

**Empty state (no messages yet)**:
- Big character avatar
- Greeting "Hey! I'm Alex"
- Subtitle about practicing the target language
- If no API key: prominent error card with "Go to Settings" button

**Please redesign**:
- Reorganize AppBar (consider: collapsed state vs. compact persistent header)
- Beautiful character presence in empty state (this is the first thing users see)
- Modern message bubble style (consider: tail vs. no-tail, shadow, spacing)
- Suggestion chips that feel tappable and fun
- Input bar that's mobile-native and confident
- Where to put streak/level info if not in AppBar

### Screen 2: Onboarding (4 steps)

**Current flow**:
1. **Welcome** — "Hey! I'm Alex" greeting + "Let's Go!" CTA
2. **Language Setup** — native language dropdown + target language dropdown
3. **API Key** — Gemini/Groq toggle + 3-step card (open URL → create key → paste)
4. **Level** — slider 1-10 with level name display + "Start Chatting!"

**Current problems**:
- No progress indicator (users don't know how many steps left)
- Page 3 (API Key) is dense and intimidating
- Welcome page has zero brand presence

**Please redesign**:
- Add progress indicator (dots or bar)
- Welcome that wow's — character animation, warm greeting, builds anticipation
- API key page that feels less technical, more guided
- Consistent layout grid across all 4 pages
- Reward feeling on the final "Start Chatting!" tap

### Screen 3: Settings (long ListView)

**Current sections** (in order):
1. Weekly Report card (navigates away)
2. My Vocabulary card (navigates away)
3. Language (native + target dropdowns + compatibility warning)
4. Level (slider + description)
5. AI Model (4 radio options: Gemini/Groq/Claude/OpenAI)
6. Model Version (sub-radios for selected provider)
7. API Key (only for selected provider)
8. Conversation Suggestions (Immediate/Delayed + slider)
9. Target Language Options (Show text / Read aloud switches)
10. Native Language Options (Show translation / Read translation switches)
11. Voice (Female/Male + speed slider)
12. Avatar (Show avatar switch)
13. Daily Reminder (enable + time picker)
14. Feedback (email link)

**Current problems**:
- 14 sections in a single scroll — overwhelming
- No grouping/search
- Weekly Report & Vocabulary buried in settings (should be primary nav?)
- Inconsistent: some are Card, some are bare Divider sections

**Please redesign**:
- Propose better information architecture (group related items, possibly hide advanced behind expansion)
- Consider: should Weekly Report / Vocabulary live in primary navigation instead of settings?
- Make each section visually distinct with clear hierarchy
- Modern toggle/radio/slider styling that fits the new palette
- API key section should feel safe (it's a sensitive input)

---

## 📦 Deliverables I want from you

1. **Design system token sheet** — colors (3 options), typography, radii, spacing, shadows, motion
2. **Character Alex direction** — 2-3 visual proposals, key expressions
3. **High-fidelity mockups** for the 3 screens above:
   - Light mode + Dark mode for each
   - Empty states + loading states + error states where relevant
   - Mobile portrait orientation, ~390x844 (iPhone 14) or similar
4. **Exportable HTML/CSS** that I can use as a Flutter porting reference (component-by-component)
5. **A short rationale doc** explaining your design choices and tradeoffs

## 🧭 Iteration plan

After your first pass:
- I'll pick the favorite color palette + character direction
- We'll iterate on the Chat screen first (it's the main hub)
- Then Onboarding, then Settings

Please prioritize feeling and brand presence over feature parity in the first pass. I'd rather see a bold, opinionated direction I can react to than a safe, generic refinement.

---

## 📎 Appendix — context files (reference only, don't redesign)

I have detailed inventory and design system snapshots if you need them. The key constraints again:
- Flutter Material 3 stack (we'll port your designs back to Flutter widgets)
- Bottom AdMob banner stays on every main screen
- Korean + English language support (variable text length)
- Dark mode is mandatory and must be first-class

Ready when you are. Surprise me.
