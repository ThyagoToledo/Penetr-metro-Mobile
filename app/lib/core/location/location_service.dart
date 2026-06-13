import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Coordenada geográfica capturada do dispositivo.
typedef GeoPoint = ({double latitude, double longitude});

/// Erro de captura de localização com mensagem amigável.
class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Serviço de GPS (encapsula geolocator + tratamento de permissões).
class LocationService {
  Future<GeoPoint> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'Serviço de localização desativado. Ative o GPS do aparelho.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure('Permissão de localização negada.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Permissão negada permanentemente. Habilite nas configurações do app.',
      );
    }

    final position = await Geolocator.getCurrentPosition();
    return (latitude: position.latitude, longitude: position.longitude);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
