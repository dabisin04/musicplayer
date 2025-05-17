import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicplayer/application/blocs/auth/auth_bloc.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_bloc.dart';
import 'package:musicplayer/application/blocs/configuration/configuration_event.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_bloc.dart';
import 'package:musicplayer/application/blocs/mix/mix_bloc.dart';
import 'package:musicplayer/application/blocs/letra/letra_bloc.dart';
import 'package:musicplayer/application/blocs/configuration/configuration_bloc.dart';
import 'package:musicplayer/core/styles/app_theme.dart';
import 'package:musicplayer/domain/services/verification_service.dart';
import 'package:musicplayer/infrastructure/adapters/cancion_repository_impl.dart';
import 'package:musicplayer/infrastructure/adapters/playlist_repository_impl.dart';
import 'package:musicplayer/infrastructure/adapters/mix_repository_impl.dart';
import 'package:musicplayer/infrastructure/adapters/letra_repository_impl.dart';
import 'package:musicplayer/infrastructure/adapters/configuration_repository_impl.dart';
import 'package:musicplayer/domain/repositories/cancion_repository.dart';
import 'package:musicplayer/domain/repositories/playlist_repository.dart';
import 'package:musicplayer/domain/repositories/mix_repository.dart';
import 'package:musicplayer/domain/repositories/letra_repository.dart';
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';
import 'package:musicplayer/domain/services/hive_database_service.dart';
import 'package:musicplayer/presentation/screens/configuration.dart';
import 'package:musicplayer/presentation/screens/home.dart';
import 'package:musicplayer/presentation/screens/search.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos local
  await HiveDatabaseService.init();

  // Repositorios
  final configuracionRepo = ConfiguracionRepositoryImpl();
  final cancionRepo = CancionRepositoryImpl(configuracionRepo);
  final playlistRepo = PlaylistRepositoryImpl(configuracionRepo);
  final mixRepo = MixRepositoryImpl(configuracionRepo);
  final letraRepo = LetraRepositoryImpl(configuracionRepo);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ConfiguracionRepository>.value(
          value: configuracionRepo,
        ),
        RepositoryProvider<CancionRepository>.value(value: cancionRepo),
        RepositoryProvider<PlaylistRepository>.value(value: playlistRepo),
        RepositoryProvider<MixRepository>.value(value: mixRepo),
        RepositoryProvider<LetraRepository>.value(value: letraRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConfiguracionBloc>(
            create:
                (_) =>
                    ConfiguracionBloc(configuracionRepo)
                      ..add(LoadApiConfig()) // carga la configuración de la API
                      ..add(
                        LoadUserConfig(),
                      ), // carga la configuración del usuario
          ),
          BlocProvider<CancionBloc>(
            create: (context) => CancionBloc(cancionRepo, configuracionRepo),
          ),
          BlocProvider<PlaylistBloc>(
            create: (context) => PlaylistBloc(playlistRepo),
          ),
          BlocProvider<MixBloc>(create: (context) => MixBloc(mixRepo)),
          BlocProvider<LetraBloc>(create: (context) => LetraBloc(letraRepo)),
          BlocProvider<TidalAuthBloc>(
            create:
                (context) => TidalAuthBloc(TidalAuthService(configuracionRepo)),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MusicPlayer',
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
          routes: {
            '/search': (context) => const SearchScreen(),
            '/configuracion': (context) => const ConfigurationScreen(),
          },
        ),
      ),
    ),
  );
}
