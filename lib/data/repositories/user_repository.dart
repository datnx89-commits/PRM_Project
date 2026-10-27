import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserRepository {
  final FirebaseService _firebaseService;

  UserRepository(this._firebaseService);

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firebaseService.usersCollection.get();
    final users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
    users.sort((a, b) => a.fullName.compareTo(b.fullName));
    return users;
  }

  Future<void> toggleUserActive(String userId) async {
    final doc = await _firebaseService.usersCollection.doc(userId).get();
    if (!doc.exists || doc.data() == null) return;
    final currentStatus = doc.data()!['isActive'] as bool? ?? true;
    await _firebaseService.usersCollection.doc(userId).update({'isActive': !currentStatus});
  }

  Future<void> changeUserRole(String userId, String newRole) async {
    await _firebaseService.usersCollection.doc(userId).update({'role': newRole});
  }
}
