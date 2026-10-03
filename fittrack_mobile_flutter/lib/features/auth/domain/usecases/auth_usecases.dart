import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class LoginUseCase {
  const LoginUseCase(this.repository);
  final AuthRepository repository;
  Future<UserEntity> call(String email, String password) =>
      repository.login(email, password);
}

class RegisterUseCase {
  const RegisterUseCase(this.repository);
  final AuthRepository repository;
  Future<UserEntity> call(String email, String password) =>
      repository.register(email, password);
}

class GetProfileUseCase {
  const GetProfileUseCase(this.repository);
  final AuthRepository repository;
  Future<UserEntity> call() => repository.profile();
}
