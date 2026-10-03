import '../../../../core/models/models.dart';
import '../../../../core/network/api_services.dart';

class WorkoutsRemoteDataSource {
  const WorkoutsRemoteDataSource(this.api);
  final SeancesApiService api;
  Future<SeanceModel> create(SeanceInput input) => api.create(input);
  Future<List<SeanceModel>> list() => api.list();
  Future<SeanceModel> getById(String id) => api.getById(id);
  Future<SeanceModel> update(String id, SeanceInput input) =>
      api.update(id, input);
  Future<SeanceValidation> validate(String id) => api.validate(id);
  Future<void> delete(String id) => api.delete(id);
}
