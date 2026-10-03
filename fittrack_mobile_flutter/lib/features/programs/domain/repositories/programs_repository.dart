import '../entities/program_entity.dart';

abstract interface class ProgramsRepository {
  Future<ProgramEntity> create(ProgramEntity input);
  Future<List<ProgramEntity>> list();
  Future<ProgramEntity?> active();
  Future<ProgramEntity> getById(String id);
  Future<ProgramEntity> update(String id, ProgramEntity input);
  Future<void> delete(String id);
}
