class Champion {
  final String id;
  final String name;
  final String title;
  final String imgUrl;

  Champion({
    required this.id, 
    required this.name, 
    required this.title, 
    required this.imgUrl
  });

  factory Champion.fromJson(String id, Map<String, dynamic> json) {
    return Champion(
      id: id,
      name: json['name'],
      title: json['title'],
      imgUrl: "https://ddragon.leagueoflegends.com/cdn/img/champion/loading/${id}_0.jpg",
    );
  }
}