import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsMainScreen extends StatefulWidget {
  const AlertsMainScreen({super.key});

  @override
  State<AlertsMainScreen> createState() => _AlertsMainScreenState();
}

class _AlertsMainScreenState extends State<AlertsMainScreen> {
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

  Future<void> _sendMessage(String phoneNumber, String prenomEnfant, String absencesList) async {
    if (phoneNumber.isEmpty || phoneNumber == 'Non renseigné') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone invalide ou manquant.')),
      );
      return;
    }

    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
      cleanPhone = '+33${cleanPhone.substring(1)}';
    }

    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone");
    final Uri smsUri = Uri.parse("sms:$cleanPhone");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir l\'application de messagerie.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _saveJustificatif(Map<String, dynamic> child, String dateStr, String? text) async {
    try {
      Map<String, dynamic> currentJustifs = Map<String, dynamic>.from(child['justificatifs_absence'] ?? {});

      if (text == null || text.trim().isEmpty) {
        currentJustifs.remove(dateStr);
      } else {
        currentJustifs[dateStr] = text.trim();
      }

      await Supabase.instance.client
          .from('enfants')
          .update({
        'justificatifs_absence': currentJustifs,
      })
          .eq('id', child['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text == null || text.trim().isEmpty
                ? 'Justificatif supprimé avec succès !'
                : 'Justificatif enregistré avec succès !'),
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

  void _showJustificatifDialog(BuildContext context, Map<String, dynamic> child, String dateStr, String currentJustif) {
    final TextEditingController controller = TextEditingController(text: currentJustif);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Justificatif pour le $dateStr'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Écrire ou modifier le motif d\'absence de ${child['prenom'] ?? ''} :'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ex : Maladie, voyage familial, motif médical...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          actions: [
            if (currentJustif.isNotEmpty)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _saveJustificatif(child, dateStr, null);
                },
                child: const Text('Supprimer'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _saveJustificatif(child, dateStr, controller.text);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDaySection(String dayName, List<Map<String, dynamic>> children) {
    final filteredChildren = children.where((child) {
      final niveauClasse = child['niveau_classe'] as String? ?? '';
      final rawAbsences = List<dynamic>.from(child['dates_absence'] ?? []);
      final filteredAbsences = _filterDatesByMonthAndYear(rawAbsences, _selectedMonthIndex, _selectedYear);
      return niveauClasse.startsWith(dayName) && filteredAbsences.isNotEmpty;
    }).toList();

    if (filteredChildren.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Aucune absence signalée pour le $dayName sur la période sélectionnée.',
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
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Niveau : $levelName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
            ...levelChildren.map((child) {
              final photoUrl = child['photo_url'] as String?;
              final prenom = child['prenom'] ?? '';
              final nom = child['nom'] ?? '';
              final telephone = child['telephone'] ?? '';
              final rawAbsences = List<dynamic>.from(child['dates_absence'] ?? []);
              final absences = _filterDatesByMonthAndYear(rawAbsences, _selectedMonthIndex, _selectedYear);
              final justifsMap = Map<String, dynamic>.from(child['justificatifs_absence'] ?? {});

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
                                    '$prenom $nom',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),

                        // Liste des absences avec gestion du justificatif
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: absences.map((dateObj) {
                            final dateStr = dateObj.toString();
                            final justifText = justifsMap[dateStr]?.toString() ?? '';
                            final hasJustif = justifText.isNotEmpty;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Absence du $dateStr',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (hasJustif) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Justificatif : $justifText',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.amber.shade200,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        hasJustif ? Icons.edit_note : Icons.add_comment,
                                        color: hasJustif ? Colors.orangeAccent : Colors.lightBlueAccent,
                                        size: 22,
                                      ),
                                      tooltip: hasJustif ? 'Modifier / Supprimer justificatif' : 'Ajouter justificatif',
                                      onPressed: () => _showJustificatifDialog(context, child, dateStr, justifText),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _sendMessage(telephone, prenom, absences.join(", ")),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Envoyer message d\'absence'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
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
                      'Suivi des absences (Alertes)',
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
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Pour chaque absence d\'un enfant ou d\'un jeune, il faut envoyer un message afin de prendre de ses nouvelles, et en cas de situation très grave comme l\'hôpital, très malade, etc., il faut prévenir le responsable de la famille directement et ne surtout pas traîner en cas d\'urgence très grave.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amberAccent,
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

                    // Filtres Année et Mois
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