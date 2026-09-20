import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'accueil.dart';
import 'enfants.dart';
import 'alerts.dart';
import 'bilan.dart'; // Importation de la page Bilan
import 'login_screen.dart'; // Importation de l'écran de connexion

// Provider pour gérer la navigation par onglets avec historique pour le bouton retour
class NavigationNotifier extends Notifier<int> {
  final List<int> _history = [0];

  @override
  int build() => 0;

  void setIndex(int index) {
    if (state != index) {
      _history.remove(index);
      _history.add(index);
      state = index;
    }
  }

  bool goBack() {
    if (_history.length > 1) {
      _history.removeLast();
      state = _history.last;
      return true;
    }
    return false;
  }
}

final navigationIndexProvider =
NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);

class EftekadApp extends ConsumerWidget {
  const EftekadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Eftekad',
      debugShowCheckedModeBanner: false,

      // 🇫🇷 Support du calendrier et de l'interface en français
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: ThemeMode.dark, // Verrouillé en mode sombre

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          primary: Colors.deepPurpleAccent,
          surface: const Color(0xFF1E1E2C),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E2C),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF161622),
          indicatorColor: Colors.deepPurpleAccent.withOpacity(0.3),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.deepPurpleAccent);
            }
            return IconThemeData(color: Colors.grey.shade400);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            );
          }),
        ),
      ),

      // Écoute de l'état de connexion Supabase pour basculer entre LoginScreen et MainScreen
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) {
            return const LoginScreen();
          }
          return const MainScreen();
        },
      ),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  final List<Widget> _pages = const [
    HomeScreen(),
    ChildrenScreen(),
    AlertsScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(navigationIndexProvider.notifier).goBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Image d'arrière-plan personnalisable depuis assets/image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback si l'image n'existe pas encore dans les assets
                  return Container(color: const Color(0xFF121212));
                },
              ),
            ),
            // Voile sombre semi-transparent pour garder une excellente lisibilité
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
              ),
            ),
            // Contenu principal de l'application
            IndexedStack(
              index: currentIndex,
              children: _pages,
            ),
            // Ajout de l'image en haut à gauche depuis assets/image
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Image.asset(
                    'assets/image/logo.png', // Modifié pour pointer vers assets/image
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback invisible ou widget vide si l'image n'est pas trouvée pour éviter les crashs
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(navigationIndexProvider.notifier).setIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.child_care_outlined),
              selectedIcon: Icon(Icons.child_care),
              label: 'Enfants ou\nJeunes',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alertes',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Bilan',
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Vues et redirection vers les pages dédiées
// -----------------------------------------------------------------------------

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnfantsScreen();
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertsMainScreen();
  }
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BilanScreen(); // Redirige directement vers la page Bilan dédiée
  }
}