# tizen

TV Remote for all mobile devices


## How to use

1. You can search devices like this

```dart

Future<void> searchDevices() async {
  final String? ip = await NetworkInfo().getWifiIP();
  if (ip == null) {
    return;
  }

  TizenHelperMethods.scanNetwork(ip).listen((tv) {
    print('Found TV $tv');
  });
}
```

3. Set the selected TV

```dart
TizenHelperMethods.selectedTv = tvVar;
```


4. Control the TV using 

```dart
TizenHelperMethods.selectedTv!.addToSocket(KeyCodes.KEY_VOLDOWN);
TizenHelperMethods.selectedTv!.addToSocket(KeyCodes.KEY_VOLUP);
TizenHelperMethods.selectedTv!.addToSocket(KeyCodes.KEY_POWER);
```


## Test the example app
The example is TV remote app and is very fun to test.

You should to try it up with your TV.



# Thanks
Thanks [@shaharhn](https://github.com/shaharhn) for developing the base of this package