import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'enfants.dart';
import 'parametres.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, List<String>> _allClassesParCycle = {
    'Maternelle': ['PS', 'MS', 'GS'],
    'Primaire': ['CP', 'CE1', 'CE2', 'CM1', 'CM2'],
    'Collège': ['6ème', '5ème', '4ème', '3ème'],
    'Lycée': ['Seconde', 'Première', 'Terminale'],
  };

  String? _userPhotoUrl;
  String _prenomUser = '';
  String _roleUser = ''; // Le vrai rôle principal stocké dans Supabase (ex: Adjoint chef)
  String _roleActif = ''; // Le rôle affiché actuellement à l'écran
  List<String> _userClasses = [];
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _checkAndApplySeptemberPromotion();
    _loadUserData();
  }

  // Charge et écoute en temps réel les données du profil utilisateur connecté
  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen((data) {
        if (data.isNotEmpty && mounted) {
          final profile = data.first;
          setState(() {
            _prenomUser = profile['prenom'] ?? '';
            _roleUser = profile['role'] ?? '';
            _roleActif = profile['role_actif'] ?? _roleUser;
            _userClasses = (profile['classes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [];
            _userPhotoUrl = profile['photo_url']?.toString();
            _isLoadingProfile = false;
          });
        } else if (_isLoadingProfile && mounted) {
          final metadata = user.userMetadata ?? {};
          setState(() {
            _prenomUser = metadata['prenom'] ?? '';
            _roleUser = metadata['role'] ?? '';
            _roleActif = metadata['role_actif'] ?? _roleUser;
            _userClasses = metadata['classes'] != null
                ? List<String>.from(metadata['classes'])
                : [];
            _userPhotoUrl = metadata['photo_url']?.toString();
            _isLoadingProfile = false;
          });
        }
      });
    }
  }

  // Permet de mettre à jour ou d'ajouter sa photo de profil en cliquant dessus
  Future<void> _updateUserProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 75);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final cleanPrenom = _prenomUser
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '');
          final fileName =
              'profiles/${cleanPrenom}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          await Supabase.instance.client.storage
              .from('photos')
              .uploadBinary(fileName, bytes);

          final imageUrl = Supabase.instance.client.storage
              .from('photos')
              .getPublicUrl(fileName);

          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'photo_url': imageUrl,
          });

          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'photo_url': imageUrl}),
          );

          setState(() {
            _userPhotoUrl = imageUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Photo de profil mise à jour avec succès !')),
            );
          }
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

  // Déconnexion de l'utilisateur
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Vérifie et applique le passage automatique de classe en rentrée de septembre
  /// pour les enfants ET pour les profils (serviteurs/responsables).
  Future<void> _checkAndApplySeptemberPromotion() async {
    try {
      final now = DateTime.now();
      final int currentAcademicYear = now.month >= 9 ? now.year : now.year - 1;

      // 1. Promotion automatique pour les enfants
      final response = await Supabase.instance.client.from('enfants').select();
      if (response != null) {
        final List<dynamic> children = response as List<dynamic>;

        for (var child in children) {
          final id = child['id'];
          final String? fullLevel = child['niveau_classe'];
          final int lastPromotedYear = child['derniere_annee_promotion'] ?? 0;

          if (fullLevel != null &&
              fullLevel.isNotEmpty &&
              lastPromotedYear < currentAcademicYear) {
            final String newLevel = _getPromotedClassLevel(fullLevel);

            if (newLevel != fullLevel) {
              await Supabase.instance.client.from('enfants').update({
                'niveau_classe': newLevel,
                'derniere_annee_promotion': currentAcademicYear,
              }).eq('id', id);
            } else {
              await Supabase.instance.client.from('enfants').update({
                'derniere_annee_promotion': currentAcademicYear,
              }).eq('id', id);
            }
          }
        }
      }

      // 2. Promotion automatique pour les profils (serviteurs / responsables)
      final responseProfiles = await Supabase.instance.client.from('profiles').select();
      if (responseProfiles != null) {
        final List<dynamic> profiles = responseProfiles as List<dynamic>;

        for (var profile in profiles) {
          final id = profile['id'];
          final List<dynamic>? rawClasses = profile['classes'];
          final int lastPromotedYear = profile['derniere_annee_promotion'] ?? 0;

          if (rawClasses != null && rawClasses.isNotEmpty && lastPromotedYear < currentAcademicYear) {
            List<String> updatedClasses = [];

            for (var c in rawClasses) {
              String promotedClass = _getPromotedSimpleClassLevel(c.toString());
              if (!updatedClasses.contains(promotedClass)) {
                updatedClasses.add(promotedClass);
              }
            }

            await Supabase.instance.client.from('profiles').update({
              'classes': updatedClasses,
              'derniere_annee_promotion': currentAcademicYear,
            }).eq('id', id);
          }
        }
      }
    } catch (_) {}
  }

  /// Fonction utilitaire pour promouvoir un niveau simple (ex: 'CP' -> 'CE1') pour les profils
  String _getPromotedSimpleClassLevel(String level) {
    switch (level.trim()) {
      case 'PS': return 'MS';
      case 'MS': return 'GS';
      case 'GS': return 'CP';
      case 'CP': return 'CE1';
      case 'CE1': return 'CE2';
      case 'CE2': return 'CM1';
      case 'CM1': return 'CM2';
      case 'CM2': return '6ème';
      case '6ème': return '5ème';
      case '5ème': return '4ème';
      case '4ème': return '3ème';
      case '3ème': return 'Seconde';
      case 'Seconde': return 'Première';
      case 'Première': return 'Terminale';
      case 'Terminale': return 'Terminale';
      default: return level;
    }
  }

  /// Calcule la classe supérieure
  String _getPromotedClassLevel(String currentFullLevel) {
    final parts = currentFullLevel.split(' ');
    if (parts.length < 2) return currentFullLevel;

    final String day = parts[0];
    String cycle = '';
    String level = '';

    if (parts.length >= 3) {
      cycle = parts[1];
      level = parts.sublist(2).join(' ');
    } else {
      level = parts[1];
    }

    String newCycle = cycle;
    String newLevel = level;

    if (level == 'PS') {
      newLevel = 'MS';
      newCycle = 'Maternelle';
    } else if (level == 'MS') {
      newLevel = 'GS';
      newCycle = 'Maternelle';
    } else if (level == 'GS') {
      newLevel = 'CP';
      newCycle = 'Primaire';
    } else if (level == 'CP') {
      newLevel = 'CE1';
      newCycle = 'Primaire';
    } else if (level == 'CE1') {
      newLevel = 'CE2';
      newCycle = 'Primaire';
    } else if (level == 'CE2') {
      newLevel = 'CM1';
      newCycle = 'Primaire';
    } else if (level == 'CM1') {
      newLevel = 'CM2';
      newCycle = 'Primaire';
    } else if (level == 'CM2') {
      newLevel = '6ème';
      newCycle = 'Collège';
    } else if (level == '6ème') {
      newLevel = '5ème';
      newCycle = 'Collège';
    } else if (level == '5ème') {
      newLevel = '4ème';
      newCycle = 'Collège';
    } else if (level == '4ème') {
      newLevel = '3ème';
      newCycle = 'Collège';
    } else if (level == '3ème') {
      newLevel = 'Seconde';
      newCycle = 'Lycée';
    } else if (level == 'Seconde') {
      newLevel = 'Première';
      newCycle = 'Lycée';
    } else if (level == 'Première') {
      newLevel = 'Terminale';
      newCycle = 'Lycée';
    } else if (level == 'Terminale') {
      newLevel = 'Terminale';
      newCycle = 'Lycée';
    }

    if (newCycle.isNotEmpty) {
      return '$day $newCycle $newLevel';
    } else {
      return '$day $newLevel';
    }
  }

  void _openAddChildModal(BuildContext context,
      {Map<String, dynamic>? childData}) {
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

  // Fenêtre modale pour changer son propre rôle instantanément (réservée à l'Adjoint chef)
  void _showRoleSwitchModal(BuildContext context) {
    List<String> options = ['Adjoint chef', 'Responsable de famille'];
    if (_roleUser.contains('Serviteur')) {
      options = ['Adjoint chef', 'Serviteur'];
    } else if (_roleUser.contains('Responsable')) {
      options = ['Adjoint chef', 'Responsable de famille'];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Changer votre rôle',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Passez instantanément de rôle :',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...options.map((r) => ListTile(
              leading: Icon(
                _roleActif == r
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off_rounded,
                color:
                _roleActif == r ? Colors.deepPurpleAccent : Colors.grey,
              ),
              title: Text(r,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    await Supabase.instance.client
                        .from('profiles')
                        .update({
                      'role_actif': r,
                    }).eq('id', user.id);

                    await Supabase.instance.client.auth.updateUser(
                      UserAttributes(data: {'role_actif': r}),
                    );

                    setState(() {
                      _roleActif = r;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text('Affichage mis à jour : $r')),
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
              },
            )),
          ],
        ),
      ),
    );
  }

  // Option Copier-Coller : Copie les détails de la personne dans le presse-papier
  void _copyProfileInfo(Map<String, dynamic> p) {
    final nom = p['nom'] ?? '';
    final prenom = p['prenom'] ?? '';
    final tel = p['telephone'] ?? '';
    final dateNaiss = p['date_naissance'] ?? 'Non renseignée';
    final pereConf = p['pere_confesseur'] ?? 'Non renseigné';
    final adresse = p['adresse'] ?? '';
    final ville = p['ville'] ?? '';
    final codePostal = p['code_postal'] ?? '';
    final jour = p['jour'] ?? '';
    final role = p['role'] ?? '';
    final classes = (p['classes'] as List<dynamic>?)?.join(', ') ?? '';

    final text = 'Nom : $prenom $nom\n'
        'Rôle : $role\n'
        'Jour : $jour\n'
        'Classe(s) / Niveau : $classes\n'
        'Téléphone : $tel\n'
        'Date de naissance : $dateNaiss\n'
        'Abouna confesseur : $pereConf\n'
        'Adresse : $adresse, $ville ($codePostal)';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Informations copiées dans le presse-papier !')),
    );
  }

  // Fenêtre modale de modification (Rôle, Cycle et Niveau / Classes) pour le Chef d'église
  void _openEditProfileModalForChef(
      BuildContext context, Map<String, dynamic> profile) {
    String? selectedJour = profile['jour'] ?? 'Samedi';
    String? selectedRole = profile['role'] ?? 'Serviteur';
    List<String> selectedClasses =
        (profile['classes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];

    List<String> roleOptions = [
      'Serviteur',
      'Responsable de famille',
      'Adjoint chef',
      'Adjoint chef + Responsable de famille',
      'Adjoint chef + Serviteur'
    ];
    if (selectedRole != null && !roleOptions.contains(selectedRole)) {
      roleOptions.add(selectedRole!);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Modifier ${profile['prenom']} ${profile['nom']}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Rôle d\'utilisateur',
                    labelStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    filled: true,
                    fillColor: Colors.deepPurple.withOpacity(0.08),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: roleOptions
                      .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r,
                          style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) => setStateModal(() => selectedRole = val),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedJour,
                  dropdownColor: const Color(0xFF1E1E2C),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Jour de caté',
                    labelStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    filled: true,
                    fillColor: Colors.deepPurple.withOpacity(0.08),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Samedi', 'Dimanche', 'Les deux']
                      .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d,
                          style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) => setStateModal(() => selectedJour = val),
                ),
                const SizedBox(height: 16),
                const Text('Cycle et Niveau (Classes attribuées) :',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _allClassesParCycle.entries.map((entry) {
                      final cycleName = entry.key;
                      final classesList = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cycle : $cycleName',
                                style: const TextStyle(
                                    color: Colors.deepPurpleAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: classesList.map((classe) {
                                final isSelected =
                                selectedClasses.contains(classe);
                                return FilterChip(
                                  label: Text('Niveau $classe',
                                      style: const TextStyle(fontSize: 11)),
                                  selected: isSelected,
                                  selectedColor: Colors.deepPurpleAccent,
                                  backgroundColor:
                                  Colors.deepPurple.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade300),
                                  onSelected: (selected) {
                                    setStateModal(() {
                                      if (selected) {
                                        selectedClasses.add(classe);
                                      } else {
                                        selectedClasses.remove(classe);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    try {
                      final profileId = profile['id'];

                      await Supabase.instance.client
                          .from('profiles')
                          .update({
                        'role': selectedRole,
                        'role_actif': selectedRole,
                        'jour': selectedJour,
                        'classes': selectedClasses,
                      }).eq('id', profileId);

                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Profil mis à jour avec succès !')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')));
                      }
                    }
                  },
                  child: const Text('Enregistrer les modifications',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fenêtre modale pour voir les serviteurs filtrés selon les classes
  void _openServiteursModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Liste des Serviteurs par classe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('profiles')
                      .select()
                      .eq('role', 'Serviteur'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur : ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    final allServiteurs = snapshot.data ?? [];

                    final serviteurs = allServiteurs.where((serviteur) {
                      final servClasses =
                          (serviteur['classes'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                              [];
                      return servClasses.any((c) => _userClasses.contains(c));
                    }).toList();

                    if (serviteurs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun serviteur enregistré pour vos classes.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: serviteurs.length,
                      itemBuilder: (context, index) {
                        final serviteur = serviteurs[index];
                        final nom = serviteur['nom'] ?? '';
                        final prenom = serviteur['prenom'] ?? '';
                        final jour = serviteur['jour'] ?? '';
                        final classes =
                            (serviteur['classes'] as List<dynamic>?)?.join(', ') ?? '';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.deepPurple.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.deepPurpleAccent,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              '$prenom $nom',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            subtitle: Text(
                              'Jour : $jour\nClasse(s) : $classes',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Widget d'affichage des listes regroupées par cycle avec fusion Maternelle + CP
  Widget _buildProfilesByClassList(List<Map<String, dynamic>> profilesList) {
    final Map<String, List<String>> customCycles = {
      'Maternelle + CP': ['PS', 'MS', 'GS', 'CP'],
      'Primaire': ['CE1', 'CE2', 'CM1', 'CM2'],
      'Collège': ['6ème', '5ème', '4ème', '3ème'],
      'Lycée': ['Seconde', 'Première', 'Terminale'],
    };

    final Map<String, List<Map<String, dynamic>>> byCycle = {};
    customCycles.forEach((cycle, _) {
      byCycle[cycle] = [];
    });

    for (var p in profilesList) {
      final classes = (p['classes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [];

      Set<String> matchedCycles = {};
      for (var c in classes) {
        customCycles.forEach((cycle, cycleClasses) {
          if (cycleClasses.contains(c)) {
            matchedCycles.add(cycle);
          }
        });
      }

      for (var cycle in matchedCycles) {
        if (byCycle.containsKey(cycle)) {
          if (!byCycle[cycle]!.contains(p)) {
            byCycle[cycle]!.add(p);
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: customCycles.entries.map((entry) {
        final cycleName = entry.key;
        final persons = byCycle[cycleName] ?? [];
        if (persons.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cycle : $cycleName',
                style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white24, height: 16),
              ...persons.map((p) {
                final nom = p['nom'] ?? '';
                final prenom = p['prenom'] ?? '';
                final tel = p['telephone'] ?? '';
                final dateNaiss = p['date_naissance'] ?? 'Non renseignée';
                final pereConf = p['pere_confesseur'] ?? 'Non renseigné';
                final adresse = p['adresse'] ?? '';
                final ville = p['ville'] ?? '';
                final codePostal = p['code_postal'] ?? '';
                final jour = p['jour'] ?? '';
                final classes = (p['classes'] as List<dynamic>?)?.join(', ') ?? '';
                final photoUrl = p['photo_url'] ?? '';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.deepPurpleAccent,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person,
                                color: Colors.white, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$prenom $nom ${jour.isNotEmpty ? "($jour)" : ""}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                color: Colors.amberAccent, size: 18),
                            tooltip: 'Copier les informations',
                            constraints: const BoxConstraints(),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () => _copyProfileInfo(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded,
                                color: Colors.deepPurpleAccent, size: 18),
                            tooltip: 'Modifier le profil',
                            constraints: const BoxConstraints(),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () =>
                                _openEditProfileModalForChef(context, p),
                          ),
                          if (tel.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.chat_rounded,
                                  color: Colors.greenAccent, size: 18),
                              tooltip: 'Ouvrir WhatsApp',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              onPressed: () => _openWhatsApp(tel),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Classes : $classes',
                        style: const TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                          Icons.phone_outlined, 'Téléphone : $tel'),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.cake_outlined,
                          'Date de naissance : $dateNaiss'),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.church_rounded,
                          'Abouna confesseur : $pereConf',
                          maxLines: 2),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.home_outlined,
                          'Adresse :\n$adresse\n$ville ($codePostal)',
                          maxLines: 3),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
            child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }

    final bool isChefEglise = _roleUser.toLowerCase().contains('chef d');
    final bool isAdjointChef = _roleUser.toLowerCase().contains('adjoint');

    final bool hasFullAdminRights = isChefEglise || (isAdjointChef && _roleActif.toLowerCase().contains('adjoint'));
    final bool canSwitchRole = isAdjointChef && !isChefEglise;

    final Stream<List<Map<String, dynamic>>> childrenStream = Supabase
        .instance.client
        .from('enfants')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_prenomUser.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Bonjour $_prenomUser${_roleActif.isNotEmpty ? " \n($_roleActif)" : ""}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurpleAccent,
                                      letterSpacing: 0.2,
                                      height: 1.25,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                if (canSwitchRole) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showRoleSwitchModal(context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent
                                            .withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.deepPurpleAccent
                                                .withOpacity(0.6)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.swap_horiz_rounded,
                                              size: 14,
                                              color: Colors.amberAccent),
                                          SizedBox(width: 3),
                                          Text(
                                            'Changer rôle',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          const Text(
                            'Eftekad',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Image.asset(
                            'assets/image/logo1.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Image.asset(
                            'assets/image/logo.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.settings,
                                      color: Colors.white, size: 26),
                                  tooltip: 'Paramètres',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const ParametresScreen(),
                                      ),
                                    );
                                    _loadUserData();
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.logout_rounded,
                                      color: Colors.amberAccent, size: 24),
                                  tooltip: 'Se déconnecter',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: _signOut,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _updateUserProfilePhoto,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.deepPurpleAccent
                                    .withOpacity(0.3),
                                backgroundImage: (_userPhotoUrl != null &&
                                    _userPhotoUrl!.isNotEmpty)
                                    ? NetworkImage(
                                    '$_userPhotoUrl?v=${DateTime.now().millisecondsSinceEpoch}')
                                    : null,
                                child: (_userPhotoUrl == null ||
                                    _userPhotoUrl!.isEmpty)
                                    ? const Icon(Icons.person,
                                    color: Colors.white, size: 16)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'St Mina, St Mercure & St Pape Cyrille VI, Église Copte Orthodoxe, Colombes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
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
                const SizedBox(height: 20),

                if (hasFullAdminRights) ...[
                  const SizedBox(height: 8),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('profiles')
                        .stream(primaryKey: ['id']).order('created_at',
                        ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Erreur de chargement : ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        );
                      }

                      final profiles = snapshot.data ?? [];

                      // 1. Liste des Serviteurs
                      final List<Map<String, dynamic>> serviteurs = profiles
                          .where((p) => (p['role'] ?? '') == 'Serviteur')
                          .toList();

                      // 2. Liste des Responsables de famille (exclut les adjoints)
                      final List<Map<String, dynamic>> responsables = profiles
                          .where((p) =>
                      (p['role'] ?? '').toString().contains('Responsable') &&
                          !(p['role'] ?? '').toString().toLowerCase().contains('adjoint'))
                          .toList();

                      // 3. Liste des Adjoints chef (uniquement pour le Chef d'église principal)
                      final List<Map<String, dynamic>> adjoints = isChefEglise
                          ? profiles
                          .where((p) =>
                          (p['role'] ?? '').toString().toLowerCase().contains('adjoint'))
                          .toList()
                          : [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Liste des Serviteurs par cycle',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          serviteurs.isEmpty
                              ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                                child: Text(
                                    'Aucun serviteur enregistré.',
                                    style:
                                    TextStyle(color: Colors.grey))),
                          )
                              : _buildProfilesByClassList(serviteurs),
                          const SizedBox(height: 28),
                          const Text(
                            'Liste des Responsables de famille par cycle',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          responsables.isEmpty
                              ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                                child: Text(
                                    'Aucun responsable de famille enregistré.',
                                    style:
                                    TextStyle(color: Colors.grey))),
                          )
                              : _buildProfilesByClassList(responsables),
                          if (isChefEglise) ...[
                            const SizedBox(height: 28),
                            const Text(
                              'Liste des Adjoints chef par cycle',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            adjoints.isEmpty
                                ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                  child: Text(
                                      'Aucun adjoint chef enregistré.',
                                      style:
                                      TextStyle(color: Colors.grey))),
                            )
                                : _buildProfilesByClassList(adjoints),
                          ],
                        ],
                      );
                    },
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _openAddChildModal(context),
                    icon: const Icon(Icons.person_add_rounded, size: 22),
                    label: const Text(
                      'Inscrire un enfant ou jeune',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  if (_roleActif.toLowerCase().contains('responsable')) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openServiteursModal(context),
                      icon: const Icon(Icons.group_rounded,
                          color: Colors.deepPurpleAccent, size: 22),
                      label: const Text(
                        'Voir les serviteurs par classe',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: Colors.deepPurpleAccent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Enfants ou Jeunes inscrits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: childrenStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
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

                      final rawChildren = snapshot.data ?? [];

                      final children = rawChildren.where((child) {
                        final childNiveau =
                            (child['niveau_classe'] as String?) ?? '';

                        bool matchClass = false;
                        for (final c in _userClasses) {
                          if (childNiveau.endsWith(c) ||
                              childNiveau.contains(' $c ')) {
                            matchClass = true;
                            break;
                          }
                        }

                        return matchClass;
                      }).toList();

                      if (children.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.child_care_rounded,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aucun enfant inscrit pour vos classes attribuées.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15),
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
                          final niveau =
                              child['niveau_classe'] ?? 'Non renseigné';
                          final telephone = child['telephone'] ?? '';
                          final adresse = child['adresse'] ?? '';
                          final ville = child['ville'] ?? '';
                          final codePostal = child['code_postal'] ?? '';

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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.1),
                                                width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.grey[800],
                                            child: photoUrl != null &&
                                                photoUrl.isNotEmpty
                                                ? ClipOval(
                                              child: Image.network(
                                                '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context,
                                                    error, stackTrace) {
                                                  return const Icon(
                                                      Icons.person,
                                                      color:
                                                      Colors.white);
                                                },
                                              ),
                                            )
                                                : const Icon(Icons.person,
                                                color: Colors.white,
                                                size: 30),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                      padding:
                                      EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(height: 1),
                                    ),
                                    _buildInfoRow(Icons.cake_outlined,
                                        'Né(e) le : ${child['date_naissance'] ?? ''}'),
                                    const SizedBox(height: 6),
                                    _buildInfoRow(Icons.home_outlined,
                                        'Adresse :\n$adresse\n$ville ($codePostal)',
                                        maxLines: 3),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoRow(
                                              Icons.phone_outlined,
                                              'Tél : $telephone'),
                                        ),
                                        if (telephone.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.chat_rounded,
                                                color: Colors.deepPurpleAccent,
                                                size: 20),
                                            tooltip: 'Ouvrir WhatsApp',
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            onPressed: () =>
                                                _openWhatsApp(telephone),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _openAddChildModal(
                                              context,
                                              childData: child),
                                          icon: const Icon(Icons.edit_rounded,
                                              size: 16),
                                          label: const Text('Modifier'),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity:
                                            VisualDensity.compact,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        16)),
                                                title: const Text(
                                                    'Confirmer la suppression'),
                                                content: const Text(
                                                    'Voulez-vous vraiment supprimer cet enfant ?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child:
                                                    const Text('Annuler'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _deleteChild(child['id']
                                                          .toString());
                                                    },
                                                    child: const Text(
                                                        'Supprimer',
                                                        style: TextStyle(
                                                            color: Colors.red,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: Colors.redAccent),
                                          label: const Text('Supprimer',
                                              style: TextStyle(
                                                  color: Colors.redAccent)),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity:
                                            VisualDensity.compact,
                                            side: BorderSide(
                                                color: Colors.redAccent
                                                    .withOpacity(0.5)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8)),
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

  Uint8List? _imageBytes;
  String? _selectedDay;
  String? _selectedCycle;
  String? _selectedLevel;
  bool _isLoading = false;

  String? _selectedBirthDay;
  String? _selectedBirthMonth;
  String? _selectedBirthYear;

  final List<String> _daysList = ['Samedi', 'Dimanche'];

  final List<String> _birthDaysList =
  List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _birthMonthsList = [
    '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'
  ];
  final List<String> _birthYearsList =
  List.generate(100, (index) => (2000 + index).toString());

  final Map<String, List<String>> _allClassesParCycle = {
    'Maternelle': ['PS', 'MS', 'GS'],
    'Primaire': ['CP', 'CE1', 'CE2', 'CM1', 'CM2'],
    'Collège': ['6ème', '5ème', '4ème', '3ème'],
    'Lycée': ['Seconde', 'Première', 'Terminale'],
  };

  Map<String, List<String>> _classesParCycle = {};
  List<String> _cyclesList = [];

  String _getCycleForClass(String classe) {
    if (['PS', 'MS', 'GS'].contains(classe)) return 'Maternelle';
    if (['CP', 'CE1', 'CE2', 'CM1', 'CM2'].contains(classe)) return 'Primaire';
    if (['6ème', '5ème', '4ème', '3ème'].contains(classe)) return 'Collège';
    if (['Seconde', 'Première', 'Terminale'].contains(classe)) return 'Lycée';
    return '';
  }

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.childData?['nom'] ?? '');
    _prenomController =
        TextEditingController(text: widget.childData?['prenom'] ?? '');
    _adresseController =
        TextEditingController(text: widget.childData?['adresse'] ?? '');
    _villeController =
        TextEditingController(text: widget.childData?['ville'] ?? '');
    _codePostalController =
        TextEditingController(text: widget.childData?['code_postal'] ?? '');

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

    _loadUserContextForAddForm();
  }

  Future<void> _loadUserContextForAddForm() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        final metadata = user.userMetadata ?? {};
        final userJour = response?['jour'] ?? metadata['jour'];

        List<String> userClasses = [];
        if (response?['classes'] != null) {
          userClasses = (response!['classes'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        } else if (metadata['classes'] != null) {
          userClasses = List<String>.from(metadata['classes']);
        }

        if (mounted) {
          setState(() {
            if (userJour != null && _daysList.contains(userJour)) {
              _selectedDay = userJour;
            }

            if (userClasses.isNotEmpty) {
              final Map<String, List<String>> filteredMap = {};
              _allClassesParCycle.forEach((cycle, classes) {
                final matching =
                classes.where((c) => userClasses.contains(c)).toList();
                if (matching.isNotEmpty) {
                  filteredMap[cycle] = matching;
                }
              });
              _classesParCycle =
              filteredMap.isNotEmpty ? filteredMap : _allClassesParCycle;
            } else {
              _classesParCycle = _allClassesParCycle;
            }
            _cyclesList = _classesParCycle.keys.toList();

            final niveauClasse =
            widget.childData?['niveau_classe'] as String?;
            if (niveauClasse != null && niveauClasse.isNotEmpty) {
              final parts = niveauClasse.split(' ');
              if (parts.isNotEmpty && _daysList.contains(parts[0])) {
                _selectedDay = parts[0];
                if (parts.length > 1) {
                  String rest = parts.sublist(1).join(' ').trim();
                  String foundCycle = '';
                  String foundClass = rest;

                  for (var cycle in _allClassesParCycle.keys) {
                    if (rest.startsWith(cycle)) {
                      foundCycle = cycle;
                      foundClass = rest.replaceFirst(cycle, '').trim();
                      break;
                    }
                  }

                  if (foundCycle.isEmpty) {
                    foundCycle = _getCycleForClass(foundClass);
                  }

                  if (_cyclesList.contains(foundCycle)) {
                    _selectedCycle = foundCycle;
                    if (_classesParCycle[foundCycle]!.contains(foundClass)) {
                      _selectedLevel = foundClass;
                    }
                  }
                }
              }
            } else {
              if (_cyclesList.length == 1) {
                _selectedCycle = _cyclesList.first;
                if (_classesParCycle[_selectedCycle]!.length == 1) {
                  _selectedLevel = _classesParCycle[_selectedCycle]!.first;
                }
              }
            }
          });
        }
      }
    } catch (_) {}
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
              leading: const Icon(Icons.photo_camera_rounded,
                  color: Colors.deepPurpleAccent),
              title: const Text('Prendre une photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Colors.deepPurpleAccent),
              title: const Text('Choisir dans la galerie',
                  style: TextStyle(color: Colors.white)),
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
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDay == null ||
        _selectedBirthMonth == null ||
        _selectedBirthYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de naissance complète'),
        ),
      );
      return;
    }
    if (_selectedDay == null ||
        _selectedCycle == null ||
        _selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez sélectionner le jour, le cycle et le niveau de classe'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = widget.childData?['photo_url'];

      if (_imageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'children_photos/$fileName';

        await Supabase.instance.client.storage
            .from('photos')
            .uploadBinary(path, _imageBytes!);

        photoUrl = Supabase.instance.client.storage
            .from('photos')
            .getPublicUrl(path);
      }

      final fullClassLevel = '$_selectedDay $_selectedCycle $_selectedLevel';
      final formattedBirthDate =
          '$_selectedBirthDay/$_selectedBirthMonth/$_selectedBirthYear';

      String rawPhone = _telephoneController.text.trim();
      String cleanPhone = rawPhone.replaceAll(' ', '');

      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+33$cleanPhone';
      }

      final now = DateTime.now();
      final currentAcademicYear = now.month >= 9 ? now.year : now.year - 1;

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
        'derniere_annee_promotion': currentAcademicYear,
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
            content: Text(widget.childData == null
                ? 'Inscription réussie !'
                : 'Modifications enregistrées !'),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
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
                isEditing
                    ? 'Modifier Enfant / Jeune'
                    : 'Inscription Enfant ou Jeune',
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
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : (widget.childData?['photo_url'] != null &&
                            widget.childData!['photo_url'].isNotEmpty
                            ? NetworkImage(widget.childData!['photo_url'])
                        as ImageProvider
                            : null),
                        child: (_imageBytes == null &&
                            (widget.childData?['photo_url'] == null ||
                                widget.childData!['photo_url'].isEmpty))
                            ? const Icon(Icons.add_a_photo_rounded,
                            size: 26, color: Colors.white70)
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
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 12, color: Colors.white),
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
                  labelStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.person_rounded,
                      color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prenomController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Prénom',
                  labelStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? 'Champ requis' : null,
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
                        labelStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.cake_rounded,
                            color: Colors.deepPurpleAccent, size: 18),
                        prefixIconConstraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: _birthDaysList
                          .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(day,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBirthDay = val),
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
                        labelStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: _birthMonthsList
                          .map((month) => DropdownMenuItem(
                          value: month,
                          child: Text(month,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBirthMonth = val),
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
                        labelStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: _birthYearsList
                          .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBirthYear = val),
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
                  labelStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.home_rounded,
                      color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (val) =>
                val == null || val.isEmpty ? 'Champ requis' : null,
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
                        labelStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.location_city_rounded,
                            color: Colors.deepPurpleAccent, size: 20),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Requis' : null,
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
                        labelStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'Requis' : null,
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
                  labelStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.phone_rounded,
                      color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  helperText: 'Exemple : +3306... ou +3307...',
                  helperStyle:
                  TextStyle(color: Colors.amber.shade200, fontSize: 10),
                  helperMaxLines: 2,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty || val == '+33') {
                    return 'Veuillez entrer le numéro';
                  }
                  final clean = val.replaceAll(' ', '');
                  if (!clean.startsWith('+3306') &&
                      !clean.startsWith('+3307')) {
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
                  labelStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.calendar_today_rounded,
                      color: Colors.deepPurpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.deepPurple.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Colors.deepPurpleAccent, width: 2)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: _daysList
                    .map((day) => DropdownMenuItem(
                    value: day,
                    child: Text(day,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDay = val;
                  });
                },
                validator: (val) => val == null ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      value: _selectedCycle,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Cycle',
                        labelStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.category_rounded,
                            color: Colors.deepPurpleAccent, size: 20),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: _cyclesList
                          .map((cycle) => DropdownMenuItem(
                          value: cycle,
                          child: Text(cycle,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCycle = val;
                          _selectedLevel = null;
                        });
                      },
                      validator: (val) => val == null ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      value: _selectedLevel,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Classe',
                        labelStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.school_rounded,
                            color: Colors.deepPurpleAccent, size: 20),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: _selectedCycle == null ||
                          !_classesParCycle.containsKey(_selectedCycle)
                          ? []
                          : _classesParCycle[_selectedCycle]!
                          .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: _selectedCycle == null
                          ? null
                          : (val) => setState(() => _selectedLevel = val),
                      validator: (val) => val == null ? 'Requis' : null,
                    ),
                  ),
                ],
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  isEditing ? 'Mettre à jour' : 'Enregistrer',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
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

    if (text.isEmpty) {
      return const TextEditingValue(
        text: '+33',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    if (!text.startsWith('+33')) {
      if (text.startsWith('0')) {
        text = '+33$text';
      } else {
        text = '+33$text';
      }
    }

    if (text.allMatches('+33').length > 1) {
      text = '+33${text.replaceAll('+33', '')}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}