import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String email, String password);
  Future<UserEntity> profile();
  Future<UserEntity> updateProfile(Map<String, dynamic> input);
  Future<void> logout();
  Future<void> refreshToken();
}
