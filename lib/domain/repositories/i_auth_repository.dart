import '../entities/user_account.dart';

abstract class IAuthRepository {
  Stream<UserAccount?> watchCurrentUser();
  Future<UserAccount?> getCurrentUser();
  Future<void> switchUserRole(UserRole role);
  Future<void> switchBranch(String branchId);
  Future<List<UserAccount>> getAvailableUsers();
  Future<void> setCurrentUser(UserAccount user);
  Future<void> saveUser(UserAccount user);
}
