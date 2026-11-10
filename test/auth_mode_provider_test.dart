import 'package:basalino/app/bootstrap/providers.dart';
import 'package:basalino/core/config/auth_mode.dart';
import 'package:basalino/core/services/auth_repository.dart';
import 'package:basalino/core/services/firebase_auth_repository.dart';
import 'package:basalino/core/services/local_auth_repository.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cloud reads are disabled by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(dataModeProvider), DataMode.local);
  });

  test('local authentication repository remains selectable', () {
    final container = ProviderContainer(
      overrides: [authModeProvider.overrideWithValue(AuthMode.local)],
    );
    addTearDown(container.dispose);

    expect(container.read(dataModeProvider), DataMode.local);
    expect(container.read(authRepositoryProvider), isA<LocalAuthRepository>());
  });

  test('Firebase mode selects the Firebase authentication repository', () {
    final firebaseRepository = FirebaseAuthRepository(auth: MockFirebaseAuth());
    final container = ProviderContainer(
      overrides: [
        authModeProvider.overrideWithValue(AuthMode.firebase),
        firebaseAuthRepositoryProvider.overrideWithValue(firebaseRepository),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authRepositoryProvider), same(firebaseRepository));
    expect(container.read(authRepositoryProvider), isA<AuthRepository>());
  });
}
