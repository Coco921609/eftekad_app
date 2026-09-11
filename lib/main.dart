import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Verrouillage en mode PORTRAIT uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style de la barre système (barre de statut transparente)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialisation de Supabase
  // Comme les données sont enregistrées dans la base de données distante Supabase,
  // la suppression ou la désinstallation de l'application n'efface rien.
  // Tout est sauvegardé et sera automatiquement retrouvé au ré-alunissage de l'application.
  await Supabase.initialize(
    url: 'https://bubyzbpiyorabayivwtc.supabase.co',
    anonKey: 'sb_publishable_23t8sBj550cI58ZZs9XQmQ_rRHVKm2s',
  );

  runApp(
    const ProviderScope(
      child: EftekadApp(),
    ),
  );
}