import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/chat/repository/chat_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

// Mocking SupabaseQueryBuilder
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<void> {}

class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder<void> {}

// A fake that actually implements PostgrestFilterBuilder to avoid casting issues
class FakeEqBuilder implements PostgrestFilterBuilder<dynamic> {
  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    return this;
  }

  @override
  Future<T> then<T>(
    FutureOr<T> Function(dynamic value) onValue, {
    Function? onError,
  }) async {
    return onValue(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ChatRepository chatRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockChatMessagesQueryBuilder;
  late MockSupabaseQueryBuilder mockChatRoomsQueryBuilder;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockChatMessagesQueryBuilder = MockSupabaseQueryBuilder();
    mockChatRoomsQueryBuilder = MockSupabaseQueryBuilder();

    when(() => mockSupabaseClient.from('chat_messages'))
        .thenAnswer((_) => mockChatMessagesQueryBuilder);
    when(() => mockSupabaseClient.from('chat_rooms'))
        .thenAnswer((_) => mockChatRoomsQueryBuilder);

    chatRepository = ChatRepository(client: mockSupabaseClient);
  });

  group('sendMessage', () {
    test(
        'inserts message and updates last_message_at on chat room successfully',
        () async {
      // Arrange
      const roomId = 'test_room_id';
      const senderId = 'test_sender_id';
      const content = 'Hello, this is a test message.';

      when(() => mockChatMessagesQueryBuilder.insert(any()))
          .thenAnswer((_) => FakeEqBuilder());

      when(() => mockChatRoomsQueryBuilder.update(any()))
          .thenAnswer((_) => FakeEqBuilder());

      // Act
      await chatRepository.sendMessage(
        roomId: roomId,
        senderId: senderId,
        content: content,
      );

      // Assert
      verify(
        () => mockChatMessagesQueryBuilder.insert(
          {
            'room_id': roomId,
            'sender_id': senderId,
            'content': content,
            'message_type': 'text',
            'file_url': null,
            'is_read': false,
          },
        ),
      ).called(1);

      verify(() => mockChatRoomsQueryBuilder.update(any())).called(1);
    });

    test('handles optional parameters like fileUrl and messageType correctly',
        () async {
      // Arrange
      const roomId = 'test_room_id';
      const senderId = 'test_sender_id';
      const content = 'Here is the file.';
      const messageType = 'image';
      const fileUrl = 'https://example.com/image.png';

      when(() => mockChatMessagesQueryBuilder.insert(any()))
          .thenAnswer((_) => FakeEqBuilder());

      when(() => mockChatRoomsQueryBuilder.update(any()))
          .thenAnswer((_) => FakeEqBuilder());

      // Act
      await chatRepository.sendMessage(
        roomId: roomId,
        senderId: senderId,
        content: content,
        messageType: messageType,
        fileUrl: fileUrl,
      );

      // Assert
      verify(
        () => mockChatMessagesQueryBuilder.insert(
          {
            'room_id': roomId,
            'sender_id': senderId,
            'content': content,
            'message_type': messageType,
            'file_url': fileUrl,
            'is_read': false,
          },
        ),
      ).called(1);

      verify(() => mockChatRoomsQueryBuilder.update(any())).called(1);
    });

    test(
        'throws exception when chat_messages insert fails and chat_rooms update is never executed',
        () async {
      // Arrange
      const roomId = 'test_room_id';
      const senderId = 'test_sender_id';
      const content = 'This message will fail to send.';

      when(() => mockChatMessagesQueryBuilder.insert(any()))
          .thenThrow(Exception('Failed to insert message'));

      // Act & Assert
      expect(
        () => chatRepository.sendMessage(
          roomId: roomId,
          senderId: senderId,
          content: content,
        ),
        throwsException,
      );

      verify(() => mockChatMessagesQueryBuilder.insert(any())).called(1);
      verifyNever(() => mockChatRoomsQueryBuilder.update(any()));
    });
  });
}
