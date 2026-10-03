import '../../../../core/models/models.dart';
import '../../../../core/network/api_services.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this.api);
  final AuthApiService api;
  Future<AuthResponseModel> login(String email, String password) =>
      api.login(email, password);
  Future<AuthResponseModel> register(String email, String password) =>
      api.register(email, password);
  Future<UserModel> profile() => api.profile();
  Future<AuthResponseModel> updateProfile(Map<String, dynamic> input) =>
      api.updateProfile(input);
}
