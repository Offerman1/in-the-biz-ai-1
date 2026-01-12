import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_contact.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Screen for adding or editing an event contact
class AddEditContactScreen extends StatefulWidget {
  /// Existing contact to edit (null for new contact)
  final EventContact? contact;

  /// Optional: pre-link to a specific shift
  final String? shiftId;

  /// Optional: pre-fill data for new contact (from BEO vendor, etc.)
  final Map<String, dynamic>? preFillData;

  const AddEditContactScreen({
    super.key,
    this.contact,
    this.shiftId,
    this.preFillData,
  });

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _picker = ImagePicker();

  // Form controllers
  final _nameController = TextEditingController();
  final _customRoleController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  // Social media controllers
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _snapchatController = TextEditingController();
  final _pinterestController = TextEditingController();

  ContactRole _selectedRole = ContactRole.custom;
  bool _isFavorite = false;
  bool _isSaving = false;
  bool _isScanning = false;
  String? _imageUrl; // Business card image
  String? _profilePhotoUrl; // Contact profile photo
  bool _showSocialMedia = false; // Toggle for social media section

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _loadExistingContact();
    } else if (widget.preFillData != null) {
      _loadPreFillData();
    }
  }

  /// Load pre-fill data (from BEO vendor, etc.)
  void _loadPreFillData() {
    final data = widget.preFillData!;
    _nameController.text = data['name'] ?? '';
    _companyController.text = data['company'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _emailController.text = data['email'] ?? '';
    _websiteController.text = data['website'] ?? '';
    _notesController.text = data['notes'] ?? '';

    // Try to match vendor type to contact role
    final type = (data['type'] ?? '').toString().toLowerCase();
    _selectedRole = _matchVendorTypeToRole(type);
    if (_selectedRole == ContactRole.custom && type.isNotEmpty) {
      _customRoleController.text = data['type'] ?? '';
    }
  }

  /// Match vendor type string to ContactRole
  ContactRole _matchVendorTypeToRole(String type) {
    final typeMap = {
      'dj': ContactRole.dj,
      'entertainment': ContactRole.dj,
      'band': ContactRole.bandMusician,
      'musician': ContactRole.bandMusician,
      'photo booth': ContactRole.photoBooth,
      'photobooth': ContactRole.photoBooth,
      'photographer': ContactRole.photographer,
      'photography': ContactRole.photographer,
      'videographer': ContactRole.videographer,
      'video': ContactRole.videographer,
      'wedding planner': ContactRole.weddingPlanner,
      'planner': ContactRole.weddingPlanner,
      'coordinator': ContactRole.eventCoordinator,
      'event coordinator': ContactRole.eventCoordinator,
      'florist': ContactRole.florist,
      'flowers': ContactRole.florist,
      'linens': ContactRole.linenRental,
      'linen rental': ContactRole.linenRental,
      'cake': ContactRole.cakeBakery,
      'bakery': ContactRole.cakeBakery,
      'catering': ContactRole.catering,
      'caterer': ContactRole.catering,
      'rentals': ContactRole.rentals,
      'lighting': ContactRole.lightingAv,
      'av': ContactRole.lightingAv,
      'audio visual': ContactRole.lightingAv,
      'rabbi': ContactRole.rabbi,
      'priest': ContactRole.priest,
      'pastor': ContactRole.pastor,
      'officiant': ContactRole.officiant,
      'venue manager': ContactRole.venueManager,
      'venue coordinator': ContactRole.venueCoordinator,
      'security': ContactRole.security,
      'valet': ContactRole.valet,
    };

    for (final entry in typeMap.entries) {
      if (type.contains(entry.key)) {
        return entry.value;
      }
    }
    return ContactRole.custom;
  }

  void _loadExistingContact() {
    final contact = widget.contact!;
    _nameController.text = contact.name;
    _selectedRole = contact.role;
    _customRoleController.text = contact.customRole ?? '';
    _companyController.text = contact.company ?? '';
    _phoneController.text = contact.phone ?? '';
    _emailController.text = contact.email ?? '';
    _websiteController.text = contact.website ?? '';
    _notesController.text = contact.notes ?? '';
    _isFavorite = contact.isFavorite;
    _imageUrl = contact.imageUrl;
    _profilePhotoUrl = contact.imageUrl; // Use same URL for profile photo

    // Social media
    _instagramController.text = contact.instagram ?? '';
    _tiktokController.text = contact.tiktok ?? '';
    _facebookController.text = contact.facebook ?? '';
    _twitterController.text = contact.twitter ?? '';
    _linkedinController.text = contact.linkedin ?? '';
    _youtubeController.text = contact.youtube ?? '';
    _snapchatController.text = contact.snapchat ?? '';
    _pinterestController.text = contact.pinterest ?? '';

    // Show social media section if any are populated
    _showSocialMedia = contact.hasSocialMedia;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customRoleController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    // Social media
    _instagramController.dispose();
    _tiktokController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _youtubeController.dispose();
    _snapchatController.dispose();
    _pinterestController.dispose();
    super.dispose();
  }

  Future<void> _scanBusinessCard() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isScanning = true);

      // Read and encode image
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call edge function to analyze business card
      final response = await http.post(
        Uri.parse(
            'https://bokdjidrybwxbomemmrg.supabase.co/functions/v1/scan-business-card'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Auto-fill form with extracted data
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          _nameController.text = data['name'];
        }
        if (data['company'] != null && data['company'].toString().isNotEmpty) {
          _companyController.text = data['company'];
        }
        if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
          _phoneController.text = data['phone'];
        }
        if (data['email'] != null && data['email'].toString().isNotEmpty) {
          _emailController.text = data['email'];
        }
        if (data['website'] != null && data['website'].toString().isNotEmpty) {
          _websiteController.text = data['website'];
        }
        if (data['title'] != null && data['title'].toString().isNotEmpty) {
          // Try to match to a role, otherwise use as custom role
          _customRoleController.text = data['title'];
          _selectedRole = ContactRole.custom;
        }

        // Social media extraction
        bool hasSocialMedia = false;
        if (data['instagram'] != null &&
            data['instagram'].toString().isNotEmpty) {
          _instagramController.text = data['instagram'];
          hasSocialMedia = true;
        }
        if (data['tiktok'] != null && data['tiktok'].toString().isNotEmpty) {
          _tiktokController.text = data['tiktok'];
          hasSocialMedia = true;
        }
        if (data['facebook'] != null &&
            data['facebook'].toString().isNotEmpty) {
          _facebookController.text = data['facebook'];
          hasSocialMedia = true;
        }
        if (data['twitter'] != null && data['twitter'].toString().isNotEmpty) {
          _twitterController.text = data['twitter'];
          hasSocialMedia = true;
        }
        if (data['linkedin'] != null &&
            data['linkedin'].toString().isNotEmpty) {
          _linkedinController.text = data['linkedin'];
          hasSocialMedia = true;
        }
        if (data['youtube'] != null && data['youtube'].toString().isNotEmpty) {
          _youtubeController.text = data['youtube'];
          hasSocialMedia = true;
        }
        if (data['snapchat'] != null &&
            data['snapchat'].toString().isNotEmpty) {
          _snapchatController.text = data['snapchat'];
          hasSocialMedia = true;
        }
        if (data['pinterest'] != null &&
            data['pinterest'].toString().isNotEmpty) {
          _pinterestController.text = data['pinterest'];
          hasSocialMedia = true;
        }

        // Auto-expand social media section if any were found
        if (hasSocialMedia) {
          setState(() => _showSocialMedia = true);
        }

        // Upload and save image URL
        final imageUrl = await _uploadBusinessCardImage(bytes, image.name);
        if (imageUrl != null) {
          setState(() => _imageUrl = imageUrl);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Business card scanned successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        throw Exception('Failed to scan business card');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // Show bottom sheet for profile photo options
  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Take Photo
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                child: Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              ),
              title: Text(
                'Take Photo',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickProfilePhoto(ImageSource.camera);
              },
            ),
            // Choose from Gallery
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.2),
                child: Icon(Icons.photo_library, color: AppTheme.accentBlue),
              ),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickProfilePhoto(ImageSource.gallery);
              },
            ),
            // Remove Photo (if exists)
            if (_profilePhotoUrl != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentRed.withValues(alpha: 0.2),
                  child: Icon(Icons.delete, color: AppTheme.accentRed),
                ),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profilePhotoUrl = null);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Pick profile photo from camera or gallery
  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Upload to Supabase Storage
      final bytes = await image.readAsBytes();
      final url = await _uploadProfilePhoto(bytes, image.name);

      if (url != null) {
        setState(() => _profilePhotoUrl = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Profile photo uploaded'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  // Upload profile photo to Supabase Storage
  Future<String?> _uploadProfilePhoto(List<int> bytes, String fileName) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$userId/profile_photos/$timestamp-$fileName';

      await Supabase.instance.client.storage
          .from('contact-images')
          .uploadBinary(path, bytes as dynamic);

      final url = Supabase.instance.client.storage
          .from('contact-images')
          .getPublicUrl(path);

      return url;
    } catch (e) {
      debugPrint('Failed to upload profile photo: $e');
      return null;
    }
  }

  Future<String?> _uploadBusinessCardImage(
      List<int> bytes, String fileName) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$userId/business_cards/$timestamp-$fileName';

      await Supabase.instance.client.storage
          .from('contact-images')
          .uploadBinary(path, bytes as dynamic);

      final url = Supabase.instance.client.storage
          .from('contact-images')
          .getPublicUrl(path);

      return url;
    } catch (e) {
      debugPrint('Failed to upload business card image: $e');
      return null;
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final contact = EventContact(
        id: widget.contact?.id,
        userId: widget.contact?.userId,
        shiftId: widget.shiftId ?? widget.contact?.shiftId,
        name: _nameController.text.trim(),
        role: _selectedRole,
        customRole: _selectedRole == ContactRole.custom
            ? _customRoleController.text.trim()
            : null,
        company: _companyController.text.trim().isNotEmpty
            ? _companyController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        imageUrl: _profilePhotoUrl ??
            _imageUrl, // Use profile photo if available, else business card
        isFavorite: _isFavorite,
        // Social media
        instagram: _instagramController.text.trim().isNotEmpty
            ? _instagramController.text.trim()
            : null,
        tiktok: _tiktokController.text.trim().isNotEmpty
            ? _tiktokController.text.trim()
            : null,
        facebook: _facebookController.text.trim().isNotEmpty
            ? _facebookController.text.trim()
            : null,
        twitter: _twitterController.text.trim().isNotEmpty
            ? _twitterController.text.trim()
            : null,
        linkedin: _linkedinController.text.trim().isNotEmpty
            ? _linkedinController.text.trim()
            : null,
        youtube: _youtubeController.text.trim().isNotEmpty
            ? _youtubeController.text.trim()
            : null,
        snapchat: _snapchatController.text.trim().isNotEmpty
            ? _snapchatController.text.trim()
            : null,
        pinterest: _pinterestController.text.trim().isNotEmpty
            ? _pinterestController.text.trim()
            : null,
      );

      if (isEditing) {
        await _db.updateEventContact(contact);
      } else {
        await _db.saveEventContact(contact);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save contact: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          isEditing ? 'Edit Contact' : 'Add Contact',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color:
                  _isFavorite ? AppTheme.accentYellow : AppTheme.textSecondary,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            tooltip: 'Toggle favorite',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Business Card Scanner Button - Compact with sparkles
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentPurple,
                      AppTheme.accentBlue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isScanning ? null : _scanBusinessCard,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isScanning)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                // Sparkle overlay
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: AppTheme.accentYellow,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _isScanning
                                ? 'Scanning...'
                                : 'AI Business Card Scanner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (!_isScanning) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Business card image preview
            if (_imageUrl != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Profile Photo Section
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Profile photo circle
                    GestureDetector(
                      onTap: _showProfilePhotoOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.cardBackground,
                            backgroundImage: _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!)
                                : null,
                            child: _profilePhotoUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppTheme.textMuted,
                                  )
                                : null,
                          ),
                          // Camera icon overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.darkBackground,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profilePhotoUrl != null
                          ? 'Tap to change photo'
                          : 'Tap to add photo',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person,
              required: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Role Picker
            _buildRolePicker(),
            const SizedBox(height: 16),

            // Custom Role (if custom selected)
            if (_selectedRole == ContactRole.custom)
              Column(
                children: [
                  _buildTextField(
                    controller: _customRoleController,
                    label: 'Custom Role',
                    icon: Icons.work,
                    hint: 'e.g., Florist, Officiant',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Company
            _buildTextField(
              controller: _companyController,
              label: 'Company',
              icon: Icons.business,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Phone
            _buildContactField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              actionIcon: Icons.call,
              actionColor: AppTheme.primaryGreen,
              onAction: _phoneController.text.isNotEmpty
                  ? () => _launchPhone(_phoneController.text)
                  : null,
            ),
            const SizedBox(height: 16),

            // Email
            _buildContactField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              actionIcon: Icons.send,
              actionColor: AppTheme.accentBlue,
              onAction: _emailController.text.isNotEmpty
                  ? () => _launchEmail(_emailController.text)
                  : null,
            ),
            const SizedBox(height: 16),

            // Website
            _buildContactField(
              controller: _websiteController,
              label: 'Website',
              icon: Icons.language,
              keyboardType: TextInputType.url,
              actionIcon: Icons.open_in_new,
              actionColor: AppTheme.accentPurple,
              onAction: _websiteController.text.isNotEmpty
                  ? () => _launchUrl(_websiteController.text)
                  : null,
            ),
            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              icon: Icons.notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Social Media Section
            _buildSocialMediaSection(),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      isEditing ? 'Save Changes' : 'Add Contact',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        hintStyle: TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryGreen),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  /// Contact field with optional action button (call, email, open website)
  Widget _buildContactField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? actionIcon,
    Color? actionColor,
    VoidCallback? onAction,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: TextStyle(color: AppTheme.textPrimary),
            onChanged: (_) =>
                setState(() {}), // Refresh to update action button
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              hintStyle: TextStyle(color: AppTheme.textMuted),
              prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                : null,
          ),
        ),
        if (actionIcon != null) ...[
          const SizedBox(width: 8),
          Material(
            color: controller.text.trim().isNotEmpty
                ? (actionColor ?? AppTheme.primaryGreen).withValues(alpha: 0.15)
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: controller.text.trim().isNotEmpty ? onAction : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  actionIcon,
                  color: controller.text.trim().isNotEmpty
                      ? (actionColor ?? AppTheme.primaryGreen)
                      : AppTheme.textMuted,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // URL Launcher helpers - just try to launch, don't check canLaunchUrl
  // (Android 11+ has package visibility restrictions that break canLaunchUrl)
  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone app')),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  Future<void> _launchSocialMedia(String platform, String handle) async {
    if (handle.isEmpty) return;

    String url;
    switch (platform) {
      case 'instagram':
        url = 'https://instagram.com/$handle';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$handle';
        break;
      case 'facebook':
        url =
            handle.startsWith('http') ? handle : 'https://facebook.com/$handle';
        break;
      case 'twitter':
        url = 'https://x.com/$handle';
        break;
      case 'linkedin':
        url = handle.startsWith('http')
            ? handle
            : 'https://linkedin.com/in/$handle';
        break;
      case 'youtube':
        url =
            handle.startsWith('http') ? handle : 'https://youtube.com/@$handle';
        break;
      case 'snapchat':
        url = 'https://snapchat.com/add/$handle';
        break;
      case 'pinterest':
        url = handle.startsWith('http')
            ? handle
            : 'https://pinterest.com/$handle';
        break;
      default:
        return;
    }

    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $platform')),
        );
      }
    }
  }

  Widget _buildRolePicker() {
    // Group roles by category
    final rolesByCategory = <String, List<ContactRole>>{};
    for (final role in ContactRole.values) {
      final category = role.category;
      rolesByCategory.putIfAbsent(category, () => []);
      rolesByCategory[category]!.add(role);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.work, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'Role',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DropdownButtonFormField<ContactRole>(
              initialValue: _selectedRole,
              dropdownColor: AppTheme.cardBackground,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
              items: ContactRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      Text(
                        role.displayName,
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      if (role != ContactRole.custom) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${role.category})',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse toggle
          InkWell(
            onTap: () => setState(() => _showSocialMedia = !_showSocialMedia),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.share, color: AppTheme.accentPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Social Media',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _showSocialMedia
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Social media fields (expanded)
          if (_showSocialMedia) ...[
            Divider(height: 1, color: AppTheme.darkBackground),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSocialField(
                    controller: _instagramController,
                    label: 'Instagram',
                    icon: FontAwesomeIcons.instagram,
                    iconColor: const Color(0xFFE4405F),
                    prefix: '@',
                    platform: 'instagram',
                  ),
                  const SizedBox(height: 12),
                  _buildSocialField(
                    controller: _tiktokController,
                    label: 'TikTok',
                    icon: FontAwesomeIcons.tiktok,
                    iconColor: const Color(0xFF00F2EA),
                    prefix: '@',
                    platform: 'tiktok',
                  ),
                  const SizedBox(height: 12),
                  _buildSocialField(
                    controller: _facebookController,
                    label: 'Facebook',
                    icon: FontAwesomeIcons.facebookF,
                    iconColor: const Color(0xFF1877F2),
                    platform: 'facebook',
                  ),
                  const SizedBox(height: 12),
                  _buildSocialField(
                    controller: _twitterController,
                    label: 'X (Twitter)',
                    icon: FontAwesomeIcons.xTwitter,
                    iconColor: AppTheme.textPrimary,
                    prefix: '@',
                    platform: 'twitter',
                  ),
                  const SizedBox(height: 12),
                  _buildSocialField(
                    controller: _linkedinController,
                    label: 'LinkedIn',
                    icon: FontAwesomeIcons.linkedinIn,
                    iconColor: const Color(0xFF0A66C2),
                    platform: 'linkedin',
                  ),
                  const SizedBox(height: 12),
                  _buildSocialField(
                    controller: _youtubeController,
                    label: 'YouTube',
                    icon: FontAwesomeIcons.youtube,
                    iconColor: const Color(0xFFFF0000),
                    platform: 'youtube',
                  ),
                  const SizedBox(height: 12),
                  _buildSocialField(
                    controller: _snapchatController,
                    label: 'Snapchat',
                    icon: FontAwesomeIcons.snapchat,
                    iconColor: const Color(0xFFFFFC00),
                    platform: 'snapchat',
                  ),
                  const SizedBox(height: 12),
                  _buildSocialField(
                    controller: _pinterestController,
                    label: 'Pinterest',
                    icon: FontAwesomeIcons.pinterestP,
                    iconColor: const Color(0xFFE60023),
                    platform: 'pinterest',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required String platform,
    String? prefix,
  }) {
    final hasValue = controller.text.trim().isNotEmpty;

    return Row(
      children: [
        // Tappable icon that opens the social media page
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasValue
                ? () => _launchSocialMedia(platform, controller.text.trim())
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasValue
                    ? iconColor.withValues(alpha: 0.25)
                    : iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: hasValue
                    ? Border.all(color: iconColor.withValues(alpha: 0.5), width: 1)
                    : null,
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: hasValue ? iconColor : iconColor.withValues(alpha: 0.5),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            style: TextStyle(color: AppTheme.textPrimary),
            onChanged: (_) => setState(() {}), // Refresh to update icon state
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: AppTheme.textMuted),
              prefixText: prefix,
              prefixStyle: TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
