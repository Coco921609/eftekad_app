import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BilanScreen extends StatefulWidget {
  const BilanScreen({super.key});

  @override
  State<BilanScreen> createState() => _BilanScreenState();
}

class _BilanScreenState extends State<BilanScreen> {
  String _selectedDay = 'Samedi';
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

  final Stream<List<Map<String, dynamic>>> _childrenStream = Supabase
      .instance.client
      .from('enfants')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthIndex = 0; // 0 = Tous les mois par défaut
    _selectedYear = now.year < 2026 ? 2026 : (now.year > 2099 ? 2099 : now.year);
    _checkAndApplySeptemberPromotion();
  }

  /// Vérifie et applique le passage automatique de classe en rentrée de septembre
  Future<void> _checkAndApplySeptemberPromotion() async {
    try {
      final now = DateTime.now();
      // On détermine l'année scolaire de rentrée (ex: septembre 2026 -> 2026, janvier 2027 -> 2026)
      final int currentAcademicYear = now.month >= 9 ? now.year : now.year - 1;

      final response = await Supabase.instance.client.from('enfants').select();
      if (response == null) return;

      final List<dynamic> children = response as List<dynamic>;

      for (var child in children) {
        final id = child['id'];
        final String? fullLevel = child['niveau_classe'];
        final int lastPromotedYear = child['derniere_annee_promotion'] ?? 0;

        // Si l'enfant n'a pas encore été promu pour l'année scolaire actuelle
        if (fullLevel != null && fullLevel.isNotEmpty && lastPromotedYear < currentAcademicYear) {
          final String newLevel = _getPromotedClassLevel(fullLevel);

          if (newLevel != fullLevel) {
            await Supabase.instance.client.from('enfants').update({
              'niveau_classe': newLevel,
              'derniere_annee_promotion': currentAcademicYear,
            }).eq('id', id);
          } else {
            // Même si pas de changement de classe (ex: déjà en Terminale), on met à jour l'année de vérification
            await Supabase.instance.client.from('enfants').update({
              'derniere_annee_promotion': currentAcademicYear,
            }).eq('id', id);
          }
        }
      }
    } catch (_) {
      // Traitement silencieux
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

  Widget _buildDaySection(String dayName, List<Map<String, dynamic>> children) {
    final filteredChildren = children.where((child) {
      final niveauClasse = child['niveau_classe'] as String? ?? '';
      return niveauClasse.startsWith(dayName);
    }).toList();

    if (filteredChildren.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Aucun enfant ou jeune inscrit pour le $dayName.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final Map<String, List<Map<String, dynamic>>> levelsMap = {};
    for (var child in filteredChildren) {
      final niveauClasse = child['niveau_classe'] as String? ?? '';
      final parts = niveauClasse.split(' ');
      String level = parts.length > 1 ? parts.sublist(1).join(' ') : 'Non renseigné';

      levelsMap.putIfAbsent(level, () => []);
      levelsMap[level]!.add(child);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: levelsMap.entries.map((levelEntry) {
        final levelName = levelEntry.key;
        final levelChildren = levelEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Niveau : $levelName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  Text(
                    '${levelChildren.length} enfant(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: levelChildren.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final child = levelChildren[index];
                  final prenom = child['prenom'] ?? '';
                  final nom = child['nom'] ?? '';
                  final photoUrl = child['photo_url'] as String?;
                  final rawAbsences = List<dynamic>.from(child['dates_absence'] ?? []);
                  final rawPresences = List<dynamic>.from(child['dates_presence'] ?? []);
                  final justifsMap = Map<String, dynamic>.from(child['justificatifs_absence'] ?? {});

                  final absences = _filterDatesByMonthAndYear(rawAbsences, _selectedMonthIndex, _selectedYear);
                  final presences = _filterDatesByMonthAndYear(rawPresences, _selectedMonthIndex, _selectedYear);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[800],
                                child: photoUrl != null && photoUrl.isNotEmpty
                                    ? ClipOval(
                                  child: Image.network(
                                    '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, color: Colors.white, size: 20);
                                    },
                                    loadingBuilder: (context, childWidget, loadingProgress) {
                                      if (loadingProgress == null) return childWidget;
                                      return const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      );
                                    },
                                  ),
                                )
                                    : const Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$prenom $nom',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Présences : ${presences.length}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Absences : ${absences.length}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Affichage direct des absences et de leurs justificatifs
                        if (absences.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Justificatifs d\'absence :',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...absences.map((dateObj) {
                                  final dateStr = dateObj.toString();
                                  final justifText = justifsMap[dateStr]?.toString() ?? '';
                                  final hasJustif = justifText.isNotEmpty;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                        ),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '$dateStr : ',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: hasJustif ? justifText : 'Non justifié',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: hasJustif ? FontStyle.italic : FontStyle.normal,
                                                    color: hasJustif ? Colors.amber.shade200 : Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTotalSummarySection(List<Map<String, dynamic>> children) {
    final filteredChildren = children.where((child) {
      final niveauClasse = child['niveau_classe'] as String? ?? '';
      return niveauClasse.startsWith(_selectedDay);
    }).toList();

    int totalYearPresences = 0;
    int totalYearAbsences = 0;

    Map<int, int> monthlyPresences = {for (int i = 1; i <= 12; i++) i: 0};
    Map<int, int> monthlyAbsences = {for (int i = 1; i <= 12; i++) i: 0};

    for (var child in filteredChildren) {
      final rawPresences = List<dynamic>.from(child['dates_presence'] ?? []);
      final rawAbsences = List<dynamic>.from(child['dates_absence'] ?? []);

      final presences = _filterDatesByMonthAndYear(rawPresences, 0, _selectedYear);
      final absences = _filterDatesByMonthAndYear(rawAbsences, 0, _selectedYear);

      totalYearPresences += presences.length;
      totalYearAbsences += absences.length;

      for (var p in presences) {
        final parsed = _parseDate(p);
        if (parsed != null && parsed.month >= 1 && parsed.month <= 12) {
          monthlyPresences[parsed.month] = (monthlyPresences[parsed.month] ?? 0) + 1;
        }
      }

      for (var a in absences) {
        final parsed = _parseDate(a);
        if (parsed != null && parsed.month >= 1 && parsed.month <= 12) {
          monthlyAbsences[parsed.month] = (monthlyAbsences[parsed.month] ?? 0) + 1;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Total Général $_selectedYear - $_selectedDay',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bilan Total Annuel ($_selectedYear)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                    Text(
                      '${filteredChildren.length} enfant(s)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Présences',
                              style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalYearPresences',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Absences',
                              style: TextStyle(fontSize: 12, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalYearAbsences',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            title: Text(
              'Sous-dossiers Totaux par Mois ($_selectedYear)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurpleAccent,
              ),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: List.generate(12, (index) {
              int monthNum = index + 1;
              String monthName = _monthsNames[monthNum];
              int pCount = monthlyPresences[monthNum] ?? 0;
              int aCount = monthlyAbsences[monthNum] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        monthName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Présences : $pCount',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Absences : $aCount',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _childrenStream,
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

            final children = snapshot.data ?? [];

            return SingleChildScrollView(
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
                      'Bilan Récapitulatif Mensuel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Clôture du 28 et 29 février selon l\'année, 30 ou 31 selon les mois. Si la fin de mois ne tombe pas un samedi ou un dimanche, réunion par WhatsApp avec les responsables de famille selon le niveau de classe.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDay = 'Samedi';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedDay == 'Samedi'
                                  ? Colors.deepPurple
                                  : Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Samedi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDay = 'Dimanche';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedDay == 'Dimanche'
                                  ? Colors.deepPurple
                                  : Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Dimanche',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filtres Année et Mois alignés côte à côte
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
                    const SizedBox(height: 8),
                    _buildDaySection(_selectedDay, children),
                    _buildTotalSummarySection(children),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}