import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WikaLiveApp());
}

const bg = Color(0xFFF7F7FA);
const card = Colors.white;
const soft = Color(0xFFF0EEF4);

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

  Future<void> signInWithGoogle() async {
    setState(() => loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        if (!(await ref.get()).exists) {
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
    } on FirebaseAuthException catch (e) {
      msg(context, e.message ?? 'Google sign-in failed');
    } catch (e) {
      msg(context, 'Google sign-in failed: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  void openPhoneLogin() {
    openPage(context, const PhoneLoginPage());
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
                  color: Color(0xFF77727F),
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

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading ? null : signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: loading ? null : openPhoneLogin,
                icon: const Icon(Icons.phone_rounded),
                label: const Text('Continue with phone number'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 6),

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
    LiveScreen(),
    PartyScreen(),
    MomentsScreen(),
    MessagesScreen(),
    MeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedIndex: index,
        indicatorColor: Colors.transparent,
        onDestinationSelected: (i) => setState(() => index = i),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF9B55E8)
                : const Color(0xFF17171D),
          );
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv_rounded, color: Color(0xFFB65BEA)),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded, color: Color(0xFFB65BEA)),
            label: 'Party',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFFB65BEA)),
            label: 'Moments',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFFB65BEA)),
            label: 'Message',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFB65BEA)),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  int topTab = 1;
  int filter = 0;

  static const hosts = [
    ['Who carEs 😜', '261.9K', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=900'],
    ['candyy09🍭❤️', '236.2K', 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=900'],
    ['Welcomew dost all', '103.2K', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=900'],
    ['Target pending', '70K', 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=900'],
    ['Golden Star', '58.4K', 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=900'],
    ['Hot live', '42.7K', 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=900'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Row(
            children: [
              _topTab('Follow', false, 0),
              _topTab('Explore', true, 1),
              _topTab('Nearby', false, 2),
              _topTab('Beauty', false, 3),
              const Spacer(),
              const Icon(Icons.search_rounded, size: 31),
              const SizedBox(width: 12),
              const Text('👑', style: TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _filterChip('Popular', filter == 0, 0),
              const SizedBox(width: 8),
              _flagChip('🇮🇳  🇧🇩  🇳🇵  🇵🇰'),
              const SizedBox(width: 8),
              _flagChip('🇺🇸  🇵🇭  🇬🇧'),
              const Spacer(),
              const Icon(Icons.tune_rounded, size: 29),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .72,
            ),
            itemBuilder: (_, i) => _liveCard(context, hosts[i]),
          ),
          const SizedBox(height: 18),
          _banner('GAME RANKING', '🏆  ✨  💰  ✨  👑', const Color(0xFF5420A4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _promoCard('90% OFF', '🎁', 'LIVE', const Color(0xFFB94AF2))),
              const SizedBox(width: 12),
              Expanded(child: _promoCard('New users', '💎', 'REWARD', const Color(0xFFFFA32D))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topTab(String text, bool selected, int value) {
    return GestureDetector(
      onTap: () => setState(() => topTab = value),
      child: Padding(
        padding: const EdgeInsets.only(right: 22),
        child: Column(
          children: [
            Text(text, style: TextStyle(fontSize: 19, fontWeight: selected ? FontWeight.w900 : FontWeight.w700, color: selected ? Colors.black : Colors.black54)),
            const SizedBox(height: 8),
            Container(width: selected ? 34 : 0, height: 4, decoration: BoxDecoration(color: const Color(0xFF8E59E8), borderRadius: BorderRadius.circular(5))),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String text, bool selected, int value) {
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(color: selected ? const Color(0xFFF1D9FF) : Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Text(text, style: const TextStyle(color: Color(0xFF9452E8), fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _flagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Text(text, style: const TextStyle(fontSize: 17)),
    );
  }

  Widget _liveCard(BuildContext context, List<String> host) {
    return InkWell(
      onTap: () => openPage(context, LiveRoomPage(host: host[0], viewers: '${host[1]} viewers')),
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(host[2], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFDACCF0), child: const Icon(Icons.person, size: 65))),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.transparent, Colors.black87]))),
            Positioned(top: 9, left: 9, child: _badge('👑 Golden Host', const Color(0xFF7D20D8))),
            Positioned(top: 9, right: 9, child: _badge('HD Live', const Color(0xFFFFB51B))),
            Positioned(left: 11, right: 11, bottom: 11, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _badge('🔗 Guest Call', Colors.white.withValues(alpha: .88), darkText: true),
              const SizedBox(height: 8),
              Text(host[0], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('🇮🇳   🔥 ${host[1]}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, {bool darkText = false}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Text(text, style: TextStyle(color: darkText ? Colors.black87 : Colors.white, fontSize: 11, fontWeight: FontWeight.w900)));
  }

  Widget _banner(String title, String decoration, Color color) {
    return Container(height: 92, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, const Color(0xFFBD56E9)]), borderRadius: BorderRadius.circular(16)), child: Stack(children: [Center(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 5)]))), Positioned(top: 6, left: 16, child: Text(decoration, style: const TextStyle(fontSize: 24)))]));
  }

  Widget _promoCard(String tag, String icon, String button, Color color) {
    return Container(height: 105, padding: const EdgeInsets.all(13), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: .9), Colors.white]), borderRadius: BorderRadius.circular(18)), child: Row(children: [Text(icon, style: const TextStyle(fontSize: 38)), const SizedBox(width: 8), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tag, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Text(button, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))) ]))]));
  }
}

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  static const rooms = [
    ['hotty hot 🔥🔥🔥🔥', 'Welcome to party!! we build friends tru...', '31', '🔥 Make Friends', 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600'],
    ['SINGH Agency', '💗 Radhe krishna 🦚', '4', '🎵 Music Party', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600'],
    ["Suman's room", "Welcome to my party room, let's chat", '3', '💬 Gossip', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600'],
    ["suhani's room", "Welcome to my party room, let's chat", '2', '💗 Emotional Share', 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=600'],
    ["humko v Patao's room", "Welcome to my party room, let's chat", '7', '🎵 Music Party', 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), children: [
      Row(children: [const Text('Me', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Colors.black45)), const SizedBox(width: 22), const Text('Party', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const Spacer(), const Icon(Icons.search_rounded, size: 31), const SizedBox(width: 15), const Text('👑', style: TextStyle(fontSize: 28))]),
      const SizedBox(height: 12),
      _tabs(),
      const SizedBox(height: 16),
      ...rooms.map((r) => _room(context, r)),
      const SizedBox(height: 8),
      _wideBanner('LUCKY BLESSING', 'x1000 Bonus'),
    ]));
  }

  Widget _tabs() => Row(children: [_tab('Popular', true), _tab('PK Battle', false), _tab('🎟 Event', false), _tab('🇮🇳 🇧🇩', false)]);
  Widget _tab(String text, bool active) => Expanded(child: Container(margin: const EdgeInsets.only(right: 7), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: active ? const Color(0xFFF0D9FF) : Colors.white, borderRadius: BorderRadius.circular(24)), child: Center(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? const Color(0xFF9956E8) : Colors.black54, fontWeight: FontWeight.w900)))));

  Widget _room(BuildContext context, List<String> r) {
    return InkWell(
      onTap: () => openPage(context, PartyRoomPage(title: r[0])),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                r[4],
                width: 94,
                height: 94,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 94,
                  height: 94,
                  color: const Color(0xFFE7D8F6),
                  child: const Icon(Icons.groups, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🇮🇳  ${r[0]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    r[1],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _smallTag(r[3]),
                      const Spacer(),
                      Text(
                        '▮▮ ${r[2]}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTag(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFE5F5), borderRadius: BorderRadius.circular(13)), child: Text(t, style: const TextStyle(color: Color(0xFFDA67B2), fontSize: 11, fontWeight: FontWeight.w800)));
  Widget _wideBanner(String a, String b) => Container(height: 86, margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B16C7), Color(0xFFB949D9)]), borderRadius: BorderRadius.circular(16)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(a, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), Text(b, style: const TextStyle(color: Color(0xFFFFE15B), fontSize: 18, fontWeight: FontWeight.w900))])));
}

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
      Row(children: [const Text('Moments', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const Spacer(), const Icon(Icons.search_rounded, size: 30), const SizedBox(width: 16), const Icon(Icons.camera_alt_outlined, size: 27)]),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(radius: 28, child: Icon(Icons.person)), SizedBox(width: 14), Expanded(child: Text('Share a moment with WikaLive...', style: TextStyle(color: Colors.black38, fontSize: 16))), Icon(Icons.add_circle, color: Color(0xFFB65BEA), size: 32)])),
      const SizedBox(height: 18),
      _moment('✨ Trending on WikaLive', 'What is everyone watching today?', Icons.local_fire_department_rounded),
      _moment('🎉 Party moments', 'Share your best party memories', Icons.celebration_rounded),
      _moment('💜 New friends', 'Meet people and discover new rooms', Icons.people_alt_rounded),
    ]));
  }

  Widget _moment(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2E6FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE7CCFF),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9B52E5),
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black45),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
      Row(children: [const Text('Message', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)), const SizedBox(width: 25), const Text('Friends', style: TextStyle(fontSize: 22, color: Colors.black45, fontWeight: FontWeight.w700)), const Spacer(), const Icon(Icons.settings_outlined, size: 29)]),
      const SizedBox(height: 20),
      Container(height: 55, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFFF0F0F3), borderRadius: BorderRadius.circular(28)), child: const Row(children: [Icon(Icons.search_rounded, color: Colors.black38), SizedBox(width: 12), Text("Please enter user's name", style: TextStyle(color: Colors.black26, fontSize: 16, fontWeight: FontWeight.w700)), Spacer(), Icon(Icons.tune_rounded)])),
      const SizedBox(height: 22),
      Row(children: [_quick('🦄', 'Crush Team'), _quick('❤️', 'New Follow'), _quick('👍', 'Interactive'), _quick('🎟', 'Event Center')]),
      const SizedBox(height: 28),
      _membership(),
    ]));
  }

  Widget _quick(String icon, String label) => Expanded(child: Column(children: [Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFFB30F), Color(0xFFE957B4)])), alignment: Alignment.center, child: Text(icon, style: const TextStyle(fontSize: 31))), const SizedBox(height: 9), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]));
  Widget _membership() => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(radius: 31, backgroundColor: Color(0xFFFFB51B), child: Icon(Icons.home_rounded, color: Colors.white, size: 34)), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('My Party Membership', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 7), Text("You haven't joined any rooms yet", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w700))]))]));
}

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final user = FirebaseAuth.instance.currentUser;
        final name = (data['name'] ?? user?.displayName ?? 'WikaLive User').toString();
        final coins = (data['coins'] ?? 0).toString();
        final shortId = uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase();

        return Container(
          color: const Color(0xFFF7F6FB),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Space',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ),
                    _topIcon(Icons.search_rounded),
                    const SizedBox(width: 10),
                    _topIcon(Icons.settings_rounded, onTap: () => openPage(context, const SettingsPage())),
                  ],
                ),
                const SizedBox(height: 14),
                _profileHero(name, shortId),
                const SizedBox(height: 14),
                _statsCard(),
                const SizedBox(height: 14),
                _kingCard(context),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _coinCard(context, coins)),
                    const SizedBox(width: 12),
                    Expanded(child: _gemCard(context)),
                  ],
                ),
                const SizedBox(height: 14),
                _inviteCard(context),
                const SizedBox(height: 16),
                _sectionTitle('My Space', '7 tools'),
                const SizedBox(height: 9),
                _toolPanel(context, [
                  _Tool(Icons.calendar_month_rounded, 'Task', const Color(0xFFFF5E72)),
                  _Tool(Icons.favorite_rounded, 'Level', const Color(0xFFE63F9A)),
                  _Tool(Icons.auto_awesome_rounded, 'Fans Club', const Color(0xFFFF4D91)),
                  _Tool(Icons.sports_esports_rounded, 'Game', const Color(0xFF6554E8)),
                  _Tool(Icons.backpack_rounded, 'Backpack', const Color(0xFFF06445)),
                  _Tool(Icons.shopping_bag_rounded, 'Dress Store', const Color(0xFFE84B7A)),
                  _Tool(Icons.confirmation_num_rounded, 'Event Center', const Color(0xFFFF695F)),
                ]),
                const SizedBox(height: 14),
                _sectionTitle('Privileges & Support', '7 services'),
                const SizedBox(height: 9),
                _toolPanel(context, [
                  _Tool(Icons.workspace_premium_rounded, 'VIP', const Color(0xFF17131F)),
                  _Tool(Icons.shield_rounded, 'Guardian', const Color(0xFF4B93B8)),
                  _Tool(Icons.login_rounded, 'Join Agency', const Color(0xFF5B9EB7)),
                  _Tool(Icons.verified_user_rounded, 'Real Person', const Color(0xFF4B4B55)),
                  _Tool(Icons.help_rounded, 'Help & Feedback', const Color(0xFFFF4F43)),
                  _Tool(Icons.headset_mic_rounded, 'Customer Service', const Color(0xFF50515B)),
                  _Tool(Icons.tune_rounded, 'Settings', const Color(0xFF5C98AA), isSetting: true),
                ], onTap: (tool) {
                  if (tool.isSetting) {
                    openPage(context, const SettingsPage());
                  } else {
                    openPage(context, _toolPage(tool.label));
                  }
                }),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'WikaLive  •  Your space, your story',
                    style: TextStyle(color: Color(0xFFAAA6B4), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Icon(icon, color: const Color(0xFF24212B), size: 23),
      ),
    );
  }

  Widget _profileHero(String name, String id) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1C43), Color(0xFF6B3D91), Color(0xFFB34D9B)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x301D1030), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(right: -22, top: -30, child: _glowCircle(115, const Color(0x35FFFFFF))),
          Positioned(right: 45, bottom: -45, child: _glowCircle(95, const Color(0x25FFD1F5))),
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFFFD37A), Color(0xFFFF6FB4)]),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                padding: const EdgeInsets.all(4),
                child: const CircleAvatar(
                  backgroundColor: Color(0xFFE8D7F8),
                  child: Icon(Icons.person_rounded, color: Color(0xFF5B3A8F), size: 45),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0x35FFFFFF), borderRadius: BorderRadius.circular(9)),
                          child: const Text('LV.1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text('ID: $id', style: const TextStyle(color: Color(0xFFDCCFE9), fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _miniBadge('🇮🇳', 'India'),
                        const SizedBox(width: 7),
                        _miniBadge('♀', '18'),
                        const SizedBox(width: 7),
                        _miniBadge('✦', '11'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _miniBadge(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x22FFFFFF))),
      child: Text('$icon $text', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 18, offset: Offset(0, 6))]),
      child: Row(
        children: [
          _stat('0', 'Friends'),
          _divider(),
          _stat('2', 'Following'),
          _divider(),
          _stat('0', 'Followers'),
          _divider(),
          _stat('2', 'Visitors'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: const Color(0xFFEDEAF1));

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF22202A))),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9994A3))),
        ],
      ),
    );
  }

  Widget _kingCard(BuildContext context) {
    return InkWell(
      onTap: () => openPage(context, const FeaturePage(
        title: 'King of Kings',
        icon: '💎',
        items: ['Premium status', 'Exclusive privileges', 'Special rewards'],
      )),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 126,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF17111E), Color(0xFF4B2267), Color(0xFF9A4B82)]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(color: Color(0x281B1025), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x25FFFFFF), border: Border.all(color: const Color(0x55FFFFFF))), child: const Center(child: Text('💎', style: TextStyle(fontSize: 32)))),
            const SizedBox(width: 13),
            const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('KING OF KINGS', style: TextStyle(color: Color(0xFFFFD98B), fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('Unlock your royal privileges', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('Exclusive status • special benefits', style: TextStyle(color: Color(0xFFDCCFE3), fontSize: 10.5, fontWeight: FontWeight.w600)),
            ])),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD66B), Color(0xFFFF9D36)]), borderRadius: BorderRadius.circular(16)), child: const Text('ACTIVATE', style: TextStyle(color: Color(0xFF3A2411), fontSize: 11, fontWeight: FontWeight.w900))),
          ],
        ),
      ),
    );
  }

  Widget _coinCard(BuildContext context, String coins) {
    return InkWell(
      onTap: () => openPage(context, const WalletPage()),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF3B9), Color(0xFFFFE7A1)]), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD66B)), child: const Center(child: Text('🪙', style: TextStyle(fontSize: 28)))), const SizedBox(width: 10), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFC83D), Color(0xFFFF7638)]), borderRadius: BorderRadius.circular(12)), child: const Text('RECHARGE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))), const SizedBox(height: 7), Text(coins, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))]))]),
      ),
    );
  }

  Widget _gemCard(BuildContext context) {
    return InkWell(
      onTap: () => openPage(context, const FeaturePage(title: 'Gems', icon: '💎', items: ['Gems balance', 'Premium uses', 'Gems history'])),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF0E0FF), Color(0xFFE5D1FF)]), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x33FFFFFF)), child: const Center(child: Text('💎', style: TextStyle(fontSize: 30)))),
          const SizedBox(width: 10),
          const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GEMS', style: TextStyle(fontSize: 11, letterSpacing: 1, color: Color(0xFF777083), fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('0', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          ]),
        ]),
      ),
    );
  }

  Widget _inviteCard(BuildContext context) {
    return InkWell(
      onTap: () => openPage(context, const FeaturePage(title: 'Invite & Earn', icon: '🎁', items: ['Invite users', 'Referral rewards', 'Invitation history'])),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 122,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3A1A52), Color(0xFF8B3F7A), Color(0xFFD36B75)]), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x221F1028), blurRadius: 16, offset: Offset(0, 7))]),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x22FFFFFF), border: Border.all(color: const Color(0x55FFFFFF))), child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD16B), size: 28)),
          const SizedBox(width: 14),
          const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('INVITE & EARN', style: TextStyle(color: Color(0xFFFFD16B), fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('Earn up to ₹2,250', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(height: 3),
            Text('Invite new users and unlock rewards', style: TextStyle(color: Color(0xFFE8DCEB), fontSize: 10.5, fontWeight: FontWeight.w600)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 17),
        ]),
      ),
    );
  }

  Widget _toolPage(String label) {
    switch (label) {
      case 'Task': return const FeaturePage(title: 'Task Center', icon: '📅', items: ['Daily tasks', 'Weekly missions', 'Task rewards', 'Task history']);
      case 'Level': return const FeaturePage(title: 'My Level', icon: '💗', items: ['Level progress', 'Level rewards', 'How to level up']);
      case 'Fans Club': return const FeaturePage(title: 'Fans Club', icon: '💖', items: ['My fans', 'Club level', 'Club rewards']);
      case 'Game': return const FeaturePage(title: 'Game Center', icon: '🎮', items: ['Mini games', 'Game ranking', 'Game rewards']);
      case 'Backpack': return const FeaturePage(title: 'Backpack', icon: '🎒', items: ['My items', 'Frames', 'Effects']);
      case 'Dress Store': return const FeaturePage(title: 'Dress Store', icon: '🛍️', items: ['Frames', 'Effects', 'Name decorations', 'Limited items']);
      case 'Event Center': return const FeaturePage(title: 'Event Center', icon: '🎟️', items: ['Live events', 'Party events', 'Rank events', 'Event rewards']);
      case 'VIP': return const FeaturePage(title: 'VIP', icon: '👑', items: ['VIP membership', 'VIP privileges', 'VIP badge', 'VIP rewards']);
      case 'Guardian': return const FeaturePage(title: 'Guardian', icon: '🛡️', items: ['Guardian status', 'Guard a host', 'Guardian privileges']);
      case 'Join Agency': return const AgencyPage();
      case 'Real Person': return const FeaturePage(title: 'Real Person Detection', icon: '🕵️', items: ['Verification', 'Verification status', 'Safety information']);
      case 'Help & Feedback': return const FeaturePage(title: 'Help & Feedback', icon: '❓', items: ['Common questions', 'Report a problem', 'Send feedback', 'Safety help']);
      case 'Customer Service': return const FeaturePage(title: 'Customer Service', icon: '🎧', items: ['Online support', 'Account help', 'Payment support', 'Live support']);
      default: return FeaturePage(title: label, icon: '✨', items: const ['Coming soon']);
    }
  }

  Widget _sectionTitle(String title, String count) {
    return Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF292630)))), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(10)), child: Text(count, style: const TextStyle(color: Color(0xFF73538E), fontSize: 9.5, fontWeight: FontWeight.w800)))]);
  }

  Widget _toolPanel(BuildContext context, List<_Tool> tools, {void Function(_Tool tool)? onTap}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 18, offset: Offset(0, 6))]),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tools.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisExtent: 106, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return InkWell(
            onTap: () => onTap?.call(tool),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 54, height: 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [tool.color.withValues(alpha: 0.14), tool.color.withValues(alpha: 0.06)]), shape: BoxShape.circle), child: Icon(tool.icon, color: tool.color, size: 29)),
                const SizedBox(height: 8),
                Text(tool.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.12, fontWeight: FontWeight.w800, color: Color(0xFF2A2730))),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSetting;
  const _Tool(this.icon, this.label, this.color, {this.isSetting = false});
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

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});
  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  String verificationId = '';
  bool codeSent = false;
  bool loading = false;

  @override
  void dispose() { phone.dispose(); otp.dispose(); super.dispose(); }

  Future<void> sendCode() async {
    final number = phone.text.trim();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
      msg(context, 'Enter number with country code, e.g. +91XXXXXXXXXX');
      return;
    }
    setState(() => loading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (e) { if (mounted) { setState(() => loading = false); msg(context, e.message ?? 'Phone verification failed'); } },
      codeSent: (id, _) { if (mounted) { setState(() { verificationId = id; codeSent = true; loading = false; }); msg(context, 'OTP sent'); } },
      codeAutoRetrievalTimeout: (id) { verificationId = id; },
    );
  }

  Future<void> verifyCode() async {
    if (verificationId.isEmpty || otp.text.trim().length != 6) { msg(context, 'Enter the 6-digit OTP'); return; }
    setState(() => loading = true);
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otp.text.trim());
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        if (!(await ref.get()).exists) {
          await ref.set({'uid': user.uid, 'name': 'WikaLive User', 'phone': user.phoneNumber ?? phone.text.trim(), 'coins': 0, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
        }
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      msg(context, e.message ?? 'Invalid OTP');
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Phone Login')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 30),
      const Icon(Icons.phone_iphone_rounded, size: 70),
      const SizedBox(height: 18),
      const Text('Login with your phone number', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 28),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', hintText: '+91XXXXXXXXXX', prefixIcon: Icon(Icons.phone_rounded), filled: true)),
      if (codeSent) ...[const SizedBox(height: 14), TextField(controller: otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'OTP', prefixIcon: Icon(Icons.lock_rounded), filled: true))],
      const SizedBox(height: 18),
      SizedBox(height: 52, child: FilledButton(onPressed: loading ? null : (codeSent ? verifyCode : sendCode), child: Text(loading ? 'Please wait...' : (codeSent ? 'Verify OTP' : 'Send OTP')))),
      if (codeSent) TextButton(onPressed: loading ? null : sendCode, child: const Text('Resend OTP')),
    ]),
  );
}

class FeaturePage extends StatelessWidget {
  final String title; final String icon; final List<String> items;
  const FeaturePage({super.key, required this.title, required this.icon, required this.items});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF241332), Color(0xFF9A4B82)]), borderRadius: BorderRadius.circular(24)), child: Column(children: [Text(icon, style: const TextStyle(fontSize: 48)), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('WikaLive premium space', style: TextStyle(color: Color(0xFFE9D9EF)))])),
      const SizedBox(height: 16),
      ...items.map((item) => Card(child: ListTile(leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B55E8)), title: Text(item, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => msg(context, '$item opened')))),
    ]),
  );
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
