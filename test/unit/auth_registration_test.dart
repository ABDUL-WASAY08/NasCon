import 'package:flutter_test/flutter_test.dart';
import 'package:nescom/core/storage/secure_storage_service.dart';
import 'package:nescom/repositories/mock/mock_repositories.dart';

void main() {
  group('MockAuthRepository registration', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository(
        storage: InMemorySessionStore(),
        backend: MockBackend(),
      );
    });

    test(
      'creates a viewer session and allows sign-in after sign-out',
      () async {
        final created = await repository.register(
          fullName: '  New Member  ',
          email: ' NEW@Example.com ',
          password: 'secure-pass-123',
        );

        expect(created.user.fullName, 'New Member');
        expect(created.user.email, 'new@example.com');
        expect(created.user.role.wire, 'viewer');

        await repository.signOut();
        final signedIn = await repository.signIn(
          email: 'new@example.com',
          password: 'secure-pass-123',
        );
        expect(signedIn.user.id, created.user.id);
      },
    );

    test('rejects duplicate email addresses case-insensitively', () async {
      await repository.register(
        fullName: 'New Member',
        email: 'new@example.com',
        password: 'secure-pass-123',
      );

      await expectLater(
        repository.register(
          fullName: 'Another Member',
          email: 'NEW@example.com',
          password: 'secure-pass-456',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
