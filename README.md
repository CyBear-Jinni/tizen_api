# tizen

TV Remote for all mobile devices


## How to use

1. First call initialize in your main function

'''dart
TizenHelperMethods.initialize();
'''

2. You can search devices like this

'''dart
Future<void> scanNetwork() async {
    await (NetworkInfo().getWifiIP()).then(
      (ip) async {
        final String subnet = ip!.substring(0, ip.lastIndexOf('.'));
        const port = 8002;
        for (var i = 0; i < 256; i++) {
          String ip = '$subnet.$i';
          await Socket.connect(ip, port,
                  timeout: const Duration(milliseconds: 50))
              .then((socket) async {
            await InternetAddress(socket.address.address)
                .reverse()
                .then((value) {
              addDeviceToList(socket.address.address);
            }).catchError((error) {
              addDeviceToList(socket.address.address);
            });
            socket.destroy();
          }).catchError((error) => null);
        }
      },
    );
    print('Done');
}

void addDeviceToList(String ip) async {
    final response = await Dio().get("http://$ip:8001/api/v2/");
    print("Found $ip");
    TV tv = TV.fromJson(response.data as Map<String, dynamic>);
    setState(() {
        tvs.add(tv);
    });
}
'''

3. Before calling tv methods please set it like so

'''dart
TizenHelperMethods.selectedTv = tvVar;
'''