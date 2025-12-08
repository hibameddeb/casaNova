import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'createCart.dart';
import 'listpage.dart';
import 'profile.dart';
import 'favorites.dart'; // Add this import
import 'map_page.dart';
import 'package:imobilier/widgets/PropertyMapPage.dart';

// =================== OWNER MODEL ===================
class Owner {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? photo;

  Owner({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.photo,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      photo: json['photo']?.toString(),
    );
  }

  String get fullName => '$firstName $lastName';
}

// =================== PROPERTY MODEL ===================
class Property {
  final String id;
  final String title;
  final String description;
  final String address;
  final int pricePerNight;
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final List<String> photos;
  final String category;
  final Owner? owner;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.pricePerNight,
    required this.bedrooms,
    required this.bathrooms,
    required this.amenities,
    required this.photos,
    required this.category,
    this.owner,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Ensure photos is always a List<String>
    List<String> photoList = [];
    if (json['photos'] != null) {
      if (json['photos'] is List) {
        photoList = List<String>.from(json['photos'].map((x) => x?.toString() ?? ''));
      }
    }
    
    return Property(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Sans titre',
      description: json['description']?.toString() ?? 'Pas de description',
      address: json['address']?.toString() ?? 'Adresse non disponible',
      pricePerNight: (json['pricePerNight'] as num?)?.toInt() ?? 0,
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
      amenities: List<String>.from(json['amenities'] ?? []),
      photos: photoList,
      category: json['category']?.toString() ?? 'Autre',
      owner: json['owner'] != null ? Owner.fromJson(json['owner']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'address': address,
      'pricePerNight': pricePerNight,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'photos': photos,
      'category': category,
      'owner': owner != null ? {
        '_id': owner!.id,
        'firstName': owner!.firstName,
        'lastName': owner!.lastName,
        'email': owner!.email,
        'phone': owner!.phone,
        'photo': owner!.photo,
      } : null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Property && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const String apiUrl = "http://192.168.185.146:5000/properties";

// Helper function to get image URL
String getImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return "https://via.placeholder.com/400x200.png?text=No+Image";
  }
  
  // If it's already a full URL, return it
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }
  
  // If it starts with uploads/, assume it's already the full path
  if (imagePath.startsWith('uploads/')) {
    return '$apiUrl/$imagePath';
  }
  
  // Otherwise, assume it's just a filename and prepend the uploads path
  return '$apiUrl/uploads/$imagePath';
}

// =================== FAVORITES API ===================
Future<List<Property>> fetchFavorites(String userId) async {
  try {
    if (userId.isEmpty) return [];
    
    final response = await http.get(
      Uri.parse('$apiUrl/favorites/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      print('Failed to fetch favorites: ${response.statusCode}');
      print('Response body: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error fetching favorites: $e');
    return [];
  }
}

Future<bool> addFavorite(String userId, String propertyId) async {
  try {
    if (userId.isEmpty || propertyId.isEmpty) return false;
    
    final response = await http.post(
      Uri.parse('$apiUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'propertyId': propertyId,
      }),
    );
    
    return response.statusCode == 201 || response.statusCode == 200;
  } catch (e) {
    print('Error adding favorite: $e');
    return false;
  }
}

Future<bool> removeFavorite(String userId, String propertyId) async {
  try {
    if (userId.isEmpty || propertyId.isEmpty) return false;
    
    final response = await http.delete(
      Uri.parse('$apiUrl/favorites/$userId/$propertyId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    return response.statusCode == 200;
  } catch (e) {
    print('Error removing favorite: $e');
    return false;
  }
}

// =================== FETCH PROPERTIES ===================
Future<List<Property>> fetchProperties({String? category}) async {
  try {
    final propertiesUrl = "$apiUrl/properties";
    final uri = category != null && category != 'Tous'
        ? Uri.parse("$propertiesUrl/category/$category")
        : Uri.parse(propertiesUrl);

    print('Fetching properties from: $uri');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('Fetched ${data.length} properties');
      
      // Debug: print first property's photos
      if (data.isNotEmpty) {
        print('First property photos: ${data[0]['photos']}');
      }
      
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      print('Failed to fetch properties: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception("Failed to fetch properties: ${response.statusCode}");
    }
  } catch (e) {
    print('Error in fetchProperties: $e');
    return [];
  }
}

// =================== HOME SCREEN ===================
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  int _selectedNavIndex = 0;
  final Color primaryColor = Colors.orange;
  final List<String> categories = ['Tous', 'Appartement', 'Maison', 'Villa'];

  late Future<List<Property>> futureProperties;
  List<Property> favoriteProperties = [];
  bool _isLoadingFavorites = false;

  @override
  void initState() {
    super.initState();
    futureProperties = fetchProperties();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final userId = widget.user['id']?.toString() ?? widget.user['_id']?.toString() ?? '';
    if (userId.isEmpty) return;
    
    setState(() {
      _isLoadingFavorites = true;
    });
    
    try {
      final favorites = await fetchFavorites(userId);
      setState(() {
        favoriteProperties = favorites;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      setState(() {
        _isLoadingFavorites = false;
      });
    }
  }

  void selectCategory(int index) {
    setState(() {
      _selectedCategory = index;
      futureProperties = fetchProperties(
        category: categories[index],
      );
    });
  }

  Future<void> toggleFavorite(Property property) async {
    final userId = widget.user['id']?.toString() ?? widget.user['_id']?.toString() ?? '';
    if (userId.isEmpty || property.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ajouter aux favoris'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    try {
      if (isFavorite(property)) {
        // Supprimer des favoris
        final success = await removeFavorite(userId, property.id);
        if (success) {
          setState(() {
            favoriteProperties.removeWhere((p) => p.id == property.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retiré des favoris'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Ajouter aux favoris
        final success = await addFavorite(userId, property.id);
        if (success) {
          setState(() {
            favoriteProperties.add(property);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajouté aux favoris !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> removeFavoriteFromDatabase(Property property) async {
    final userId = widget.user['id']?.toString() ?? widget.user['_id']?.toString() ?? '';
    if (userId.isEmpty || property.id.isEmpty) return;
    
    try {
      final success = await removeFavorite(userId, property.id);
      if (success) {
        setState(() {
          favoriteProperties.removeWhere((p) => p.id == property.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiré des favoris'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error removing favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool isFavorite(Property property) {
    return favoriteProperties.any((p) => p.id == property.id);
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedNavIndex = index);
          
          if (label == 'Profil') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(user: widget.user),
              ),
            );
          } else if (label == 'Favoris') {
            final userId = widget.user['id']?.toString() ?? widget.user['_id']?.toString() ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritesPage(
                  favoriteProperties: favoriteProperties,
                  primaryColor: primaryColor,
                  onRemoveFavorite: removeFavoriteFromDatabase,
                  userId: userId,
                ),
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon,
                color: isSelected ? primaryColor : Colors.grey.shade600, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get user photo URL
    final userPhoto = widget.user['photo'];
    final userPhotoUrl = userPhoto != null ? getImageUrl(userPhoto.toString()) : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Trouvez votre prochain séjour',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(user: widget.user),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.orange.shade200,
                radius: 20,
                backgroundImage: userPhotoUrl != null
                    ? NetworkImage(userPhotoUrl) as ImageProvider
                    : null,
                child: userPhotoUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
              child: TextField(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Rechercher une destination, ville...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => selectCategory(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300)),
                      child: Center(
                        child: Text(
                          categories[index],
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Propriétés en vedette',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPropertiesPage()));
                  },
                  child: Text('Voir tout',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<Property>>(
              future: futureProperties,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucune propriété trouvée'));
                } else {
                  final properties = snapshot.data!;
                  print('Displaying ${properties.length} properties');
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return PropertyCard(
                        property: property,
                        primaryColor: primaryColor,
                        isFavorite: isFavorite(property),
                        onFavoriteToggle: () => toggleFavorite(property),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPropertyPage(user: widget.user),
            ),
          );
          
          // Refresh properties if a new property was added
          if (result == true) {
            setState(() {
              futureProperties = fetchProperties(
                category: categories[_selectedCategory],
              );
            });
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Accueil', 0),
              Stack(
                children: [
                  _buildNavItem(Icons.favorite_border, Icons.favorite, 'Favoris', 1),
                  if (_isLoadingFavorites)
                    Positioned(
                      top: 2,
                      right: 20,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 48),
              _buildNavItem(Icons.message_outlined, Icons.message, 'Messages', 2),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== PROPERTY CARD ===================
class PropertyCard extends StatelessWidget {
  final Property property;
  final Color primaryColor;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const PropertyCard({
    super.key,
    required this.property,
    required this.primaryColor,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Get the first photo or use placeholder
    final imageUrl = property.photos.isNotEmpty 
        ? getImageUrl(property.photos[0])
        : "https://via.placeholder.com/400x200.png?text=No+Image";

    print('PropertyCard - Image URL: $imageUrl');
    print('PropertyCard - Photos array: ${property.photos}');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $imageUrl, Error: $error');
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Image non disponible',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? primaryColor : Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${property.pricePerNight} / nuit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservationPage(
                              property: property,
                              primaryColor: primaryColor,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Réserver',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // --- MAP BUTTON ---
 ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyMapPage(
          address: property.address, // Pass only the address
        ),
      ),
    );
  },
  icon: const Icon(Icons.map_outlined, size: 20),
  label: const Text("Map"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueGrey.shade800,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
),





                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}