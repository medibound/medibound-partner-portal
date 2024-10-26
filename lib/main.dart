import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mediboundbusiness/pages/DashboardScreen.dart';
import 'package:medibound_library/medibound_library.dart'; // Import the library

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  await initialize();


  runApp(DevicePortalApp());
}

TextTheme rubikTextTheme(Brightness brightness) {
  final textColor = brightness == Brightness.dark ? Colors.white : Colors.black;

  return GoogleFonts.rubikTextTheme().apply(
    bodyColor: textColor,
    displayColor: textColor,
  );
}



class DevicePortalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    
    return MaterialApp(
      title: 'Device Portal',
      theme: ThemeData(
          textTheme: rubikTextTheme(MediaQuery.of(context).platformBrightness),
          
          colorScheme: ColorScheme(
            primary: MbColors(context).primary,
            primaryContainer: MbColors(context).onPrimary,
            secondary: MbColors(context).secondary,
            secondaryContainer: MbColors(context).onSecondary,
            surface: MbColors(context).onBackground,
            background: MbColors(context).background,
            error: MbColors(context).error,
            onPrimary: MbColors(context).onPrimary,
            onSecondary: MbColors(context).onSecondary,
            onSurface: MbColors(context).surface,
            onBackground: MbColors(context).onBackground,
            onError: MbColors(context).error,
            surfaceTint: Colors.transparent,
            brightness: MediaQuery.of(context).platformBrightness,
          ),
          cardColor:
              MediaQuery.of(context).platformBrightness == Brightness.dark
                  ? Color.fromARGB(255, 11, 12, 12)
                  : Colors.white,
          listTileTheme: ListTileThemeData(
            selectedTileColor: Colors.transparent,
            titleTextStyle: GoogleFonts.rubik(textStyle: TextStyle(fontWeight: FontWeight.w500)),
            shape: RoundedRectangleBorder(
              
              borderRadius: BorderRadius.circular(10),
            ),
            
          ),
          cardTheme: CardTheme(
            elevation: 16,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  width: 1,
                  color:
                      MbColors(context).surface.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            shadowColor: Colors.black.withOpacity(0.2),
          )),
      home: DashboardScreen(
        auth: FirebaseAuth.instance,
      ),
    );
  }
}
