import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/champion.dart';

class ChampionsTab extends StatefulWidget {
  const ChampionsTab({super.key});

  @override
  State<ChampionsTab> createState() => _ChampionsTabState();
}

class _ChampionsTabState extends State<ChampionsTab> {
  List<Champion> champions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChampions();
  }

  Future<void> fetchChampions() async {
    const url = "https://ddragon.leagueoflegends.com/cdn/14.8.1/data/es_MX/champion.json";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['data'];
        List<Champion> loadedChamps = [];
        data.forEach((key, value) {
          loadedChamps.add(Champion.fromJson(key, value));
        });
        setState(() {
          champions = loadedChamps;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF610463)));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 800 ? 6 : (screenWidth > 500 ? 4 : 3);

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: champions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final champ = champions[index];
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF121212),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))
              ),
              builder: (context) => ChampionDetailSheet(champ: champ),
            );
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF610463), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF732571).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      champ.imgUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF732571), strokeWidth: 2));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                champ.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}

// WIDGET DE DETALLES CON SISTEMA DE PESTAÑAS
class ChampionDetailSheet extends StatefulWidget {
  final Champion champ;
  const ChampionDetailSheet({super.key, required this.champ});

  @override
  State<ChampionDetailSheet> createState() => _ChampionDetailSheetState();
}

class _ChampionDetailSheetState extends State<ChampionDetailSheet> {
  int selectedTab = 0;
  String? activeLabel, activeName, activeDescription;

  Future<Map<String, dynamic>> fetchChampionDetails(String champId) async {
    final url = "https://ddragon.leagueoflegends.com/cdn/14.8.1/data/es_MX/champion/$champId.json";
    final response = await http.get(Uri.parse(url));
    return json.decode(response.body)['data'][champId];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabMenu(),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchChampionDetails(widget.champ.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF610463)));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error de conexión", style: TextStyle(color: Colors.white)));
                }
                
                final data = snapshot.data!;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: selectedTab == 0 
                    ? _buildResumenContent(data) 
                    : _buildEstadisticasContent(data),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // COMPONENTES DE LA INTERFAZ

  Widget _buildHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage("https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${widget.champ.id}_0.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.champ.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            Text(widget.champ.title, style: const TextStyle(color: Color(0xFFE040FB), fontStyle: FontStyle.italic, shadows: [Shadow(blurRadius: 3, color: Colors.black)])),
          ],
        ),
      ),
    );
  }

  Widget _buildTabMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF1A1A1A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabButton("RESUMEN", 0),
          _buildTabButton("ESTADÍSTICAS", 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF610463) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF610463)),
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  // CONTENIDO PESTAÑA 0: RESUMEN
  Widget _buildResumenContent(Map<String, dynamic> data) {
    final spells = data['spells'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("HISTORIA", style: TextStyle(color: Color(0xFF732571), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(data['lore'], style: const TextStyle(color: Colors.white70, height: 1.5), textAlign: TextAlign.justify),
        const SizedBox(height: 25),
        const Text("HABILIDADES", style: TextStyle(color: Color(0xFF732571), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAbilityIcon("https://ddragon.leagueoflegends.com/cdn/14.8.1/img/passive/${data['passive']['image']['full']}", "P", data['passive']['name'], data['passive']['description']),
            for (var i = 0; i < spells.length; i++)
              _buildAbilityIcon("https://ddragon.leagueoflegends.com/cdn/14.8.1/img/spell/${spells[i]['id']}.png", ["Q", "W", "E", "R"][i], spells[i]['name'], spells[i]['description']),
          ],
        ),
        if (activeName != null) _buildAbilityDetailPanel(),
      ],
    );
  }

  // CONTENIDO PESTAÑA 1: ESTADÍSTICAS 
  Widget _buildEstadisticasContent(Map<String, dynamic> data) {
    final info = data['info'];
    final stats = data['stats'];
    final difficultyValue = info['difficulty'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ATRIBUTOS DE COMBATE", style: TextStyle(color: Color(0xFF732571), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildAttributeBar("Ataque", info['attack'] / 10),
                  _buildAttributeBar("Defensa", info['defense'] / 10),
                  _buildAttributeBar("Magia", info['magic'] / 10),
                ],
              ),
            ),
            const SizedBox(width: 20), // Separador central
          
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF610463), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _getDifficultyColor(difficultyValue).withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                  ]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("DIFICULTAD", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      _getDifficultyText(difficultyValue),
                      style: TextStyle(
                        color: _getDifficultyColor(difficultyValue),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text("$difficultyValue / 10", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 35),
        const Text("ESTADÍSTICAS TÉCNICAS", style: TextStyle(color: Color(0xFF732571), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildStatsTable(stats),
        
        const SizedBox(height: 30),
        const Text("CONSEJOS DE JUEGO", style: TextStyle(color: Color(0xFF732571), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        for (var tip in data['allytips'])
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text("• $tip", style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
      ],
    );
  }

  // LOGICA DE DIFICULTAD 
  
  String _getDifficultyText(int difficulty) {
    if (difficulty <= 3) return "BAJA";
    if (difficulty <= 6) return "MEDIA";
    return "ALTA";
  }

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 3) return Colors.greenAccent; // Fácil = Verde
    if (difficulty <= 6) return Colors.orangeAccent; // Medio = Naranja
    return Colors.redAccent; // Difícil = Rojo
  }

  // HELPERS REUTILIZABLES

  Widget _buildAttributeBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white10,
            color: const Color(0xFFE040FB),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityDetailPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF610463))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$activeLabel - $activeName", style: const TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(activeDescription!.replaceAll(RegExp(r'<[^>]*>'), ''), style: const TextStyle(color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildStatsTable(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Table(
        children: [
          _buildStatRow("Vida", "${stats['hp']}", "Daño", "${stats['attackdamage']}"),
          _buildStatRow("Maná", "${stats['mp']}", "Rango", "${stats['attackrange']}"),
          _buildStatRow("Armadura", "${stats['armor']}", "Vel. Mov", "${stats['movespeed']}"),
        ],
      ),
    );
  }

  TableRow _buildStatRow(String l1, String v1, String l2, String v2) {
    return TableRow(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text("$l1: $v1", style: const TextStyle(color: Colors.white70))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text("$l2: $v2", style: const TextStyle(color: Colors.white70))),
    ]);
  }

  Widget _buildAbilityIcon(String url, String label, String name, String desc) {
    bool isSelected = activeLabel == label;
    return GestureDetector(
      onTap: () => setState(() { activeLabel = label; activeName = name; activeDescription = desc; }),
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? const Color(0xFFE040FB) : const Color(0xFF610463), width: 2),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFFE040FB) : Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}