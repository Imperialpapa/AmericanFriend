import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/services/pipeline/sentence_splitter.dart';

/// 실제 스트리밍처럼 몇 글자씩 잘라 보낸다.
Stream<String> _tokens(String text, {int size = 3}) async* {
  for (var i = 0; i < text.length; i += size) {
    yield text.substring(i, i + size > text.length ? text.length : i + size);
  }
}

void main() {
  const splitter = SentenceSplitter();

  test('약어 뒤에서 멈추지 않고 이어지는 문장을 계속 나눈다', () async {
    final out = await splitter
        .split(_tokens('Dr. Kim is here. She met Mr. Lee in the U.S. last year. '
            'They are friends. We talk a lot.'))
        .toList();

    expect(out, [
      'Dr. Kim is here.',
      'She met Mr. Lee in the U.S. last year.',
      'They are friends.',
      'We talk a lot.',
    ]);
  });

  test('괄호 안의 마침표에서는 자르지 않지만, 괄호가 닫힌 뒤 문장은 나눈다', () async {
    final out = await splitter
        .split(_tokens('I went there (저는 거기 갔어요. 정말요) yesterday. '
            'It was fun. See you.'))
        .toList();

    expect(out, [
      'I went there (저는 거기 갔어요. 정말요) yesterday.',
      'It was fun.',
      'See you.',
    ]);
  });

  test('괄호가 끝내 안 닫혀도 상한을 넘으면 스트림 종료 전에 내보낸다', () async {
    final controller = StreamController<String>();
    final out = <String>[];
    final done = Completer<void>();
    splitter
        .split(controller.stream)
        .listen(out.add, onDone: done.complete);

    controller.add('Look (this never closes. ');
    for (var i = 0; i < 40; i++) {
      controller.add('Filler sentence $i. ');
    }
    await pumpEventQueue();

    // 스트림은 아직 열려 있다 — 예전엔 여기까지 한 문장도 안 나와 TTS가 멈췄다.
    expect(out, isNotEmpty);
    expect(out.first.length,
        greaterThan(SentenceSplitter.maxUnclosedParenLength));
    expect(out.first, startsWith('Look (this never closes.'));

    await controller.close();
    await done.future;
    expect(out.join(' '), contains('Filler sentence 39.'));
  });

  test('취소된 스트림의 잔여 텍스트가 다음 호출로 새지 않는다', () async {
    final first = StreamController<String>();
    final sub = splitter.split(first.stream).listen((_) {});
    first.add('This sentence was cut off by the user');
    await pumpEventQueue();
    // async* 구독 취소는 제너레이터가 다음 이벤트를 받을 때 반영되므로
    // 완료를 기다리지 않는다(파이프라인의 barge-in 경로와 같다).
    unawaited(sub.cancel());

    final out = await splitter.split(_tokens('Hello there. ')).toList();
    expect(out, ['Hello there.']);
    await first.close();
  });

  test('같은 인스턴스로 동시에 두 스트림을 나눠도 글자가 섞이지 않는다', () async {
    const a = 'Alpha one is here. Alpha two follows.';
    const b = 'Beta two is new. Beta keeps streaming.';
    final ca = StreamController<String>();
    final cb = StreamController<String>();
    final fa = splitter.split(ca.stream).toList();
    final fb = splitter.split(cb.stream).toList();

    for (var i = 0; i < a.length || i < b.length; i++) {
      if (i < a.length) ca.add(a[i]);
      if (i < b.length) cb.add(b[i]);
      await pumpEventQueue(times: 2);
    }
    await ca.close();
    await cb.close();

    expect(await fa, ['Alpha one is here.', 'Alpha two follows.']);
    expect(await fb, ['Beta two is new.', 'Beta keeps streaming.']);
  });
}
