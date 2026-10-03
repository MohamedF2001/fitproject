import '../../../../core/models/models.dart';
import '../../../../core/network/api_services.dart';

class GoalsRemoteDataSource {
  const GoalsRemoteDataSource(this.api);
  final ObjectifsApiService api;
  Future<ObjectifModel> create(ObjectifInput input) => api.create(input);
  Future<List<ObjectifModel>> list() => api.list();
  Future<ObjectifModel> getById(String id) => api.getById(id);
  Future<ObjectifModel> update(String id, ObjectifInput input) =>
      api.update(id, input);
}
