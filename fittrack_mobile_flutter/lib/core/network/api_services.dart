import 'package:dio/dio.dart';

import '../models/models.dart';

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<dynamic> _list(dynamic value) => value is List ? value : const [];
dynamic _body(Response<dynamic> response) => response.data;
Map<String, dynamic> _resource(dynamic body, String key) {
  final map = _map(body);
  final value = map[key];
  return value is Map ? _map(value) : map;
}

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;
  Future<AuthResponseModel> register(String email, String motDePasse) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'email': email, 'motDePasse': motDePasse},
    );
    return AuthResponseModel.fromJson(_map(_body(response)));
  }

  Future<AuthResponseModel> login(String email, String motDePasse) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'motDePasse': motDePasse},
    );
    return AuthResponseModel.fromJson(_map(_body(response)));
  }

  Future<UserModel> profile() async =>
      UserModel.fromJson(_map(_body(await _dio.get('/auth/profile'))));
  Future<AuthResponseModel> updateProfile(Map<String, dynamic> input) async =>
      AuthResponseModel.fromJson(
        _map(_body(await _dio.put('/auth/profile', data: input))),
      );
}

class ExercicesApiService {
  ExercicesApiService(this._dio);
  final Dio _dio;
  Future<List<GroupeExerciceModel>> list({
    String? muscle,
    String? categorie,
  }) async {
    final response = await _dio.get(
      '/exercices',
      queryParameters: {
        if (muscle != null && muscle.isNotEmpty) 'muscle': muscle,
        if (categorie != null && categorie.isNotEmpty) 'categorie': categorie,
      },
    );
    return _list(
      _body(response),
    ).map((e) => GroupeExerciceModel.fromJson(_map(e))).toList();
  }

  Future<ExerciceModel> getById(String id) async =>
      ExerciceModel.fromJson(_map(_body(await _dio.get('/exercices/$id'))));
}

class ProgrammesApiService {
  ProgrammesApiService(this._dio);
  final Dio _dio;
  Future<ProgrammeModel> create(ProgrammeInput input) async {
    final response = await _dio.post('/programmes', data: input.toJson());
    return ProgrammeModel.fromJson(_resource(_body(response), 'programme'));
  }

  Future<List<ProgrammeModel>> list() async => _list(
        _body(await _dio.get('/programmes')),
      ).map((e) => ProgrammeModel.fromJson(_map(e))).toList();
  Future<ProgrammeModel?> active() async {
    final body = _map(_body(await _dio.get('/programmes/actif')));
    return body.isEmpty ? null : ProgrammeModel.fromJson(body);
  }

  Future<ProgrammeModel> getById(String id) async =>
      ProgrammeModel.fromJson(_map(_body(await _dio.get('/programmes/$id'))));
  Future<ProgrammeModel> update(String id, ProgrammeInput input) async {
    final response = await _dio.put('/programmes/$id', data: input.toJson());
    return ProgrammeModel.fromJson(_resource(_body(response), 'programme'));
  }

  Future<void> delete(String id) async => _dio.delete('/programmes/$id');
}

class SeancesApiService {
  SeancesApiService(this._dio);
  final Dio _dio;
  Future<SeanceModel> create(SeanceInput input) async {
    final response = await _dio.post('/seances', data: input.toJson());
    return SeanceModel.fromJson(_resource(_body(response), 'seance'));
  }

  Future<List<SeanceModel>> list() async => _list(
        _body(await _dio.get('/seances')),
      ).map((e) => SeanceModel.fromJson(_map(e))).toList();
  Future<SeanceModel> getById(String id) async =>
      SeanceModel.fromJson(_map(_body(await _dio.get('/seances/$id'))));
  Future<SeanceModel> update(String id, SeanceInput input) async {
    final response = await _dio.put('/seances/$id', data: input.toJson());
    return SeanceModel.fromJson(_resource(_body(response), 'seance'));
  }

  Future<void> delete(String id) async => _dio.delete('/seances/$id');
  Future<SeanceValidation> validate(String id) async {
    final body = _map(_body(await _dio.put('/seances/$id/valider')));
    return SeanceValidation(
      seance: SeanceModel.fromJson(_map(body['seance'])),
      succesObtenus: _list(
        body['succesObtenus'],
      ).map((e) => SuccesModel.fromJson(_map(e))).toList(),
    );
  }
}

class SeanceValidation {
  const SeanceValidation({required this.seance, required this.succesObtenus});
  final SeanceModel seance;
  final List<SuccesModel> succesObtenus;
}

class ObjectifsApiService {
  ObjectifsApiService(this._dio);
  final Dio _dio;
  Future<ObjectifModel> create(ObjectifInput input) async {
    final response = await _dio.post('/users/objectifs', data: input.toJson());
    return ObjectifModel.fromJson(_resource(_body(response), 'objectif'));
  }

  Future<List<ObjectifModel>> list() async => _list(
        _body(await _dio.get('/users/objectifs')),
      ).map((e) => ObjectifModel.fromJson(_map(e))).toList();
  Future<ObjectifModel> getById(String id) async => ObjectifModel.fromJson(
        _map(_body(await _dio.get('/users/objectifs/$id'))),
      );
  Future<ObjectifModel> update(String id, ObjectifInput input) async {
    final response = await _dio.put(
      '/users/objectifs/$id',
      data: input.toJson(),
    );
    return ObjectifModel.fromJson(_resource(_body(response), 'objectif'));
  }

  Future<void> delete(String id) async {
    await _dio.delete('/users/objectifs/$id');
  }
}

class SuccesApiService {
  SuccesApiService(this._dio);
  final Dio _dio;
  Future<List<SuccesModel>> list() async => _list(
        _body(await _dio.get('/users/succes')),
      ).map((e) => SuccesModel.fromJson(_map(e))).toList();
}
