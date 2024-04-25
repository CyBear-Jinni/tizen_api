import 'device.dart';

class TV {
  String id;
  String isSupport;
  String name;
  String remote;
  String type;
  String uri;
  String version;
  Device device;

  TV({
    required this.id,
    required this.isSupport,
    required this.name,
    required this.remote,
    required this.type,
    required this.uri,
    required this.version,
    required this.device,
  });

  factory TV.fromJson(Map<String, dynamic> json) {
    return TV(
      id: json['id'],
      isSupport: json['isSupport'],
      name: json['name'],
      remote: json['remote'],
      type: json['type'],
      uri: json['uri'],
      version: json['version'],
      device: Device.fromJson(json['device']),
    );
  }
}
