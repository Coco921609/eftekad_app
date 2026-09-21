import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eftekad',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const EnfantsScreen(),
    );
  }
}

class EnfantsScreen extends StatefulWidget {
  const EnfantsScreen({super.key});

  @override
  State<EnfantsScreen> createState() => _EnfantsScreenState();
}

class _EnfantsScreenState extends State<EnfantsScreen> {
  final Stream<List<Map<String, dynamic>>> _childrenStream = Supabase
      .instance.client
      .from('enfants')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  @override
  void initState() {
    super.initState();
    _checkAndApplySeptemberPromotion();
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

          if (fullLevel != null && fullLevel.isNotEmpty && lastPromotedYear < currentAcademicYear) {
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
    } catch (_) {
      // Gestion silencieuse
    }
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

  /// Calcule la classe supérieure en conservant le jour et ajustant le cycle si besoin
  String _getPromotedClassLevel(String currentFullLevel) {
    final parts = currentFullLevel.split(' ');
    if (parts.length < 2) return currentFullLevel;

    final String day = parts[0]; // Samedi ou Dimanche
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

    // MATERNELLE
    if (level == 'PS') {
      newLevel = 'MS';
      newCycle = 'Maternelle';
    } else if (level == 'MS') {
      newLevel = 'GS';
      newCycle = 'Maternelle';
    } else if (level == 'GS') {
      newLevel = 'CP';
      newCycle = 'Primaire';
    }
    // PRIMAIRE
    else if (level == 'CP') {
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
    }
    // COLLÈGE
    else if (level == '6ème') {
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
    }
    // LYCÉE
    else if (level == 'Seconde') {
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

  void _navigateToDay(BuildContext context, String day) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            JourEnfantsScreen(day: day, childrenStream: _childrenStream),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                              color: Colors.white,
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
                    Image.asset(
                      'assets/image/logo1.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Jours de Catéchiste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vous cliquez sur samedi, dimanche ou les deux pour faire l\'appel des enfants ou des jeunes selon les jours du caté.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToDay(context, 'Samedi'),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today_rounded, size: 22),
                      SizedBox(width: 14),
                      Text(
                        'Samedi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _navigateToDay(context, 'Dimanche'),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today_rounded, size: 22),
                      SizedBox(width: 14),
                      Text(
                        'Dimanche',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _navigateToDay(context, 'Les deux'),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today_rounded, size: 22),
                      SizedBox(width: 14),
                      Text(
                        'Les deux',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 520,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/marie',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/image/marie.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context2, error2, stackTrace2) {
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JourEnfantsScreen extends StatefulWidget {
  final String day;
  final Stream<List<Map<String, dynamic>>> childrenStream;

  const JourEnfantsScreen({super.key, required this.day, required this.childrenStream});

  @override
  State<JourEnfantsScreen> createState() => _JourEnfantsScreenState();
}

class _JourEnfantsScreenState extends State<JourEnfantsScreen> {
  late int _selectedMonthIndex;
  late int _selectedYear;

  final List<String> _monthsNames = [
    'Tous les mois',
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthIndex = now.month;
    _selectedYear = now.year < 2026 ? 2026 : (now.year > 2099 ? 2099 : now.year);
  }

  List<int> get _availableYears {
    return List.generate(2099 - 2026 + 1, (index) => 2026 + index);
  }

  DateTime? _parseDate(dynamic dateVal) {
    if (dateVal == null) return null;
    if (dateVal is DateTime) return dateVal;
    final str = dateVal.toString().trim();
    final parts = str.split(RegExp(r'[/.-]'));
    if (parts.length >= 3) {
      if (parts[0].length == 4) {
        int? y = int.tryParse(parts[0]);
        int? m = int.tryParse(parts[1]);
        int? d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      } else {
        int? d = int.tryParse(parts[0]);
        int? m = int.tryParse(parts[1]);
        int? y = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      }
    }
    return DateTime.tryParse(str);
  }

  List<dynamic> _filterDatesByMonthAndYear(List<dynamic> dates, int monthIndex, int year) {
    return dates.where((d) {
      final parsed = _parseDate(d);
      if (parsed == null) return false;
      if (parsed.year != year) return false;
      if (monthIndex == 0) return true;
      return parsed.month == monthIndex;
    }).toList();
  }

  Future<void> _updateStatut(Map<String, dynamic> profile, String dateStr, String type) async {
    try {
      List<dynamic> currentAbsences = List.from(profile['dates_absence'] ?? []);
      List<dynamic> currentPresences = List.from(profile['dates_presence'] ?? []);

      if (type == 'absence') {
        if (currentAbsences.contains(dateStr)) {
          currentAbsences.remove(dateStr);
        } else {
          currentAbsences.add(dateStr);
          currentPresences.remove(dateStr);
        }
      } else if (type == 'presence') {
        if (currentPresences.contains(dateStr)) {
          currentPresences.remove(dateStr);
        } else {
          currentPresences.add(dateStr);
          currentAbsences.remove(dateStr);
        }
      }

      await Supabase.instance.client
          .from('profiles')
          .update({
        'dates_absence': currentAbsences,
        'dates_presence': currentPresences,
      })
          .eq('id', profile['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mise à jour effectuée avec succès !'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showStatutDialog(BuildContext context, Map<String, dynamic> profile, String type) {
    final now = DateTime.now();
    final targetMonth = _selectedMonthIndex == 0 ? now.month : _selectedMonthIndex;
    final targetYear = _selectedYear;

    final currentDay = now.day;
    final maxDaysInMonth = DateUtils.getDaysInMonth(targetYear, targetMonth);
    final safeDay = currentDay > maxDaysInMonth ? maxDaysInMonth : currentDay;

    DateTime selectedDate = DateTime(targetYear, targetMonth, safeDay);
    final isAbsence = type == 'absence';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dayStr = selectedDate.day.toString().padLeft(2, '0');
            final monthStr = selectedDate.month.toString().padLeft(2, '0');
            final yearStr = selectedDate.year.toString();
            final formattedDate = "$dayStr/$monthStr/$yearStr";

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isAbsence ? 'Gérer l\'absence : ${profile['prenom'] ?? ''}' : 'Gérer la présence : ${profile['prenom'] ?? ''}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAbsence ? 'Sélectionner la date d\'absence :' : 'Sélectionner la date de présence :'),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2026),
                        lastDate: DateTime(2099, 12, 31),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade900,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Icon(Icons.calendar_month_rounded, color: Colors.deepPurpleAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAbsence ? Colors.red.shade900 : Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _updateStatut(profile, formattedDate, type);
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showModifierDialog(BuildContext context, Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modifier / Corriger : ${profile['prenom'] ?? ''}'),
        content: const SingleChildScrollView(
          child: Text('Si vous vous êtes trompé entre absence et présence, choisissez l\'action à corriger :'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              _showStatutDialog(context, profile, 'presence');
            },
            child: const Text('Mettre Présent(e)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _showStatutDialog(context, profile, 'absence');
            },
            child: const Text('Mettre Absent(e)'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesSection(String title, List<Map<String, dynamic>> profilesList) {
    if (profilesList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.only(top: 10, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${profilesList.length} personne(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        ...profilesList.map((profile) {
          final photoUrl = profile['photo_url'] as String?;
          final rawAbsences = List<dynamic>.from(profile['dates_absence'] ?? []);
          final rawPresences = List<dynamic>.from(profile['dates_presence'] ?? []);

          final absences = _filterDatesByMonthAndYear(rawAbsences, _selectedMonthIndex, _selectedYear);
          final presences = _filterDatesByMonthAndYear(rawPresences, _selectedMonthIndex, _selectedYear);

          final telephone = profile['telephone'] ?? '';
          final role = profile['role'] ?? 'Serviteur';
          final classes = profile['classes'] != null ? (profile['classes'] as List).join(', ') : 'Aucune classe';

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
                            border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[800],
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? ClipOval(
                              child: Image.network(
                                '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, color: Colors.white, size: 40);
                                },
                                loadingBuilder: (context, childWidget, loadingProgress) {
                                  if (loadingProgress == null) return childWidget;
                                  return const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                },
                              ),
                            )
                                : const Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile['prenom'] ?? ''} ${profile['nom'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 0.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rôle : $role',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Classes : $classes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tél : ${telephone.isNotEmpty ? telephone : 'Non renseigné'}',
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
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showStatutDialog(context, profile, 'absence'),
                          icon: const Icon(Icons.event_busy, size: 14),
                          label: const Text('Absence', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900.withOpacity(0.7),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showStatutDialog(context, profile, 'presence'),
                          icon: const Icon(Icons.check_circle, size: 14),
                          label: const Text('Présent(e)', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showModifierDialog(context, profile),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      absences.isEmpty
                          ? 'Aucune absence enregistrée'
                          : 'Absences : ${absences.join(", ")}',
                      color: absences.isEmpty ? Colors.grey : Colors.redAccent,
                      fontWeight: absences.isEmpty ? FontWeight.normal : FontWeight.bold,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      Icons.check_circle_outline,
                      presences.isEmpty
                          ? 'Aucune présence enregistrée'
                          : 'Présences : ${presences.join(", ")}',
                      color: presences.isEmpty ? Colors.grey : Colors.greenAccent,
                      fontWeight: presences.isEmpty ? FontWeight.normal : FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('profiles')
              .stream(primaryKey: ['id'])
              .order('nom', ascending: true),
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

            final profiles = snapshot.data ?? [];
            final filteredProfiles = profiles.where((p) {
              final role = (p['role'] ?? '').toString().toLowerCase();
              if (role.contains('chef d')) return false;

              if (widget.day == 'Les deux') return true;
              final pJour = (p['jour'] ?? '').toString();
              return pJour.toLowerCase().contains(widget.day.toLowerCase());
            }).toList();

            // 1. Liste des Serviteurs
            final serviteurs = filteredProfiles
                .where((p) => (p['role'] ?? '') == 'Serviteur')
                .toList();

            // 2. Liste des Responsables de famille (contient "Responsable", sans être adjoint)
            final responsables = filteredProfiles
                .where((p) =>
            (p['role'] ?? '').toString().toLowerCase().contains('responsable') &&
                !(p['role'] ?? '').toString().toLowerCase().contains('adjoint'))
                .toList();

            // 3. Liste des Adjoints chef (contient "Adjoint")
            final adjoints = filteredProfiles
                .where((p) =>
                (p['role'] ?? '').toString().toLowerCase().contains('adjoint'))
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Serviteurs / Responsables - ${widget.day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              isExpanded: true,
                              dropdownColor: Colors.grey.shade900,
                              items: _availableYears.map((y) {
                                return DropdownMenuItem<int>(
                                  value: y,
                                  child: Text(
                                    '$y',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedYear = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedMonthIndex,
                              isExpanded: true,
                              dropdownColor: Colors.grey.shade900,
                              icon: const Icon(Icons.folder_special, color: Colors.deepPurpleAccent, size: 20),
                              items: List.generate(_monthsNames.length, (index) {
                                return DropdownMenuItem<int>(
                                  value: index,
                                  child: Text(
                                    index == 0 ? 'Tous les mois' : _monthsNames[index],
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedMonthIndex = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  if (filteredProfiles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun profil trouvé pour le ${widget.day}.',
                              style: const TextStyle(color: Colors.grey, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _buildProfilesSection('Liste des Serviteurs', serviteurs),
                    const SizedBox(height: 16),
                    _buildProfilesSection('Liste des Responsables de famille', responsables),
                    const SizedBox(height: 16),
                    _buildProfilesSection('Liste des Adjoints chef', adjoints),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1, Color? color, FontWeight? fontWeight}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 15, color: color ?? Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey.shade300,
              fontWeight: fontWeight ?? FontWeight.normal,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}