import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../models/models.dart';

class LocalStorage {
  LocalStorage._(this._box) : _memory = null;
  LocalStorage.memory()
      : _box = null,
        _memory = <String, dynamic>{};

  final Box<dynamic>? _box;
  final Map<String, dynamic>? _memory;

  static Future<LocalStorage> init() async {
    await Hive.initFlutter();
    return LocalStorage._(await Hive.openBox<dynamic>('fittrack'));
  }

  dynamic _get(String key) => _box?.get(key) ?? _memory?[key];
  Future<void> _put(String key, dynamic value) async {
    if (_box != null) {
      await _box.put(key, value);
    } else {
      _memory![key] = value;
    }
  }

  Future<void> _delete(String key) async {
    if (_box != null) {
      await _box.delete(key);
    } else {
      _memory!.remove(key);
    }
  }

  String? get token => _get(AppConstants.tokenKey) as String?;
  bool get hasSeenOnboarding => (_get('has_seen_onboarding') as bool?) ?? false;

  Future<void> setHasSeenOnboarding(bool value) async {
    await _put('has_seen_onboarding', value);
  }

  UserModel? get user {
    final raw = _get(AppConstants.userKey) as String?;
    return raw == null ? null : UserModel.fromJson(jsonDecode(raw));
  }

  Future<void> saveSession(String token, UserModel user) async {
    await _put(AppConstants.tokenKey, token);
    await _put(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<void> saveUser(UserModel user) async =>
      _put(AppConstants.userKey, jsonEncode(user.toJson()));

  Future<void> clearSession() async {
    await _delete(AppConstants.tokenKey);
    await _delete(AppConstants.userKey);
  }

  List<GroupeExerciceModel> get cachedExercises {
    final raw = _get(AppConstants.exercisesCacheKey) as String?;
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => GroupeExerciceModel.fromJson(Map.from(e))).toList();
  }

  Future<void> cacheExercises(List<GroupeExerciceModel> groups) => _put(
        AppConstants.exercisesCacheKey,
        jsonEncode(groups.map((e) => e.toJson()).toList()),
      );

  ProgrammeModel? get cachedActiveProgram {
    final raw = _get(AppConstants.activeProgramCacheKey) as String?;
    return raw == null ? null : ProgrammeModel.fromJson(jsonDecode(raw));
  }

  Future<void> cacheActiveProgram(ProgrammeModel? program) async {
    if (program == null) {
      await _delete(AppConstants.activeProgramCacheKey);
    } else {
      await _put(
        AppConstants.activeProgramCacheKey,
        jsonEncode(program.toJson()),
      );
    }
  }

  List<Map<String, dynamic>> get weightHistory {
    final value = _get(AppConstants.weightHistoryKey);
    return value is List
        ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  Future<void> addWeight(double weight) async {
    final history = List<Map<String, dynamic>>.from(weightHistory)
      ..add({'date': DateTime.now().toIso8601String(), 'poids': weight});
    await _put(AppConstants.weightHistoryKey, history);
  }
}
