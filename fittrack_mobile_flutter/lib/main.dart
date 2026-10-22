import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await initializeDateFormatting('fr');
  final storage = await LocalStorage.init();
  final baseUrl = dotenv.maybeGet(AppConstants.apiBaseUrl) ??
      //'http://192.168.0.189:3000/api';
      'https://fittrack-backend-murex.vercel.app/api';
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        dioClientProvider.overrideWithValue(DioClient(storage, baseUrl)),
      ],
      child: const FitTrackApp(),
    ),
  );
}

class FitTrackApp extends ConsumerWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
