class Device {
  String frameTVSupport;
  String gamePadSupport;
  String imeSyncedSupport;
  String os;
  String tokenAuthSupport;
  String voiceSupport;
  String countryCode;
  String description;
  String developerIP;
  String developerMode;
  String duid;
  String firmwareVersion;
  String id;
  String ip;
  String model;
  String modelName;
  String name;
  String networkType;
  String resolution;
  String smartHubAgreement;
  String ssid;
  String type;
  String udn;
  String wifiMac;

  Device({
    required this.frameTVSupport,
    required this.gamePadSupport,
    required this.imeSyncedSupport,
    required this.os,
    required this.tokenAuthSupport,
    required this.voiceSupport,
    required this.countryCode,
    required this.description,
    required this.developerIP,
    required this.developerMode,
    required this.duid,
    required this.firmwareVersion,
    required this.id,
    required this.ip,
    required this.model,
    required this.modelName,
    required this.name,
    required this.networkType,
    required this.resolution,
    required this.smartHubAgreement,
    required this.ssid,
    required this.type,
    required this.udn,
    required this.wifiMac,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      frameTVSupport: json['FrameTVSupport'],
      gamePadSupport: json['GamePadSupport'],
      imeSyncedSupport: json['ImeSyncedSupport'],
      os: json['OS'],
      tokenAuthSupport: json['TokenAuthSupport'],
      voiceSupport: json['VoiceSupport'],
      countryCode: json['countryCode'],
      description: json['description'],
      developerIP: json['developerIP'],
      developerMode: json['developerMode'],
      duid: json['duid'],
      firmwareVersion: json['firmwareVersion'],
      id: json['id'],
      ip: json['ip'],
      model: json['model'],
      modelName: json['modelName'],
      name: json['name'],
      networkType: json['networkType'],
      resolution: json['resolution'],
      smartHubAgreement: json['smartHubAgreement'],
      ssid: json['ssid'],
      type: json['type'],
      udn: json['udn'],
      wifiMac: json['wifiMac'],
    );
  }
}
