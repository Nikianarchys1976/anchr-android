import 'package:anchr_android/objects/link.dart';

class LinkCollection {
  final String id;
  final String name;
  final String ownerId;
  final bool shared;
  final List<Link> links;

  const LinkCollection({this.id, this.name, this.ownerId, this.shared, this.links});

  factory LinkCollection.fromJson(Map<String, dynamic> json) {
    return LinkCollection(
        id: json['_id'],
        name: json['name'],
        ownerId: json['owner'],
        shared: json['shared'],
        links: (json['links'] as List<dynamic>
        )
            .map((l) => Link.fromJson(l))
            .toList()
    );
  }
}