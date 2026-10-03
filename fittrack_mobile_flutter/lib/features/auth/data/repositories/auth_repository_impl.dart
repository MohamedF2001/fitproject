import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.remote, this.onLogout);
  final AuthRemoteDataSource remote;
  final Future<void> Function() onLogout;
  @override
  Future<UserEntity> login(String email, String password) async =>
      (await remote.login(email, password)).user.toEntity();
  @override
  Future<UserEntity> register(String email, String password) async =>
      (await remote.register(email, password)).user.toEntity();
  @override
  Future<UserEntity> profile() async => (await remote.profile()).toEntity();
  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> input) async =>
      (await remote.updateProfile(input)).user.toEntity();
  @override
  Future<void> logout() => onLogout();
  @override
  Future<void> refreshToken() =>
      throw UnimplementedError('Le backend ne fournit pas de refresh token.');
}
