import 'package:flutter/material.dart';
import 'package:tt_app/pages/home.dart';

void main() {

    // Disable debug logs in production
    // debugPrint = (String message, {int wrapWidth}) {};

    runApp(MyApp());
}

class MyApp extends StatelessWidget {

    @override
    Widget build(BuildContext context) {
        final title = 'Twitter Timeline Demo';
        return MaterialApp(
            title: title,
            theme: ThemeData(
                primarySwatch: Colors.purple,
                scaffoldBackgroundColor: Colors.grey[200]
            ),
            home: HomePage(title: title),
        );
    }
}