import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicplayer/application/blocs/mix/mix_bloc.dart';
import 'package:musicplayer/application/blocs/mix/mix_event.dart';
import 'package:musicplayer/application/blocs/mix/mix_state.dart';

class MixSection extends StatefulWidget {
  const MixSection({super.key});
  @override
  State<MixSection> createState() => _MixSectionState();
}

class _MixSectionState extends State<MixSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<MixBloc, MixState>(
      builder: (context, state) {
        if (state is MixLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MixesLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tus mixes',
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
                itemCount: state.mixes.length,
                separatorBuilder:
                    (_, __) =>
                        const Divider(color: Colors.transparent, height: 8),
                itemBuilder: (_, index) {
                  final m = state.mixes[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        m.portadaUrl ?? '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            ),
                      ),
                    ),
                    title: Text(
                      m.titulo,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      m.subtitulo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      context.read<MixBloc>().add(LoadMixInfo(m.id));
                      context.read<MixBloc>().add(LoadMixTracks(m.id));
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
