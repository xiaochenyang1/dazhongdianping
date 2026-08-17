import 'package:geolocator/geolocator.dart';

enum LocationPermissionState {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine;

  bool get isGranted =>
      this == LocationPermissionState.whileInUse ||
      this == LocationPermissionState.always;
}

class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

abstract class LocationService {
  Future<bool> isServiceEnabled();

  Future<LocationPermissionState> checkPermission();

  Future<LocationPermissionState> requestPermission();

  Future<UserLocation> getCurrentLocation();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) => Geolocator.distanceBetween(
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
  );

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionState> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  @override
  Future<LocationPermissionState> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  @override
  Future<UserLocation> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  LocationPermissionState _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.denied => LocationPermissionState.denied,
        LocationPermission.deniedForever =>
          LocationPermissionState.deniedForever,
        LocationPermission.whileInUse => LocationPermissionState.whileInUse,
        LocationPermission.always => LocationPermissionState.always,
        LocationPermission.unableToDetermine =>
          LocationPermissionState.unableToDetermine,
      };
}
