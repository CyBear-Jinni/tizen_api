class Device {
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
      frameTVSupport: json['FrameTVSupport'] as String,
      gamePadSupport: json['GamePadSupport'] as String,
      imeSyncedSupport: json['ImeSyncedSupport'] as String,
      os: json['OS'] as String,
      tokenAuthSupport: json['TokenAuthSupport'] as String,
      voiceSupport: json['VoiceSupport'] as String,
      countryCode: json['countryCode'] as String,
      description: json['description'] as String,
      developerIP: json['developerIP'] as String,
      developerMode: json['developerMode'] as String,
      duid: json['duid'] as String,
      firmwareVersion: json['firmwareVersion'] as String,
      id: json['id'] as String,
      ip: json['ip'] as String,
      model: json['model'] as String,
      modelName: json['modelName'] as String,
      name: json['name'] as String,
      networkType: json['networkType'] as String,
      resolution: json['resolution'] as String,
      smartHubAgreement: json['smartHubAgreement'] as String,
      ssid: json['ssid'] as String,
      type: json['type'] as String,
      udn: json['udn'] as String,
      wifiMac: json['wifiMac'] as String,
    );
  }

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
}
