import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  final dio = Dio();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _getCurrentLocation();
      if (_currentPosition != null) {
        await _fetchNearbyVets();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Harita yüklenirken bir hata oluştu. Lütfen tekrar deneyin.'),
          duration: Duration(seconds: 3),
        ),
      );
      debugPrint('Harita başlatma hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen konum servisini etkinleştirin'),
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return false;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni reddedildi'),
              duration: Duration(seconds: 3),
            ),
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Konum izinleri kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.'),
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('İzin kontrolü hatası: $e');
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: 'Mevcut Konumunuz'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      rethrow;
    }
  }

  Future<void> _fetchNearbyVets() async {
    if (_currentPosition == null) return;

    try {
      final response = await dio.get(
        'https://overpass-api.de/api/interpreter',
        queryParameters: {
          'data': '''
            [out:json][timeout:25];
            (
              node["amenity"="veterinary"](around:5000,${_currentPosition!.latitude},${_currentPosition!.longitude});
              way["amenity"="veterinary"](around:5000,${_currentPosition!.latitude},${_currentPosition!.longitude});
              relation["amenity"="veterinary"](around:5000,${_currentPosition!.latitude},${_currentPosition!.longitude});
            );
            out body;
            >;
            out skel qt;
          '''
        },
      ).timeout(const Duration(seconds: 30));

      if (response.data['elements'] != null) {
        for (var element in response.data['elements']) {
          if (element['lat'] != null && element['lon'] != null) {
            setState(() {
              _markers.add(
                Marker(
                  markerId: MarkerId('vet_${element['id']}'),
                  position: LatLng(element['lat'], element['lon']),
                  infoWindow: InfoWindow(
                    title: element['tags']?['name'] ?? 'Veteriner',
                    snippet: element['tags']?['addr:street'] ?? '',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Veteriner bilgileri yüklenirken hata oluştu. Lütfen tekrar deneyin.')),
      );
      debugPrint('Veterinerler yüklenirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Veterinerler"),
        backgroundColor: Colors.blue,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Harita yükleniyor...'),
          ],
        ),
      );
    }

    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Konum alınamadı'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeMap,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition ?? const LatLng(41.0082, 28.9784),
        zoom: 14,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_currentPosition != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 14),
          );
        }
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      markers: _markers,
    );
  }
}
