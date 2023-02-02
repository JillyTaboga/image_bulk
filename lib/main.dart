import 'package:fluent_ui/fluent_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'interface/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: FluentApp(
        debugShowCheckedModeBanner: false,
        title: 'FileBulker',
        home: HomeScreen(),
      ),
    );
  }
}
