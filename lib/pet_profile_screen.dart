import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'vaccine_calendar_table.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shop_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetProfileScreen extends StatefulWidget {
  final String petName;
  final String petId;
  final File? petImage;
  final String? imageUrl;
  final bool isNewPet;
  final void Function(String petName, File? image) onSave;
  final void Function() onDelete;

  const PetProfileScreen({
    super.key,
    required this.petName,
    required this.petId,
    this.petImage,
    this.imageUrl,
    required this.isNewPet,
    required this.onSave,
    required this.onDelete,
  });

  @override
  _PetProfileScreenState createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  bool _isEditing = false;
  File? _image;

  // Veriyi saklayan fonksiyon
  Future<void> saveProfileData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        String? imageUrl;
        if (_image != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('pet_images/${currentUser.uid}/${widget.petId}.jpg');
          await storageRef.putFile(_image!);
          imageUrl = await storageRef.getDownloadURL();
        }

        final updateData = {
          'isim': _nameController.text,
          'tür': _breedController.text,
          'yaş': _ageController.text,
          'kilo': _weightController.text,
          'boy': _heightController.text,
          'rnk': _colorController.text,
        };

        if (imageUrl != null) {
          updateData['imageUrl'] = imageUrl;
        }

        // Firestore'a kaydet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('pets')
            .doc(widget.petId)
            .update(updateData);

        widget.onSave(_nameController.text, _image);
      } catch (e) {
        print('Profil kaydedilirken hata: $e');
        // Eğer döküman yoksa, set ile oluştur
        if (e is FirebaseException && e.code == 'not-found') {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .collection('pets')
                .doc(widget.petId)
                .set({
              'isim': _nameController.text,
              'tür': _breedController.text,
              'yaş': _ageController.text,
              'kilo': _weightController.text,
              'boy': _heightController.text,
              'renk': _colorController.text,
            });
          } catch (setError) {
            print('Profil oluşturulurken hata: $setError');
          }
        }
      }
    }
  }

  // Veriyi yükleyen fonksiyon
  Future<void> loadProfileData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final petDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('pets')
            .doc(widget.petId)
            .get();

        if (petDoc.exists) {
          setState(() {
            _breedController.text = petDoc.data()?['tür'] ?? 'Border Collie';
            _ageController.text = petDoc.data()?['yaş'] ?? '1y 4m 11d';
            _weightController.text = petDoc.data()?['kilo'] ?? '7.5 kg';
            _heightController.text = petDoc.data()?['boy'] ?? '54 cm';
            _colorController.text = petDoc.data()?['renk'] ?? 'Siyah';
          });
        }
      } catch (e) {
        print('Profil yüklenirken hata: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _image = widget.petImage;
      _nameController.text = widget.petName;
    });
    loadProfileData();
  }

  @override
  void dispose() {
    saveProfileData(); // Uygulama kapatıldığında veriyi kaydet
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
      saveProfileData(); // Fotoğrafı seçtikten sonra kaydediyoruz
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evcil Hayvan Profili',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (widget.imageUrl != null
                                  ? NetworkImage(widget.imageUrl!)
                                  : const AssetImage('assets/default_pet.png'))
                              as ImageProvider,
                      child: (_image == null && widget.imageUrl == null)
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isEditing ? _buildEditForm() : _buildProfileView(),
                  const SizedBox(height: 16),
                  const Divider(),
                  _bellasStatus(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VaccineCalendarScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Aşı Ekle',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        Text(
          _nameController.text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(
          _breedController.text,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Text(
          'Evcil Hayvan Hakkında',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _infoBox('Yaş', _ageController.text),
              _infoBox('Kilo', _weightController.text),
              _infoBox('Boy', _heightController.text),
              _infoBox('Renk', _colorController.text),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Edit'),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'İsim'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _breedController,
          decoration: const InputDecoration(labelText: 'Tür'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ageController,
          decoration: const InputDecoration(labelText: 'Yaş'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _weightController,
          decoration: const InputDecoration(labelText: 'Kilo'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _heightController,
          decoration: const InputDecoration(labelText: 'Boy'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _colorController,
          decoration: const InputDecoration(labelText: 'Renk'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isEditing = false;
            });
            widget.onSave(_nameController.text, _image); // Save the changes
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _infoBox(String title, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _bellasStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evcil Hayvan Durumu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _statusBox(
          'Sağlık',
          'Abnormal',
          Icons.favorite,
          Colors.red,
          actionLabel: 'Veteriner Ara',
        ),
        const SizedBox(height: 8),
        _statusBox(
          'Yemek',
          'Aç',
          Icons.fastfood,
          Colors.orange,
          actionLabel: 'Mama kontrolü',
        ),
        const SizedBox(height: 8),
        _statusBox(
          'Mod',
          'Abnormal',
          Icons.sentiment_dissatisfied,
          Colors.blue,
          actionLabel: 'Islık çal',
        ),
      ],
    );
  }

  Widget _statusBox(String title, String status, IconData icon, Color iconColor,
      {required String actionLabel}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 32),
      title: Text(title),
      subtitle: Text(status),
      trailing: ElevatedButton(
        onPressed: () {
          switch (title) {
            case 'Sağlık':
              // Veteriner numaralarını gösteren dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Yakındaki Veterinerler'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildVetContact(
                              'Dr. Ahmet Yılmaz', '+90 555 123 4567'),
                          _buildVetContact(
                              'Dr. Ayşe Demir', '+90 555 234 5678'),
                          _buildVetContact(
                              'Dr. Mehmet Kaya', '+90 555 345 6789'),
                          _buildVetContact(
                              'Dr. Zeynep Şahin', '+90 555 456 7890'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kapat'),
                      ),
                    ],
                  );
                },
              );
              break;
            case 'Yemek':
              // Shop sayfasına yönlendirme
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShopPage()),
              );
              break;
            case 'Mod':
              // Ses çalma ve animasyon gösterme
              _playWhistleAndShowAnimation();
              break;
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: iconColor,
          foregroundColor: Colors.white,
        ),
        child: Text(actionLabel),
      ),
    );
  }

  // Veteriner iletişim widget'ı
  Widget _buildVetContact(String name, String phone) {
    return ListTile(
      title: Text(name),
      subtitle: Text(phone),
      trailing: IconButton(
        icon: const Icon(Icons.phone),
        onPressed: () async {
          final Uri url = Uri.parse('tel:$phone');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        },
      ),
    );
  }

  // Islık çalma ve animasyon gösterme fonksiyonu
  void _playWhistleAndShowAnimation() {
    // Snackbar göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.music_note, color: Colors.white),
            SizedBox(width: 8),
            Text('Islık çalınıyor...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    // Burada ıslık sesi çalınabilir (audioplayers paketi kullanılarak)
    // Örnek: AudioPlayer().play(AssetSource('whistle.mp3'));
  }
}
