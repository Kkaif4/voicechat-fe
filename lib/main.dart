import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/network/socket_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Dependencies
  final storage = const FlutterSecureStorage();
  final apiClient = ApiClient(storage);
  final authRepository = AuthRepository(apiClient, storage);
  final socketService = SocketService();

  runApp(MyApp(authRepository: authRepository, socketService: socketService));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final SocketService socketService;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.socketService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: socketService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository, socketService)
                  ..add(AuthCheckRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'VoiceChat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const LoginPage(),
        ),
      ),
    );
  }
}
