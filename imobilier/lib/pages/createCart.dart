import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddPropertyPage extends StatefulWidget {
  final Map<String, dynamic>? user; // Add user parameter
  
  const AddPropertyPage({super.key, this.user});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final Color primaryColor = Colors.orange;
  int currentStep = 1;
  final int totalSteps = 5;

  static const String baseUrl = "http://192.168.185.146:5000";
  static const String propertiesApi = "$baseUrl/properties";
  static const String uploadApi = "$baseUrl/upload";

  // Controllers
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  // Counters
  int bedrooms = 1;
  int bathrooms = 1;

  // Category
  String selectedCategory = 'Autre';
  final List<String> categories = ['Appartement', 'Maison', 'Villa', 'Autre'];

  // Amenities
  final List<Amenity> amenities = [
    Amenity(icon: Icons.wifi, label: 'Wi-Fi', isSelected: false),
    Amenity(icon: Icons.pool, label: 'Pool', isSelected: false),
    Amenity(icon: Icons.kitchen, label: 'Kitchen', isSelected: false),
    Amenity(icon: Icons.local_parking, label: 'Free Parking', isSelected: false),
    Amenity(icon: Icons.ac_unit, label: 'Air Conditioning', isSelected: false),
  ];

  // Photos
  List<File> selectedPhotos = [];
  bool _isLoading = false;

  // Pick images
  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        selectedPhotos.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedPhotos.removeAt(index);
    });
  }

  Future<List<String>> uploadImages() async {
    List<String> uploadedUrls = [];

    for (var img in selectedPhotos) {
      try {
        var req = http.MultipartRequest(
          "POST",
          Uri.parse(uploadApi),
        );

        req.files.add(await http.MultipartFile.fromPath("image", img.path));

        var res = await req.send();
        var body = await res.stream.bytesToString();
        final decoded = jsonDecode(body);

        if (decoded["url"] != null) {
          uploadedUrls.add(decoded["url"]);
        } else {
          print("Upload response missing URL: $decoded");
        }
      } catch (e) {
        print("Error uploading image: $e");
      }
    }

    return uploadedUrls;
  }

  Future<void> submitListing() async {
    // Validation
    if (titleCtrl.text.isEmpty ||
        descriptionCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty ||
        priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is logged in
    final userId = widget.user?['id']?.toString() ?? widget.user?['_id']?.toString();
    
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour ajouter une propriété'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload photos
      List<String> photoUrls = await uploadImages();

      // Build property data with owner
      final Map<String, dynamic> data = {
        "title": titleCtrl.text.trim(),
        "description": descriptionCtrl.text.trim(),
        "address": addressCtrl.text.trim(),
        "pricePerNight": int.parse(priceCtrl.text),
        "bedrooms": bedrooms,
        "bathrooms": bathrooms,
        "amenities": amenities
            .where((a) => a.isSelected)
            .map((a) => a.label)
            .toList(),
        "photos": photoUrls,
        "category": selectedCategory,
        "userId": userId, // Add the owner/user ID
      };

      print("Sending data to: $propertiesApi");
      print("Data: $data");

      final response = await http.post(
        Uri.parse(propertiesApi),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      setState(() => _isLoading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Propriété ajoutée avec succès!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Wait a bit to show the success message
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Erreur inconnue';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $errorMessage"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Submit error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur réseau: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ================= UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajouter une propriété',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step Indicator
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape $currentStep sur $totalSteps',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: currentStep / totalSteps,
                  valueColor: AlwaysStoppedAnimation(primaryColor),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Details
                  _buildSectionTitle('Détails de la propriété'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: titleCtrl,
                    label: 'Titre de l\'annonce',
                    hint: 'ex: Magnifique villa avec vue mer',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: descriptionCtrl,
                    label: 'Description',
                    hint: 'Décrivez votre propriété...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),

                  // Location
                  _buildSectionTitle('Localisation'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: addressCtrl,
                    label: 'Adresse',
                    hint: 'Entrez l\'adresse de la propriété',
                  ),
                  const SizedBox(height: 32),

                  // Pricing
                  _buildSectionTitle('Prix et caractéristiques'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: priceCtrl,
                    label: 'Prix par nuit',
                    hint: '150',
                    keyboardType: TextInputType.number,
                    prefixText: "\$ ",
                  ),
                  const SizedBox(height: 20),

                  // Bedrooms / Bathrooms
                  Row(
                    children: [
                      Expanded(
                        child: _buildCounter(
                          label: 'Chambres',
                          value: bedrooms,
                          onIncrement: () => setState(() => bedrooms++),
                          onDecrement: () =>
                              setState(() => bedrooms > 1 ? bedrooms-- : 1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCounter(
                          label: 'Salles de bain',
                          value: bathrooms,
                          onIncrement: () => setState(() => bathrooms++),
                          onDecrement: () =>
                              setState(() => bathrooms > 1 ? bathrooms-- : 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Category
                  _buildSectionTitle('Catégorie'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Amenities
                  _buildSectionTitle('Équipements'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        amenities.map((a) => _buildAmenityChip(a)).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Photos
                  _buildSectionTitle('Photos'),
                  const SizedBox(height: 16),
                  _buildPhotosSection(),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : submitListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: primaryColor.withOpacity(0.6),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Publier l'annonce",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets ---------------------
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixText: prefixText,
            filled: true,
            fillColor: Colors.grey.shade50,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300)),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: primaryColor),
                onPressed: onDecrement,
              ),
              Expanded(
                child: Center(
                  child: Text("$value",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: primaryColor),
                onPressed: onIncrement,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityChip(Amenity a) {
    return GestureDetector(
      onTap: () => setState(() => a.isSelected = !a.isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: a.isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: a.isSelected ? primaryColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(a.icon,
                size: 18,
                color: a.isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(a.label,
                style: TextStyle(
                    color: a.isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      children: [
        if (selectedPhotos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: selectedPhotos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      selectedPhotos[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: pickImages,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text("Ajouter des photos",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                Text("(${selectedPhotos.length} sélectionnée${selectedPhotos.length > 1 ? 's' : ''})",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    addressCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }
}

class Amenity {
  final IconData icon;
  final String label;
  bool isSelected;

  Amenity({
    required this.icon,
    required this.label,
    required this.isSelected,
  });
}