import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/presentation/providers/activity_recorder_provider.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';

Message _msg(String id, MessageRole role, [String content = 'hi']) => Message(
      id: id,
      content: content,
      role: role,
      timestamp: DateTime(2026),
      conversationId: 'c1',
    );

void main() {
  group('isNewUserTurn (BUG #10)', () {
    test('첫 메시지: 새 대화 생성 후 user 메시지 추가 → 1회만 센다', () {
      const empty = ChatState();
      const created = ChatState(conversationId: 'c1');
      final sent = ChatState(
        conversationId: 'c1',
        messages: [_msg('1', MessageRole.user)],
        isAiTyping: true,
      );
      expect(isNewUserTurn(empty, created), isFalse);
      expect(isNewUserTurn(created, sent), isTrue);
    });

    test('스트리밍 갱신·AI 답변 추가는 세지 않는다', () {
      final sent = ChatState(
        conversationId: 'c1',
        messages: [_msg('1', MessageRole.user)],
        isAiTyping: true,
      );
      final streaming = sent.copyWith(currentAiResponse: 'Hello');
      final done = sent.copyWith(
        messages: [...sent.messages, _msg('1_ai', MessageRole.assistant)],
        isAiTyping: false,
        currentAiResponse: '',
      );
      expect(isNewUserTurn(sent, streaming), isFalse);
      expect(isNewUserTurn(streaming, done), isFalse);
    });

    test('다음 턴 user 메시지는 센다', () {
      final done = ChatState(conversationId: 'c1', messages: [
        _msg('1', MessageRole.user),
        _msg('1_ai', MessageRole.assistant),
      ]);
      final next = done.copyWith(
        messages: [...done.messages, _msg('2', MessageRole.user)],
      );
      expect(isNewUserTurn(done, next), isTrue);
    });

    test('키 없음으로 전송이 막히면(에러만 설정) 세지 않는다', () {
      const before = ChatState(conversationId: 'c1');
      final blocked = before.copyWith(error: 'Please set your API key');
      expect(isNewUserTurn(before, blocked), isFalse);
    });

    test('대화가 바뀌면(불러오기·새 대화) 세지 않는다', () {
      const before = ChatState(conversationId: 'c1');
      final loaded = ChatState(conversationId: 'c2', messages: [
        _msg('1', MessageRole.user),
      ]);
      expect(isNewUserTurn(before, loaded), isFalse);
    });

    test('한 번에 여러 user 메시지가 들어오면(복원) 세지 않는다', () {
      const before = ChatState(conversationId: 'c1');
      final restored = ChatState(conversationId: 'c1', messages: [
        _msg('1', MessageRole.user),
        _msg('1_ai', MessageRole.assistant),
        _msg('2', MessageRole.user),
      ]);
      expect(isNewUserTurn(before, restored), isFalse);
    });

    test('빈 내용의 user 메시지는 세지 않는다', () {
      const before = ChatState(conversationId: 'c1');
      final blank = ChatState(conversationId: 'c1', messages: [
        _msg('1', MessageRole.user, '   '),
      ]);
      expect(isNewUserTurn(before, blank), isFalse);
    });
  });
}
