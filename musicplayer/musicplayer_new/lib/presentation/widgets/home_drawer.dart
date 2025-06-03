import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicplayer/application/blocs/playlist/playlist_bloc.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_state.dart';
import 'package:musicplayer/application/blocs/mix/mix_bloc.dart';
import 'package:musicplayer/application/blocs/mix/mix_state.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_bloc.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_state.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  Widget _buildBadge(Widget child, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1C1C1E)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menú',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Inicio
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // Playlists con badge del count
            BlocBuilder<PlaylistBloc, PlaylistState>(
              builder: (context, state) {
                final count =
                    state is PlaylistsLoaded ? state.playlists.length : 0;
                return ListTile(
                  leading: _buildBadge(
                    const Icon(Icons.playlist_play, color: Colors.white),
                    count,
                  ),
                  title: const Text(
                    'Playlists',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Quizá llevar a sección de playlists
                  },
                );
              },
            ),

            // Mixes con badge
            BlocBuilder<MixBloc, MixState>(
              builder: (context, state) {
                final count = state is MixesLoaded ? state.mixes.length : 0;
                return ListTile(
                  leading: _buildBadge(
                    const Icon(Icons.shuffle, color: Colors.white),
                    count,
                  ),
                  title: const Text(
                    'Mixes',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),

            // Canciones con badge
            BlocBuilder<CancionBloc, CancionState>(
              builder: (context, state) {
                final count =
                    state is CancionesCargadas ? state.canciones.length : 0;
                return ListTile(
                  leading: _buildBadge(
                    const Icon(Icons.music_note, color: Colors.white),
                    count,
                  ),
                  title: const Text(
                    'Canciones',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),

            const Divider(color: Colors.grey),

            // Configuración
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Configuración',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/configuracion');
              },
            ),
          ],
        ),
      ),
    );
  }
}
