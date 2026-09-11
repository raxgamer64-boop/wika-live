import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WikaLiveApp());
}

const bg = Color(0xFFF7F8FC);
const card = Color(0xFFFFFFFF);
const soft = Color(0xFFF0ECFF);
const accent = Color(0xFF9B55E8);
const textMain = Color(0xFF17151D);
const textMuted = Color(0xFF77747E);

class WikaLiveApp extends StatelessWidget {
  const WikaLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WikaLive',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bg,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: textMain,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFE9D8FF),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, color: textMain),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.data == null
            ? const AuthPage()
            : const HomePage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool login = true;
  bool obscure = true;
  bool loading = false;

  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty ||
        pass.text.isEmpty ||
        (!login && name.text.trim().isEmpty)) {
      msg(context, 'Please fill all required fields');
      return;
    }

    if (pass.text.length < 6) {
      msg(context, 'Password must be at least 6 characters');
      return;
    }

    setState(() => loading = true);

    try {
      if (login) {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text,
        );

        final user = credential.user;
        if (user != null) {
          final ref = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);

          final snap = await ref.get();

          if (!snap.exists) {
            await ref.set({
              'uid': user.uid,
              'name': user.displayName ?? 'WikaLive User',
              'email': user.email ?? '',
              'coins': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } else {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text,
        );

        await credential.user?.updateDisplayName(
          name.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'name': name.text.trim(),
          'email': email.text.trim(),
          'coins': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      String text = e.message ?? 'Authentication failed';

      if (e.code == 'invalid-credential') {
        text = 'Invalid email or password';
      } else if (e.code == 'email-already-in-use') {
        text = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        text = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        text = 'Enter a valid email address';
      }

      msg(context, text);
    } catch (e) {
      msg(context, 'Something went wrong: $e');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 45),
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 76,
              ),
              const SizedBox(height: 12),
              const Text(
                'WikaLive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                login
                    ? 'Welcome back! Sign in to continue.'
                    : 'Create your WikaLive account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 35),

              if (!login)
                field(
                  name,
                  'Name',
                  Icons.person_outline,
                ),

              field(
                email,
                'Email',
                Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),

              field(
                pass,
                'Password',
                Icons.lock_outline,
                obscure: obscure,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          login ? 'Login' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    login = !login;
                    name.clear();
                    email.clear();
                    pass.clear();
                  });
                },
                child: Text(
                  login
                      ? 'New here? Create an account'
                      : 'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    LiveScreen(),
    PartyScreen(),
    MessagesScreen(),
    MeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv_rounded),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Party',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Moments',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Message',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    LiveScreen(),
    PartyScreen(),
    MessagesScreen(),
    MeScreen(),
  ];

  final titles = const [
    'WikaLive',
    'Live',
    'Party',
    'Messages',
    'Me',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          titles[index],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              openPage(
                context,
                const NotificationsPage(),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
          IconButton(
            onPressed: () {
              openPage(
                context,
                const WalletPage(),
              );
            },
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF11111A),
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            index = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Party',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const hosts = [
    ['Mia', '261.9K', 'M'],
    ['Luna', '236.2K', 'L'],
    ['Sofia', '103.2K', 'S'],
    ['Puja', '70K', 'P'],
    ['Nina', '48.6K', 'N'],
    ['Ava', '32.4K', 'A'],
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF0ECFF), Color(0xFFFDF9FF), bg],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Follow   Explore   Nearby   Beauty',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textMain,
                        ),
                      ),
                    ),
                    _roundIcon(
                      context,
                      Icons.search_rounded,
                      () => msg(context, 'Search coming soon'),
                    ),
                    const SizedBox(width: 8),
                    _roundIcon(
                      context,
                      Icons.workspace_premium_rounded,
                      () => msg(context, 'Rewards'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _pill('Popular', selected: true),
                    const SizedBox(width: 8),
                    _pill('🇮🇳 🇧🇩 🇳🇵 🇵🇰'),
                    const SizedBox(width: 8),
                    _pill('🇺🇸 🇵🇭 🇬🇧'),
                    const Spacer(),
                    const Icon(Icons.tune_rounded, size: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _liveCard(
                context,
                hosts[i][0],
                hosts[i][1],
                hosts[i][2],
                i.isEven,
              ),
              childCount: hosts.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .78,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _banner(
              'WikaLive',
              'Meet new people • Go live • Make friends',
              Icons.auto_awesome_rounded,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
      ],
    );
  }

  static Widget _roundIcon(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.75),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textMain),
      ),
    );
  }

  static Widget _pill(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF0D9FF) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? accent : textMain,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _liveCard(
    BuildContext context,
    String name,
    String viewers,
    String initial,
    bool hd,
  ) {
    return InkWell(
      onTap: () => openPage(
        context,
        LiveRoomPage(host: name, viewers: 'Live'),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hd
                ? const [Color(0xFF8C4FEA), Color(0xFF4A246F)]
                : const [Color(0xFFFFC5DE), Color(0xFF7D54D8)],
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 5),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white.withOpacity(.24),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: _tag('🌸 Golden Host'),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _tag(hd ? 'HD Live' : 'PK'),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  Text(
                    viewers,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget _banner(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFE7D3FF), Color(0xFFFFD9EA)],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  static const hosts = [
    ['Mia', '261.9K', 'M'],
    ['Luna', '236.2K', 'L'],
    ['Puja', '103.2K', 'P'],
    ['Sofia', '70K', 'S'],
    ['Nina', '52.4K', 'N'],
    ['Ava', '41.1K', 'A'],
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _top(context, 'Explore'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _card(context, hosts[i]),
              childCount: hosts.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .76,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _top(BuildContext context, String active) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0ECFF), Color(0xFFFDF9FF)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Follow',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 22),
              Text(
                active,
                style: const TextStyle(
                  color: textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Icon(Icons.search_rounded, size: 29),
              const SizedBox(width: 14),
              const Icon(Icons.workspace_premium_rounded, size: 29),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _chip('Popular', true),
              const SizedBox(width: 8),
              _chip('🇮🇳 🇧🇩 🇳🇵'),
              const SizedBox(width: 8),
              _chip('🇺🇸 🇵🇭 🇬🇧'),
              const Spacer(),
              const Icon(Icons.tune_rounded),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _chip(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECD6FF) : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? accent : textMain,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _card(BuildContext context, List<String> host) {
    return InkWell(
      onTap: () => openPage(context, LiveRoomPage(host: host[0], viewers: host[1])),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7E45D8), Color(0xFF251B3D)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white24,
                child: Text(
                  host[2],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE33D65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '👁 ${host[1]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 11,
              bottom: 12,
              right: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Tap to join live',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cat extends StatelessWidget {
  final String text;
  final bool selected;

  const _Cat(
    this.text, [
    this.selected = false,
  ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? soft : card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(text),
    );
  }
}

class LiveRoomPage extends StatefulWidget {
  final String host;
  final String viewers;

  const LiveRoomPage({
    super.key,
    required this.host,
    required this.viewers,
  });

  @override
  State<LiveRoomPage> createState() =>
      _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  bool following = false;

  final controller = TextEditingController();

  final chat = [
    'Alex: Hello 👋',
    'Sam: Nice live!',
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.deepPurple.shade800,
                      Colors.black,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 110,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                  ),

                  const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.host,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.viewers,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        following = !following;
                      });
                    },
                    child: Text(
                      following ? 'Following' : 'Follow',
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 14,
              right: 14,
              bottom: 78,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: chat
                    .map(
                      (x) => _ChatBubble(x),
                    )
                    .toList(),
              ),
            ),

            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Say something...',
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    onPressed: () {
                      if (controller.text
                          .trim()
                          .isNotEmpty) {
                        setState(() {
                          chat.add(
                            'You: ${controller.text.trim()}',
                          );
                        });
                      }

                      controller.clear();
                    },
                    icon: const Icon(Icons.send),
                  ),

                  IconButton(
                    onPressed: () {
                      showGiftSheet(context);
                    },
                    icon: const Icon(
                      Icons.card_giftcard,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;

  const _ChatBubble(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  static const rooms = [
    ['hotty hot 🔥🔥🔥', 'Welcome to party!! we build friends together', '31', 'HH'],
    ['SINGH Agency', 'Radhe krishna 🦚', '4', 'SA'],
    ["Suman's room", "Welcome to my party room, let's chat", '3', 'SR'],
    ["suhani's room", "Welcome to my party room, let's chat", '2', 'SU'],
    ["humko v Patao's room", "Welcome to my party room, let's chat", '8', 'HP'],
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          sliver: SliverList.builder(
            itemCount: rooms.length,
            itemBuilder: (context, i) => _room(context, rooms[i], i),
          ),
        ),
      ],
    );
  }

  static Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0ECFF), Color(0xFFFDF9FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Me',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 22),
              const Text(
                'Party',
                style: TextStyle(
                  color: textMain,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Icon(Icons.search_rounded, size: 29),
              const SizedBox(width: 14),
              const Icon(Icons.workspace_premium_rounded, size: 29),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _tab('Popular', true),
              const SizedBox(width: 8),
              _tab('PK Battle', false),
              const SizedBox(width: 8),
              _tab('Event', false),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _tab(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECD6FF) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? accent : textMain,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget _room(
    BuildContext context,
    List<String> room,
    int index,
  ) {
    return InkWell(
      onTap: () => openPage(
        context,
        PartyRoomPage(title: room[0]),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x12000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: index.isEven
                      ? const [Color(0xFFFF7DB6), Color(0xFF7A49DB)]
                      : const [Color(0xFF87CFFF), Color(0xFFAF7CF4)],
                ),
              ),
              child: Center(
                child: Text(
                  room[3],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🇮🇳 ${room[0]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room[1],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBD7FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Lv.${index + 1}',
                          style: const TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Music Party',
                        style: TextStyle(
                          color: Color(0xFFBD55D9),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: accent,
                ),
                Text(
                  room[2],
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textMain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePartyPage extends StatelessWidget {
  const CreatePartyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Party'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Party name',
                filled: true,
                fillColor: card,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  if (controller.text
                      .trim()
                      .isEmpty) {
                    return;
                  }

                  Navigator.pop(context);
                  msg(
                    context,
                    'Party created',
                  );
                },
                child: const Text(
                  'Create Party',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartyRoomPage extends StatefulWidget {
  final String title;

  const PartyRoomPage({
    super.key,
    required this.title,
  });

  @override
  State<PartyRoomPage> createState() =>
      _PartyRoomState();
}

class _PartyRoomState
    extends State<PartyRoomPage> {
  final controller = TextEditingController();

  final list = [
    'Welcome to the party! 🎉',
    'Have fun everyone!',
  ];

  bool mic = true;
  bool speaker = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            height: 190,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 38,
                    child: Icon(
                      Icons.groups,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    mic
                        ? 'Mic on'
                        : 'Mic off',
                  ),

                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            mic = !mic;
                          });
                        },
                        icon: Icon(
                          mic
                              ? Icons.mic
                              : Icons.mic_off,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            speaker = !speaker;
                          });
                        },
                        icon: Icon(
                          speaker
                              ? Icons.volume_up
                              : Icons.volume_off,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showGiftSheet(context);
                        },
                        icon: const Icon(
                          Icons.card_giftcard,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(list[i]),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Write a message...',
                        filled: true,
                        fillColor: card,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(24),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      if (controller.text
                          .trim()
                          .isNotEmpty) {
                        setState(() {
                          list.add(
                            'You: ${controller.text.trim()}',
                          );
                        });
                      }

                      controller.clear();
                    },
                    icon: const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF0ECFF), Color(0xFFFDF9FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: textMain,
                      ),
                    ),
                    SizedBox(width: 24),
                    Text(
                      'Friends',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.settings_outlined, size: 27),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: textMuted),
                      SizedBox(width: 10),
                      Text(
                        "Please enter user's name",
                        style: TextStyle(
                          color: Color(0xFFB5B3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.sort_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quick('🦄', 'Crush Team'),
                    _quick('❤️', 'New Follow'),
                    _quick('👍', 'Interactive'),
                    _quick('🎟️', 'Event Center'),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(18),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _membership(),
              const SizedBox(height: 14),
              _messageRow(
                context,
                'Mia',
                'Welcome to WikaLive 💜',
                Icons.favorite_rounded,
              ),
              _messageRow(
                context,
                'Luna',
                'Come join my live room!',
                Icons.live_tv_rounded,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  static Widget _quick(String emoji, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white,
          child: Text(emoji, style: const TextStyle(fontSize: 27)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: textMain,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  static Widget _membership() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 31,
            backgroundColor: Color(0xFFFFB62F),
            child: Icon(Icons.home_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Party Membership',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textMain,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "You haven't joined any rooms yet",
                  style: TextStyle(
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _messageRow(
    BuildContext context,
    String name,
    String preview,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => openPage(context, ChatPage(name: name, initial: name.isNotEmpty ? name[0] : 'W')),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x14000000))),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE4D3FF),
              child: Text(
                name[0],
                style: const TextStyle(
                  color: accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: accent),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String name;
  final String initial;

  const ChatPage({
    super.key,
    required this.name,
    required this.initial,
  });

  @override
  State<ChatPage> createState() =>
      _ChatState();
}

class _ChatState extends State<ChatPage> {
  final controller = TextEditingController();

  late final List<Map<String, String>>
      list;

  @override
  void initState() {
    super.initState();

    list = [
      {
        'from': widget.name,
        'text': widget.initial,
      },
      {
        'from': widget.name,
        'text': 'How are you? 😊',
      },
    ];
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    if (controller.text.trim().isEmpty) {
      return;
    }

    setState(() {
      list.add({
        'from': 'You',
        'text': controller.text.trim(),
      });
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final mine =
                    list[i]['from'] == 'You';

                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 300,
                    ),
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mine
                          ? soft
                          : card,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: Text(
                      list[i]['text']!,
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => send(),
                      decoration:
                          InputDecoration(
                        hintText: 'Message...',
                        filled: true,
                        fillColor: card,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(25),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: send,
                    icon: const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login again'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name =
            (data?['name'] ?? user.displayName ?? 'WikaLive User').toString();
        final email = (data?['email'] ?? user.email ?? '').toString();
        final coins = data?['coins'] is num
            ? (data!['coins'] as num).toInt()
            : 0;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF0ECFF), Color(0xFFFDF9FF), bg],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () => openPage(
                            context,
                            const SettingsPage(),
                          ),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 53,
                      backgroundColor: const Color(0xFF6543B7),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'W',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(
                          color: textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(value: '0', label: 'Friends'),
                        _Stat(value: '0', label: 'Follow'),
                        _Stat(value: '0', label: 'Followers'),
                        _Stat(value: '0', label: 'Visitors'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _goldBanner(context),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _coinCard(
                          'Coins',
                          coins.toString(),
                          Icons.monetization_on_rounded,
                          const Color(0xFFFFF3BF),
                          () => openPage(context, const WalletPage()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _coinCard(
                          'Gems',
                          '0',
                          Icons.diamond_rounded,
                          const Color(0xFFEFE0FF),
                          () => msg(context, 'Gems'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _featureGrid(context),
                  const SizedBox(height: 14),
                  _settingsGrid(context),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _goldBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A270D), Color(0xFF8D5315)],
        ),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 35)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'King of Kings',
                  style: TextStyle(
                    color: Color(0xFFFFE0A0),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Become and enjoy exclusive privileges',
                  style: TextStyle(
                    color: Color(0xFFFFE0A0),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => msg(context, 'VIP activation coming soon'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFBE45),
              foregroundColor: textMain,
            ),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  static Widget _coinCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 112,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 38, color: accent),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: textMain,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _featureGrid(BuildContext context) {
    final items = [
      ['🎁', 'Gifts', () => openPage(context, const GiftsPage())],
      ['💗', 'Fans Club', () => msg(context, 'Fans Club')],
      ['🎮', 'Game', () => msg(context, 'Games')],
      ['🎒', 'Backpack', () => msg(context, 'Backpack')],
      ['🏪', 'Store', () => msg(context, 'Store')],
      ['🎟️', 'Events', () => msg(context, 'Events')],
    ];

    return _whitePanel(
      children: items.map((item) {
        return InkWell(
          onTap: item[2] as VoidCallback,
          child: Column(
            children: [
              Text(item[0] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                item[1] as String,
                style: const TextStyle(
                  color: textMain,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _settingsGrid(BuildContext context) {
    final items = [
      ['👑', 'VIP', () => msg(context, 'VIP')],
      ['🛡️', 'Guardian', () => msg(context, 'Guardian')],
      ['↪️', 'Join agency', () => openPage(context, const AgencyPage())],
      ['🧑', 'Real person', () => msg(context, 'Verification')],
      ['❓', 'Help', () => msg(context, 'Help & Feedback')],
      ['🎧', 'Customer Service', () => msg(context, 'Customer Service')],
    ];

    return _whitePanel(
      children: items.map((item) {
        return InkWell(
          onTap: item[2] as VoidCallback,
          child: Column(
            children: [
              Text(item[0] as String, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                item[1] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textMain,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _whitePanel({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.25,
        children: children,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: textMain,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login again'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          final coins = data?['coins'] is num
              ? (data!['coins'] as num).toInt()
              : 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Coins',
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coins.toString(),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Coins',
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              menu(
                context,
                'Buy Coins',
                Icons.add_circle_outline,
                null,
                onTap: () {
                  msg(
                    context,
                    'Coin purchase will be connected later',
                  );
                },
              ),

              menu(
                context,
                'Gift History',
                Icons.history,
                const GiftHistoryPage(),
              ),

              menu(
                context,
                'Withdraw',
                Icons.account_balance_outlined,
                const WithdrawalPage(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class GiftHistoryPage extends StatelessWidget {
  const GiftHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Gift History',
      items: [
        'No gift history yet.',
      ],
    );
  }
}

class GiftsPage extends StatelessWidget {
  const GiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gifts'),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(18),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: const [
          GiftTile('❤️'),
          GiftTile('⭐'),
          GiftTile('🎁'),
          GiftTile('🌹'),
          GiftTile('💎'),
          GiftTile('👑'),
          GiftTile('🔥'),
          GiftTile('🎉'),
          GiftTile('💖'),
        ],
      ),
    );
  }
}

class GiftTile extends StatelessWidget {
  final String emoji;

  const GiftTile(
    this.emoji, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(
            fontSize: 38,
          ),
        ),
      ),
    );
  }
}

class HostPage extends StatelessWidget {
  const HostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Become a Host',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.videocam,
            size: 70,
          ),

          const SizedBox(height: 16),

          const Text(
            'Become a WikaLive Host',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Go live, build your audience and earn from gifts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: 25),

          FilledButton(
            onPressed: () {
              msg(
                context,
                'Host application submitted',
              );
            },
            child: const Text(
              'Apply to Become a Host',
            ),
          ),
        ],
      ),
    );
  }
}

class AgencyPage extends StatelessWidget {
  const AgencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          menu(
            context,
            'My Agency',
            Icons.business,
            null,
            onTap: () {
              msg(
                context,
                'Agency dashboard coming next',
              );
            },
          ),

          menu(
            context,
            'Invitations',
            Icons.mail_outline,
            null,
            onTap: () {
              msg(
                context,
                'No new invitations',
              );
            },
          ),

          menu(
            context,
            'My Hosts',
            Icons.people_outline,
            null,
            onTap: () {
              msg(
                context,
                'Host list coming next',
              );
            },
          ),

          menu(
            context,
            'Join Agency',
            Icons.login,
            null,
            onTap: () {
              msg(
                context,
                'Agency joining will be connected to backend',
              );
            },
          ),
        ],
      ),
    );
  }
}

class WithdrawalPage extends StatelessWidget {
  const WithdrawalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Withdrawal',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'Available balance',
              ),
              subtitle: Text(
                '₹0',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            TextField(
              controller: controller,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Withdrawal amount',
                prefixText: '₹',
                filled: true,
                fillColor: card,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  msg(
                    context,
                    'Withdrawal request will be connected later',
                  );
                },
                child: const Text(
                  'Request Withdrawal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsPage
    extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      title: 'Notifications',
      items: [
        'No new notifications.',
      ],
    );
  }
}

class SettingsPage
    extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() =>
      _SettingsState();
}

class _SettingsState
    extends State<SettingsPage> {
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            tileColor: card,
            value: notifications,
            onChanged: (value) {
              setState(() {
                notifications = value;
              });
            },
            title: const Text(
              'Notifications',
            ),
          ),

          menu(
            context,
            'Language',
            Icons.language,
            null,
            onTap: () {
              msg(
                context,
                'Language settings',
              );
            },
          ),

          menu(
            context,
            'Privacy & Security',
            Icons.security,
            null,
            onTap: () {
              msg(
                context,
                'Privacy settings',
              );
            },
          ),

          menu(
            context,
            'Help & Support',
            Icons.help_outline,
            null,
            onTap: () {
              msg(
                context,
                'Support will be connected later',
              );
            },
          ),

          menu(
            context,
            'Logout',
            Icons.logout,
            null,
            onTap: () {
              FirebaseAuth.instance
                  .signOut();
            },
          ),
        ],
      ),
    );
  }
}

class SimplePage
    extends StatelessWidget {
  final String title;
  final List<String> items;

  const SimplePage({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: items
            .map(
              (item) => ListTile(
                tileColor: card,
                title: Text(item),
              ),
            )
            .toList(),
      ),
    );
  }
}

void showGiftSheet(
  BuildContext context,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: card,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Send Gift',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 24,
                children: [
                  '❤️',
                  '⭐',
                  '🎁',
                  '🌹',
                  '💎',
                ]
                    .map(
                      (emoji) => InkWell(
                        onTap: () {
                          Navigator.pop(
                            context,
                          );

                          msg(
                            context,
                            'Gift $emoji sent',
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              emoji,
                              style:
                                  const TextStyle(
                                fontSize: 38,
                              ),
                            ),
                            const SizedBox(
                                height: 5),
                            Text(emoji),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget menu(
  BuildContext context,
  String title,
  IconData icon,
  Widget? page, {
  VoidCallback? onTap,
}) {
  return Container(
    margin:
        const EdgeInsets.only(bottom: 10),
    child: ListTile(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
      ),
      tileColor: card,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: onTap ??
          (page == null
              ? null
              : () {
                  openPage(
                    context,
                    page,
                  );
                }),
    ),
  );
}

Widget badge(String text) {
  return Container(
    padding:
        const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius:
          BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

void openPage(
  BuildContext context,
  Widget page,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => page,
    ),
  );
}

void msg(
  BuildContext context,
  String text,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}
