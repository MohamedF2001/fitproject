import '../../domain/entities/program_entity.dart';
import '../../domain/repositories/programs_repository.dart';
import '../datasources/programs_remote_data_source.dart';

class ProgramsRepositoryImpl implements ProgramsRepository {
  const ProgramsRepositoryImpl(this.remote);
  final ProgramsRemoteDataSource remote;
  @override
  Future<ProgramEntity> create(ProgramEntity input) async =>
      (await remote.create(input.toInput())).toEntity();
  @override
  Future<List<ProgramEntity>> list() async =>
      (await remote.list()).map((e) => e.toEntity()).toList();
  @override
  Future<ProgramEntity?> active() async {
    final x = await remote.active();
    return x?.toEntity();
  }

  @override
  Future<ProgramEntity> getById(String id) async =>
      (await remote.getById(id)).toEntity();
  @override
  Future<ProgramEntity> update(String id, ProgramEntity input) async =>
      (await remote.update(id, input.toInput())).toEntity();
  @override
  Future<void> delete(String id) => remote.delete(id);
}
