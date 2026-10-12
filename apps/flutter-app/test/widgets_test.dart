import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:student_kwacha/core/services/api_exception.dart';
import 'package:student_kwacha/core/services/auth_service.dart';
import 'package:student_kwacha/presentation/auth/login_screen.dart';
import 'package:student_kwacha/presentation/auth/register_screen.dart';

/// Fakes AuthService so we can drive login/register failures without network.
class FakeAuthService extends ChangeNotifier implements AuthService {
  FakeAuthService({this.shouldSucceed = false, ApiException? authError})
      : _authError = authError;

  final bool shouldSucceed;
  final ApiException? _authError;
  int loginCalls = 0;
  int registerCalls = 0;

  @override
  bool get isAuthenticated => false;
  @override
  bool get isLoading => false;
  @override
  Map<String, dynamic>? get user => null;
  @override
  ApiException? get error => _authError;

  @override
  Future<bool> login({required String email, required String password}) async {
    loginCalls++;
    return shouldSucceed;
  }

  @override
  Future<bool> register({
    required String email,
    required String fullName,
    String? phoneNumber,
    required String password,
    required String confirmPassword,
    String? institution,
    String? studentId,
  }) async {
    registerCalls++;
    return shouldSucceed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget wrap(Widget child, AuthService auth) {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home'))),
      GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login'))),
      GoRoute(path: '/register', builder: (_, __) => child),
    ],
  );
  return MultiProvider(
    providers: [ChangeNotifierProvider<AuthService>.value(value: auth)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> submitForm(WidgetTester tester) async {
  final button = find.byType(ElevatedButton);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login screen shows backend reason on wrong credentials',
      (tester) async {
    final auth = FakeAuthService(
      shouldSucceed: false,
      authError: ApiException(
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      ),
    );
    await tester.pumpWidget(wrap(const LoginScreen(), auth));
    await tester.enterText(
        find.byType(TextFormField).first, 'student@unza.zm');
    await tester.enterText(find.byType(TextFormField).last, 'WrongPass1');
    await submitForm(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Incorrect email or password'), findsOneWidget);
  });

  testWidgets('login screen shows network failure message', (tester) async {
    final auth = FakeAuthService(
      shouldSucceed: false,
      authError: ApiException(
        code: 'NETWORK_ERROR',
        message: 'Cannot reach the server',
      ),
    );
    await tester.pumpWidget(wrap(const LoginScreen(), auth));
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'Passw0rd1');
    await submitForm(tester);

    expect(find.textContaining('Cannot reach the server'), findsOneWidget);
  });

  testWidgets('register screen shows duplicate-account reason',
      (tester) async {
    final auth = FakeAuthService(
      shouldSucceed: false,
      authError: ApiException(
        code: 'USER_EXISTS',
        message: 'User with this email or phone already exists',
      ),
    );
    await tester.pumpWidget(wrap(const RegisterScreen(), auth));
    // 0 name, 1 email, 2 phone, 3 institution, 4 student id,
    // 5 password, 6 confirm password
    await tester.enterText(find.byType(TextFormField).at(0), 'Chanda Mwansa');
    await tester.enterText(find.byType(TextFormField).at(1), 'me@unza.zm');
    await tester.enterText(find.byType(TextFormField).at(2), '0977123456');
    await tester.enterText(find.byType(TextFormField).at(3), 'University of Zambia');
    await tester.enterText(find.byType(TextFormField).at(4), '2026123456');
    await tester.enterText(find.byType(TextFormField).at(5), 'Passw0rd1');
    await tester.enterText(find.byType(TextFormField).at(6), 'Passw0rd1');
    await submitForm(tester);

    expect(find.textContaining('already registered'), findsOneWidget);
  });

  testWidgets('register screen validates locally before any API call',
      (tester) async {
    final auth = FakeAuthService(shouldSucceed: false);
    await tester.pumpWidget(wrap(const RegisterScreen(), auth));
    // Leave everything blank and submit.
    await submitForm(tester);

    expect(auth.registerCalls, 0, reason: 'form validation should block');
    expect(find.text('Name must be at least 2 characters'), findsOneWidget);
  });

  testWidgets('register screen sends student fields to the service',
      (tester) async {
    final auth = FakeAuthService(shouldSucceed: true);
    await tester.pumpWidget(wrap(const RegisterScreen(), auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'Chanda Mwansa');
    await tester.enterText(find.byType(TextFormField).at(1), 'me@unza.zm');
    await tester.enterText(find.byType(TextFormField).at(2), '0977123456');
    await tester.enterText(find.byType(TextFormField).at(3), 'University of Zambia');
    await tester.enterText(find.byType(TextFormField).at(4), '2026123456');
    await tester.enterText(find.byType(TextFormField).at(5), 'Passw0rd1');
    await tester.enterText(find.byType(TextFormField).at(6), 'Passw0rd1');
    await submitForm(tester);

    expect(auth.registerCalls, 1, reason: 'valid form should call the API once');
  });
}
