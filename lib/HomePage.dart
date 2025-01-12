import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'pet_profile_screen.dart';
import 'chat_page.dart';
import 'map_page.dart';
import 'shop_page.dart';
import 'profile_page.dart';
import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';

class Pet {
  String id;
  String name;
  File? image;
  String? imageUrl;
  String status;
  DateTime lastActivity;
  bool isActive;

  Pet({
    required this.id,
    required this.name,
    this.image,
    this.imageUrl,
    this.status = 'Mutlu',
    DateTime? lastActivity,
    this.isActive = true,
  }) : lastActivity = lastActivity ?? DateTime.now();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Pet> _pets = [];

  @override
  void initState() {
    super.initState();
    _loadPetsFromFirestore();
  }

  Future<String?> _fetchUsername() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      return userDoc['username'] as String?;
    }
    return null;
  }

  Future<String?> _fetchProfileImage() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        String? profileImageUrl = userDoc.get('profileImageUrl') as String?;
        return profileImageUrl;
      } catch (e) {
        print('Profil resmi yüklenirken hata: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> _loadPetsFromFirestore() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('pets')
            .get();

        setState(() {
          _pets.clear();
          for (var doc in snapshot.docs) {
            _pets.add(
              Pet(
                id: doc.id,
                name: doc['name'] as String,
                status: doc['status'] as String? ?? 'Mutlu',
                lastActivity: (doc['lastActivity'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                imageUrl: doc['imageUrl'] as String?,
              ),
            );
          }
        });
      } catch (e) {
        print('Pets yüklenirken hata oluştu: $e');
      }
    }
  }

  void _addPet() async {
    if (_pets.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sadece 4 evcil hayvan ekleyebilirsiniz.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resim Kaynağı Seçin"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Kamera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Galeri"),
          ),
        ],
      ),
    );

    if (pickedSource == null) return;

    final pickedFile = await picker.pickImage(source: pickedSource);

    if (pickedFile != null) {
      final newPet = Pet(
        id: DateTime.now().toString(),
        name: 'Pet ${_pets.length + 1}',
        image: File(pickedFile.path),
      );
      setState(() {
        _pets.add(newPet);
      });

      _savePetToFirestore(newPet);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetProfileScreen(
            petId: newPet.id,
            petName: newPet.name,
            petImage: newPet.image,
            imageUrl: newPet.imageUrl,
            isNewPet: true,
            onSave: (String name, File? image) {
              _updatePet(newPet.id, name, image);
            },
            onDelete: () {
              _deletePet(newPet.id);
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  void _savePetToFirestore(Pet pet) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        String? imageUrl;
        if (pet.image != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('pet_images/${currentUser.uid}/${pet.id}.jpg');
          await storageRef.putFile(pet.image!);
          imageUrl = await storageRef.getDownloadURL();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('pets')
            .doc(pet.id)
            .set({
          'name': pet.name,
          'imageUrl': imageUrl,
          'status': pet.status,
          'lastActivity': Timestamp.fromDate(pet.lastActivity),
          'isActive': pet.isActive,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Pet kaydedilirken hata oluştu: $e');
      }
    }
  }

  void _deletePet(String petId) {
    setState(() {
      _pets.removeWhere((pet) => pet.id == petId);
    });
    _deletePetFromFirestore(petId);
  }

  void _deletePetFromFirestore(String petId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Önce Storage'dan fotoğrafı sil
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('pet_images/${currentUser.uid}/$petId.jpg');
          await storageRef.delete();
        } catch (e) {
          print('Fotoğraf silinirken hata oluştu: $e');
        }

        // Firestore'dan pet dokümanını sil
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('pets')
            .doc(petId)
            .delete();
      } catch (e) {
        print('Pet silinirken hata oluştu: $e');
      }
    }
  }

  void _updatePet(String petId, String name, File? image) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        String? imageUrl;
        if (image != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('pet_images/${currentUser.uid}/$petId.jpg');
          await storageRef.putFile(image);
          imageUrl = await storageRef.getDownloadURL();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('pets')
            .doc(petId)
            .update({
          'name': name,
          if (imageUrl != null) 'imageUrl': imageUrl,
        });

        setState(() {
          final petIndex = _pets.indexWhere((pet) => pet.id == petId);
          if (petIndex != -1) {
            _pets[petIndex].name = name;
            _pets[petIndex].image = image;
            if (imageUrl != null) {
              _pets[petIndex].imageUrl = imageUrl;
            }
          }
        });
      } catch (e) {
        print('Pet güncellenirken hata oluştu: $e');
      }
    }
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShopPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.green, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showVeterinarianInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Veteriner Bilgileri"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Veteriner Adı: Dr. Mehmet Öz"),
            SizedBox(height: 8),
            Text("Telefon Numarası: +90 555 123 4567"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _showCareList() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Bakım Listesi"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("1. Tüy Bakımı"),
            Text("2. Düzenli Egzersiz"),
            Text("3. Aşı Takibi"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _showNutritionSuggestions() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Beslenme Önerileri"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("1. Yüksek proteinli mama."),
            Text("2. Taze sebze ve meyveler."),
            Text("3. Bol su tüketimi."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _showEventCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("Etkinlikler"),
            backgroundColor: Colors.green,
          ),
          body: Center(
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (date) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Seçilen Tarih: ${date.toString().split(' ')[0]}'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: FutureBuilder<String?>(
          future: _fetchUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('yükleniyor...');
            } else if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Hoşgeldin!');
            } else {
              return Text('Hoşgeldin ${snapshot.data ?? 'User'}');
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: FutureBuilder<String?>(
                future: _fetchProfileImage(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return CircleAvatar(
                      backgroundImage: NetworkImage(snapshot.data!),
                      backgroundColor: Colors.white.withOpacity(0.9),
                    );
                  }
                  return CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: const Icon(Icons.person, color: Colors.black54),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _showVeterinarianInfo,
                    child: _buildMenuButton(
                        'Veteriner', Icons.medical_services, Colors.green),
                  ),
                  GestureDetector(
                    onTap: _showCareList,
                    child: _buildMenuButton('Bakım', Icons.pets, Colors.green),
                  ),
                  GestureDetector(
                    onTap: _showNutritionSuggestions,
                    child: _buildMenuButton(
                        'Beslenme', Icons.restaurant, Colors.green),
                  ),
                  GestureDetector(
                    onTap: _showEventCalendar,
                    child: _buildMenuButton(
                        'Etkinlikler', Icons.calendar_today, Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: Icons.pets,
                      value: _pets.length.toString(),
                      label: 'Toplam Pet',
                    ),
                    _buildStatItem(
                      icon: Icons.sentiment_satisfied,
                      value:
                          _pets.where((pet) => pet.isActive).length.toString(),
                      label: 'Aktif Pet',
                    ),
                    _buildStatItem(
                      icon: Icons.assignment,
                      value: _pets.length.toString(),
                      label: 'Görevler',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Evcil Hayvanlarım',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: _addPet,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets[index];
                    return _buildPetCard(pet);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: BottomNavigationBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.home),
                    ),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.chat),
                    ),
                    label: "Chat",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.map),
                    ),
                    label: "Harita",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.shopping_cart),
                    ),
                    label: "Mağaza",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.person),
                    ),
                    label: "Profil",
                  ),
                ],
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.grey,
                onTap: (index) {
                  _navigateToPage(context, index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetProfileScreen(
              petId: pet.id,
              petName: pet.name,
              petImage: pet.image,
              imageUrl: pet.imageUrl,
              isNewPet: false,
              onDelete: () {
                _deletePet(pet.id);
                Navigator.pop(context);
              },
              onSave: (String name, File? image) {
                _updatePet(pet.id, name, image);
              },
            ),
          ),
        );
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Pet'),
              content: const Text('Are you sure you want to delete this pet?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _deletePet(pet.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: pet.imageUrl != null
                  ? NetworkImage(pet.imageUrl!)
                  : (pet.image != null
                          ? FileImage(pet.image!)
                          : const AssetImage('assets/default_pet.png'))
                      as ImageProvider,
            ),
            const SizedBox(height: 6),
            Text(
              pet.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Son aktivite: şimdi',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
