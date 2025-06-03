// lib/presentation/screens/search.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:musicplayer/application/blocs/cancion/cancion_bloc.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_event.dart';
import 'package:musicplayer/application/blocs/cancion/cancion_state.dart';
import 'package:musicplayer/application/blocs/mix/mix_bloc.dart';
import 'package:musicplayer/application/blocs/mix/mix_event.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_bloc.dart';
import 'package:musicplayer/application/blocs/playlist/playlist_event.dart';
import 'package:musicplayer/domain/entities/cancion.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _searchMode = 'general';
  final List<OrigenCancion> _origenesSeleccionados = [
    OrigenCancion.tidal,
    OrigenCancion.youtube,
    OrigenCancion.local,
  ];

  List<Cancion> _results = [];
  bool _isLoading = false;
  bool _showFilters = false;
  Timer? _debounceTimer;

  static const _historyKey = 'search_history';
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _addToHistory(String q) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(q);
    _history.insert(0, q);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    await prefs.setStringList(_historyKey, _history);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() => _history = []);
  }

  void _onSearch(String query) {
    if (query.isEmpty) return;

    // Cancelar búsqueda anterior si existe
    _debounceTimer?.cancel();

    // Configurar nuevo timer para debounce
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _addToHistory(query);
      setState(() {
        _isLoading = true;
        _showFilters = false;
      });
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final cancionBloc = context.read<CancionBloc>();
    final mixBloc = context.read<MixBloc>();
    final playlistBloc = context.read<PlaylistBloc>();
    final isUrl =
        query.contains('http') ||
        query.contains('tidal.com') ||
        query.contains('youtube.com');

    setState(() {
      _isLoading = true;
    });

    if (isUrl) {
      _handleUrlSearch(query, cancionBloc, mixBloc, playlistBloc);
    } else {
      _handleTextSearch(query, cancionBloc);
    }
  }

  void _handleUrlSearch(
    String query,
    CancionBloc cancionBloc,
    MixBloc mixBloc,
    PlaylistBloc playlistBloc,
  ) {
    final uri = Uri.parse(query);
    if (query.contains('/track/') || query.contains('watch?v=')) {
      cancionBloc.add(ObtenerCancionPorId(query));
    } else if (query.contains('/mix/')) {
      final mixId = uri.pathSegments.lastWhere((seg) => seg.isNotEmpty);
      mixBloc.add(LoadMixInfo(mixId));
      mixBloc.add(LoadMixTracks(mixId));
    } else if (query.contains('/playlist/')) {
      final playlistId = uri.pathSegments.lastWhere((seg) => seg.isNotEmpty);
      playlistBloc.add(LoadPlaylistTracks(playlistId));
    } else if (query.contains('/album/')) {
      final albumName = uri.pathSegments
          .lastWhere((seg) => seg.isNotEmpty)
          .replaceAll('-', ' ');
      cancionBloc.add(BuscarPorAlbum(albumName));
    } else {
      cancionBloc.add(ObtenerCancionPorId(query));
    }
  }

  void _handleTextSearch(String query, CancionBloc cancionBloc) {
    const limit = 10; // Límite por defecto
    switch (_searchMode) {
      case 'name':
        cancionBloc.add(BuscarPorNombre(query, limit: limit));
        break;
      case 'artist':
        cancionBloc.add(BuscarPorArtista(query, limit: limit));
        break;
      case 'album':
        cancionBloc.add(BuscarPorAlbum(query, limit: limit));
        break;
      default:
        cancionBloc.add(
          BuscarCancionesFiltradasLazy(
            query,
            _origenesSeleccionados,
            limit: limit,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar o pegar enlace…',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => _onSearch(_controller.text.trim()),
                      ),
                    ),
                    onSubmitted: (q) => _onSearch(q.trim()),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Modo de búsqueda',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        _typeChip('General', 'general'),
                        const SizedBox(width: 4),
                        _typeChip('Nombre', 'name'),
                        const SizedBox(width: 4),
                        _typeChip('Artista', 'artist'),
                        const SizedBox(width: 4),
                        _typeChip('Álbum', 'album'),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Orígenes', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        _originChip('Tidal', OrigenCancion.tidal),
                        const SizedBox(width: 4),
                        _originChip('YouTube', OrigenCancion.youtube),
                        const SizedBox(width: 4),
                        _originChip('Local', OrigenCancion.local),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState:
                  _showFilters
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocListener<CancionBloc, CancionState>(
                listener: (ctx, st) {
                  if (st is CancionesCargadas ||
                      st is CancionesFiltradasLazyCargadas) {
                    setState(() {
                      _results =
                          st is CancionesCargadas
                              ? st.canciones
                              : (st as CancionesFiltradasLazyCargadas)
                                  .canciones;
                      _isLoading = false;
                    });
                  }
                  if (st is CancionEncontrada) {
                    setState(() {
                      _results = [st.cancion];
                      _isLoading = false;
                    });
                  }
                  if (st is CancionError) {
                    setState(() => _isLoading = false);
                  }
                },
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : _results.isEmpty
                        ? _buildHistorialComoSeccion()
                        : _buildGroupedResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialComoSeccion() {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'No hay historial aún',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historial de búsquedas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: const Text(
                  'Limpiar',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
        ..._history.map(
          (query) => ListTile(
            leading: const Icon(Icons.history, color: Colors.white70),
            title: Text(query, style: const TextStyle(color: Colors.white)),
            onTap: () {
              _controller.text = query;
              _onSearch(query);
            },
          ),
        ),
      ],
    );
  }

  Widget _typeChip(String label, String mode) {
    final sel = _searchMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      selectedColor: Colors.white,
      backgroundColor: const Color(0xFF2A2A2A),
      labelStyle: TextStyle(color: sel ? Colors.black : Colors.white),
      onSelected: (_) => setState(() => _searchMode = mode),
    );
  }

  Widget _originChip(String label, OrigenCancion origen) {
    final selected = _origenesSeleccionados.contains(origen);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Colors.white,
      backgroundColor: const Color(0xFF2A2A2A),
      labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
      onSelected: (_) {
        setState(() {
          if (selected) {
            _origenesSeleccionados.remove(origen);
          } else {
            _origenesSeleccionados.add(origen);
          }
        });
      },
    );
  }

  Widget _buildGroupedResults() {
    final playlists =
        _results
            .where((c) => c.album.toLowerCase().contains('playlist'))
            .toList();
    final mixes =
        _results.where((c) => c.album.toLowerCase().contains('mix')).toList();
    final tidal =
        _results.where((c) => c.origen == OrigenCancion.tidal).toList();
    final youtube =
        _results.where((c) => c.origen == OrigenCancion.youtube).toList();
    final local =
        _results.where((c) => c.origen == OrigenCancion.local).toList();

    return ListView(
      children: [
        if (playlists.isNotEmpty)
          _section('Playlists', playlists, (c) {
            context.read<CancionBloc>().add(BuscarPorAlbum(c.album));
            setState(() => _isLoading = true);
          }),
        if (mixes.isNotEmpty)
          _section('Mixes', mixes, (c) {
            context.read<CancionBloc>().add(BuscarCanciones(c.name));
            setState(() => _isLoading = true);
          }),
        if (tidal.isNotEmpty) _section('🎶 TIDAL', tidal, (_) {}),
        if (youtube.isNotEmpty) _section('📺 YouTube', youtube, (_) {}),
        if (local.isNotEmpty) _section('💾 Local', local, (_) {}),
      ],
    );
  }

  Widget _section(
    String title,
    List<Cancion> items,
    void Function(Cancion) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map(
          (c) => ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                c.coverUrl ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                        const Icon(Icons.music_note, color: Colors.grey),
              ),
            ),
            title: Text(c.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              c.artist,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () {
                context.read<CancionBloc>().add(DescargarCancion(c));
              },
            ),
            onTap: () => onTap(c),
          ),
        ),
      ],
    );
  }
}
