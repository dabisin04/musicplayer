import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_bloc.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_event.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_state.dart';

class SongSection extends StatefulWidget {
  const SongSection({super.key});

  @override
  State<SongSection> createState() => _SongSectionState();
}

class _SongSectionState extends State<SongSection>
    with AutomaticKeepAliveClientMixin {
  List _cancionesCache = [];

  @override
  void initState() {
    super.initState();
    context.read<CancionBloc>().add(ObtenerCancionesLocales());
  }

  @override
  bool get wantKeepAlive => true;

  void _actualizarCache(List canciones) {
    final nuevas =
        canciones.where((c) {
          final path = c.localPath;
          final exists = path != null && File(path).existsSync();
          print('[CACHE] ${c.name} - Path: $path - Existe: $exists');
          return path != null;
        }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _cancionesCache = nuevas;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<CancionBloc, CancionState>(
      listener: (context, state) {
        if (state is CancionesCargadas) {
          print('[LISTENER] Canciones cargadas: ${state.canciones.length}');
          _actualizarCache(state.canciones);
        }

        if (state is CancionDescargada || state is CancionEncontrada) {
          context.read<CancionBloc>().add(ObtenerCancionesLocales());
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Tus canciones descargadas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child:
                _cancionesCache.isEmpty
                    ? const Text(
                      'No tienes canciones descargadas o aún se están cargando.',
                      style: TextStyle(color: Colors.grey),
                    )
                    : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cancionesCache.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) {
                        final c = _cancionesCache[index];
                        final fileExists = File(c.localPath!).existsSync();

                        return GestureDetector(
                          onTap: () {
                            // TODO: reproducir canción c
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      c.coverUrl ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.music_note,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ),
                                  if (!fileExists)
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.redAccent,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
