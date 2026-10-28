<!-- DRAFT: 사용자 법률 검토 필요 -->
# Korean Friend Privacy Policy

Last updated: September 23, 2026

Korean Friend ("the app") is an AI language-learning app you use without signing up. The app does not ask for account details such as your name, e-mail address or phone number. This policy explains what information is sent where while you use the app, and how long it is kept.

## 1. What we process and why

### Conversation content
- What: the sentences you type or say (speech is converted to text first), the AI's replies, and the AI instructions that carry your conversation settings (level, languages, topic)
- Why: to generate AI replies, assess your level, and suggest sentences and evaluate pronunciation
- Where it goes: on the free tier, through the app server (Vercel) to the AI provider (currently Groq); with your own API key, directly to the AI provider you chose.
- The app server does not store conversation content. Each AI provider keeps data according to its own policy.

### Device ID
- What: a random ID (UUID) created the first time you open the app. It is not linked to your name or phone number.
- Why: to count the free tier's daily limit and to prevent report abuse
- Even with your own API key, this ID is sent along when you report a response.

### IP address
- Why: to block excessive requests (a daily limit per IP address)
- The app server does not store your IP address itself, only a hash (a one-way transformed value). It may appear in the hosting provider's (Vercel) access logs.

### Advertising ID and ad-related data
- The app shows Google AdMob banner ads. Google collects the advertising ID, device and app information, IP address and similar data to serve and measure ads and to prevent invalid clicks.
- How Google uses this data: https://policies.google.com/technologies/ads
- You can reset or delete the advertising ID in your phone's settings (for example Privacy > Ads; this varies by device).

### Voice (microphone)
- The microphone is used only for voice input, pronunciation practice and hands-free conversation.
- Your voice is processed by your phone's speech recognition service (for example Google speech recognition), and the app receives only the resulting text. The app does not store audio or send it to the app server. The speech recognition service handles audio according to its provider's policy.

### Reports on AI responses
- What: the reported AI reply (up to 2,000 characters), your message right before it (up to 1,000 characters), the reason, the AI provider and model name, app version, language setting, and a hashed device ID
- Why: to review and improve harmful or incorrect replies

### Data stored only on your device
- Conversation history, vocabulary, learning records (streak, level, missions), settings, and your own API keys (in the device's encrypted storage)
- This data is not sent to the app server.

## 2. Service providers and international transfers

The companies below process data to run the app's features. All of them are outside Korea, and data is sent to them over the internet (encrypted HTTPS) while you use the app.

- Vercel Inc. (USA): runs the app server and relays requests. The server runs in regions close to you, such as Singapore, and in the USA. Data: conversation content, device ID, IP address
- Upstash, Inc. (USA): stores daily-limit counters and reports. Data: device ID, hashed IP address, report contents
- Groq, Inc. (USA): generates AI replies on the free tier. Data: conversation content
- If you use your own API key, the provider you chose: Anthropic PBC (USA), Google LLC (USA, Gemini), OpenAI, L.L.C. (USA), Groq, Inc. (USA). Data: conversation content
- Google LLC (USA): AdMob ads. Data: advertising ID, device and app information, IP address

If you do not want your data transferred abroad, stop using the app and uninstall it. AI conversations cannot be provided without these transfers.

## 3. Retention and deletion

- Daily-limit counters (device ID, hashed IP address): deleted automatically after 48 hours
- Reports on AI responses: only the latest 2,000 are kept; older ones are deleted automatically
- Reports that failed to send: up to 20 are kept on your device and deleted once they are sent
- Data stored only on your device: until you uninstall the app
- Data kept by AI providers and Google: according to each company's policy

## 4. How to delete your data and your rights

- Everything stored on your device: uninstall the app, or go to your phone's Settings > Apps > Korean Friend > Storage > Clear data
- Advertising ID: reset or delete it in your phone's settings
- To access, correct, delete or stop the processing of data kept on the server (such as reports), e-mail us at the address below. Because the app has no accounts, please include the date and content of your report so we can find it.

## 5. Security

- All communication is encrypted with HTTPS.
- Your own API keys stay in the device's encrypted storage and are never sent to the app server.
- The app server stores IP addresses and reporters' device IDs only as hashes.

## 6. Contact

- Privacy contact: the Korean Friend developer
- E-mail: raphael70kim@gmail.com (in the app: Settings > Send feedback)

## 7. Changes to this policy

If this policy changes, we will let you know through an app update or an in-app notice.
