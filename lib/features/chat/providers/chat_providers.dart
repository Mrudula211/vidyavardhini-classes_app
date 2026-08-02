import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/chat_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../repository/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final userChatRoomsProvider = FutureProvider<List<ChatRoomModel>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final role = ref.watch(currentUserRoleProvider).value;

  if (user == null || role == null) return [];

  return repo.fetchUserChatRooms(
    userId: user.id,
    role: role,
  );
});

final chatMessagesStreamProvider = StreamProvider.family<List<ChatMessageModel>, String>((ref, roomId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamMessages(roomId);
});

final chatRoomDetailProvider = FutureProvider.family<ChatRoomModel?, String>((ref, roomId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.fetchChatRoomById(roomId);
});
