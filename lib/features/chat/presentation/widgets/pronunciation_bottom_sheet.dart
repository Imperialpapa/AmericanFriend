import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/ai/prompts/pronunciation_prompt.dart';

/// 따라 읽기 발음 연습 바텀시트
class PronunciationBottomSheet extends ConsumerStatefulWidget {
  final String originalText;

  const PronunciationBottomSheet({super.key, required this.originalText});

  @override
  ConsumerState<PronunciationBottomSheet> createState() =>
      _PronunciationBottomSheetState();
}

enum _PracticePhase { ready, listening, evaluating, result }

class _PronunciationBottomSheetState
    extends ConsumerState<PronunciationBottomSheet> {
  final SpeechToText _stt = SpeechToText();
  _PracticePhase _phase = _PracticePhase.ready;
  String _spokenText = '';
  String _partialText = '';
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    await _stt.initialize();
  }

  Future<void> _playOriginal() async {
    final ttsQueue = ref.read(ttsQueueProvider);
    await ttsQueue.enqueue(widget.originalText);
  }

  Future<void> _startListening() async {
    setState(() {
      _phase = _PracticePhase.listening;
      _spokenText = '';
      _partialText = '';
      _error = null;
    });

    final settings = ref.read(settingsProvider);
    await _stt.listen(
      onResult: (result) {
        setState(() => _partialText = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _spokenText = result.recognizedWords;
          _evaluate();
        }
      },
      listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation),
      localeId: settings.sttLanguage,
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    if (_partialText.isNotEmpty && _spokenText.isEmpty) {
      _spokenText = _partialText;
      _evaluate();
    }
  }

  Future<void> _evaluate() async {
    setState(() => _phase = _PracticePhase.evaluating);

    final settings = ref.read(settingsProvider);
    final aiService = ref.read(aiServiceProvider);

    try {
      final prompt = PronunciationPrompt.build(
        originalText: widget.originalText,
        spokenText: _spokenText,
        nativeLanguage: settings.nativeLanguage,
        targetLanguage: settings.targetLanguage,
      );

      final result = await aiService.evaluatePronunciation(prompt: prompt);
      if (mounted) {
        setState(() {
          _result = result;
          _phase = _PracticePhase.result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _phase = _PracticePhase.result;
        });
      }
    }
  }

  Color _scoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 드래그 핸들
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // 제목
                Text(
                  l.pronSheetTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 원문
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.originalText,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _playOriginal,
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: Text(l.pronListenFirst),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 상태별 UI
                if (_phase == _PracticePhase.ready) ...[
                  Text(
                    l.pronReadyHint,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildMicButton(false),
                ],

                if (_phase == _PracticePhase.listening) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _partialText.isEmpty ? l.pronListening : _partialText,
                      style: TextStyle(
                        fontSize: 15,
                        color: _partialText.isEmpty ? Colors.grey : null,
                        fontStyle: _partialText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMicButton(true),
                ],

                if (_phase == _PracticePhase.evaluating) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l.pronEvaluating),
                ],

                if (_phase == _PracticePhase.result) ...[
                  if (_error != null)
                    Text(l.pronError(_error!),
                        style: const TextStyle(color: Colors.redAccent))
                  else if (_result != null) ...[
                    _buildResultView(),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _phase = _PracticePhase.ready;
                        _spokenText = '';
                        _partialText = '';
                        _result = null;
                        _error = null;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l.pronTryAgain),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMicButton(bool isListening) {
    return GestureDetector(
      onTap: isListening ? _stopListening : _startListening,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening ? Colors.red : Theme.of(context).colorScheme.primary,
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final score = (_result!['score'] as num?)?.toInt() ?? 0;
    final overall = _result!['overall'] as String? ?? '';
    final feedback = (_result!['feedback'] as List?) ?? [];

    return Column(
      children: [
        // 점수
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _scoreColor(score).withValues(alpha: 0.15),
            border: Border.all(color: _scoreColor(score), width: 3),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _scoreColor(score),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _scoreLabel(AppLocalizations.of(context), score),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _scoreColor(score),
          ),
        ),
        const SizedBox(height: 8),

        // 사용자가 말한 내용
        Text(
          '"$_spokenText"',
          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // 전체 코멘트
        if (overall.isNotEmpty)
          Text(overall, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 12),

        // 세부 피드백
        if (feedback.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context).pronDetails,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          ...feedback.map((item) {
            final word = item['word'] ?? '';
            final issue = item['issue'] ?? '';
            final tip = item['tip'] ?? '';
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"$word"',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(issue, style: const TextStyle(fontSize: 13)),
                  if (tip.isNotEmpty)
                    Text(tip,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _scoreLabel(AppLocalizations l, int score) {
    if (score >= 90) return l.pronScoreExcellent;
    if (score >= 70) return l.pronScoreGood;
    if (score >= 50) return l.pronScoreKeepPracticing;
    return l.pronScoreNeedsWork;
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }
}
