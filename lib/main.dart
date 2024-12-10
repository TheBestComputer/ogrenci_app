import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiUrl = 'http://10.0.2.2:3000/ogrenciler';
  List<dynamic> ogrenciler = [];

  @override
  void initState() {
    super.initState();
    fetchOgrenciler();
  }

  // **READ**: Tüm öğrencileri getir
  Future<void> fetchOgrenciler() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      setState(() {
        ogrenciler = json.decode(response.body);
      });
    } else {
      throw Exception('Öğrenciler alınamadı.');
    }
  }

  // **CREATE**: Yeni öğrenci ekle
  Future<void> addOgrenci(String ad, String soyad, int bolumId) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"ad": ad, "soyad": soyad, "BolumId": bolumId}),
    );
    if (response.statusCode == 200) {
      fetchOgrenciler();
    } else {
      throw Exception('Öğrenci eklenemedi.');
    }
  }

  // **DELETE**: Öğrenciyi sil
  Future<void> deleteOgrenci(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 200) {
      fetchOgrenciler();
    } else {
      throw Exception('Öğrenci silinemedi.');
    }
  }

  // Öğrenci düzenleme dialogu
  void showEditDialog(Map<String, dynamic> ogrenci) {
    String ad = ogrenci['ad'];
    String soyad = ogrenci['soyad'];
    String bolumId = ogrenci['BolumId'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenciyi Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Ad'),
              controller: TextEditingController(text: ad),
              onChanged: (value) => ad = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Soyad'),
              controller: TextEditingController(text: soyad),
              onChanged: (value) => soyad = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Bölüm ID'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: bolumId),
              onChanged: (value) => bolumId = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Kaydet'),
            onPressed: () {
              if (ad.isNotEmpty && soyad.isNotEmpty && bolumId.isNotEmpty) {
                // Veritabanında güncelleme
                updateOgrenci(
                  ogrenci['ogrenciID'],
                  ad,
                  soyad,
                  int.parse(bolumId),
                ).then((_) {
                  Navigator.pop(context); // Dialogu kapat
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> updateOgrenci(int id, String ad, String soyad, int bolumId) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"ad": ad, "soyad": soyad, "BolumId": bolumId}),
    );
    if (response.statusCode == 200) {
      fetchOgrenciler(); // Listeyi yenile
    } else {
      throw Exception('Öğrenci güncellenemedi.');
    }
  }


  // Yeni öğrenci ekleme dialogu
  void showAddDialog() {
    String ad = '';
    String soyad = '';
    String bolumId = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Öğrenci Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Ad'),
              onChanged: (value) => ad = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Soyad'),
              onChanged: (value) => soyad = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Bölüm ID'),
              keyboardType: TextInputType.number,
              onChanged: (value) => bolumId = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Ekle'),
            onPressed: () {
              if (ad.isNotEmpty && soyad.isNotEmpty && bolumId.isNotEmpty) {
                addOgrenci(ad, soyad, int.parse(bolumId));
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: ogrenciler.length,
        itemBuilder: (context, index) {
          final ogrenci = ogrenciler[index];
          return ListTile(
            title: Text('${ogrenci['ad']} ${ogrenci['soyad']}'),
            subtitle: Text('Bölüm ID: ${ogrenci['BolumId']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => showEditDialog(ogrenci),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteOgrenci(ogrenci['ogrenciID']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
