import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WikaLiveApp());
}

const bg = Color(0xFF0B0B12);
const card = Color(0xFF171722);
const soft = Color(0xFF29293A);

class WikaLiveApp extends StatelessWidget {
  const WikaLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WikaLive',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        useMaterial3: true,
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

  @override
  Widget build(BuildContext context) {
    final hosts = [
      ['Mia', '1.8K', 'M'],
      ['Luna', '2.4K', 'L'],
      ['Sofia', '980', 'S'],
      ['Emma', '3.1K', 'E'],
      ['Nina', '1.2K', 'N'],
      ['Ava', '760', 'A'],
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4B2A8C),
                Color(0xFF251A49),
                Color(0xFF15131F),
              ],
            ),
            border: Border.all(color: Colors.white10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your world is live',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                        SizedBox(width: 6),
                        Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Welcome to WikaLive',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.05,
                  letterSpacing: -0.5,
               fontWeight: FontWeight.w800, ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Watch live, join parties and connect with people.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 18),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 14),
                    Icon(Icons.search_rounded, color: Colors.white54),
                    SizedBox(width: 10),
                    Text('Search hosts, rooms...', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(child: actionCard(context, 'Live', Icons.live_tv_rounded, 1)),
            const SizedBox(width: 12),
            Expanded(child: actionCard(context, 'Party', Icons.groups_rounded, 2)),
          ],
        ),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Live',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () {
                final state = context.findAncestorStateOfType<_HomePageState>();
                state?.setState(() => state.index = 1);
              },
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hosts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              return liveMini(context, hosts[i][0], hosts[i][1], hosts[i][2]);
            },
          ),
        ),

        const SizedBox(height: 26),

        const Text(
          'Explore WikaLive',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _exploreCard(
                icon: Icons.card_giftcard_rounded,
                title: 'Send gifts',
                subtitle: 'Support your favorite hosts',
                onTap: () => openPage(context, const GiftsPage()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _exploreCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'My wallet',
                subtitle: 'Manage your coins',
                onTap: () => openPage(context, const WalletPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _exploreCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  static Widget actionCard(BuildContext context, String title, IconData icon, int tab) {
    return InkWell(
      onTap: () {
        final state = context.findAncestorStateOfType<_HomePageState>();
        state?.setState(() => state.index = tab);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 29),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  static Widget liveMini(
    BuildContext context,
    String name,
    String viewers,
    String initial,
  ) {
    return InkWell(
      onTap: () {
        openPage(context, LiveRoomPage(host: name, viewers: '$viewers viewers'));
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6336C7), Color(0xFF171321)],
          ),
          border: Border.all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 7)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 11,
              left: 11,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4652),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6),
                    SizedBox(width: 5),
                    Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_rounded, size: 11),
                    const SizedBox(width: 4),
                    Text(viewers, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  const Text('Tap to join live', style: TextStyle(fontSize: 10, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  static const hosts = [
    ['Mia', '2.4K'],
    ['Luna', '1.8K'],
    ['Sofia', '3.1K'],
    ['Emma', '956'],
    ['Nina', '1.2K'],
    ['Ava', '2.0K'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24,
      ),
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _Cat('For You', true),
              _Cat('Popular'),
              _Cat('New'),
              _Cat('PK'),
              _Cat('Music'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Live Now',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hosts.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: .72,
          ),
          itemBuilder: (_, i) {
            return InkWell(
              onTap: () {
                openPage(
                  context,
                  LiveRoomPage(
                    host: hosts[i][0],
                    viewers: '${hosts[i][1]} viewers',
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.deepPurple.shade700,
                      Colors.black87,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: badge('LIVE'),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 34,
                        child: Icon(
                          Icons.person,
                          size: 38,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            hosts[i][0],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${hosts[i][1]} viewers',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
    'Music Party',
    'Fun & Chat',
    'Night Party',
    'Friends Room',
    'Gaming Party',
    'Talk Room',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Party Rooms',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                openPage(
                  context,
                  const CreatePartyPage(),
                );
              },
              icon: const Icon(
                Icons.add_circle_outline,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Join a room and chat with people.',
          style: TextStyle(
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 20),

        ...rooms.map(
          (room) => Card(
            color: card,
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(12),
              leading: const CircleAvatar(
                radius: 27,
                child: Icon(Icons.groups),
              ),
              title: Text(
                room,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${5 + rooms.indexOf(room)} people',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                openPage(
                  context,
                  PartyRoomPage(
                    title: room,
                  ),
                );
              },
            ),
          ),
        ),
      ],
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

  static const chats = [
    ['Mia', 'Hi! Welcome to WikaLive 👋'],
    ['Luna', 'See you in my live!'],
    ['Sofia', 'Thanks for joining ❤️'],
    ['Emma', 'Hello 😊'],
    ['Ava', 'Let’s chat later.'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chats.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (_, i) {
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          tileColor: card,
          leading: CircleAvatar(
            child: Text(
              chats[i][0][0],
            ),
          ),
          title: Text(
            chats[i][0],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            chats[i][1],
          ),
          trailing: const Text(
            'now',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          onTap: () {
            openPage(
              context,
              ChatPage(
                name: chats[i][0],
                initial: chats[i][1],
              ),
            );
          },
        );
      },
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
      return const Center(
        child: Text('Please login again'),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final name =
            (data?['name'] ?? user.displayName ?? 'WikaLive User')
                .toString();

        final email =
            (data?['email'] ?? user.email ?? '').toString();

        final coins = data?['coins'] is num
            ? (data!['coins'] as num).toInt()
            : 0;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 48,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'W',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (email.isNotEmpty)
              Center(
                child: Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white60,
                  ),
                ),
              ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_outlined),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Coins',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    coins.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            menu(
              context,
              'Wallet',
              Icons.account_balance_wallet_outlined,
              const WalletPage(),
            ),

            menu(
              context,
              'My Gifts',
              Icons.card_giftcard,
              const GiftsPage(),
            ),

            menu(
              context,
              'Become a Host',
              Icons.videocam_outlined,
              const HostPage(),
            ),

            menu(
              context,
              'Agency',
              Icons.business_center_outlined,
              const AgencyPage(),
            ),

            menu(
              context,
              'Settings',
              Icons.settings_outlined,
              const SettingsPage(),
            ),

            const SizedBox(height: 10),

            FilledButton.tonalIcon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        );
      },
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
