import '../../../../core/models/models.dart';
import '../../../../core/network/api_services.dart';

class ProgramsRemoteDataSource {
  const ProgramsRemoteDataSource(this.api);
  final ProgrammesApiService api;
  Future<ProgrammeModel> create(ProgrammeInput input) => api.create(input);
  Future<List<ProgrammeModel>> list() => api.list();
  Future<ProgrammeModel?> active() => api.active();
  Future<ProgrammeModel> getById(String id) => api.getById(id);
  Future<ProgrammeModel> update(String id, ProgrammeInput input) =>
      api.update(id, input);
  Future<void> delete(String id) => api.delete(id);
}
