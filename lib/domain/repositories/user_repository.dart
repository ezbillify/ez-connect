import 'package:app/domain/models/user.dart';

abstract class UserRepository {
  Future<User?> getUserById(String id);
  Future<User?> getCurrentUser();
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
  Future<List<User>> searchUsers(String query);
}
