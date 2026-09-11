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
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vous cliquez sur samedi et dimanche pour faire l\'appel des enfants ou des jeunes selon les jours du caté.',
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
                const SizedBox(height: 24),
                SizedBox(
                  height: 520,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/image/marie.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
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

  Future<void> _updateStatut(Map<String, dynamic> child, String dateStr, String type) async {
    try {
      List<dynamic> currentAbsences = List.from(child['dates_absence'] ?? []);
      List<dynamic> currentPresences = List.from(child['dates_presence'] ?? []);

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
          .from('enfants')
          .update({
        'dates_absence': currentAbsences,
        'dates_presence': currentPresences,
      })
          .eq('id', child['id']);

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

  void _showStatutDialog(BuildContext context, Map<String, dynamic> child, String type) {
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
              title: Text(isAbsence ? 'Gérer l\'absence : ${child['prenom'] ?? ''}' : 'Gérer la présence : ${child['prenom'] ?? ''}'),
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
                    _updateStatut(child, formattedDate, type);
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

  void _showModifierDialog(BuildContext context, Map<String, dynamic> child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modifier / Corriger : ${child['prenom'] ?? ''}'),
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
              _showStatutDialog(context, child, 'presence');
            },
            child: const Text('Mettre Présent(e)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _showStatutDialog(context, child, 'absence');
            },
            child: const Text('Mettre Absent(e)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.childrenStream,
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
            final filteredChildren = children.where((child) {
              final niveauClasse = child['niveau_classe'] as String? ?? '';
              return niveauClasse.startsWith(widget.day);
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Catéchiste - ${widget.day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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

                  if (filteredChildren.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.child_care_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun enfant ou jeune inscrit pour le ${widget.day}.',
                              style: const TextStyle(color: Colors.grey, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...() {
                    final Map<String, List<Map<String, dynamic>>> levelsMap = {};
                    for (var child in filteredChildren) {
                      final niveauClasse = child['niveau_classe'] as String? ?? '';
                      final parts = niveauClasse.split(' ');
                      String level = parts.length > 1 ? parts.sublist(1).join(' ') : 'Non renseigné';

                      levelsMap.putIfAbsent(level, () => []);
                      levelsMap[level]!.add(child);
                    }

                    return levelsMap.entries.map((levelEntry) {
                      final levelName = levelEntry.key;
                      final levelChildren = levelEntry.value;

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
                            child: Text(
                              'Niveau : $levelName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                          ),
                          ...levelChildren.map((child) {
                            final photoUrl = child['photo_url'] as String?;
                            final rawAbsences = List<dynamic>.from(child['dates_absence'] ?? []);
                            final rawPresences = List<dynamic>.from(child['dates_presence'] ?? []);

                            final absences = _filterDatesByMonthAndYear(rawAbsences, _selectedMonthIndex, _selectedYear);
                            final presences = _filterDatesByMonthAndYear(rawPresences, _selectedMonthIndex, _selectedYear);

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
                                                  '${child['prenom'] ?? ''} ${child['nom'] ?? ''}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
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
                                            onPressed: () => _showStatutDialog(context, child, 'absence'),
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
                                            onPressed: () => _showStatutDialog(context, child, 'presence'),
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
                                            onPressed: () => _showModifierDialog(context, child),
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
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList();
                  }(),
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