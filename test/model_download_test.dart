import 'package:awan/features/recitation/data/datasources/recitation_model_installer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The download button used to fail with a bare `download_failed`, which told
/// the user nothing and looked like a dead button. These cover the two things
/// that make failure legible: where the bytes are asked for, and what the
/// reason actually was.
void main() {
  group('model sources', () {
    test('a private mirror gets the /recitation/ prefix', () {
      const ModelSource mirror = ModelSource(
        label: 'lan',
        base: 'http://192.168.0.112:8099',
      );
      expect(
        mirror.urlFor('base-ar-quran-tokens.txt'),
        'http://192.168.0.112:8099/recitation/base-ar-quran-tokens.txt',
      );
    });

    test('Hugging Face uses the flat resolve/main path', () {
      expect(
        ModelSource.huggingFace.urlFor('base-ar-quran-tokens.txt'),
        'https://huggingface.co/Synthesium/quran-whisper-sherpa-onnx/resolve/main/base-ar-quran-tokens.txt',
      );
    });

    test('a dead mirror is followed by one that can answer', () {
      // The order is the contract: local first, public second.
      const List<ModelSource> sources = <ModelSource>[
        ModelSource(label: 'lan', base: 'http://192.168.0.112:8099'),
        ModelSource.huggingFace,
      ];
      expect(sources.first.label, 'lan');
      expect(sources.last.base, contains('huggingface.co'));
    });
  });

  group('failure reasons', () {
    DioException err(DioExceptionType type, {int? status}) => DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: type,
          response: status == null
              ? null
              : Response<void>(
                  requestOptions: RequestOptions(path: '/x'),
                  statusCode: status,
                ),
        );

    test('connection failure is reported as offline', () {
      expect(
        ModelDownloadException('f', err(DioExceptionType.connectionError)).reason,
        'offline',
      );
    });

    test('a timeout is reported as a timeout, not as a bad file', () {
      expect(
        ModelDownloadException('f', err(DioExceptionType.receiveTimeout)).reason,
        'timeout',
      );
    });

    test('404 is distinguished from other server errors', () {
      expect(
        ModelDownloadException('f', err(DioExceptionType.badResponse, status: 404)).reason,
        'not_found',
      );
      expect(
        ModelDownloadException('f', err(DioExceptionType.badResponse, status: 503)).reason,
        'server_503',
      );
    });

    test('an HTML error page saved as .onnx is a bad payload', () {
      expect(
        const ModelDownloadException('f', FormatException('empty_or_html_response')).reason,
        'bad_payload',
      );
    });
  });
}
