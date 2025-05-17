import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicplayer/presentation/widgets/home_drawer.dart';
import 'package:musicplayer/presentation/widgets/persistant_nav_bar.dart';
import 'package:musicplayer/presentation/widgets/playlist_section.dart';
import 'package:musicplayer/presentation/widgets/mix_section.dart';
import 'package:musicplayer/presentation/widgets/song_section.dart';
import 'package:musicplayer/presentation/screens/search.dart';

import 'package:musicplayer/application/blocs/playlist/playlist_bloc.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_event.dart';
import 'package:musicplayer/application/blocs/mix/mix_bloc.dart';
import 'package:musicplayer/application/blocs/mix/mix_event.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_bloc.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<PlaylistBloc>().add(LoadPlaylists());
    context.read<MixBloc>().add(LoadMixes());
    context.read<CancionBloc>().add(ObtenerCancionesLocales());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HomeDrawer(),
      bottomNavigationBar: PersistentNavBar(
        selectedIndex: _currentIndex,
        onTap: _onNavTap,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [_InicioPage(), _SearchPage()],
      ),
    );
  }
}

class _InicioPage extends StatelessWidget {
  const _InicioPage();

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder:
          (context, innerScrolled) => [
            SliverAppBar(
              title: const Text('Tu música', style: TextStyle(fontSize: 24)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              snap: true,
              forceElevated: innerScrolled,
            ),
          ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: const [
            SizedBox(height: 16),
            PlaylistSection(),
            SizedBox(height: 24),
            MixSection(),
            SizedBox(height: 24),
            SongSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();

  @override
  Widget build(BuildContext context) {
    return SearchScreen();
  }
}
