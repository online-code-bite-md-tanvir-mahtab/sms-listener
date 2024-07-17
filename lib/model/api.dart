class API {
  final int? id;
  final String name;
  final String url;

  API({this.id, required this.name, required this.url});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }

  static API fromMap(Map<String, dynamic> map) {
    return API(
      id: map['id'],
      name: map['name'],
      url: map['url'],
    );
  }
}
