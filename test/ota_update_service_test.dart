// test/ota_update_service_test.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_iq5_flash/modules/constants.dart';
import 'package:ja_iq5_flash/modules/i18n.dart';
import 'package:ja_iq5_flash/modules/services/ota_update_service.dart';
import 'package:ja_iq5_flash/modules/ui/glass_update_dialog.dart';
import 'package:ja_iq5_flash/modules/ui/styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File configFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ota_test_');
    configFile = File('${tempDir.path}/update_config.json');

    OtaUpdateService().setCustomConfigFileForTesting(configFile);
    OtaUpdateService().setCustomServerDirForTesting(null);
  });

  tearDown(() async {
    OtaUpdateService().setCustomConfigFileForTesting(null);
    OtaUpdateService().setCustomServerDirForTesting(null);

    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('SemanticVersion Unit Tests', () {
    test('Release follows rc and malformed versions are rejected', () {
      expect(
        SemanticVersion.tryParse('1.2.0-rc.2')! <
            SemanticVersion.tryParse('1.2.0-rc.10')!,
        true,
      );
      expect(
        SemanticVersion.tryParse('1.2.0-rc.10')! <
            SemanticVersion.tryParse('1.2.0')!,
        true,
      );
      expect(SemanticVersion.tryParse('1.2.3.4'), isNull);
      expect(
        SemanticVersion.tryParse('1.2.0')!.hashCode,
        SemanticVersion.tryParse('1.2.0+0')!.hashCode,
      );
      expect(OtaUpdateService.isValidPackageName('../other_v9.0.0.zip'), false);
      expect(OtaUpdateService.isValidPackageName('OtherApp_v9.0.0.zip'), false);
      expect(
        OtaUpdateService.isValidPackageName(
          'JA_IQ5_Flash_v1.2.2_Windows_x64.zip',
        ),
        true,
      );
    });

    test('Correctly parses SemVer formats with and without prefix', () {
      final v1 = SemanticVersion.tryParse('1.0.0');
      expect(v1, isNotNull);
      expect(v1!.major, equals(1));
      expect(v1.minor, equals(0));
      expect(v1.patch, equals(0));
      expect(v1.build, isNull);

      final v2 = SemanticVersion.tryParse('v2.4.1+15');
      expect(v2, isNotNull);
      expect(v2!.major, equals(2));
      expect(v2.minor, equals(4));
      expect(v2.patch, equals(1));
      expect(v2.build, equals(15));

      final v3 = SemanticVersion.tryParse('1.1');
      expect(v3, isNotNull);
      expect(v3!.major, equals(1));
      expect(v3.minor, equals(1));
      expect(v3.patch, equals(0));

      final vInvalid = SemanticVersion.tryParse('invalid_version_string');
      expect(vInvalid, isNull);

      final vNull = SemanticVersion.tryParse(null);
      expect(vNull, isNull);

      expect(appVersion, equals('1.3.0+3'));
    });

    test('SemanticVersion comparison operators work correctly', () {
      final v100 = SemanticVersion.tryParse('1.0.0')!;
      final v101 = SemanticVersion.tryParse('1.0.1')!;
      final v110 = SemanticVersion.tryParse('1.1.0')!;
      final v200 = SemanticVersion.tryParse('2.0.0')!;
      final v100b1 = SemanticVersion.tryParse('1.0.0+1')!;
      final v100b2 = SemanticVersion.tryParse('1.0.0+2')!;

      expect(v100 < v101, isTrue);
      expect(v101 < v110, isTrue);
      expect(v110 < v200, isTrue);
      expect(v200 > v110, isTrue);
      expect(v100b1 < v100b2, isTrue);
      expect(v100 == SemanticVersion.tryParse('1.0.0')!, isTrue);
      expect(v110 >= v100, isTrue);
      expect(v100 <= v110, isTrue);
      expect(v100 > v110, isFalse);
    });

    test('SemanticVersion string representation is consistent', () {
      final v1 = SemanticVersion.tryParse('1.2.3')!;
      expect(v1.toString(), equals('1.2.3'));

      final v2 = SemanticVersion.tryParse('v1.2.3+4')!;
      expect(v2.toString(), equals('1.2.3+4'));
    });
  });

  group('UpdatePackageInfo & OtaUpdateConfig Tests', () {
    test('formattedSize converts bytes to human-readable units', () {
      final pkg0 = UpdatePackageInfo(
        version: SemanticVersion.tryParse('1.0.0')!,
        fileName: 'test.zip',
        fullPath: '/path/test.zip',
        fileSize: 0,
      );
      expect(pkg0.formattedSize, equals('0 B'));

      final pkgKb = UpdatePackageInfo(
        version: SemanticVersion.tryParse('1.0.0')!,
        fileName: 'test.zip',
        fullPath: '/path/test.zip',
        fileSize: 1024,
      );
      expect(pkgKb.formattedSize, equals('1.00 KB'));

      final pkgMb = UpdatePackageInfo(
        version: SemanticVersion.tryParse('1.0.0')!,
        fileName: 'test.zip',
        fullPath: '/path/test.zip',
        fileSize: 14 * 1024 * 1024 + 512 * 1024,
      );
      expect(pkgMb.formattedSize, contains('MB'));

      final pkgGb = UpdatePackageInfo(
        version: SemanticVersion.tryParse('1.0.0')!,
        fileName: 'test.zip',
        fullPath: '/path/test.zip',
        fileSize: 2 * 1024 * 1024 * 1024,
      );
      expect(pkgGb.formattedSize, contains('GB'));
    });

    test('OtaUpdateConfig serialization and deserialization', () {
      final config = OtaUpdateConfig(
        serverPath: r'\\server\share\updates',
        username: 'admin',
        password: 'secretPassword',
        checkInterval: 'weekly',
        autoDownload: true,
      );

      final json = config.toJson();
      expect(json['serverPath'], equals(r'\\server\share\updates'));
      expect(json['username'], equals('admin'));
      expect(json['password'], equals('secretPassword'));
      expect(json['checkInterval'], equals('weekly'));
      expect(json['autoDownload'], isTrue);

      final parsed = OtaUpdateConfig.fromJson(json);
      expect(parsed.serverPath, equals(config.serverPath));
      expect(parsed.username, equals(config.username));
      expect(parsed.password, equals(config.password));
      expect(parsed.checkInterval, equals(config.checkInterval));
      expect(parsed.autoDownload, equals(config.autoDownload));
    });

    test(
      'OtaUpdateConfig defaults use user-requested server and credentials',
      () {
        final defaults = OtaUpdateConfig.defaults();
        expect(defaults.serverPath, contains(r'10.81.141.226'));
        expect(defaults.serverPath, contains('JA_Update'));
        expect(defaults.serverPath, contains('JA_IQ5_Flash'));
        expect(defaults.username, equals('user'));
        expect(defaults.password, equals('user'));
        expect(defaults.checkInterval, equals('daily'));
      },
    );
  });

  group('OtaUpdateService Logic Tests', () {
    test(
      'uses the ZIP filename version when version.json is inconsistent',
      () async {
        final serverDir = Directory('${tempDir.path}/server')..createSync();
        const packageName = 'JA_IQ5_Flash_v1.2.2_Windows_x64.zip';
        File('${serverDir.path}/$packageName').writeAsBytesSync([1, 2, 3]);
        File('${serverDir.path}/version.json').writeAsStringSync('''
{
  "version": "9.9.9",
  "fileName": "$packageName"
}
''');
        final service = OtaUpdateService();
        service.setCustomServerDirForTesting(serverDir);

        final result = await service.checkForUpdates(
          overrideCurrentVersion: '1.0.0',
        );

        expect(result.hasUpdate, isTrue);
        expect(result.packageInfo!.version.toString(), equals('1.2.2'));
      },
    );

    test('parses only a valid version from an approved package filename', () {
      expect(
        OtaUpdateService.packageVersionFromFileName(
          'JA_IQ5_Flash_v1.2.3+4_Windows_x64.zip',
        )!.toString(),
        equals('1.2.3+4'),
      );
      expect(
        OtaUpdateService.packageVersionFromFileName('JA_IQ5_Flash_notes.zip'),
        isNull,
      );
    });

    test('rejects an update package whose SHA-256 does not match', () async {
      final packageFile = File('${tempDir.path}/JA_IQ5_Flash_v9.9.9.zip')
        ..writeAsBytesSync([1, 2, 3]);
      final package = UpdatePackageInfo(
        version: SemanticVersion.tryParse('9.9.9')!,
        fileName: packageFile.uri.pathSegments.last,
        fullPath: packageFile.path,
        fileSize: packageFile.lengthSync(),
        sha256: '0' * 64,
      );

      await expectLater(
        OtaUpdateService().validatePackageForTesting(package),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Update package checksum verification failed',
          ),
        ),
      );
    });

    test('extractSmbShareRoot properly parses UNC root path', () {
      expect(
        OtaUpdateService.extractSmbShareRoot(
          r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_IQ5_Flash',
        ),
        equals(r'\\10.81.141.226\temp'),
      );

      expect(
        OtaUpdateService.extractSmbShareRoot(r'\\192.168.1.100\SharedFolder'),
        equals(r'\\192.168.1.100\SharedFolder'),
      );

      expect(
        OtaUpdateService.extractSmbShareRoot('//10.81.141.226/temp/subfolder'),
        equals(r'\\10.81.141.226\temp'),
      );
    });

    test('shouldCheckForUpdates respects intervals correctly', () {
      final service = OtaUpdateService();
      final now = DateTime.now();

      // Interval: off -> always false
      expect(
        service.shouldCheckForUpdates(interval: 'off', lastCheckTime: null),
        isFalse,
      );

      // Interval: daily
      expect(
        service.shouldCheckForUpdates(interval: 'daily', lastCheckTime: null),
        isTrue,
      );
      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: now.subtract(const Duration(hours: 12)),
        ),
        isFalse,
      );
      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: now.subtract(const Duration(hours: 25)),
        ),
        isTrue,
      );

      // Interval: weekly
      expect(
        service.shouldCheckForUpdates(
          interval: 'weekly',
          lastCheckTime: now.subtract(const Duration(days: 3)),
        ),
        isFalse,
      );
      expect(
        service.shouldCheckForUpdates(
          interval: 'weekly',
          lastCheckTime: now.subtract(const Duration(days: 8)),
        ),
        isTrue,
      );

      // Interval: monthly
      expect(
        service.shouldCheckForUpdates(
          interval: 'monthly',
          lastCheckTime: now.subtract(const Duration(days: 15)),
        ),
        isFalse,
      );
      expect(
        service.shouldCheckForUpdates(
          interval: 'monthly',
          lastCheckTime: now.subtract(const Duration(days: 32)),
        ),
        isTrue,
      );
    });

    test(
      'loadExternalConfigFile and saveExternalConfigFile persist correctly',
      () async {
        final service = OtaUpdateService();
        final loadedDefaults = await service.loadExternalConfigFile();
        expect(loadedDefaults.serverPath, contains('10.81.141.226'));

        final modified = loadedDefaults.copyWith(
          serverPath: r'\\192.168.1.200\updates',
          username: 'admin2',
          password: 'password2',
          checkInterval: 'weekly',
        );
        await service.saveExternalConfigFile(modified);

        final reloaded = await service.loadExternalConfigFile();
        expect(reloaded.serverPath, equals(r'\\192.168.1.200\updates'));
        expect(reloaded.username, equals('admin2'));
        expect(reloaded.password, equals('password2'));
        expect(reloaded.checkInterval, equals('weekly'));
      },
    );

    test(
      'generateApplyUpdateScript generates robust robocopy handoff with rollback',
      () {
        final script = OtaUpdateService.generateApplyUpdateScript(
          oldPid: 1234,
          sourceDir: r'C:\Temp\OTA_Extract_123',
          targetDir: r'C:\Program Files\JA_IQ5_Flash',
          exeName: 'ja_iq5_flash.exe',
        );

        expect(script, contains('robocopy'));
        expect(script, contains('/E'));
        expect(script, contains('/XD'));
        expect(script, contains('backup'));
        expect(script, contains('rollback'));
        expect(script, contains('ja_iq5_flash.exe'));
        expect(script, contains('config.ini'));
        expect(script, contains('update_config.json'));
        expect(script, contains('license.key'));
      },
    );
  });

  group('GlassUpdateDialog Widget Tests', () {
    testWidgets(
      'Renders GlassUpdateDialog with version details and release notes',
      (tester) async {
        setLang('VI');
        final pkg = UpdatePackageInfo(
          version: SemanticVersion.tryParse('9.9.9')!,
          fileName: 'JA_IQ5_Flash_v9.9.9_Windows_x64.zip',
          fullPath: r'\\server\share\JA_IQ5_Flash_v9.9.9_Windows_x64.zip',
          fileSize: 45 * 1024 * 1024,
          releaseNotes: 'Bản vá sửa lỗi tốc độ flash Sahara 9008.',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlassUpdateDialog(packageInfo: pkg, theme: AppTheme()),
            ),
          ),
        );

        // Verify title & version badges
        expect(find.text(tr('ota_dialog_title')), findsOneWidget);
        expect(find.text('v9.9.9'), findsOneWidget);
        expect(find.text('v$appVersion'), findsOneWidget);
        expect(
          find.text('Bản vá sửa lỗi tốc độ flash Sahara 9008.'),
          findsOneWidget,
        );

        // Verify action buttons
        expect(find.byKey(const ValueKey('btn-update-later')), findsOneWidget);
        expect(find.byKey(const ValueKey('btn-update-now')), findsOneWidget);
      },
    );

    testWidgets('Clicking update later closes dialog', (tester) async {
      setLang('EN');
      final pkg = UpdatePackageInfo(
        version: SemanticVersion.tryParse('9.9.9')!,
        fileName: 'JA_IQ5_Flash_v9.9.9_Windows_x64.zip',
        fullPath: r'\\server\share\JA_IQ5_Flash_v9.9.9_Windows_x64.zip',
        fileSize: 10 * 1024 * 1024,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    showGlassUpdateDialog(context: context, packageInfo: pkg),
                child: const Text('SHOW DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('SHOW DIALOG'));
      await tester.pumpAndSettle();

      expect(find.byType(GlassUpdateDialog), findsOneWidget);

      // Tap Remind Later button
      await tester.tap(find.byKey(const ValueKey('btn-update-later')));
      await tester.pumpAndSettle();

      expect(find.byType(GlassUpdateDialog), findsNothing);
    });
  });
}
