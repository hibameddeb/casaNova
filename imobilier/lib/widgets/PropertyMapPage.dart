import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class PropertyMapPage extends StatefulWidget {
  final String address;

  const PropertyMapPage({super.key, required this.address});

  @override
  State<PropertyMapPage> createState() => _PropertyMapPageState();
}

class _PropertyMapPageState extends State<PropertyMapPage> {
  LatLng? location;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCoordinates(widget.address);
  }

  Future<void> fetchCoordinates(String address) async {
    final url =
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1');

    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        setState(() {
          location = LatLng(lat, lon);
          isLoading = false;
        });
      } else {
        // fallback if address not found
        setState(() {
          location = LatLng(36.8065, 10.1815); // Tunis
          isLoading = false;
        });
      }
    } else {
      setState(() {
        location = LatLng(36.8065, 10.1815); // Tunis
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Location'),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: location,
                zoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.app",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, size: 40, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.address,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
