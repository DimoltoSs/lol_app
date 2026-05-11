import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --- WIDGET DE BÚSQUEDA ---
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  Future<void> _searchPlayer() async {
    final query = _searchController.text.trim();
    if (!query.contains('#')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formato: Nombre#TAG')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parts = query.split('#');
      // Nota: Usa 10.0.2.2:5000 si estás en el emulador de Android
      final url = Uri.parse('http://127.0.0.1:5000/api/player/${parts[0]}/${parts[1]}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final playerData = json.decode(response.body);
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF121212),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) => PlayerProfileSheet(playerData: playerData),
          );
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jugador no encontrado')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Busca a un Invocador', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  hintText: 'Ej. ITM Twilight#ITM',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF732571)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE040FB), width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchPlayer,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF610463), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Buscar Estadísticas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- VISTA DETALLADA DEL PERFIL ---
class PlayerProfileSheet extends StatelessWidget {
  final Map<String, dynamic> playerData;
  const PlayerProfileSheet({super.key, required this.playerData});

  String _getRankEmblemUrl(String rankTier) {
    if (rankTier == "UNRANKED") return "";
    String baseTier = rankTier.split(" ")[0].toLowerCase();
    return "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-static-assets/global/default/images/ranked-emblem/emblem-$baseTier.png";
  }

  @override
  Widget build(BuildContext context) {
    final String name = playerData['gameName'] ?? "Desconocido";
    final String tag = "#${playerData['tagLine'] ?? ""}";
    final int level = playerData['summonerLevel'] ?? 0;
    final int iconId = playerData['profileIconId'] ?? 1;
    final String iconUrl = "https://raw.communitydragon.org/latest/plugins/rcp-be-lol-game-data/global/default/v1/profile-icons/$iconId.jpg";
    final String topChamp = playerData['topChampion'] ?? "Teemo";
    final String splashUrl = "https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${topChamp}_0.jpg";
    final String rank = playerData['tier'] ?? "UNRANKED";
    final String lp = "${playerData['leaguePoints'] ?? 0} LP";
    final String emblemUrl = _getRankEmblemUrl(rank);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // --- CABECERA CON SPLASH ---
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(splashUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE040FB), width: 2)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(iconUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey, size: 50)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: Text("Nivel $level", style: const TextStyle(color: Colors.white, fontSize: 12))),
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          Text(tag, style: const TextStyle(color: Color(0xFFE040FB), fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- SECCIÓN DE RANGO REESCALADA ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CLASIFICATORIA ACTUAL", style: TextStyle(color: Color(0xFF732571), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF610463))),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 140, height: 140,
                          child: OverflowBox(
                            maxWidth: 200, maxHeight: 200,
                            child: Transform.scale(
                              scale: 1.4,
                              child: Image.network(
                                emblemUrl, 
                                fit: BoxFit.contain, 
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: Colors.grey, size: 70)
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Ranked Solo/Duo", style: TextStyle(color: Colors.grey)),
                              Text(rank, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(lp, style: const TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}