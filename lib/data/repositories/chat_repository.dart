import '../models/chat_model.dart';
import '../services/firebase_service.dart';

class ChatRepository {
  final FirebaseService _firebase;

  ChatRepository(this._firebase);

  /// Lấy danh sách cuộc trò chuyện của user (Customer hoặc Owner)
  Stream<List<ChatConversationModel>> getConversationsStream(String userId) {
    return _firebase.chatConversationsCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((d) => ChatConversationModel.fromMap(d.data(), d.id))
          .where((c) => c.customerId == userId || c.ownerId == userId)
          .toList();

      list.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Lấy hoặc tạo mới cuộc hội thoại giữa khách và chủ sân
  Future<ChatConversationModel> getOrCreateConversation({
    required String customerId,
    required String customerName,
    required String ownerId,
    required String ownerName,
    String? fieldId,
    String? fieldName,
  }) async {
    final query = await _firebase.chatConversationsCollection
        .where('customerId', isEqualTo: customerId)
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      // Cập nhật sân đang hỏi nếu khác
      if (fieldId != null && doc.data()['fieldId'] != fieldId) {
        await doc.reference.update({
          'fieldId': fieldId,
          'fieldName': fieldName,
        });
      }
      return ChatConversationModel.fromMap(doc.data(), doc.id);
    }

    final docRef = _firebase.chatConversationsCollection.doc();
    final conv = ChatConversationModel(
      id: docRef.id,
      customerId: customerId,
      customerName: customerName,
      ownerId: ownerId,
      ownerName: ownerName,
      fieldId: fieldId,
      fieldName: fieldName,
      createdAt: DateTime.now(),
    );
    await docRef.set(conv.toMap());
    return conv;
  }

  /// Lắng nghe tin nhắn trong cuộc hội thoại theo thời gian thực
  Stream<List<ChatMessageModel>> getMessagesStream(String conversationId) {
    return _firebase.chatConversationsCollection
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => ChatMessageModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return list;
    });
  }

  /// Gửi tin nhắn mới
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    final now = DateTime.now();
    final msgDocRef = _firebase.chatConversationsCollection
        .doc(conversationId)
        .collection('messages')
        .doc();

    final msg = ChatMessageModel(
      id: msgDocRef.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content.trim(),
      isRead: false,
      sentAt: now,
    );

    final batch = _firebase.firestore.batch();
    batch.set(msgDocRef, msg.toMap());
    batch.update(_firebase.chatConversationsCollection.doc(conversationId), {
      'lastMessage': content.trim(),
      'lastMessageAt': now.toIso8601String(),
    });

    await batch.commit();
  }

  /// Đánh dấu các tin nhắn của người kia là đã đọc
  Future<void> markMessagesAsRead(String conversationId, String currentUserId) async {
    final snapshot = await _firebase.chatConversationsCollection
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firebase.firestore.batch();
    bool hasUpdates = false;
    for (var doc in snapshot.docs) {
      if (doc.data()['senderId'] != currentUserId) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      await batch.commit();
    }
  }
}
