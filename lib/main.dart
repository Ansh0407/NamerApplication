import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MyAppState()..loadFromPrefs(),
      child: const MyApp(),
    ),
  );
}

/* ===================== APP ROOT ===================== */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();

    return MaterialApp(
      title: 'Namer Application',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 89, 39, 136),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 89, 39, 136),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: appState.themeMode,
      home: const MyHomePage(),
    );
  }
}

/* ===================== APP STATE ===================== */

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  final favorites = <WordPair>[];

  ThemeMode themeMode = ThemeMode.light;

  /* ---------- PERSISTENCE ---------- */

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final isDark = prefs.getBool('isDarkMode') ?? false;
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load favorites
    final saved = prefs.getStringList('favorites') ?? [];
    favorites
      ..clear()
      ..addAll(saved.map(_stringToWordPair));

    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setBool('isDarkMode', themeMode == ThemeMode.dark);
    prefs.setStringList(
      'favorites',
      favorites.map(_wordPairToString).toList(),
    );
  }

  /* ---------- THEME ---------- */

  void toggleTheme() {
    themeMode =
        themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _savePrefs();
    notifyListeners();
  }

  /* ---------- WORD LOGIC ---------- */

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    _savePrefs();
    notifyListeners();
  }

  void addFavorite(WordPair pair) {
    favorites.add(pair);
    _savePrefs();
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    _savePrefs();
    notifyListeners();
  }

  /* ---------- HELPERS ---------- */

  String _wordPairToString(WordPair pair) =>
      '${pair.first}|${pair.second}';

  WordPair _stringToWordPair(String value) {
    final parts = value.split('|');
    return WordPair(parts[0], parts[1]);
  }
}

/* ===================== HOME PAGE ===================== */

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final page = selectedIndex == 0
        ? const GeneratorPage()
        : const FavoritesPage();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() => selectedIndex = value);
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ===================== GENERATOR PAGE ===================== */

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final pair = appState.current;
    final isFavorite = appState.favorites.contains(pair);

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BigCard(pair: pair),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: appState.toggleFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    label: const Text('Like'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: appState.getNext,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🌙 Floating Theme Toggle
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(blurRadius: 8, color: Colors.black26),
              ],
            ),
            child: IconButton(
              icon: Icon(
                appState.themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: appState.toggleTheme,
            ),
          ),
        ),
      ],
    );
  }
}

/* ===================== FAVORITES PAGE ===================== */

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final favorites = appState.favorites;

    if (favorites.isEmpty) {
      return const Center(
        child: Text('No favorites yet ❤️', style: TextStyle(fontSize: 18)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '${favorites.length} Favorites',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final pair = favorites[index];

              return Dismissible(
                key: ValueKey(pair.asPascalCase),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  appState.removeFavorite(pair);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${pair.asPascalCase} removed'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          appState.addFavorite(pair);
                        },
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.favorite),
                    title: Text(pair.asPascalCase),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        appState.removeFavorite(pair);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ===================== BIG CARD (HERO + ANIMATION) ===================== */

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .displayMedium!
        .copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        );

    return Hero(
      tag: pair.asLowerCase,
      child: Card(
        color: Theme.of(context).colorScheme.primary,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              pair.asLowerCase,
              key: ValueKey(pair.asLowerCase),
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
