import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _serviteurFormKey = GlobalKey<FormState>();
  final _responsableFormKey = GlobalKey<FormState>();
  final _adjointFormKey = GlobalKey<FormState>();
  final _chefFormKey = GlobalKey<FormState>();

  // Contrôleurs Connexion
  final TextEditingController _loginPrenomController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Contrôleurs Serviteur
  final TextEditingController _servPasswordController = TextEditingController();
  final TextEditingController _servNomController = TextEditingController();
  final TextEditingController _servPrenomController = TextEditingController();
  final TextEditingController _servTelephoneController = TextEditingController(text: '+33');
  final TextEditingController _servAdresseController = TextEditingController();
  final TextEditingController _servVilleController = TextEditingController();
  final TextEditingController _servCodePostalController = TextEditingController();
  final TextEditingController _servAutrePereController = TextEditingController();

  String? _servBirthDay;
  String? _servBirthMonth;
  String? _servBirthYear;
  String? _servJour;
  String? _servPereConfesseur;
  final List<String> _servSelectedClasses = [];

  // Contrôleurs Responsable de famille
  final TextEditingController _respPasswordController = TextEditingController();
  final TextEditingController _respNomController = TextEditingController();
  final TextEditingController _respPrenomController = TextEditingController();
  final TextEditingController _respTelephoneController = TextEditingController(text: '+33');
  final TextEditingController _respAdresseController = TextEditingController();
  final TextEditingController _respVilleController = TextEditingController();
  final TextEditingController _respCodePostalController = TextEditingController();
  final TextEditingController _respAutrePereController = TextEditingController();

  String? _respBirthDay;
  String? _respBirthMonth;
  String? _respBirthYear;
  String? _respJour;
  String? _respPereConfesseur;
  final List<String> _respSelectedClasses = [];

  // Contrôleurs Adjoint chef
  final TextEditingController _adjointPasswordController = TextEditingController();
  final TextEditingController _adjointNomController = TextEditingController();
  final TextEditingController _adjointPrenomController = TextEditingController();
  final TextEditingController _adjointTelephoneController = TextEditingController(text: '+33');
  final TextEditingController _adjointAdresseController = TextEditingController();
  final TextEditingController _adjointVilleController = TextEditingController();
  final TextEditingController _adjointCodePostalController = TextEditingController();
  final TextEditingController _adjointAutrePereController = TextEditingController();
  final TextEditingController _adjointAccessCodeController = TextEditingController();

  String? _adjointBirthDay;
  String? _adjointBirthMonth;
  String? _adjointBirthYear;
  String? _adjointJour;
  String? _adjointRoleSub = 'Serviteur';
  String? _adjointPereConfesseur;
  final List<String> _adjointSelectedClasses = [];

  // Contrôleurs Chef d'église
  final TextEditingController _chefPasswordController = TextEditingController();
  final TextEditingController _chefNomController = TextEditingController();
  final TextEditingController _chefPrenomController = TextEditingController();
  final TextEditingController _chefTelephoneController = TextEditingController(text: '+33');
  final TextEditingController _chefAccessCodeController = TextEditingController();

  // Listes pour la date de naissance (De 1940 à 2099)
  final List<String> _birthDaysList = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _birthMonthsList = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
  final List<String> _birthYearsList = List.generate(2099 - 1940 + 1, (index) => (1940 + index).toString());

  // Liste des Pères Confesseurs (Abouna)
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

  // Gestion de la photo de profil
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final Map<String, List<String>> _classesParCycle = {
    'Maternelle': ['PS', 'MS', 'GS'],
    'Primaire': ['CP', 'CE1', 'CE2', 'CM1', 'CM2'],
    'Collège': ['6ème', '5ème', '4ème', '3ème'],
    'Lycée': ['Seconde', 'Première', 'Terminale'],
  };

  bool _isSignUp = false;
  int _signUpTabindex = 0; // 0: Serviteur, 1: Responsable, 2: Adjoint chef, 3: Chef d'église
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginErrorMessage;

  @override
  void dispose() {
    _loginPrenomController.dispose();
    _loginPasswordController.dispose();
    _servPasswordController.dispose();
    _servNomController.dispose();
    _servPrenomController.dispose();
    _servTelephoneController.dispose();
    _servAdresseController.dispose();
    _servVilleController.dispose();
    _servCodePostalController.dispose();
    _servAutrePereController.dispose();
    _respPasswordController.dispose();
    _respNomController.dispose();
    _respPrenomController.dispose();
    _respTelephoneController.dispose();
    _respAdresseController.dispose();
    _respVilleController.dispose();
    _respCodePostalController.dispose();
    _respAutrePereController.dispose();
    _adjointPasswordController.dispose();
    _adjointNomController.dispose();
    _adjointPrenomController.dispose();
    _adjointTelephoneController.dispose();
    _adjointAdresseController.dispose();
    _adjointVilleController.dispose();
    _adjointCodePostalController.dispose();
    _adjointAutrePereController.dispose();
    _adjointAccessCodeController.dispose();
    _chefPasswordController.dispose();
    _chefNomController.dispose();
    _chefPrenomController.dispose();
    _chefTelephoneController.dispose();
    _chefAccessCodeController.dispose();
    super.dispose();
  }

  String _getInternalEmail(String prenom) {
    final cleanPrenom = prenom.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$cleanPrenom@gmail.com';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image : $e')),
        );
      }
    }
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
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.deepPurpleAccent),
              title: const Text('Galerie', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.deepPurpleAccent),
              title: const Text('Appareil photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImageToSupabase(String prenom) async {
    if (_selectedImage == null) return null;
    try {
      final cleanPrenom = prenom.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final fileName = '${cleanPrenom}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, _selectedImage!);

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _loginErrorMessage = null;
    });

    try {
      final prenom = _loginPrenomController.text.trim();
      final internalEmail = _getInternalEmail(prenom);

      await Supabase.instance.client.auth.signInWithPassword(
        email: internalEmail,
        password: _loginPasswordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bienvenue ! Connexion réussie.'),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on AuthException catch (_) {
      setState(() {
        _loginErrorMessage = 'Prénom ou mot de passe incorrect';
      });
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Erreur de connexion : $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitSignUp(String role) async {
    if (role == 'Chef d\'église' || role.contains('Adjoint chef')) {
      final accessCode = role == 'Chef d\'église' ? _chefAccessCodeController.text.trim() : _adjointAccessCodeController.text.trim();
      if (accessCode != 'EFTEKAD2026!') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code d\'accès secret incorrect !'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final formKey = role == 'Serviteur'
        ? _serviteurFormKey
        : (role == 'Responsable'
        ? _responsableFormKey
        : (role.contains('Adjoint chef') ? _adjointFormKey : _chefFormKey));

    if (!formKey.currentState!.validate()) return;

    if (role == 'Serviteur') {
      if (_servBirthDay == null || _servBirthMonth == null || _servBirthYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner la date de naissance complète')));
        return;
      }
      if (_servJour == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner le jour de caté')));
        return;
      }
      if (_servSelectedClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez cocher au moins une classe')));
        return;
      }
    }

    if (role == 'Responsable') {
      if (_respBirthDay == null || _respBirthMonth == null || _respBirthYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner la date de naissance complète')));
        return;
      }
      if (_respJour == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner le jour de caté')));
        return;
      }
      if (_respSelectedClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez cocher au moins une classe')));
        return;
      }
    }

    if (role.contains('Adjoint chef')) {
      if (_adjointBirthDay == null || _adjointBirthMonth == null || _adjointBirthYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner la date de naissance complète')));
        return;
      }
      if (_adjointJour == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner le jour de caté')));
        return;
      }
      if (_adjointSelectedClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez cocher au moins une classe')));
        return;
      }
    }

    setState(() => _isLoading = true);

    String prenom, nom, telephone, password, adresse, ville, codePostal, dateNaissance;
    List<String> classes = [];
    String? jour;
    String? pereConfesseur;
    String finalRole = role;

    if (role == 'Serviteur') {
      prenom = _servPrenomController.text.trim();
      nom = _servNomController.text.trim();
      telephone = _servTelephoneController.text.trim();
      password = _servPasswordController.text.trim();
      adresse = _servAdresseController.text.trim();
      ville = _servVilleController.text.trim();
      codePostal = _servCodePostalController.text.trim();
      dateNaissance = '$_servBirthDay/$_servBirthMonth/$_servBirthYear';
      jour = _servJour;
      classes = _servSelectedClasses;
      pereConfesseur = _servPereConfesseur == 'Autre' ? _servAutrePereController.text.trim() : _servPereConfesseur;
    } else if (role == 'Responsable') {
      prenom = _respPrenomController.text.trim();
      nom = _respNomController.text.trim();
      telephone = _respTelephoneController.text.trim();
      password = _respPasswordController.text.trim();
      adresse = _respAdresseController.text.trim();
      ville = _respVilleController.text.trim();
      codePostal = _respCodePostalController.text.trim();
      dateNaissance = '$_respBirthDay/$_respBirthMonth/$_respBirthYear';
      jour = _respJour;
      classes = _respSelectedClasses;
      finalRole = 'Responsable de famille';
      pereConfesseur = _respPereConfesseur == 'Autre' ? _respAutrePereController.text.trim() : _respPereConfesseur;
    } else if (role.contains('Adjoint chef')) {
      prenom = _adjointPrenomController.text.trim();
      nom = _adjointNomController.text.trim();
      telephone = _adjointTelephoneController.text.trim();
      password = _adjointPasswordController.text.trim();
      adresse = _adjointAdresseController.text.trim();
      ville = _adjointVilleController.text.trim();
      codePostal = _adjointCodePostalController.text.trim();
      dateNaissance = '$_adjointBirthDay/$_adjointBirthMonth/$_adjointBirthYear';
      jour = _adjointJour;
      classes = _adjointSelectedClasses;
      finalRole = 'Adjoint chef + $_adjointRoleSub';
      pereConfesseur = _adjointPereConfesseur == 'Autre' ? _adjointAutrePereController.text.trim() : _adjointPereConfesseur;
    } else {
      prenom = _chefPrenomController.text.trim();
      nom = _chefNomController.text.trim();
      telephone = _chefTelephoneController.text.trim();
      password = _chefPasswordController.text.trim();
      finalRole = 'Chef d\'église';
      adresse = '';
      ville = '';
      codePostal = '';
      dateNaissance = '';
    }

    final internalEmail = _getInternalEmail(prenom);

    try {
      final String? photoUrl = await _uploadImageToSupabase(prenom);

      final response = await Supabase.instance.client.auth.signUp(
        email: internalEmail,
        password: password,
        data: {
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'role': finalRole,
          'jour': jour,
          'classes': classes,
          'pere_confesseur': pereConfesseur ?? '',
          'adresse': adresse,
          'ville': ville,
          'code_postal': codePostal,
          'date_naissance': dateNaissance,
          'photo_url': photoUrl ?? '',
          'access_code': role == 'Chef d\'église' ? _chefAccessCodeController.text.trim() : _adjointAccessCodeController.text.trim(),
        },
      );

      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Compte créé avec succès ! Connectez-vous.'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() {
            _isSignUp = false;
            _selectedImage = null;
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (errorMessage.toLowerCase().contains('already registered')) {
          errorMessage = 'Ce compte existe déjà. Veuillez vous connecter.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Piratage bloqué')) {
          errorMessage = 'Code d\'accès secret invalide.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $errorMessage'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetPrenomController = TextEditingController();
    final TextEditingController resetNewPasswordController = TextEditingController();
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouveau mot de passe', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Entrez votre prénom et votre nouveau mot de passe.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetPrenomController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Prénom', Icons.person_outline_rounded),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: resetNewPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Nouveau mot de passe', Icons.lock_rounded, isPassword: true),
                  validator: (val) => val == null || val.length < 6 ? 'Min 6 caractères' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              onPressed: isResetting
                  ? null
                  : () async {
                if (!resetFormKey.currentState!.validate()) return;
                setDialogState(() => isResetting = true);

                try {
                  final prenomClean = resetPrenomController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                  await Supabase.instance.client.rpc(
                    'update_password_by_prenom',
                    params: {
                      'p_prenom': prenomClean,
                      'p_new_password': resetNewPasswordController.text.trim(),
                    },
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Mot de passe mis à jour avec succès !'),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (_) {
                  setDialogState(() => isResetting = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur : Prénom introuvable'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: isResetting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Mettre à jour', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSignUp) {
          setState(() {
            _isSignUp = false;
            _selectedImage = null;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/image/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.church_rounded, size: 70, color: Colors.deepPurpleAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Eftekad',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'St Mina, St Mercure & St Pape Cyrille VI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                    child: !_isSignUp
                        ? _buildLoginForm()
                        : Column(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                                  child: _selectedImage == null
                                      ? const Icon(Icons.camera_alt_rounded, color: Colors.white70, size: 28)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.deepPurpleAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _signUpTabindex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _signUpTabindex == 0 ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                  ),
                                  child: Text(
                                    'Serviteur',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: _signUpTabindex == 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _signUpTabindex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _signUpTabindex == 1 ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.1),
                                  ),
                                  child: Text(
                                    'Responsable',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: _signUpTabindex == 1 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _signUpTabindex = 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _signUpTabindex == 2 ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.1),
                                  ),
                                  child: Text(
                                    'Adjoint chef',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: _signUpTabindex == 2 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _signUpTabindex = 3),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _signUpTabindex == 3 ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                  ),
                                  child: Text(
                                    'Chef église',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: _signUpTabindex == 3 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _signUpTabindex == 0
                            ? _buildServiteurForm()
                            : (_signUpTabindex == 1
                            ? _buildResponsableForm()
                            : (_signUpTabindex == 2 ? _buildAdjointForm() : _buildChefForm())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _selectedImage = null;
                        _loginErrorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUp
                          ? 'Déjà un compte ? Se connecter'
                          : 'Pas de compte ? Créer un compte',
                      style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Connexion',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _loginPrenomController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration('Prénom', Icons.person_rounded),
            validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez entrer votre prénom' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration('Mot de passe', Icons.lock_rounded, isPassword: true),
            validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez entrer votre mot de passe' : null,
          ),
          if (_loginErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _loginErrorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitLogin,
            style: _elevatedButtonStyle(),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiteurForm() {
    return Form(
      key: _serviteurFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _servNomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Nom', Icons.badge_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _servPrenomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Prénom', Icons.person_outline_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _servTelephoneController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            decoration: _inputDecoration('Téléphone (+3306 ou +3307)', Icons.phone_rounded),
            validator: (val) {
              if (val == null || val.isEmpty || val == '+33') return 'Requis';
              final clean = val.replaceAll(' ', '');
              if (!clean.startsWith('+3306') && !clean.startsWith('+3307')) {
                return 'Doit commencer par +3306 ou +3307';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _servBirthDay,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Jour'),
                  items: _birthDaysList
                      .map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _servBirthDay = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 10,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _servBirthMonth,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Mois'),
                  items: _birthMonthsList
                      .map((month) => DropdownMenuItem(value: month, child: Text(month, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _servBirthMonth = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 13,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _servBirthYear,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Année'),
                  items: _birthYearsList
                      .map((year) => DropdownMenuItem(value: year, child: Text(year, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _servBirthYear = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _servAdresseController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Adresse postale', Icons.home_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _servVilleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Ville', Icons.location_city_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _servCodePostalController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('Code postal', Icons.pin_drop_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: _servJour,
            dropdownColor: const Color(0xFF1E1E2C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Jour de caté', Icons.calendar_today_rounded),
            items: ['Samedi', 'Dimanche']
                .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _servJour = val),
            validator: (val) => val == null ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: _servPereConfesseur,
            dropdownColor: const Color(0xFF1E1E2C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Abouna confesseur', Icons.church_rounded),
            items: _listeAbounas
                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _servPereConfesseur = val),
            validator: (val) => val == null ? 'Requis' : null,
          ),
          if (_servPereConfesseur == 'Autre') ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _servAutrePereController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('Précisez le nom d\'Abouna', Icons.edit_rounded),
              validator: (val) => _servPereConfesseur == 'Autre' && (val == null || val.trim().isEmpty) ? 'Requis' : null,
            ),
          ],
          const SizedBox(height: 12),
          const Text('Sélectionnez les classes :', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildClassesSelectionList(_servSelectedClasses, (updatedList) {
            setState(() {
              _servSelectedClasses.clear();
              _servSelectedClasses.addAll(updatedList);
            });
          }),
          const SizedBox(height: 10),
          TextFormField(
            controller: _servPasswordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Mot de passe (min 6 car.)', Icons.lock_rounded, isPassword: true),
            validator: (val) => val == null || val.length < 6 ? 'Min 6 caractères' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitSignUp('Serviteur'),
            style: _elevatedButtonStyle(),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Créer mon compte Serviteur', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsableForm() {
    return Form(
      key: _responsableFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _respNomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Nom', Icons.badge_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _respPrenomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Prénom', Icons.person_outline_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _respTelephoneController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            decoration: _inputDecoration('Téléphone (+3306 ou +3307)', Icons.phone_rounded),
            validator: (val) {
              if (val == null || val.isEmpty || val == '+33') return 'Requis';
              final clean = val.replaceAll(' ', '');
              if (!clean.startsWith('+3306') && !clean.startsWith('+3307')) {
                return 'Doit commencer par +3306 ou +3307';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _respBirthDay,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Jour'),
                  items: _birthDaysList
                      .map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _respBirthDay = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 10,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _respBirthMonth,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Mois'),
                  items: _birthMonthsList
                      .map((month) => DropdownMenuItem(value: month, child: Text(month, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _respBirthMonth = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 13,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _respBirthYear,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Année'),
                  items: _birthYearsList
                      .map((year) => DropdownMenuItem(value: year, child: Text(year, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _respBirthYear = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _respAdresseController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Adresse postale', Icons.home_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _respVilleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Ville', Icons.location_city_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _respCodePostalController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('Code postal', Icons.pin_drop_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: _respJour,
            dropdownColor: const Color(0xFF1E1E2C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Jour de caté', Icons.calendar_today_rounded),
            items: ['Samedi', 'Dimanche', 'Les deux']
                .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _respJour = val),
            validator: (val) => val == null ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: _respPereConfesseur,
            dropdownColor: const Color(0xFF1E1E2C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Abouna confesseur', Icons.church_rounded),
            items: _listeAbounas
                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _respPereConfesseur = val),
            validator: (val) => val == null ? 'Requis' : null,
          ),
          if (_respPereConfesseur == 'Autre') ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _respAutrePereController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('Précisez le nom d\'Abouna', Icons.edit_rounded),
              validator: (val) => _respPereConfesseur == 'Autre' && (val == null || val.trim().isEmpty) ? 'Requis' : null,
            ),
          ],
          const SizedBox(height: 12),
          const Text('Sélectionnez les classes à superviser :', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildClassesSelectionList(_respSelectedClasses, (updatedList) {
            setState(() {
              _respSelectedClasses.clear();
              _respSelectedClasses.addAll(updatedList);
            });
          }),
          const SizedBox(height: 10),
          TextFormField(
            controller: _respPasswordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Mot de passe (min 6 car.)', Icons.lock_rounded, isPassword: true),
            validator: (val) => val == null || val.length < 6 ? 'Min 6 caractères' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitSignUp('Responsable'),
            style: _elevatedButtonStyle(),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Créer mon compte Responsable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjointForm() {
    return Form(
      key: _adjointFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: const Text(
              '🔒 Accès restreint : Code d\'accès secret requis pour l\'Adjoint chef.',
              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _adjointAccessCodeController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Code d\'accès secret', Icons.security_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Code requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjointNomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Nom', Icons.badge_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjointPrenomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Prénom', Icons.person_outline_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjointTelephoneController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            decoration: _inputDecoration('Téléphone (+3306 ou +3307)', Icons.phone_rounded),
            validator: (val) {
              if (val == null || val.isEmpty || val == '+33') return 'Requis';
              final clean = val.replaceAll(' ', '');
              if (!clean.startsWith('+3306') && !clean.startsWith('+3307')) {
                return 'Doit commencer par +3306 ou +3307';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _adjointBirthDay,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Jour'),
                  items: _birthDaysList
                      .map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _adjointBirthDay = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 10,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _adjointBirthMonth,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Mois'),
                  items: _birthMonthsList
                      .map((month) => DropdownMenuItem(value: month, child: Text(month, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _adjointBirthMonth = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 13,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _adjointBirthYear,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _dateDropdownDecoration('Année'),
                  items: _birthYearsList
                      .map((year) => DropdownMenuItem(value: year, child: Text(year, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _adjointBirthYear = val),
                  validator: (val) => val == null ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjointAdresseController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Adresse postale', Icons.home_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjointVilleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Ville', Icons.location_city_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjointCodePostalController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('Code postal', Icons.pin_drop_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: _adjointRoleSub,
            dropdownColor: const Color(0xFF1E1E2C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Rôle (Serviteur ou Responsable)', Icons.work_rounded),
            items: ['Serviteur', 'Responsable de famille']
                .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _adjointRoleSub = val),
            validator: (val) => val == null ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: _adjointJour,
            dropdownColor: const Color(0xFF1E1E2C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Jour de caté', Icons.calendar_today_rounded),
            items: ['Samedi', 'Dimanche', 'Les deux']
                .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _adjointJour = val),
            validator: (val) => val == null ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isDense: true,
            isExpanded: true,
            value: _adjointPereConfesseur,
            dropdownColor: const Color(0xFF1E1E2C),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Abouna confesseur', Icons.church_rounded),
            items: _listeAbounas
                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _adjointPereConfesseur = val),
            validator: (val) => val == null ? 'Requis' : null,
          ),
          if (_adjointPereConfesseur == 'Autre') ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _adjointAutrePereController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('Précisez le nom d\'Abouna', Icons.edit_rounded),
              validator: (val) => _adjointPereConfesseur == 'Autre' && (val == null || val.trim().isEmpty) ? 'Requis' : null,
            ),
          ],
          const SizedBox(height: 12),
          const Text('Sélectionnez les classes :', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildClassesSelectionList(_adjointSelectedClasses, (updatedList) {
            setState(() {
              _adjointSelectedClasses.clear();
              _adjointSelectedClasses.addAll(updatedList);
            });
          }),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjointPasswordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Mot de passe (min 6 car.)', Icons.lock_rounded, isPassword: true),
            validator: (val) => val == null || val.length < 6 ? 'Min 6 caractères' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitSignUp('Adjoint chef'),
            style: _elevatedButtonStyle(),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Créer mon compte Adjoint chef', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChefForm() {
    return Form(
      key: _chefFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: const Text(
              '🔒 Accès restreint : Code secret requis pour le Chef d\'église.',
              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _chefAccessCodeController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Code d\'accès secret', Icons.security_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Code requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _chefNomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Nom', Icons.badge_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _chefPrenomController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Prénom', Icons.person_outline_rounded),
            validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _chefTelephoneController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            decoration: _inputDecoration('Téléphone (+3306 ou +3307)', Icons.phone_rounded),
            validator: (val) {
              if (val == null || val.isEmpty || val == '+33') return 'Requis';
              final clean = val.replaceAll(' ', '');
              if (!clean.startsWith('+3306') && !clean.startsWith('+3307')) {
                return 'Doit commencer par +3306 ou +3307';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _chefPasswordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Mot de passe (min 6 car.)', Icons.lock_rounded, isPassword: true),
            validator: (val) => val == null || val.length < 6 ? 'Min 6 caractères' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitSignUp('Chef d\'église'),
            style: _elevatedButtonStyle(),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Créer mon compte Chef d\'église', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesSelectionList(List<String> selectedList, Function(List<String>) onSelectionChanged) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _classesParCycle.entries.map((entry) {
          final cycleName = entry.key;
          final classes = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycleName,
                  style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 2.0,
                  children: classes.map((classe) {
                    final isSelected = selectedList.contains(classe);
                    return FilterChip(
                      label: Text(classe, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: Colors.deepPurpleAccent,
                      backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade300),
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        final newList = List<String>.from(selectedList);
                        if (selected) {
                          newList.add(classe);
                        } else {
                          newList.remove(classe);
                        }
                        onSelectionChanged(newList);
                      },
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

  InputDecoration _inputDecoration(String label, IconData icon, {bool isPassword = false, bool showIcon = true}) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      prefixIcon: showIcon ? Icon(icon, color: Colors.deepPurpleAccent, size: 18) : null,
      prefixIconConstraints: showIcon ? null : const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      )
          : null,
      filled: true,
      fillColor: Colors.deepPurple.withOpacity(0.08),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  InputDecoration _dateDropdownDecoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
      filled: true,
      fillColor: Colors.deepPurple.withOpacity(0.08),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
  }

  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurpleAccent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (text.isEmpty) {
      return const TextEditingValue(text: '+33', selection: TextSelection.collapsed(offset: 3));
    }
    if (!text.startsWith('+33')) {
      text = '+33${text.startsWith('0') ? text.substring(1) : text}';
    }
    if (text.allMatches('+33').length > 1) {
      text = '+33${text.replaceAll('+33', '')}';
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}