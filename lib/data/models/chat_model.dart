class ChatConversationModel {
  final String id;
  final String customerId;
  final String? customerName;
  final String ownerId;
  final String? ownerName;
  final String? fieldId;
  final String? fieldName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  ChatConversationModel({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.ownerId,
    this.ownerName,
    this.fieldId,
    this.fieldName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatConversationModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'],
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'],
      fieldId: map['fieldId'],
      fieldName: map['fieldName'],
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.tryParse(map['lastMessageAt'])
          : null,
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String content;
  final bool isRead;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.content,
    this.isRead = false,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'isRead': isRead,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      content: map['content'] ?? '',
      isRead: map['isRead'] as bool? ?? false,
      sentAt: map['sentAt'] != null
          ? DateTime.tryParse(map['sentAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
