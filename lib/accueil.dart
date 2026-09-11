import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'enfants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Stream<List<Map<String, dynamic>>> _childrenStream = Supabase
      .instance.client
      .from('enfants')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  void _openAddChildModal(BuildContext context, {Map<String, dynamic>? childData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddChildForm(childData: childData),
      ),
    );
  }

  Future<void> _deleteChild(String id) async {
    try {
      await Supabase.instance.client.from('enfants').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enfant supprimé avec succès !'),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone');
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Eftekad',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'St Mina, St Mercure & St Pape Cyrille VI, Église Copte Orthodoxe, Colombes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Image.asset(
                          'assets/image/logo1.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/image/logo.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/image/1.jpg',
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.deepPurple.withOpacity(0.1),
                        alignment: Alignment.center,
                        child: const Text(
                          'Image non trouvée',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: () => _openAddChildModal(context),
                  icon: const Icon(Icons.person_add_rounded, size: 22),
                  label: const Text(
                    'Inscrire un enfant ou jeune',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Enfants inscrits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _childrenStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Erreur de chargement : ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    }

                    final children = snapshot.data ?? [];

                    if (children.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.child_care_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text(
                                'Aucun enfant ou jeune inscrit pour le moment.',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: children.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final child = children[index];
                        final photoUrl = child['photo_url'] as String?;
                        final niveau = child['niveau_classe'] ?? 'Non renseigné';
                        final telephone = child['telephone'] ?? '';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 1,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.grey[800],
                                          child: photoUrl != null && photoUrl.isNotEmpty
                                              ? ClipOval(
                                            child: Image.network(
                                              '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.person, color: Colors.white);
                                              },
                                              loadingBuilder: (context, childWidget, loadingProgress) {
                                                if (loadingProgress == null) return childWidget;
                                                return const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                );
                                              },
                                            ),
                                          )
                                              : const Icon(Icons.person, color: Colors.white, size: 30),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${child['prenom'] ?? ''} ${child['nom'] ?? ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              niveau,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1),
                                  ),
                                  _buildInfoRow(Icons.cake_outlined, 'Né(e) le : ${child['date_naissance'] ?? ''}'),
                                  const SizedBox(height: 6),
                                  _buildInfoRow(Icons.home_outlined, 'Adresse : ${child['adresse'] ?? ''}, ${child['ville'] ?? ''} (${child['code_postal'] ?? ''})', maxLines: 2),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoRow(Icons.phone_outlined, 'Tél : $telephone'),
                                      ),
                                      if (telephone.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.chat_rounded, color: Colors.deepPurpleAccent, size: 20),
                                          tooltip: 'Ouvrir WhatsApp',
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _openWhatsApp(telephone),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _openAddChildModal(context, childData: child),
                                        icon: const Icon(Icons.edit_rounded, size: 16),
                                        label: const Text('Modifier'),
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: const Text('Confirmer la suppression'),
                                              content: const Text('Voulez-vous vraiment supprimer cet enfant ?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Annuler'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteChild(child['id'].toString());
                                                  },
                                                  child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                        label: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 15, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class AddChildForm extends StatefulWidget {
  final Map<String, dynamic>? childData;

  const AddChildForm({super.key, this.childData});

  @override
  State<AddChildForm> createState() => _AddChildFormState();
}

class _AddChildFormState extends State<AddChildForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _adresseController;
  late final TextEditingController _villeController;
  late final TextEditingController _codePostalController;
  late final TextEditingController _telephoneController;

  File? _imageFile;
  String? _selectedDay;
  String? _selectedLevel;
  bool _isLoading = false;

  String? _selectedBirthDay;
  String? _selectedBirthMonth;
  String? _selectedBirthYear;

  final List<String> _daysList = ['Samedi', 'Dimanche'];

  final List<String> _birthDaysList = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _birthMonthsList = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
  final List<String> _birthYearsList = List.generate(100, (index) => (2000 + index).toString());

  Map<String, List<String>> get _levelsMap => {
    'Samedi': ['PS/MS', 'GS/CP', 'CE1/CE2', 'CM1/CM2', '6e/5e', '4e/3e', 'Lycéen'],
    'Dimanche': ['PS/MS', 'GS', 'CP', 'CE1/CE2', 'CM1/CM2', '6e/5e', '4e/3e', 'Lycéen'],
  };

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.childData?['nom'] ?? '');
    _prenomController = TextEditingController(text: widget.childData?['prenom'] ?? '');
    _adresseController = TextEditingController(text: widget.childData?['adresse'] ?? '');
    _villeController = TextEditingController(text: widget.childData?['ville'] ?? '');
    _codePostalController = TextEditingController(text: widget.childData?['code_postal'] ?? '');

    final savedDate = widget.childData?['date_naissance'] as String?;
    if (savedDate != null && savedDate.isNotEmpty) {
      final parts = savedDate.split('/');
      if (parts.length == 3) {
        if (_birthDaysList.contains(parts[0])) _selectedBirthDay = parts[0];
        if (_birthMonthsList.contains(parts[1])) _selectedBirthMonth = parts[1];
        if (_birthYearsList.contains(parts[2])) _selectedBirthYear = parts[2];
      }
    }

    String initialPhone = widget.childData?['telephone'] ?? '+33';
    _telephoneController = TextEditingController(text: initialPhone);

    final niveauClasse = widget.childData?['niveau_classe'] as String?;
    if (niveauClasse != null && niveauClasse.isNotEmpty) {
      final parts = niveauClasse.split(' ');
      if (parts.isNotEmpty && _daysList.contains(parts[0])) {
        _selectedDay = parts[0];
        if (parts.length > 1) {
          final lvl = parts.sublist(1).join(' ');
          if (_levelsMap[_selectedDay]!.contains(lvl)) {
            _selectedLevel = lvl;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _telephoneController.dispose();
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
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDay == null || _selectedBirthMonth == null || _selectedBirthYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de naissance complète'),
        ),
      );
      return;
    }
    if (_selectedDay == null || _selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner le jour et le niveau de classe'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = widget.childData?['photo_url'];

      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'children_photos/$fileName';
        await Supabase.instance.client.storage
            .from('photos')
            .upload(path, _imageFile!);
        photoUrl = Supabase.instance.client.storage
            .from('photos')
            .getPublicUrl(path);
      }

      final fullClassLevel = '$_selectedDay $_selectedLevel';
      final formattedBirthDate = '$_selectedBirthDay/$_selectedBirthMonth/$_selectedBirthYear';

      String rawPhone = _telephoneController.text.trim();
      String cleanPhone = rawPhone.replaceAll(' ', '');

      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+33$cleanPhone';
      }

      final Map<String, dynamic> dataToSave = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'date_naissance': formattedBirthDate,
        'adresse': _adresseController.text.trim(),
        'ville': _villeController.text.trim(),
        'code_postal': _codePostalController.text.trim(),
        'telephone': cleanPhone,
        'photo_url': photoUrl,
        'niveau_classe': fullClassLevel,
      };

      if (widget.childData == null) {
        dataToSave['dates_absence'] = [];
        await Supabase.instance.client.from('enfants').insert(dataToSave);
      } else {
        await Supabase.instance.client
            .from('enfants')
            .update(dataToSave)
            .eq('id', widget.childData!['id']);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.childData == null ? 'Inscription réussie !' : 'Modifications enregistrées !'),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.childData != null;

    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEditing ? 'Modifier Enfant / Jeune' : 'Inscription Enfant ou Jeune',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.childData?['photo_url'] != null && widget.childData!['photo_url'].isNotEmpty
                            ? NetworkImage(widget.childData!['photo_url']) as ImageProvider
                            : null),
                        child: (_imageFile == null && (widget.childData?['photo_url'] == null || widget.childData!['photo_url'].isEmpty))
                            ? const Icon(Icons.add_a_photo_rounded, size: 26, color: Colors.white70)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nomController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.person_rounded, color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _prenomController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Prénom',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      value: _selectedBirthDay,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Jour',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.cake_rounded, color: Colors.deepPurpleAccent, size: 18),
                        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _birthDaysList
                          .map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBirthDay = val),
                      validator: (val) => val == null ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 9,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      value: _selectedBirthMonth,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Mois',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _birthMonthsList
                          .map((month) => DropdownMenuItem(value: month, child: Text(month, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBirthMonth = val),
                      validator: (val) => val == null ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      value: _selectedBirthYear,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Année',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _birthYearsList
                          .map((year) => DropdownMenuItem(value: year, child: Text(year, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBirthYear = val),
                      validator: (val) => val == null ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _adresseController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Adresse postale',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.home_rounded, color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _villeController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Ville',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.deepPurpleAccent, size: 20),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _codePostalController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Code postal',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _telephoneController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Numéro de téléphone',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.phone_rounded, color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  helperText: 'Exemple : +3306... ou +3307...',
                  helperStyle: TextStyle(color: Colors.amber.shade200, fontSize: 10),
                  helperMaxLines: 2,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty || val == '+33') {
                    return 'Veuillez entrer le numéro';
                  }
                  final clean = val.replaceAll(' ', '');
                  if (!clean.startsWith('+3306') && !clean.startsWith('+3307')) {
                    return 'Le numéro doit commencer par +3306 ou +3307';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                isDense: true,
                isExpanded: true,
                value: _selectedDay,
                dropdownColor: const Color(0xFF1E1E2C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Jour de caté',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: _daysList
                    .map((day) => DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDay = val;
                    _selectedLevel = null;
                  });
                },
                validator: (val) => val == null ? 'Veuillez choisir un jour' : null,
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                isDense: true,
                isExpanded: true,
                value: _selectedLevel,
                dropdownColor: const Color(0xFF1E1E2C),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Niveau de classe',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.school_rounded, color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: _selectedDay == null
                    ? []
                    : _levelsMap[_selectedDay]!
                    .map((level) => DropdownMenuItem(value: level, child: Text(level, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: _selectedDay == null ? null : (val) => setState(() => _selectedLevel = val),
                validator: (val) => val == null ? 'Veuillez choisir un niveau' : null,
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveChild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  isEditing ? 'Mettre à jour' : 'Enregistrer',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text;

    if (!text.startsWith('+33')) {
      text = '+33';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}