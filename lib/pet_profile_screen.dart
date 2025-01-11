import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'vaccine_calendar_table.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shop_page.dart';

class PetProfileScreen extends StatefulWidget {
  final String petName;
  final String petId;
  final File? petImage;
  final bool isNewPet;
  final void Function(String petName, File? image) onSave;
  final void Function() onDelete;

  const PetProfileScreen({
    super.key,
    required this.petName,
    required this.petId,
    required this.petImage,
    required this.isNewPet,
    required this.onSave,
    required this.onDelete,
  });

  @override
  _PetProfileScreenState createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);
    await prefs.setString('breed', _breedController.text);
    await prefs.setString('age', _ageController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('height', _heightController.text);
    await prefs.setString('color', _colorController.text);
    if (_image != null) {
      await prefs.setString('${widget.petId}_imagePath',
          _image!.path); // Pet'e özel ID ile kaydediyoruz
    }
  }

  // Veriyi yükleyen fonksiyon
  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = widget.petName;
      _breedController.text = prefs.getString('breed') ?? 'Border Collie';
      _ageController.text = prefs.getString('age') ?? '1y 4m 11d';
      _weightController.text = prefs.getString('weight') ?? '7.5 kg';
      _heightController.text = prefs.getString('height') ?? '54 cm';
      _colorController.text = prefs.getString('color') ?? 'Black';
      String? imagePath = prefs.getString(
          '${widget.petId}_imagePath'); // Pet'e özel ID ile fotoğraf yolu alınıyor
      if (imagePath != null && File(imagePath).existsSync()) {
        _image = File(imagePath);
      } else {
        _image = widget.petImage; // Load the image passed from the HomePage
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadProfileData(); // Uygulama başlatıldığında veriyi yükle
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

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'sender': 'user', 'text': message});
    });

    var url = Uri.parse('https://api.openai.com/v1/chat/completions');

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_API_KEY',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': message},
        ],
      }),
    );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': responseBody['choices'][0]['message']['content']
        });
      });
    } else {
      setState(() {
        _messages
            .add({'sender': 'bot', 'text': 'Sorry, something went wrong.'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildChatBox(),
              );
            },
          ),
        ],
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
                          ? FileImage(_image!) as ImageProvider
                          : const AssetImage('Assets/köpke.jpg'),
                      child: _image == null
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
                      'Add Vaccine',
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
          'About Bella',
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
              _infoBox('Age', _ageController.text),
              _infoBox('Weight', _weightController.text),
              _infoBox('Height', _heightController.text),
              _infoBox('Color', _colorController.text),
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
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _breedController,
          decoration: const InputDecoration(labelText: 'Breed'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ageController,
          decoration: const InputDecoration(labelText: 'Age'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _weightController,
          decoration: const InputDecoration(labelText: 'Weight'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _heightController,
          decoration: const InputDecoration(labelText: 'Height'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _colorController,
          decoration: const InputDecoration(labelText: 'Color'),
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
          child: const Text('Save'),
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
          'Bella\'s Status',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _statusBox(
          'Health',
          'Abnormal',
          Icons.favorite,
          Colors.red,
          actionLabel: 'Contact Vet',
        ),
        const SizedBox(height: 8),
        _statusBox(
          'Food',
          'Hungry',
          Icons.fastfood,
          Colors.orange,
          actionLabel: 'Check Food',
        ),
        const SizedBox(height: 8),
        _statusBox(
          'Mood',
          'Abnormal',
          Icons.sentiment_dissatisfied,
          Colors.blue,
          actionLabel: 'Whistle',
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
            case 'Health':
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
            case 'Food':
              // Shop sayfasına yönlendirme
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShopPage()),
              );
              break;
            case 'Mood':
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

  Widget _buildChatBox() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              var message = _messages[index];
              return Align(
                alignment: message['sender'] == 'user'
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: message['sender'] == 'user'
                        ? Colors.blue[100]
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(message['text']!),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    _sendMessage(_messageController.text);
                    _messageController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
