import "dart:async";
import "dart:io";

import "package:dpip/global.dart";
import "package:dpip/util/log.dart";
import "package:geocoding/geocoding.dart";
import "package:geolocator/geolocator.dart";

StreamSubscription<Position>? positionStreamSubscription;
Timer? restartTimer;

class GetLocationPosition {
  double latitude;
  double longitude;
  String country;

  GetLocationPosition(this.latitude, this.longitude, this.country);

  Map<String, dynamic> toJson() {
    return {
      "latitude": latitude,
      "longitude": longitude,
      "country": country,
    };
  }
}

class GetLocationResult {
  final GetLocationPosition position;
  final bool change;

  GetLocationResult(this.position, this.change);

  Map<String, dynamic> toJson() {
    return {
      "position": position.toJson(),
      "change": change,
    };
  }
}

class LocationResult {
  final String cityTown;
  final bool change;

  LocationResult(this.cityTown, this.change);

  Map<String, dynamic> toJson() {
    return {
      "cityTown": cityTown,
      "change": change,
    };
  }
}

class LocationStatus {
  final String locstatus;
  final bool islocstatus;

  LocationStatus(this.locstatus, this.islocstatus);
}

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

  Future<LocationResult> getLatLngLocation(double latitude, double longitude) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    LocationResult locationGet = LocationResult("", false);
    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first;
      String? city;
      String? town;
      String? code;

      if (Platform.isIOS) {
        city = placemark.subAdministrativeArea;
        town = placemark.locality;
        code = placemark.isoCountryCode == "TW" ? placemark.postalCode?.substring(0, 3) : "";
      } else if (Platform.isAndroid) {
        city = placemark.administrativeArea;
        town = placemark.subAdministrativeArea;
        code = placemark.isoCountryCode == "TW" ? placemark.postalCode?.substring(0, 3) : "";
      }

      String citytown = "$city $town $code";
      String citytowntemp = Global.preference.getString("user-country") ?? "";

      if ((citytowntemp == "" || citytowntemp != citytown) && code != "") {
        await Global.preference.setString("user-country", citytown);
        locationGet = LocationResult(citytown, true);
      } else if (code == "") {
        await Global.preference.setString("user-country", "");
        locationGet = LocationResult("", true);
      } else {
        locationGet = LocationResult(citytowntemp, false);
      }
    }
    return locationGet;
  }

  @pragma("vm:entry-point")
  Future<GetLocationResult> androidGetLocation() async {
    bool positionchange = false;
    final positionlattemp = Global.preference.getDouble("user-lat") ?? 0.0;
    final positionlontemp = Global.preference.getDouble("user-lon") ?? 0.0;

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    LocationResult country = await getLatLngLocation(position.latitude, position.longitude);
    GetLocationPosition positionlast = GetLocationPosition(position.latitude, position.longitude, country.cityTown);
    double distance =
        Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
    if (distance >= 250) {
      Global.preference.setDouble("user-lat", position.latitude);
      Global.preference.setDouble("user-lon", position.longitude);
      positionchange = true;
      TalkerManager.instance.debug("距離: $distance 更新位置");
    } else {
      TalkerManager.instance.debug("距離: $distance 不更新位置");
    }

    return GetLocationResult(positionlast, positionchange);
  }
}
