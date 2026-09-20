import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _serviteurFormKey = GlobalKey<FormState>();
  final _responsableFormKey = GlobalKey<FormState>();

  // Contrôleurs Connexion (Prénom + Mot de passe)
  final TextEditingController _loginPrenomController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Contrôleurs Serviteur
  final TextEditingController _servPasswordController = TextEditingController();
  final TextEditingController _servNomController = TextEditingController();
  final TextEditingController _servPrenomController = TextEditingController();
  final TextEditingController _servTelephoneController = TextEditingController(text: '+33');
  String? _servJour;
  final List<String> _servSelectedClasses = [];

  // Contrôleurs Responsable de famille
  final TextEditingController _respPasswordController = TextEditingController();
  final TextEditingController _respNomController = TextEditingController();
  final TextEditingController _respPrenomController = TextEditingController();
  final TextEditingController _respTelephoneController = TextEditingController(text: '+33');
  String? _respJour;
  final List<String> _respSelectedClasses = [];

  // Tous les cycles et classes disponibles
  final Map<String, List<String>> _classesParCycle = {
    'Maternelle': ['PS', 'MS', 'GS'],
    'Primaire': ['CP', 'CE1', 'CE2', 'CM1', 'CM2'],
    'Collège': ['6ème', '5ème', '4ème', '3ème'],
    'Lycée': ['Seconde', 'Première', 'Terminale'],
  };

  bool _isSignUp = false;
  int _signUpTabindex = 0;
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
    _respPasswordController.dispose();
    _respNomController.dispose();
    _respPrenomController.dispose();
    _respTelephoneController.dispose();
    super.dispose();
  }

  // Génère un email interne valide pour Supabase à partir du prénom
  String _getInternalEmail(String prenom) {
    final cleanPrenom = prenom.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$cleanPrenom@gmail.com';
  }

  // Connexion
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

  // Inscription
  Future<void> _submitSignUp(String role) async {
    final formKey = role == 'Serviteur' ? _serviteurFormKey : _responsableFormKey;
    if (!formKey.currentState!.validate()) return;

    if (role == 'Serviteur' && _servJour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner le jour de caté')));
      return;
    }
    if (role == 'Serviteur' && _servSelectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez cocher au moins une classe')));
      return;
    }
    if (role == 'Responsable' && _respJour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner le jour de caté')));
      return;
    }
    if (role == 'Responsable' && _respSelectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez cocher au moins une classe')));
      return;
    }

    setState(() => _isLoading = true);

    final prenom = role == 'Serviteur' ? _servPrenomController.text.trim() : _respPrenomController.text.trim();
    final internalEmail = _getInternalEmail(prenom);
    final password = role == 'Serviteur' ? _servPasswordController.text.trim() : _respPasswordController.text.trim();
    final nom = role == 'Serviteur' ? _servNomController.text.trim() : _respNomController.text.trim();
    final telephone = role == 'Serviteur' ? _servTelephoneController.text.trim() : _respTelephoneController.text.trim();
    final jour = role == 'Serviteur' ? _servJour : _respJour;
    final classes = role == 'Serviteur' ? _servSelectedClasses : _respSelectedClasses;

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: internalEmail,
        password: password,
        data: {
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'role': role,
          'jour': jour,
          'classes': classes,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
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

  // Boîte de dialogue pour le mot de passe oublié
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
    return Scaffold(
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
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _signUpTabindex = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _signUpTabindex == 0 ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.1),
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                ),
                                child: Text(
                                  'Serviteur',
                                  style: TextStyle(
                                    color: Colors.white,
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _signUpTabindex == 1 ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.1),
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                ),
                                child: Text(
                                  'Responsable famille',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: _signUpTabindex == 1 ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _signUpTabindex == 0 ? _buildServiteurForm() : _buildResponsableForm(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
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
    );
  }

  // -------------------------------------------------------------------
  // FORMULAIRE DE CONNEXION
  // -------------------------------------------------------------------
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

  // -------------------------------------------------------------------
  // FORMULAIRE SERVITEUR
  // -------------------------------------------------------------------
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

  // -------------------------------------------------------------------
  // FORMULAIRE RESPONSABLE DE FAMILLE
  // -------------------------------------------------------------------
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

  InputDecoration _inputDecoration(String label, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.deepPurpleAccent, size: 18),
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
      text = '+33' + text.replaceAll('+33', '');
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}