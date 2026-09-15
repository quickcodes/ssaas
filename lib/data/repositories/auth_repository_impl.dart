import '../../domain/entities/user_account.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/local_data_store.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final LocalDataStore _ds;
  AuthRepositoryImpl(this._ds);

  @override
  Stream<UserAccount?> watchCurrentUser() => _ds.watchCurrentUser();

  @override
  Future<UserAccount?> getCurrentUser() async => _ds.getCurrentUser();

  @override
  Future<void> switchUserRole(UserRole role) async {
    _ds.switchUserRole(role);
  }

  @override
  Future<void> switchBranch(String branchId) async {
    _ds.switchBranch(branchId);
  }

  @override
  Future<List<UserAccount>> getAvailableUsers() async =>
      _ds.getAvailableUsers();

  @override
  Future<void> setCurrentUser(UserAccount user) async {
    _ds.setCurrentUser(user);
  }

  @override
  Future<void> saveUser(UserAccount user) async => _ds.saveUser(user);
}
