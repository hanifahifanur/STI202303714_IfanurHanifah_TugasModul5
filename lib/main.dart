import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Kampus Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}

// ===================================================================
// HOME PAGE
// ===================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? pos;
  String? address;
  bool tracking = false;
  String status = "Belum mengambil lokasi";

  StreamSubscription<Position>? sub;

  bool highAccuracy = true;
  int distanceFilter = 10;

  final List<Map<String, dynamic>> events = [
    {"title": "Seminar AI", "lat": -7.4246, "lng": 109.2332},
    {"title": "Job Fair", "lat": -7.4261, "lng": 109.2315},
    {"title": "Expo UKM", "lat": -7.4229, "lng": 109.2350},
  ];

  // ============================
  // PERMISSION
  // ============================
  Future<bool> ensurePermission() async {
    final service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      setState(() => status = "GPS mati, nyalakan terlebih dahulu");
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      setState(() => status = "Izin lokasi ditolak");
      return false;
    }

    return true;
  }

  // ============================
  // GET CURRENT
  // ============================
  Future<void> getCurrent() async {
    if (!await ensurePermission()) return;

    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy:
          highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
    );

    setState(() {
      pos = p;
      status = "Lokasi berhasil diambil (one-time)";
    });

    reverseGeocode(p);
  }

  // ============================
  // REVERSE GEOCODE
  // ============================
  Future<void> reverseGeocode(Position p) async {
    try {
      final placemarks =
          await gc.placemarkFromCoordinates(p.latitude, p.longitude);
      final m = placemarks.first;
      setState(() {
        address = "${m.street}, ${m.locality}, ${m.subAdministrativeArea}";
      });
    } catch (_) {}
  }

  // ============================
  // TRACKING
  // ============================
  Future<void> toggleTracking() async {
    if (tracking) {
      await sub?.cancel();
      setState(() {
        tracking = false;
        status = "Tracking dihentikan";
      });
      return;
    }

    if (!await ensurePermission()) return;

    final settings = LocationSettings(
      accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
      distanceFilter: distanceFilter,
    );

    sub = Geolocator.getPositionStream(locationSettings: settings).listen((p) {
      setState(() {
        pos = p;
        tracking = true;
        status = "Tracking berjalan...";
      });

      reverseGeocode(p);
    });
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Kampus Locator")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: $status",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),

                      // ======================
                      // AKURASI
                      // ======================
                      Row(
                        children: [
                          const Text("Akurasi: "),
                          Switch(
                            value: highAccuracy,
                            onChanged: (v) => setState(() => highAccuracy = v),
                          ),
                          Text(highAccuracy ? "High" : "Medium"),
                          const Spacer(),
                          const Text("Filter: "),
                          DropdownButton<int>(
                            value: distanceFilter,
                            items: [0, 5, 10, 20, 50]
                                .map((v) => DropdownMenuItem(
                                    value: v, child: Text("$v m")))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => distanceFilter = v!),
                          )
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ======================
                      // INFO POSISI
                      // ======================
                      if (pos != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Lat: ${pos!.latitude}"),
                              Text("Lng: ${pos!.longitude}"),
                              Text("Accuracy: ${pos!.accuracy} m"),
                              Text(
                                  "Speed: ${(pos!.speed * 3.6).toStringAsFixed(1)} km/h"),
                              Text(
                                  "Heading: ${pos!.heading.toStringAsFixed(0)}°"),
                              Text("Time: ${pos!.timestamp}"),
                              if (address != null) Text("Alamat: $address"),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ======================
                      // EVENT
                      // ======================
                      if (pos != null) ...[
                        const Text(
                          "Event Terdekat",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...events.map((e) {
                          final title = e["title"];
                          final lat = e["lat"];
                          final lng = e["lng"];

                          final jarak = Geolocator.distanceBetween(
                            pos!.latitude,
                            pos!.longitude,
                            lat,
                            lng,
                          );

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.event),
                              title: Text(title),
                              subtitle: Text(
                                  "${jarak.toStringAsFixed(0)} meter dari lokasi anda"),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapPage(
                                      lat: lat,
                                      lng: lng,
                                      label: title,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ]
                    ],
                  ),
                ),
              ),
            ),

            // ======================
            // TOMBOL BAWAH RAPI
            // ======================
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // GET CURRENT
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: getCurrent,
                          child: FittedBox(
                            child: Row(
                              children: const [
                                Icon(Icons.my_location, size: 20),
                                SizedBox(width: 6),
                                Text("Get Current"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // TRACKING
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                tracking ? Colors.redAccent : Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: toggleTracking,
                          child: FittedBox(
                            child: Row(
                              children: [
                                Icon(
                                  tracking ? Icons.stop : Icons.play_arrow,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(tracking
                                    ? "Stop Tracking"
                                    : "Start Tracking"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // MAP
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.blueAccent, width: 2),
                            foregroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: pos == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MapPage(
                                        lat: pos!.latitude,
                                        lng: pos!.longitude,
                                        label: "Posisi Saya",
                                      ),
                                    ),
                                  );
                                },
                          child: FittedBox(
                            child: Row(
                              children: const [
                                Icon(Icons.map, size: 20),
                                SizedBox(width: 6),
                                Text("Buka Map"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// MAP PAGE (tidak error)
// ===================================================================
class MapPage extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;

  const MapPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,   // AMAN untuk semua versi
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.event.kampus.locator",
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_pin,
                  size: 50,
                  color: Colors.red,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
