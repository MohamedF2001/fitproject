import '../../../../core/models/models.dart';
import '../../../../core/network/api_services.dart';

class ExercisesRemoteDataSource {
  const ExercisesRemoteDataSource(this.api);
  final ExercicesApiService api;
  Future<List<GroupeExerciceModel>> list({String? muscle, String? category}) =>
      api.list(muscle: muscle, categorie: category);
  Future<ExerciceModel> getById(String id) => api.getById(id);
}
