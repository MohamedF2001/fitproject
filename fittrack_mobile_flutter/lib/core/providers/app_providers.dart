import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failure.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../network/api_services.dart';
import '../storage/local_storage.dart';

final storageProvider = Provider<LocalStorage>((ref) => LocalStorage.memory());
final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(ref.read(storageProvider), 'http://10.0.2.2:3000/api'),
);
final authApiProvider = Provider(
  (ref) => AuthApiService(ref.read(dioClientProvider).dio),
);
final exercisesApiProvider = Provider(
  (ref) => ExercicesApiService(ref.read(dioClientProvider).dio),
);
final programsApiProvider = Provider(
  (ref) => ProgrammesApiService(ref.read(dioClientProvider).dio),
);
final workoutsApiProvider = Provider(
  (ref) => SeancesApiService(ref.read(dioClientProvider).dio),
);
final goalsApiProvider = Provider(
  (ref) => ObjectifsApiService(ref.read(dioClientProvider).dio),
);
final achievementsApiProvider = Provider(
  (ref) => SuccesApiService(ref.read(dioClientProvider).dio),
);

class AuthState {
  const AuthState({this.token, this.user, this.loading = false, this.error});
  final String? token;
  final UserModel? user;
  final bool loading;
  final Failure? error;
  bool get isAuthenticated => token?.isNotEmpty == true && user != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.read(storageProvider);
    return AuthState(token: storage.token, user: storage.user);
  }

  Future<ApiResult<void>> login(String email, String password) async {
    state = AuthState(token: state.token, user: state.user, loading: true);
    try {
      final response = await ref.read(authApiProvider).login(email, password);
      await ref
          .read(storageProvider)
          .saveSession(response.token, response.user);
      state = AuthState(token: response.token, user: response.user);
      await refreshProfile();
      return const ApiResult.success(null);
    } catch (error) {
      final failure = ref.read(dioClientProvider).failureFrom(error);
      state = AuthState(error: failure);
      return ApiResult.failure(failure);
    }
  }

  Future<ApiResult<void>> register(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      final response =
          await ref.read(authApiProvider).register(email, password);
      await ref
          .read(storageProvider)
          .saveSession(response.token, response.user);
      state = AuthState(token: response.token, user: response.user);
      await refreshProfile();
      return const ApiResult.success(null);
    } catch (error) {
      final failure = ref.read(dioClientProvider).failureFrom(error);
      state = AuthState(error: failure);
      return ApiResult.failure(failure);
    }
  }

  Future<ApiResult<UserModel>> refreshProfile() async {
    if (!state.isAuthenticated) {
      return const ApiResult.failure(AuthFailure('Non connecté'));
    }
    try {
      final user = await ref.read(authApiProvider).profile();
      await ref.read(storageProvider).saveUser(user);
      state = AuthState(token: state.token, user: user);
      return ApiResult.success(user);
    } catch (error) {
      final failure = ref.read(dioClientProvider).failureFrom(error);
      if (failure is AuthFailure) await logout();
      return ApiResult.failure(failure);
    }
  }

  Future<ApiResult<UserModel>> updateProfile({
    String? nom,
    String? prenom,
    double? poids,
    double? taille,
  }) async {
    try {
      final response = await ref.read(authApiProvider).updateProfile({
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (poids != null) 'poids': poids,
        if (taille != null) 'taille': taille,
      });
      await ref.read(storageProvider).saveUser(response.user);
      if (poids != null) await ref.read(storageProvider).addWeight(poids);
      state = AuthState(token: state.token, user: response.user);
      return ApiResult.success(response.user);
    } catch (error) {
      return ApiResult.failure(ref.read(dioClientProvider).failureFrom(error));
    }
  }

  Future<void> logout() async {
    await ref.read(storageProvider).clearSession();
    state = const AuthState();
  }

  Future<ApiResult<void>> refreshToken() async => const ApiResult.failure(
        UnimplementedFailure('Le backend ne fournit pas de refresh token.'),
      );
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final hasCompleteProfileProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.isComplete == true;
});

final programsProvider = FutureProvider.autoDispose<List<ProgrammeModel>>((
  ref,
) async {
  return _safe(() => ref.read(programsApiProvider).list(), ref);
});

final activeProgramProvider = FutureProvider.autoDispose<ProgrammeModel?>((
  ref,
) async {
  try {
    final program = await ref.read(programsApiProvider).active();
    await ref.read(storageProvider).cacheActiveProgram(program);
    return program;
  } catch (_) {
    return ref.read(storageProvider).cachedActiveProgram;
  }
});

final exercisesProvider = FutureProvider.autoDispose<List<GroupeExerciceModel>>(
  (ref) async {
    try {
      final groups = await ref.read(exercisesApiProvider).list();
      await ref.read(storageProvider).cacheExercises(groups);
      return groups;
    } catch (_) {
      return ref.read(storageProvider).cachedExercises;
    }
  },
);

final workoutsProvider = FutureProvider.autoDispose<List<SeanceModel>>((
  ref,
) async {
  return _safe(() => ref.read(workoutsApiProvider).list(), ref);
});

final goalsProvider = FutureProvider.autoDispose<List<ObjectifModel>>((
  ref,
) async {
  return _safe(() => ref.read(goalsApiProvider).list(), ref);
});

final achievementsProvider = FutureProvider.autoDispose<List<SuccesModel>>((
  ref,
) async {
  return _safe(() => ref.read(achievementsApiProvider).list(), ref);
});

Future<ApiResult<T>> executeApi<T>(
  Future<T> Function() action,
  DioClient client,
) async {
  try {
    return ApiResult.success(await action());
  } catch (error) {
    return ApiResult.failure(client.failureFrom(error));
  }
}

Future<T> _safe<T>(Future<T> Function() call, Ref ref) async {
  try {
    return await call();
  } catch (error) {
    throw FailureException(ref.read(dioClientProvider).failureFrom(error));
  }
}
