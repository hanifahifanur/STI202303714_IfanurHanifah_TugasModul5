# Event Kampus Locator
Aplikasi Flutter untuk Praktikum Layanan Lokasi, Tracking, Google Maps, dan OpenStreetMap.

Aplikasi ini digunakan untuk menampilkan posisi pengguna, melakukan tracking lokasi (real-time), menampilkan alamat dengan reverse geocoding, menampilkan jarak ke event kampus terdekat, dan melihat peta menggunakan Google Maps serta OpenStreetMap.

---

## Fitur Aplikasi

### 1. Get Current Location
- Mengambil lokasi pengguna sekali (one-time).
- Menampilkan:
  - Latitude
  - Longitude
  - Accuracy
  - Speed (km/h)
  - Heading
  - Timestamp

### 2. Start / Stop Tracking
- Mengambil lokasi secara terus menerus menggunakan Position Stream.
- Menggunakan `distanceFilter = 10 meter`.
- Akurasi dapat diubah (Low, Medium, High).

### 3. Reverse Geocoding
- Mengubah koordinat menjadi alamat.
- Menampilkan nama jalan, kecamatan, kota, dll.

### 4. Event Kampus
- Menampilkan 3 event kampus:
  - Seminar AI
  - Job Fair
  - Expo UKM
- Menghitung jarak dari posisi pengguna.

### 5. Google Maps
- Menampilkan peta Google Maps.
- Menampilkan marker posisi pengguna.
- Menggerakkan kamera ke lokasi pengguna.

### 6. OpenStreetMap (OSM)
- Menampilkan peta OSM (tile server gratis).
- Menampilkan marker posisi pengguna.

