import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_kwacha/core/services/api_exception.dart';

void main() {
  group('ApiException.from Dio backend error envelope', () {
    test('extracts code, message and field details', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 400,
          data: {
            'success': false,
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Invalid input',
              'details': [
                {'field': 'body.password', 'message': 'Password must be at least 8 characters'},
                {'field': 'body.email', 'message': 'Invalid email address'},
              ],
            },
          },
        ),
      );

      final e = ApiException.from(dio);
      expect(e.code, 'VALIDATION_ERROR');
      expect(e.message, 'Invalid input');
      expect(e.statusCode, 400);
      expect(e.details, hasLength(2));
      expect(e.details[0].field, 'body.password');
      expect(e.details[0].message, 'Password must be at least 8 characters');
    });

    test('handles error envelope without details', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {
            'success': false,
            'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid email or password'},
          },
        ),
      );

      final e = ApiException.from(dio);
      expect(e.code, 'INVALID_CREDENTIALS');
      expect(e.displayMessage, 'Invalid email or password');
      expect(e.details, isEmpty);
    });

    test('missing message falls back to default', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 422,
          data: {'success': false, 'error': {'code': 'WEIRD'}},
        ),
      );

      expect(ApiException.from(dio).message, 'Request failed');
    });

    test('non-Map data falls through to connection classification', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 502,
          data: 'Bad Gateway',
        ),
        type: DioExceptionType.badResponse,
      );

      final e = ApiException.from(dio);
      expect(e.code, isNull);
      expect(e.statusCode, 502);
    });
  });

  group('ApiException connection failures', () {
    test('connectionTimeout is classified as NETWORK_TIMEOUT', () {
      final e = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      ));
      expect(e.code, 'NETWORK_TIMEOUT');
      expect(e.isNetworkError, isTrue);
      expect(e.displayMessage, contains('too long'));
    });

    test('connectionError is classified as NETWORK_ERROR', () {
      final e = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ));
      expect(e.code, 'NETWORK_ERROR');
      expect(e.isNetworkError, isTrue);
      expect(e.displayMessage, contains('Cannot reach the server'));
    });

    test('sendTimeout classified as network timeout', () {
      final e = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.sendTimeout,
      ));
      expect(e.isNetworkError, isTrue);
    });

    test('receiveTimeout has its own message', () {
      final e = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      ));
      expect(e.code, 'NETWORK_TIMEOUT');
    });
  });

  group('displayMessage picks the most human-readable text', () {
    test('generic top-level message is replaced with the first field detail', () {
      final e = ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: const [
          ApiFieldError(field: 'body.confirm_password', message: 'Passwords do not match'),
        ],
      );
      expect(e.displayMessage, 'Confirm password: Passwords do not match');
    });

    test('non-generic top-level message is kept as is', () {
      final e = ApiException(
        code: 'USER_EXISTS',
        message: 'User with this email or phone already exists',
        details: const [],
      );
      expect(e.displayMessage, 'User with this email or phone already exists');
    });

    test('snake_case fields are humanized and prefixed only when needed', () {
      final e = ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Validation failed',
        details: const [
          ApiFieldError(field: 'body.target_amount', message: 'must be positive'),
        ],
      );
      expect(e.displayMessage, 'Target amount: must be positive');
    });

    test('field message already naming the field is not double-prefixed', () {
      final e = ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: const [
          ApiFieldError(field: 'body.password', message: 'Password must be at least 8 characters'),
        ],
      );
      expect(e.displayMessage, 'Password must be at least 8 characters');
    });

    test('multiple details get a "+N more" suffix', () {
      final e = ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: const [
          ApiFieldError(field: 'body.password', message: 'Password must be at least 8 characters'),
          ApiFieldError(field: 'body.password', message: 'Password must contain at least one number'),
          ApiFieldError(field: 'body.email', message: 'Invalid email address'),
        ],
      );
      expect(e.displayMessage, endsWith('(+2 more)'));
    });

    test('single detail has no suffix', () {
      final e = ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Validation failed',
        details: const [
          ApiFieldError(field: 'body.password', message: 'Required'),
        ],
      );
      expect(e.displayMessage, 'Password: Required');
    });
  });

  group('ApiException passthrough', () {
    test('ApiException instances return unchanged', () {
      final original = ApiException(code: 'X', message: 'kept');
      expect(identical(ApiException.from(original), original), isTrue);
    });

    test('arbitrary errors carry their toString as message', () {
      final e = ApiException.from(StateError('boom'));
      expect(e.message, contains('boom'));
    });
  });
}
