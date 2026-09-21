import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _passwordController;
  late TextEditingController _autrePereController;

  String? _role;
  String? _jour;
  String? _pereConfesseur;
  List<String> _selectedClasses = [];
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _obscurePassword = true;
  bool _isChef = false;

  String? _userPhotoUrl;
  Uint8List? _imageBytes;

  final List<String> _listeAbounas = [
    'Abouna Cherubim El Moharaki',
    'Abouna Bedaba El Moharaki',
    'Abouna Moussa Wahib',
    'Abouna Yolios Anba Bishoy',
    'Abouna Antoine Wahba',
    'Abouna Youhana Sadek',
    'Abouna Joseph Stefanos',
    'Abouna Biktor Anba Bishoy',
    'Abouna Samuel Amin',
    'Abouna Anquelos Weessa',
    'Abouna Tawadros Iskander',
    'Abouna Kirellos Wakim',
    'Abouna Raphaël Dedieu',
    'Abouna Arsenios Gadan',
    'Abouna Abraham Shenouda',
    'Autre',
  ];

  final Map<String, List<String>> _classesParCycle = {
    'Maternelle': ['PS', 'MS', 'GS'],
    'Primaire': ['CP', 'CE1', 'CE2', 'CM1', 'CM2'],
    'Collège': ['6ème', '5ème', '4ème', '3ème'],
    'Lycée': ['Seconde', 'Première', 'Terminale'],
  };

  @override
  void initState() {
    super.initState();
    _autrePereController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        final metadata = user.userMetadata ?? {};

        final nom = response?['nom'] ?? metadata['nom'] ?? '';
        final prenom = response?['prenom'] ?? metadata['prenom'] ?? '';
        final telephone = response?['telephone'] ?? metadata['telephone'] ?? metadata['phone'] ?? '+33';

        final role = response?['role'] ?? metadata['role'] ?? 'Serviteur';
        final jour = response?['jour'] ?? metadata['jour'] ?? 'Samedi';
        final photoUrl = response?['photo_url'] ?? metadata['photo_url'];
        final pereConf = response?['pere_confesseur'] ?? metadata['pere_confesseur'] ?? '';

        List<String> classes = [];
        if (response?['classes'] != null) {
          classes = (response!['classes'] as List<dynamic>).map((e) => e.toString()).toList();
        } else if (metadata['classes'] != null) {
          classes = List<String>.from(metadata['classes']);
        }

        String? selectedPere;
        if (_listeAbounas.contains(pereConf)) {
          selectedPere = pereConf;
        } else if (pereConf.isNotEmpty) {
          selectedPere = 'Autre';
          _autrePereController.text = pereConf;
        }

        setState(() {
          _nomController = TextEditingController(text: nom);
          _prenomController = TextEditingController(text: prenom);
          _telephoneController = TextEditingController(text: telephone);
          _passwordController = TextEditingController();
          _role = role;
          _jour = jour;
          _pereConfesseur = selectedPere;
          _selectedClasses = classes;
          _userPhotoUrl = photoUrl?.toString();
          _isChef = role.toLowerCase().contains('chef d');
          _isLoadingData = false;
        });
      }
    } catch (_) {
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata ?? {};
      final role = metadata['role'] ?? 'Serviteur';
      final pereConf = metadata['pere_confesseur'] ?? '';

      String? selectedPere;
      if (_listeAbounas.contains(pereConf)) {
        selectedPere = pereConf;
      } else if (pereConf.isNotEmpty) {
        selectedPere = 'Autre';
        _autrePereController.text = pereConf;
      }

      setState(() {
        _nomController = TextEditingController(text: metadata['nom'] ?? '');
        _prenomController = TextEditingController(text: metadata['prenom'] ?? '');
        _telephoneController = TextEditingController(text: metadata['telephone'] ?? metadata['phone'] ?? '+33');
        _passwordController = TextEditingController();
        _role = role;
        _jour = metadata['jour'] ?? 'Samedi';
        _pereConfesseur = selectedPere;
        _userPhotoUrl = metadata['photo_url']?.toString();
        if (metadata['classes'] != null) {
          _selectedClasses = List<String>.from(metadata['classes']);
        }
        _isChef = role.toLowerCase().contains('chef d');
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _autrePereController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Choisir une source',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: Colors.deepPurpleAccent),
              title: const Text('Prendre une photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.deepPurpleAccent),
              title: const Text('Choisir dans la galerie', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 75);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  String _getInternalEmail(String prenom) {
    final cleanPrenom =
    prenom.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$cleanPrenom@gmail.com';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final nom = _nomController.text.trim();
      final prenom = _prenomController.text.trim();
      final telephone = _telephoneController.text.trim();
      final newPassword = _passwordController.text.trim();
      final internalEmail = _getInternalEmail(prenom);

      final currentMetadata = user.userMetadata ?? {};

      final finalRole = _role ?? currentMetadata['role'] ?? 'Serviteur';
      final finalJour = _jour ?? currentMetadata['jour'] ?? 'Samedi';
      final finalClasses = _selectedClasses.isNotEmpty ? _selectedClasses : (currentMetadata['classes'] ?? <String>[]);
      final finalPereConfesseur = _isChef
          ? (currentMetadata['pere_confesseur'] ?? '')
          : (_pereConfesseur == 'Autre' ? _autrePereController.text.trim() : (_pereConfesseur ?? ''));

      String? photoUrl = _userPhotoUrl;
      if (_imageBytes != null) {
        final cleanPrenom = prenom.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final fileName = 'profiles/${cleanPrenom}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('photos')
            .uploadBinary(fileName, _imageBytes!);
        photoUrl = Supabase.instance.client.storage
            .from('photos')
            .getPublicUrl(fileName);
      }

      final newMetadata = {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'role': finalRole,
        'jour': finalJour,
        'classes': finalClasses,
        'pere_confesseur': finalPereConfesseur,
        'photo_url': photoUrl,
      };

      final Map<String, dynamic> updateData = {
        'id': user.id,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'role': finalRole,
        'jour': finalJour,
        'classes': finalClasses,
        'pere_confesseur': finalPereConfesseur,
        'photo_url': photoUrl,
      };

      await Supabase.instance.client.from('profiles').upsert(updateData);

      UserAttributes userAttributes;
      if (newPassword.isNotEmpty) {
        userAttributes = UserAttributes(
          email: internalEmail,
          password: newPassword,
          data: newMetadata,
        );
      } else {
        userAttributes = UserAttributes(
          email: internalEmail,
          data: newMetadata,
        );
      }

      await Supabase.instance.client.auth.updateUser(userAttributes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $errorMessage'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Suppression complète et définitive du compte (peu importe le rôle)
  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').delete().eq('id', user.id);
        await Supabase.instance.client.rpc('delete_user_account');
      }

      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client.from('profiles').delete().eq('id', user.id);
        }
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      );
    }

    List<String> roleOptions = [
      'Serviteur',
      'Responsable de famille',
      'Adjoint chef',
      'Adjoint chef + Responsable de famille',
      'Adjoint chef + Serviteur'
    ];
    if (_role != null && !roleOptions.contains(_role)) {
      roleOptions.add(_role!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Paramètres du profil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: _imageBytes != null
                                    ? MemoryImage(_imageBytes!)
                                    : (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                    ? NetworkImage('$_userPhotoUrl?v=${DateTime.now().millisecondsSinceEpoch}') as ImageProvider
                                    : null),
                                child: (_imageBytes == null && (_userPhotoUrl == null || _userPhotoUrl!.isEmpty))
                                    ? const Icon(Icons.person, size: 42, color: Colors.white70)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF1E1E2C), width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nomController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration('Nom', Icons.badge_rounded),
                        validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _prenomController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration:
                        _inputDecoration('Prénom', Icons.person_outline_rounded),
                        validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _telephoneController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        decoration: _inputDecoration(
                            'Téléphone (+3306 ou +3307)', Icons.phone_rounded),
                        validator: (val) {
                          if (val == null || val.isEmpty || val == '+33') {
                            return 'Requis';
                          }
                          final clean = val.replaceAll(' ', '');
                          if (!clean.startsWith('+3306') &&
                              !clean.startsWith('+3307')) {
                            return 'Doit commencer par +3306 ou +3307';
                          }
                          return null;
                        },
                      ),

                      if (!_isChef) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          isDense: false,
                          isExpanded: true,
                          value: _pereConfesseur,
                          dropdownColor: const Color(0xFF1E1E2C),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _inputDecoration('Abouna confesseur', Icons.church_rounded),
                          items: _listeAbounas
                              .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              softWrap: true,
                            ),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _pereConfesseur = val),
                          validator: (val) => !_isChef && val == null ? 'Requis' : null,
                        ),
                        if (_pereConfesseur == 'Autre') ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _autrePereController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration('Précisez le nom d\'Abouna', Icons.edit_rounded),
                            validator: (val) => !_isChef && _pereConfesseur == 'Autre' && (val == null || val.trim().isEmpty) ? 'Requis' : null,
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Text(
                          'Rôle :',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Modification réservée au Chef d\'église (verrouillé)',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isDense: false,
                          isExpanded: true,
                          value: _role,
                          dropdownColor: const Color(0xFF1E1E2C),
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                          decoration: _inputDecoration(
                              'Rôle d\'utilisateur', Icons.admin_panel_settings_rounded),
                          items: roleOptions
                              .map((r) => DropdownMenuItem(
                            value: r,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                r,
                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.2),
                                softWrap: true,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          isDense: false,
                          isExpanded: true,
                          value: _jour,
                          dropdownColor: const Color(0xFF1E1E2C),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _inputDecoration(
                              'Jour de caté', Icons.calendar_today_rounded),
                          items: ['Samedi', 'Dimanche', 'Les deux']
                              .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              softWrap: true,
                            ),
                          ))
                              .toList(),
                          onChanged: null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Classes et Cycles attribués (Verrouillés) :',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildClassesSelectionList(false),
                      ],

                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nouveau mot de passe',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(laisser vide si inchangé)',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration(
                                'Mot de passe (min 6 car.)', Icons.lock_rounded,
                                isPassword: true),
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  val.length < 6) {
                                return 'Min 6 caractères';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text(
                          'Valider les modifications',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _deleteAccount,
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent, size: 20),
                  label: const Text(
                    'Supprimer mon compte',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassesSelectionList(bool isEditable) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _classesParCycle.entries.map((entry) {
          final cycleName = entry.key;
          final classes = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycleName,
                  style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: classes.map((classe) {
                    final isSelected = _selectedClasses.contains(classe);
                    return FilterChip(
                      label: Text(classe, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: Colors.deepPurpleAccent,
                      backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade300),
                      visualDensity: VisualDensity.compact,
                      onSelected: isEditable
                          ? (selected) {
                        setState(() {
                          if (selected) {
                            _selectedClasses.add(classe);
                          } else {
                            _selectedClasses.remove(classe);
                          }
                        });
                      }
                          : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {bool isPassword = false}) {
    return InputDecoration(
      isDense: false,
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.deepPurpleAccent, size: 18),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(
            _obscurePassword
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey,
            size: 18),
        onPressed: () =>
            setState(() => _obscurePassword = !_obscurePassword),
      )
          : null,
      filled: true,
      fillColor: Colors.deepPurple.withOpacity(0.08),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (text.isEmpty) {
      return const TextEditingValue(
          text: '+33', selection: TextSelection.collapsed(offset: 3));
    }
    if (!text.startsWith('+33')) {
      text = '+33${text.startsWith('0') ? text.substring(1) : text}';
    }
    if (text.allMatches('+33').length > 1) {
      text = '+33${text.replaceAll('+33', '')}';
    }
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}