import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_bloc.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_event.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_state.dart';

class PlaylistSection extends StatefulWidget {
  const PlaylistSection({super.key});
  @override
  State<PlaylistSection> createState() => _PlaylistSectionState();
}

class _PlaylistSectionState extends State<PlaylistSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PlaylistBloc, PlaylistState>(
      builder: (context, state) {
        if (state is PlaylistLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PlaylistsLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tus playlists',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.playlists.length,
                separatorBuilder:
                    (_, __) =>
                        const Divider(color: Colors.transparent, height: 8),
                itemBuilder: (_, index) {
                  final p = state.playlists[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        p.coverUrl ?? '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.playlist_play,
                              color: Colors.grey,
                            ),
                      ),
                    ),
                    title: Text(
                      p.nombre,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      context.read<PlaylistBloc>().add(
                        LoadPlaylistTracks(p.id),
                      );
                    },
                  );
                },
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
