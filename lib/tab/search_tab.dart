import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --- WIDGET DE BÚSQUEDA PRINCIPAL ---
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
      // Nota: Si usas emulador Android, la IP debe ser 10.0.2.2 en lugar de 127.0.0.1
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jugador no encontrado o error de red')));
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
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Buscar Estadísticas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerProfileSheet extends StatelessWidget {
  final Map<String, dynamic> playerData;
  const PlayerProfileSheet({super.key, required this.playerData});

  String _getRankEmblemUrl(String rankTier) {
    if (rankTier == "UNRANKED") return "";
    String baseTier = rankTier.split(" ")[0].toLowerCase();
    return "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-static-assets/global/default/images/ranked-emblem/emblem-$baseTier.png";
  }

  Widget _buildItemIcon(int itemId, String patch, {bool isTrinket = false}) {
    if (itemId == 0) {
      return Container(width: 24, height: 24, margin: EdgeInsets.only(right: isTrinket ? 0 : 2), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)));
    }
    return Container(
      width: 24, height: 24, margin: EdgeInsets.only(right: isTrinket ? 0 : 2),
      child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network('https://ddragon.leagueoflegends.com/cdn/$patch/img/item/$itemId.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey))),
    );
  }

  Widget _buildSmallIcon(String url, {bool isCircular = false}) {
    return Container(
      width: 22, height: 22, margin: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircular ? 20 : 4),
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[800])),
      ),
    );
  }

  Widget _buildTinyIcon(String url) {
    return Container(
      width: 14, height: 14, margin: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10), // Runas redondas
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[800])),
      ),
    );
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
    final String latestPatch = playerData['latestPatch'] ?? "14.10.1";
    final List<dynamic> matches = playerData['matchHistory'] ?? [];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Container(
            height: 200, width: double.infinity,
            decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(splashUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(width: 90, height: 90, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE040FB), width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(iconUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.grey, size: 50)))),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), margin: const EdgeInsets.only(bottom: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: Text("Nivel $level", style: const TextStyle(color: Colors.white, fontSize: 12))),
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          Text(tag, style: const TextStyle(color: Color(0xFFE040FB), fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF610463))),
                    child: Row(
                      children: [
                        SizedBox(width: 80, height: 80, child: OverflowBox(maxWidth: 130, maxHeight: 130, child: Transform.scale(scale: 1.4, child: Image.network(emblemUrl, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Colors.grey, size: 50))))),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Ranked Solo/Duo", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(rank, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(lp, style: const TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.bold))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("ÚLTIMAS PARTIDAS", style: TextStyle(color: Color(0xFF732571), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (matches.isEmpty) const Center(child: Text("Sin partidas recientes.", style: TextStyle(color: Colors.grey))),
                    
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final bool isWin = match['win'] ?? false;
                      
                      final champIconUrl = "https://raw.communitydragon.org/latest/plugins/rcp-be-lol-game-data/global/default/v1/champion-icons/${match['championId']}.png";
                      final spell1Url = "https://ddragon.leagueoflegends.com/cdn/$latestPatch/img/spell/${match['spell1Name']}.png";
                      final spell2Url = "https://ddragon.leagueoflegends.com/cdn/$latestPatch/img/spell/${match['spell2Name']}.png";
                      
                      final primaryKeystoneUrl = "https://ddragon.leagueoflegends.com/cdn/img/${match['primaryKeystoneIcon']}";
                      final pRune1Url = "https://ddragon.leagueoflegends.com/cdn/img/${match['primaryRune1Icon']}";
                      final pRune2Url = "https://ddragon.leagueoflegends.com/cdn/img/${match['primaryRune2Icon']}";
                      final pRune3Url = "https://ddragon.leagueoflegends.com/cdn/img/${match['primaryRune3Icon']}";
                      
                      final secondaryStyleUrl = "https://ddragon.leagueoflegends.com/cdn/img/${match['secondaryStyleIcon']}";
                      final sRune1Url = "https://ddragon.leagueoflegends.com/cdn/img/${match['secondaryRune1Icon']}";
                      final sRune2Url = "https://ddragon.leagueoflegends.com/cdn/img/${match['secondaryRune2Icon']}";

                      final int kills = match['kills'] ?? 0;
                      final int deaths = match['deaths'] ?? 0;
                      final int assists = match['assists'] ?? 0;
                      final int teamKills = match['teamKills'] ?? 0;
                      final int totalCs = match['totalCs'] ?? 0;
                      final int gameDuration = match['gameDuration'] ?? 1;
                      final int gold = match['goldEarned'] ?? 0;
                      final int vision = match['visionScore'] ?? 0;

                      final double kdaRatio = deaths == 0 ? (kills + assists).toDouble() : (kills + assists) / deaths;
                      final int kp = teamKills == 0 ? 0 : (((kills + assists) / teamKills) * 100).round();
                      final double csPerMin = totalCs / (gameDuration / 60);
                      final String goldStr = gold >= 1000 ? "${(gold / 1000).toStringAsFixed(1)}k" : gold.toString();
                      final String durationStr = "${(gameDuration ~/ 60)}:${(gameDuration % 60).toString().padLeft(2, '0')}";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isWin ? const Color(0xFF1E2B3C) : const Color(0xFF3B1E22),
                          border: Border(left: BorderSide(color: isWin ? Colors.blueAccent : Colors.redAccent, width: 6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isWin ? "VICTORIA" : "DERROTA", style: TextStyle(color: isWin ? Colors.blueAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text("$durationStr min", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(champIconUrl, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 48, height: 48, color: Colors.grey))),
                                        Positioned(bottom: -4, right: -4, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)), child: Text("${match['champLevel']}", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))))
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    Column(children: [_buildSmallIcon(spell1Url), _buildSmallIcon(spell2Url)]),
                                    const SizedBox(width: 2),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        Row(
                                          children: [
                                            _buildSmallIcon(primaryKeystoneUrl, isCircular: true),
                                            _buildTinyIcon(pRune1Url),
                                            _buildTinyIcon(pRune2Url),
                                            _buildTinyIcon(pRune3Url),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            _buildSmallIcon(secondaryStyleUrl, isCircular: true),
                                            _buildTinyIcon(sRune1Url),
                                            _buildTinyIcon(sRune2Url),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          children: [
                                            TextSpan(text: "$kills ", style: const TextStyle(color: Colors.white)), const TextSpan(text: "/ ", style: TextStyle(color: Colors.grey)), TextSpan(text: "$deaths ", style: const TextStyle(color: Colors.redAccent)), const TextSpan(text: "/ ", style: TextStyle(color: Colors.grey)), TextSpan(text: "$assists", style: const TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text("${kdaRatio.toStringAsFixed(2)}:1 KDA", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      Text("KP $kp%", style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("$totalCs CS (${csPerMin.toStringAsFixed(1)})", style: const TextStyle(color: Colors.grey, fontSize: 11)), const SizedBox(height: 2),
                                    Row(children: [const Icon(Icons.circle, color: Colors.amber, size: 10), const SizedBox(width: 4), Text(goldStr, style: const TextStyle(color: Colors.grey, fontSize: 11))]), const SizedBox(height: 2),
                                    Row(children: [const Icon(Icons.remove_red_eye, color: Colors.blueGrey, size: 12), const SizedBox(width: 4), Text("$vision", style: const TextStyle(color: Colors.grey, fontSize: 11))]),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildItemIcon(match['item0'] ?? 0, latestPatch), _buildItemIcon(match['item1'] ?? 0, latestPatch), _buildItemIcon(match['item2'] ?? 0, latestPatch), _buildItemIcon(match['item3'] ?? 0, latestPatch), _buildItemIcon(match['item4'] ?? 0, latestPatch), _buildItemIcon(match['item5'] ?? 0, latestPatch), const Spacer(), _buildItemIcon(match['item6'] ?? 0, latestPatch, isTrinket: true),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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