import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile_flutter/core/models/models.dart';

void main() {
  test('models deserialize the API shape', () {
    final user = UserModel.fromJson({
      '_id': 'u1',
      'email': 'test@example.com',
      'nom': 'Test',
      'prenom': 'User',
      'poids': 70,
      'taille': 1.75,
    });
    expect(user.id, 'u1');
    expect(user.poids, 70);
    expect(user.taille, 1.75);
  });
}
