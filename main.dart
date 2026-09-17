import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Google Sign-In v7+ requires explicit initialization.
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '3472205178-9u0i8qco4otu0qgmm6e9gabh4st49j1r.apps.googleusercontent.com',
  );

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
  String? gender;

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
    if (loading) return;
    setState(() => loading = true);

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        final ref =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snap = await ref.get();

        if (!snap.exists) {
          await ref.set({
            'uid': user.uid,
            'name': user.displayName ?? 'WikaLive User',
            'email': user.email ?? '',
            'coins': 0,
            'diamonds': 0,
            'bio': '',
            'country': 'India',
            'gender': null,
            'photos': user.photoURL == null ? [] : [user.photoURL],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on GoogleSignInException catch (e) {
      if (mounted) {
        msg(context, 'Google login failed: ${e.code}');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        msg(context, 'Google login failed: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (mounted) {
        msg(context, 'Google login failed: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

    if (!login && gender == null) {
      msg(context, 'Select your gender');
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
              'diamonds': 0,
              'bio': '',
              'country': 'India',
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
          'diamonds': 0,
          'bio': '',
          'country': 'India',
          'gender': gender,
          'photos': [],
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

              if (!login) ...[
                field(name, 'Name', Icons.person_outline),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_rounded), filled: true),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => gender = v),
                ),
              ],

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
                    gender = null;
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
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  final pages = const [LiveScreen(), PartyScreen(), MomentsScreen(), MessagesScreen(), MeScreen()];
  static const accent = Color(0xFFB65BEA);
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09070F),
      body: IndexedStack(index:index,children:pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFF100C18), border: Border(top: BorderSide(color: Color(0x221FFFFFF)))),
        child: NavigationBar(
          height: 76, backgroundColor: Colors.transparent, elevation: 0,
          selectedIndex:index, indicatorColor: const Color(0x263F1A55),
          onDestinationSelected:(i)=>setState(()=>index=i),
          labelTextStyle: WidgetStateProperty.resolveWith((st)=>TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:st.contains(WidgetState.selected)?Colors.white:Colors.white54)),
          destinations: const [
            NavigationDestination(icon:Icon(Icons.live_tv_outlined,color:Colors.white54),selectedIcon:Icon(Icons.live_tv_rounded,color:Color(0xFFD47BFF)),label:'Live'),
            NavigationDestination(icon:Icon(Icons.groups_outlined,color:Colors.white54),selectedIcon:Icon(Icons.groups_rounded,color:Color(0xFFD47BFF)),label:'Party'),
            NavigationDestination(icon:Icon(Icons.auto_awesome_outlined,color:Colors.white54),selectedIcon:Icon(Icons.auto_awesome,color:Color(0xFFD47BFF)),label:'Moments'),
            NavigationDestination(icon:Icon(Icons.forum_outlined,color:Colors.white54),selectedIcon:Icon(Icons.forum_rounded,color:Color(0xFFD47BFF)),label:'Message'),
            NavigationDestination(icon:Icon(Icons.person_outline_rounded,color:Colors.white54),selectedIcon:Icon(Icons.person_rounded,color:Color(0xFFD47BFF)),label:'Me'),
          ],
        ),
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
  String section = 'Follow';
  final sections = const [
    'Follow', 'Popular', 'Explore', 'Nearby', 'Beauty', 'Country', 'New Host'
  ];

  Query<Map<String, dynamic>> _base() => FirebaseFirestore.instance
      .collection('users')
      .where('isLive', isEqualTo: true);

  num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  DateTime _date(dynamic v) => v is Timestamp
      ? v.toDate()
      : DateTime.fromMillisecondsSinceEpoch(0);

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _hosts() {
    return _base().snapshots().map((s) {
      final list = [...s.docs];
      if (section == 'Popular' || section == 'Explore') {
        list.sort((a, b) => _num(b.data()['giftReceived'])
            .compareTo(_num(a.data()['giftReceived'])));
      }
      if (section == 'Beauty') {
        list.sort((a, b) => _num(b.data()['beautyScore'] ?? b.data()['qualityScore'])
            .compareTo(_num(a.data()['beautyScore'] ?? a.data()['qualityScore'])));
      }
      if (section == 'New Host') {
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        list.removeWhere((d) {
          final v = d.data()['createdAt'];
          return v is! Timestamp || _date(v).isBefore(cutoff);
        });
      }
      return list;
    });
  }

  Future<Set<String>> _following() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final q = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();
    return q.docs.map((e) => e.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF09070F),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WikaLive', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          SizedBox(height: 2),
                          Text('Discover people who are live now', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    _glass(Icons.search_rounded, () => openPage(context, const UserSearchPage())),
                    const SizedBox(width: 8),
                    _glass(Icons.leaderboard_rounded, () => openPage(context, const RankingPage())),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (c, i) {
                    final x = sections[i];
                    final active = section == x;
                    return InkWell(
                      onTap: () {
                        if (x == 'Country') {
                          openPage(context, const CountryLivePage());
                          return;
                        }
                        setState(() => section = x);
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: active
                              ? const LinearGradient(colors: [Color(0xFF9B55E8), Color(0xFFE052A5)])
                              : null,
                          color: active ? null : const Color(0xFF15111D),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: active ? Colors.transparent : const Color(0x18FFFFFF)),
                        ),
                        child: Text(x, style: TextStyle(color: active ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: _hero(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: Row(
                  children: [
                    const Text('Live now', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text(section, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _hosts(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                final docs = snap.data ?? [];
                if (section == 'Follow') {
                  return SliverToBoxAdapter(
                    child: FutureBuilder<Set<String>>(
                      future: _following(),
                      builder: (c, f) => _grid(
                        c,
                        docs.where((d) => (f.data ?? {}).contains(d.id)).toList(),
                        'No followed host is live right now.',
                      ),
                    ),
                  );
                }
                if (section == 'Nearby') {
                  return SliverToBoxAdapter(child: _nearby(context, docs));
                }
                return SliverToBoxAdapter(child: _grid(context, docs, 'No live hosts found.'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _glass(IconData icon, VoidCallback tap) => InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF15111D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x18FFFFFF)),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      );

  Widget _hero(BuildContext c) => Container(
        margin: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF28133E), Color(0xFF7B2F72), Color(0xFFE052A5)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x552D0C43), blurRadius: 28, offset: Offset(0, 12))],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -5,
              top: -20,
              child: Icon(Icons.auto_awesome, size: 120, color: Color(0x22FFFFFF)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(9)),
                  child: const Text('LIVE • REAL TIME', style: TextStyle(color: Color(0xFFFFD76A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const Spacer(),
                const Text('Your next\nfavorite host is live.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.02)),
                const SizedBox(height: 7),
                const Text('Watch • Chat • Follow • Gift', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: IconButton(
                onPressed: () => openPage(c, const HostPage()),
                icon: const Icon(Icons.add_circle, color: Colors.white, size: 34),
              ),
            ),
          ],
        ),
      );

  Widget _grid(BuildContext c, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String empty) {
    if (docs.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(empty, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      itemCount: docs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .68,
      ),
      itemBuilder: (c, i) {
        final x = docs[i].data();
        final raw = x['photos'];
        final photos = raw is List ? raw : [];
        final photo = photos.isNotEmpty ? photos.first.toString() : (x['photoUrl'] ?? '').toString();
        final name = (x['name'] ?? 'Host').toString();
        final viewers = x['viewers'] ?? 0;
        return InkWell(
          onTap: () => openPage(c, LiveRoomPage(host: name, viewers: '$viewers viewers')),
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                photo.isEmpty
                    ? Container(color: const Color(0xFF21182A), child: const Icon(Icons.person_rounded, size: 70, color: Color(0xFFB46BE0)))
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF21182A), child: const Icon(Icons.person_rounded, size: 70, color: Color(0xFFB46BE0))),
                      ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Color(0x66000000), Colors.transparent]),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xF5090610)]),
                  ),
                ),
                Positioned(top: 10, left: 10, child: _badge('LIVE')),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                    child: Text('${x['countryFlag'] ?? '🌍'}', style: const TextStyle(fontSize: 13)),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, color: Colors.white60, size: 14),
                          const SizedBox(width: 4),
                          Text('$viewers watching', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD76A), size: 17),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFE44787), borderRadius: BorderRadius.circular(9)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
      );

  Widget _nearby(BuildContext c, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _grid(c, [], 'Please login again.');
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (c, s) {
        final m = s.data?.data() ?? {};
        final lat = _num(m['latitude']);
        final lon = _num(m['longitude']);
        if (lat == 0 && lon == 0) {
          return const SizedBox(height: 250, child: Center(child: Text('Nearby needs saved location.', style: TextStyle(color: Colors.white54))));
        }
        final near = docs.where((d) {
          final x = d.data();
          final a = _num(x['latitude']);
          final b = _num(x['longitude']);
          final dx = (a - lat).abs() * 111;
          final dy = (b - lon).abs() * 111;
          return a != 0 && b != 0 && (dx * dx + dy * dy) < 2500;
        }).toList();
        return _grid(c, near, 'No live host found within 50 km.');
      },
    );
  }
}

class CountryLivePage extends StatelessWidget {
  const CountryLivePage({super.key});

  static const countries = [
    ['🇮🇳', 'India'], ['🇧🇩', 'Bangladesh'], ['🇵🇰', 'Pakistan'], ['🇳🇵', 'Nepal'],
    ['🇱🇰', 'Sri Lanka'], ['🇦🇪', 'UAE'], ['🇸🇦', 'Saudi Arabia'], ['🇮🇩', 'Indonesia'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore by Country')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: countries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45,
        ),
        itemBuilder: (context, index) {
          final country = countries[index];
          return InkWell(
            onTap: () => openPage(context, CountryHostsPage(country: country[1])),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5))],
              ),
              child: Row(children: [
                Text(country[0], style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 10),
                Expanded(child: Text(country[1], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class CountryHostsPage extends StatelessWidget {
  final String country;
  const CountryHostsPage({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$country Live')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').where('isLive', isEqualTo: true).where('country', isEqualTo: country).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          return _HostList(docs: snap.data?.docs ?? []);
        },
      ),
    );
  }
}

class _HostList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  const _HostList({required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const Center(child: Text('No live hosts'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final x = docs[index].data();
        final photo = (x['photoUrl'] ?? '').toString();
        return ListTile(
          contentPadding: const EdgeInsets.all(10),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: CircleAvatar(radius: 28, backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null, child: photo.isEmpty ? const Icon(Icons.person) : null),
          title: Text((x['name'] ?? 'Host').toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('LIVE • ${x['viewers'] ?? 0} viewers'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => openPage(context, LiveRoomPage(host: (x['name'] ?? 'Host').toString(), viewers: '${x['viewers'] ?? 0} viewers')),
        );
      },
    );
  }
}

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  static const rooms = [
    ['Midnight Vibes', 'Music • Chill', '31'],
    ['SINGH Agency', 'Talk • Meet', '24'],
    ['Suman’s Room', 'Friends • Chat', '18'],
    ['Late Night Cafe', 'Open Mic', '12'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF09070F),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Party', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      Text('Voice rooms & social nights', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _a(Icons.search_rounded, () => openPage(context, const FeaturePage(title: 'Search Party'))),
                const SizedBox(width: 8),
                _a(Icons.add_rounded, () => openPage(context, const CreatePartyPage())),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 170,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF21102F), Color(0xFF63306F), Color(0xFFB8498E)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: -8,
                    bottom: -22,
                    child: Icon(Icons.graphic_eq_rounded, size: 150, color: Color(0x1FFFFFFF)),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PARTY WORLD', style: TextStyle(color: Color(0xFFFFD76A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                      Spacer(),
                      Text('Find your people.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                      SizedBox(height: 5),
                      Text('Talk • Sing • Laugh • Connect', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: FilledButton(
                      onPressed: () => openPage(context, const CreatePartyPage()),
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF5C2B69)),
                      child: const Text('Create room'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (c, i) {
                  final x = ['Trending', 'Music', 'Talk', 'PK', 'New'][i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: i == 0 ? const Color(0xFF9B55E8) : const Color(0xFF15111D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(x, style: TextStyle(color: i == 0 ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.w800)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rooms you may like', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...rooms.map((r) => _room(context, r)),
          ],
        ),
      ),
    );
  }

  Widget _a(IconData i, VoidCallback t) => InkWell(
        onTap: t,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF15111D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x18FFFFFF)),
          ),
          child: Icon(i, color: Colors.white),
        ),
      );

  Widget _room(BuildContext c, List<String> r) => InkWell(
        onTap: () => openPage(c, PartyRoomPage(title: r[0])),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF120E18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE65CA7), Color(0xFF7540D8)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r[0], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(r[1], style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF55E68A), size: 8),
                        const SizedBox(width: 5),
                        Text('${r[2]} online', style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
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

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
      Row(children: [const Text('Moments', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: () => openPage(context, const FeaturePage(title: 'Search Moments')), icon: const Icon(Icons.search_rounded, size: 30)), const SizedBox(width: 6), IconButton(onPressed: () => openPage(context, const FeaturePage(title: 'Create Moment', icon: '📸', items: ['Add photo', 'Write a caption', 'Publish moment'])), icon: const Icon(Icons.camera_alt_outlined, size: 27))]),
      const SizedBox(height: 20),
      InkWell(onTap: () => openPage(context, const FeaturePage(title: 'Create Moment', icon: '📸', items: ['Add photo', 'Write a caption', 'Publish moment'])), borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(radius: 28, child: Icon(Icons.person)), SizedBox(width: 14), Expanded(child: Text('Share a moment with WikaLive...', style: TextStyle(color: Colors.black38, fontSize: 16))), Icon(Icons.add_circle, color: Color(0xFFB65BEA), size: 32)]))),
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
      Row(children: [const Text('Message', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)), const SizedBox(width: 25), const Text('Friends', style: TextStyle(fontSize: 22, color: Colors.black45, fontWeight: FontWeight.w700)), const Spacer(), IconButton(onPressed: () => openPage(context, const SettingsPage()), icon: const Icon(Icons.settings_outlined, size: 29))]),
      const SizedBox(height: 20),
      InkWell(onTap: () => openPage(context, const FeaturePage(title: 'Search Messages', icon: '🔎', items: ['Search users', 'Recent chats', 'Message requests'])), borderRadius: BorderRadius.circular(28), child: Container(height: 55, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFFF0F0F3), borderRadius: BorderRadius.circular(28)), child: const Row(children: [Icon(Icons.search_rounded, color: Colors.black38), SizedBox(width: 12), Text("Please enter user's name", style: TextStyle(color: Colors.black26, fontSize: 16, fontWeight: FontWeight.w700)), Spacer(), Icon(Icons.tune_rounded)]))),
      const SizedBox(height: 22),
      Row(children: [_quick('🦄', 'Wika Team'), _quick('❤️', 'New Follow'), _quick('👍', 'Interactive'), _quick('🎟', 'Event Center')]),
      const SizedBox(height: 28),
      _membership(),
    ]));
  }

  Widget _quick(String icon, String label) => Expanded(child: Column(children: [Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFFB30F), Color(0xFFE957B4)])), alignment: Alignment.center, child: Text(icon, style: const TextStyle(fontSize: 31))), const SizedBox(height: 9), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]));
  Widget _membership() => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(radius: 31, backgroundColor: Color(0xFFFFB51B), child: Icon(Icons.home_rounded, color: Colors.white, size: 34)), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('My Party Membership', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 7), Text("You haven't joined any rooms yet", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w700))]))]));
}

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});
  @override Widget build(BuildContext context){final u=FirebaseAuth.instance.currentUser;final uid=u?.uid;if(uid==null)return const Center(child:Text('Please login again',style:TextStyle(color:Colors.white)));return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),builder:(context,s){final d=s.data?.data()??{};final name=(d['name']??u?.displayName??'WikaLive User').toString();final id=(d['id']??uid.substring(0,8)).toString();final raw=d['photos'];final photos=raw is List?raw:[];final photo=photos.isNotEmpty?photos.first.toString():(d['photoUrl']??'').toString();return Container(color:const Color(0xFF09070F),child:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
    Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Me',style:TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),Text('Your WikaLive space',style:TextStyle(color:Colors.white54,fontSize:11,fontWeight:FontWeight.w600))])),IconButton(onPressed:()=>openPage(context,const SettingsPage()),icon:const Icon(Icons.settings_rounded,color:Colors.white70))]),
    const SizedBox(height:8),InkWell(onTap:()=>openPage(context,const ProfilePage()),borderRadius:BorderRadius.circular(28),child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF241536),Color(0xFF66336F),Color(0xFFB74D9E)]),borderRadius:BorderRadius.circular(28),boxShadow:const[BoxShadow(color:Color(0x402E0D43),blurRadius:24,offset:Offset(0,10))]),child:Row(children:[CircleAvatar(radius:38,backgroundImage:photo.isNotEmpty?NetworkImage(photo):null,backgroundColor:const Color(0xFFE7D7F4),child:photo.isEmpty?const Icon(Icons.person_rounded,size:42,color:Color(0xFF65418A)):null),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text('ID: $id',style:const TextStyle(color:Colors.white60,fontSize:10,fontWeight:FontWeight.w700)),const SizedBox(height:9),Row(children:[_chip('LV 1'),const SizedBox(width:6),_chip((d['country']??'India').toString()),const SizedBox(width:6),_chip('Edit')])])),const Icon(Icons.chevron_right_rounded,color:Colors.white54)]))),
    const SizedBox(height:14),_stats(context,uid),const SizedBox(height:14),Row(children:[Expanded(child:_money(context,'🪙','Coins','Recharge',const WalletPage())),const SizedBox(width:10),Expanded(child:_money(context,'💎','Diamonds','Withdraw',const DiamondWithdrawalPage()))]),const SizedBox(height:18),const Text('Quick access',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:4,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:.86,children:[_quick(context,Icons.person_add_alt_1,'Following',const FollowingPage()),_quick(context,Icons.people_alt_rounded,'Followers',const FollowersPage()),_quick(context,Icons.visibility_rounded,'Visitors',const VisitorsPage()),_quick(context,Icons.card_giftcard_rounded,'Gifts',const GiftsPage()),_quick(context,Icons.workspace_premium_rounded,'Ranking',const RankingPage()),_quick(context,Icons.favorite_rounded,'Friends',const FriendsPage()),_quick(context,Icons.notifications_rounded,'Alerts',const NotificationsPage()),_quick(context,Icons.live_tv_rounded,'Go Live',const HostPage())]),
  ])));});}
  Widget _chip(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:const Color(0x25FFFFFF),borderRadius:BorderRadius.circular(9)),child:Text(t,style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w800)));
  Widget _stats(BuildContext c,String uid)=>Container(padding:const EdgeInsets.symmetric(vertical:17),decoration:BoxDecoration(color:const Color(0xFF120E18),borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0x14FFFFFF))),child:Row(children:[_count(c,uid,'friends','Friends',const FriendsPage()),_count(c,uid,'following','Following',const FollowingPage()),_count(c,uid,'followers','Followers',const FollowersPage()),_count(c,uid,'visitors','Visitors',const VisitorsPage())]));
  Widget _count(BuildContext c,String uid,String sub,String label,Widget page)=>Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').doc(uid).collection(sub).snapshots(),builder:(c,s)=>InkWell(onTap:()=>openPage(c,page),child:Column(children:[Text('${s.data?.size??0}',style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(label,style:const TextStyle(color:Colors.white38,fontSize:9,fontWeight:FontWeight.w700))]))));
  Widget _money(BuildContext c,String e,String t,String sub,Widget page)=>InkWell(onTap:()=>openPage(c,page),borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF17111F),Color(0xFF24162E)]),borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0x16FFFFFF))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e,style:const TextStyle(fontSize:24)),const SizedBox(height:5),Text(t,style:const TextStyle(color:Colors.white54,fontSize:10,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(sub,style:const TextStyle(color:Color(0xFFD57BFF),fontSize:11,fontWeight:FontWeight.w900))])));
  Widget _quick(BuildContext c,IconData i,String t,Widget p)=>InkWell(onTap:()=>openPage(c,p),borderRadius:BorderRadius.circular(18),child:Container(decoration:BoxDecoration(color:const Color(0xFF120E18),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0x14FFFFFF))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,color:const Color(0xFFD477FF),size:24),const SizedBox(height:8),Text(t,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:9,fontWeight:FontWeight.w800))])));
}

class _Tool {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSetting;
  const _Tool(this.icon, this.label, this.color, {this.isSetting = false});
}

class LiveRoomPage extends StatefulWidget {
  final String host; final String viewers;
  const LiveRoomPage({super.key,required this.host,required this.viewers});
  @override State<LiveRoomPage> createState()=>_LiveRoomPageState();
}
class _LiveRoomPageState extends State<LiveRoomPage> {
  bool following=false; final controller=TextEditingController(); final chat=['Alex: Hello 👋','Sam: Nice live!','Mia: Amazing room ✨'];
  @override void dispose(){controller.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.black,body:SafeArea(child:Stack(children:[
    Positioned.fill(child:Container(decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF25133A),Color(0xFF8A3E8F),Color(0xFF070609)])),child:const Center(child:Icon(Icons.person_rounded,size:150,color:Colors.white12)))),
    Positioned(top:10,left:10,right:10,child:Row(children:[IconButton(onPressed:()=>Navigator.pop(context),style:IconButton.styleFrom(backgroundColor:Colors.black45),icon:const Icon(Icons.close_rounded,color:Colors.white)),const CircleAvatar(radius:23,child:Icon(Icons.person)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.host,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:16)),Text('● ${widget.viewers}',style:const TextStyle(color:Colors.white70,fontSize:11))])),TextButton(onPressed:()=>setState(()=>following=!following),style:TextButton.styleFrom(backgroundColor:const Color(0xCCFFFFFF)),child:Text(following?'Following':'Follow'))])),
    Positioned(top:78,right:12,child:Column(children:[_roomButton(Icons.share_rounded,'Share'),const SizedBox(height:8),_roomButton(Icons.favorite_rounded,'Like'),const SizedBox(height:8),_roomButton(Icons.card_giftcard_rounded,'Gift')])),
    Positioned(left:12,right:70,bottom:86,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:chat.map((x)=>_ChatBubble(x)).toList())),
    Positioned(left:10,right:10,bottom:10,child:Row(children:[Expanded(child:TextField(controller:controller,style:const TextStyle(color:Colors.white),decoration:InputDecoration(hintText:'Say something…',hintStyle:const TextStyle(color:Colors.white54),filled:true,fillColor:Colors.black45,border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(28)),borderSide:BorderSide.none)))),const SizedBox(width:7),_roomButton(Icons.send_rounded,'Send',onTap:(){final t=controller.text.trim();if(t.isNotEmpty)setState(()=>chat.add('You: $t'));controller.clear();}),const SizedBox(width:7),_roomButton(Icons.card_giftcard_rounded,'Gift',onTap:()=>showGiftSheet(context))]))
  ])));
  Widget _roomButton(IconData i,String t,{VoidCallback? onTap})=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),decoration:BoxDecoration(color:Colors.black45,borderRadius:BorderRadius.circular(18)),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(i,color:Colors.white,size:22),Text(t,style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700))])));
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
                  openPage(context, const RechargePage());
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
                const DiamondWithdrawalPage(),
              ),
            ],
          );
        },
      ),
    );
  }
}


class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final amounts = const [100, 500, 1000, 2500, 5000, 10000];
  bool loading = false;

  Future<void> recharge(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      msg(context, 'Please login again');
      return;
    }

    setState(() => loading = true);
    try {
      // Demo/local wallet action. A real payment gateway must be connected
      // before charging a user's real money.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastRechargeAmount': amount,
        'lastRechargeAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => loading = false);
      msg(context, 'Recharge selected: ₹$amount');
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      msg(context, 'Unable to process recharge');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharge')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Choose an amount', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: amounts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (_, i) => FilledButton(
              onPressed: loading ? null : () => recharge(amounts[i]),
              child: Text('₹${amounts[i]}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Payment gateway is not connected yet, so this screen records the selected recharge amount without charging real money.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
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
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Host application'),
                  content: const Text('Your host application has been submitted successfully.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('OK'),
                    ),
                  ],
                ),
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
              openPage(context, const SimplePage(title: 'My Agency', items: ['Agency dashboard', 'Agency profile', 'Agency earnings', 'Agency members']));
            },
          ),

          menu(
            context,
            'Invitations',
            Icons.mail_outline,
            null,
            onTap: () {
              openPage(context, const SimplePage(title: 'Invitations', items: ['No pending invitations', 'Invite a host', 'Invitation history']));
            },
          ),

          menu(
            context,
            'My Hosts',
            Icons.people_outline,
            null,
            onTap: () {
              openPage(context, const SimplePage(title: 'My Hosts', items: ['My hosts', 'Active hosts', 'Host performance']));
            },
          ),

          menu(
            context,
            'Join Agency',
            Icons.login,
            null,
            onTap: () {
              openPage(context, const SimplePage(title: 'Join Agency', items: ['Find an agency', 'Agency invitation code', 'Join request status']));
            },
          ),
        ],
      ),
    );
  }
}


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF09070F),
        body: Center(
          child: Text('Please login again', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),
      builder: (context, s) {
        final d = s.data?.data() ?? <String, dynamic>{};
        final raw = d['photos'];
        final photos = raw is List
            ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).take(5).toList()
            : <String>[];
        if (photos.isEmpty && (d['photoUrl'] ?? '').toString().isNotEmpty) {
          photos.add(d['photoUrl'].toString());
        }
        final name = (d['name'] ?? u.displayName ?? 'WikaLive User').toString();
        final id = (d['id'] ?? (u.uid.length >= 8 ? u.uid.substring(0, 8) : u.uid)).toString();

        return Scaffold(
          backgroundColor: const Color(0xFF09070F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF09070F),
            foregroundColor: Colors.white,
            title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(
                onPressed: () => openPage(context, const EditProfilePage()),
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              SizedBox(
                height: 360,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photos.isEmpty
                        ? Container(
                            color: const Color(0xFF1B1422),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 110,
                              color: Color(0xFFB46BE0),
                            ),
                          )
                        : PageView.builder(
                            itemCount: photos.length,
                            itemBuilder: (c, i) => Image.network(
                              photos[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1B1422),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 110,
                                  color: Color(0xFFB46BE0),
                                ),
                              ),
                            ),
                          ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xFF09070F)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'ID: $id',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0x55FFFFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${photos.length}/5 photos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (d['bio'] ?? '').toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _tag('🌍 ${d['country'] ?? 'India'}'),
                        _tag('🎙 ${d['language'] ?? 'English'}'),
                        if ('${d['tag'] ?? ''}'.isNotEmpty) _tag('#${d['tag']}'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => openPage(context, const FollowingPage()),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Following'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openPage(context, const FollowersPage()),
                            icon: const Icon(Icons.people_alt_outlined),
                            label: const Text('Followers'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'About',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    _line('Gender', d['gender']),
                    _line('Birthday', d['birthday']),
                    _line('Language', d['language']),
                    _line('Country', d['country']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF17111F),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0x18FFFFFF)),
        ),
        child: Text(
          t,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      );

  Widget _line(String a, dynamic d) => d == null || '$d'.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(a, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$d', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final picker = ImagePicker();
  final name = TextEditingController();
  final bio = TextEditingController();
  final birthday = TextEditingController();
  final tag = TextEditingController();
  final language = TextEditingController();
  final country = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  List<String> photos = [];
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    name.dispose(); bio.dispose(); birthday.dispose(); tag.dispose(); language.dispose(); country.dispose(); height.dispose(); weight.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final d = (await FirebaseFirestore.instance.collection('users').doc(u.uid).get()).data() ?? {};
    name.text = (d['name'] ?? u.displayName ?? '').toString();
    bio.text = (d['bio'] ?? '').toString();
    birthday.text = (d['birthday'] ?? '').toString();
    tag.text = (d['tag'] ?? '').toString();
    language.text = (d['language'] ?? '').toString();
    country.text = (d['country'] ?? 'India').toString();
    height.text = (d['height'] ?? '').toString();
    weight.text = (d['weight'] ?? '').toString();
    final raw = d['photos'];
    photos = raw is List ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).take(5).toList() : [];
    if (photos.isEmpty && (d['photoUrl'] ?? '').toString().isNotEmpty) photos.add(d['photoUrl'].toString());
    if (mounted) setState(() => loading = false);
  }

  Future<void> _addPhoto() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || photos.length >= 5) return;
    try {
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1800);
      if (file == null) return;
      setState(() => saving = true);
      final ref = FirebaseStorage.instance.ref('users/${u.uid}/photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(await file.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      if (mounted) setState(() => photos.add(url));
    } catch (e) {
      if (mounted) msg(context, 'Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _save() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    setState(() => saving = true);
    try {
      await u.updateDisplayName(name.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'name': name.text.trim(), 'bio': bio.text.trim(), 'birthday': birthday.text.trim(), 'tag': tag.text.trim(),
        'language': language.text.trim(), 'country': country.text.trim(), 'height': height.text.trim(), 'weight': weight.text.trim(),
        'photos': photos, 'photoUrl': photos.isEmpty ? '' : photos.first, 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) { msg(context, 'Profile updated'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) msg(context, 'Update failed: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _field(String label, TextEditingController c, IconData icon, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: const Color(0xFFF7F7FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final completion = [name.text, bio.text, birthday.text, tag.text, language.text, country.text, photos.isNotEmpty ? 'photo' : ''].where((x) => x.trim().isNotEmpty).length * 14;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text('Edit information', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true, backgroundColor: Colors.white),
      body: ListView(
        children: [
          Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(18, 0, 18, 14), child: Center(child: Text('Completion ${completion.clamp(0, 100)}%', style: const TextStyle(color: Color(0xFFF08B2E), fontSize: 17, fontWeight: FontWeight.w900)))),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('My album  +0% ↗', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              SizedBox(height: 118, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 5, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, i) {
                if (i >= photos.length) return GestureDetector(onTap: saving ? null : _addPhoto, child: Container(width: 105, decoration: BoxDecoration(color: const Color(0xFFF0F1F5), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.add_rounded, size: 42, color: Color(0xFFD2D7E5))));
                return Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(photos[i], width: 105, height: 118, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 105, height: 118, color: soft, child: const Icon(Icons.person)))), Positioned(right: 5, top: 5, child: InkWell(onTap: () => setState(() => photos.removeAt(i)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16))))]);
              })),
              const SizedBox(height: 10),
              const Text('Add up to 5 photos. The first photo is your main profile photo.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),
          Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(18, 20, 18, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Basic information  +15% ↗', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _field('Nickname', name, Icons.person_outline_rounded),
            _field('Birthday', birthday, Icons.cake_outlined),
            _field('Height', height, Icons.height_rounded),
            _field('Weight', weight, Icons.monitor_weight_outlined),
          ])),
          const SizedBox(height: 8),
          Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(18, 20, 18, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Personal information  +25% ↗', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _field('Language', language, Icons.language_rounded),
            _field('Tag', tag, Icons.local_offer_outlined),
            _field('Country', country, Icons.flag_outlined),
            _field('Bio', bio, Icons.edit_note_rounded, maxLines: 3),
            const SizedBox(height: 8),
            const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.male_rounded), title: Text('Gender'), subtitle: Text('Gender is selected during account creation and cannot be changed here.')),
          ])),
          Padding(padding: const EdgeInsets.all(18), child: SizedBox(height: 54, child: FilledButton(onPressed: saving ? null : _save, child: Text(saving ? 'Saving...' : 'Save information', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))))),
        ],
      ),
    );
  }
}

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  String type = 'Live';
  String period = 'Daily';
  final types = const ['Live', 'Sender', 'Party'];
  final periods = const ['Hourly', 'Daily', 'Weekly'];

  String get field {
    switch (type) {
      case 'Sender': return 'giftSent';
      case 'Party': return 'partyGiftReceived';
      default: return 'giftReceived';
    }
  }

  Color get accent => const Color(0xFFFFB52E);

  num _number(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

  String _amount(dynamic v) {
    final n = _number(v);
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}m';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }

  String _photo(Map<String, dynamic> d) {
    final photos = d['photos'];
    if (photos is List && photos.isNotEmpty) return photos.first.toString();
    return (d['photoUrl'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF21170C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF21170C),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Ranking', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: types.map((x) => Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: GestureDetector(
                    onTap: () => setState(() => type = x),
                    child: Column(
                      children: [
                        Text(
                          x == 'Live' ? '💗 Live' : x == 'Sender' ? '💰 Sender' : '🏠 Party',
                          style: TextStyle(color: type == x ? Colors.white : Colors.white60, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 7),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(color: type == x ? accent : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 48,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(28)),
            child: Row(
              children: periods.map((x) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => period = x),
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: period == x ? const Color(0xFFFFE89A) : Colors.transparent, borderRadius: BorderRadius.circular(25)),
                    child: Text(x, style: TextStyle(color: period == x ? Colors.black87 : Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            child: Row(children: [
              const Icon(Icons.access_time_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 7),
              const Text('Today\'s ranking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(period, style: TextStyle(color: accent, fontWeight: FontWeight.w900)),
            ]),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = [...(snapshot.data?.docs ?? [])];
                docs.sort((a, b) => _number(b.data()[field]).compareTo(_number(a.data()[field])));
                final top = docs.take(50).toList();
                if (top.isEmpty) return const Center(child: Text('No ranking data', style: TextStyle(color: Colors.white70)));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 30),
                  children: [
                    if (top.length >= 3) _podium(context, top[0], top[1], top[2]),
                    ...List.generate(top.length > 3 ? top.length - 3 : 0, (i) {
                      final rank = i + 4;
                      return _rankTile(context, top[i + 3], rank);
                    }),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(color: const Color(0xFF3A2815), borderRadius: BorderRadius.circular(24), border: Border.all(color: accent.withOpacity(.22))),
                      child: Row(children: [
                        const Text('50+', style: TextStyle(color: Colors.white70, fontSize: 25, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 18),
                        const CircleAvatar(radius: 26, child: Icon(Icons.person)),
                        const SizedBox(width: 14),
                        const Expanded(child: Text('Your position', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17))),
                        Text('0', style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 20)),
                      ]),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _podium(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> first, QueryDocumentSnapshot<Map<String, dynamic>> second, QueryDocumentSnapshot<Map<String, dynamic>> third) {
    final items = [second, first, third];
    final labels = [2, 1, 3];
    final heights = [205.0, 245.0, 190.0];
    return SizedBox(
      height: 305,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final d = items[i].data();
          final url = _photo(d);
          return Expanded(
            child: GestureDetector(
              onTap: () => openPage(context, UserProfilePage(uid: items[i].id)),
              child: Container(
                height: heights[i],
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFE8A6), i == 1 ? const Color(0xFFD18A21) : const Color(0xFF9E6D39)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: const Color(0xFFFFD76A), width: 1.4),
                ),
                child: Column(children: [
                  Text(labels[i] == 1 ? '👑' : 'TOP${labels[i]}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF6B4212))),
                  const SizedBox(height: 6),
                  CircleAvatar(radius: i == 1 ? 48 : 39, backgroundImage: url.isNotEmpty ? NetworkImage(url) : null, child: url.isEmpty ? const Icon(Icons.person, size: 35) : null),
                  const SizedBox(height: 7),
                  Text((d['name'] ?? 'User').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5A3510))),
                  const SizedBox(height: 5),
                  Text('${d['countryFlag'] ?? '🌍'}', style: const TextStyle(fontSize: 20)),
                  const Spacer(),
                  Text('${_amount(d[field])}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3C250A))),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _rankTile(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc, int rank) {
    final d = doc.data();
    final url = _photo(d);
    return GestureDetector(
      onTap: () => openPage(context, UserProfilePage(uid: doc.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF342313), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          SizedBox(width: 38, child: Text('$rank', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w800))),
          CircleAvatar(radius: 30, backgroundImage: url.isNotEmpty ? NetworkImage(url) : null, child: url.isEmpty ? const Icon(Icons.person) : null),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((d['name'] ?? 'User').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${d['countryFlag'] ?? '🌍'}  ${d['title'] ?? 'WikaLive User'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700)),
          ])),
          Text('${_amount(d[field])}', style: TextStyle(color: accent, fontSize: 19, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class MyApp extends WikaLiveApp {
  const MyApp({super.key});
}

class FollowingPage extends StatelessWidget {
  const FollowingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const _UserSubList(title: 'Following', sub: 'following');
  }
}

class FollowersPage extends StatelessWidget {
  const FollowersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const _UserSubList(title: 'Followers', sub: 'followers');
  }
}

class UserProfilePage extends StatelessWidget {
  final String uid;
  const UserProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final d = snapshot.data!.data() ?? {};
          final raw = d['photos'];
          final photos = raw is List
              ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).take(5).toList()
              : <String>[];
          if (photos.isEmpty && (d['photoUrl'] ?? '').toString().isNotEmpty) {
            photos.add(d['photoUrl'].toString());
          }

          return ListView(
            children: [
              SizedBox(
                height: 300,
                child: photos.isEmpty
                    ? Container(
                        color: soft,
                        child: const Icon(Icons.person, size: 110),
                      )
                    : PageView.builder(
                        itemCount: photos.length,
                        itemBuilder: (context, index) => Image.network(
                          photos[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: soft,
                            child: const Icon(Icons.person, size: 110),
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (d['name'] ?? 'WikaLive User').toString(),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text((d['bio'] ?? '').toString()),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _profileInfo('Gender', d['gender']),
                        _profileInfo('Birthday', d['birthday']),
                        _profileInfo('Tag', d['tag']),
                        _profileInfo('Language', d['language']),
                        _profileInfo('Country', d['country']),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (FirebaseAuth.instance.currentUser?.uid != uid)
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('following')
                            .doc(uid)
                            .snapshots(),
                        builder: (context, followingSnapshot) {
                          final following = followingSnapshot.data?.exists ?? false;
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final me = FirebaseAuth.instance.currentUser;
                                if (me == null || me.uid == uid) return;
                                final myRef = FirebaseFirestore.instance
                                    .collection('users').doc(me.uid)
                                    .collection('following').doc(uid);
                                final theirRef = FirebaseFirestore.instance
                                    .collection('users').doc(uid)
                                    .collection('followers').doc(me.uid);
                                if (following) {
                                  await myRef.delete();
                                  await theirRef.delete();
                                } else {
                                  await myRef.set({
                                    'uid': uid,
                                    'name': (d['name'] ?? 'User').toString(),
                                    'photoUrl': (d['photoUrl'] ?? '').toString(),
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  await theirRef.set({
                                    'uid': me.uid,
                                    'name': (me.displayName ?? 'User').toString(),
                                    'photoUrl': '',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                }
                              },
                              icon: Icon(following ? Icons.check : Icons.person_add_alt_1),
                              label: Text(following ? 'Following' : 'Follow'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _profileInfo(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Chip(label: Text('$label: $value'));
  }
}

class FriendsPage extends StatelessWidget { const FriendsPage({super.key}); @override Widget build(BuildContext c)=>_UserSubList(title:'Friends',sub:'friends'); }
class VisitorsPage extends StatelessWidget { const VisitorsPage({super.key}); @override Widget build(BuildContext c)=>_UserSubList(title:'Visitors',sub:'visitors'); }
class _UserSubList extends StatelessWidget { final String title,sub; const _UserSubList({required this.title,required this.sub}); @override Widget build(BuildContext c){final u=FirebaseAuth.instance.currentUser;if(u==null)return const Scaffold(body:Center(child:Text('Please login again')));return Scaffold(appBar:AppBar(title:Text(title)),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').doc(u.uid).collection(sub).snapshots(),builder:(c,s){final docs=s.data?.docs??[];if(docs.isEmpty)return Center(child:Text('No $title yet'));return ListView.builder(itemCount:docs.length,itemBuilder:(c,i){final d=docs[i].data();final id=(d['uid']??docs[i].id).toString();return ListTile(leading:CircleAvatar(child:const Icon(Icons.person)),title:Text((d['name']??'User').toString()),onTap:()=>openPage(c,UserProfilePage(uid:id)));});}));}}

class UserSearchPage extends StatefulWidget { const UserSearchPage({super.key}); @override State<UserSearchPage> createState()=>_UserSearchPageState(); }
class _UserSearchPageState extends State<UserSearchPage> { final c=TextEditingController(); @override void dispose(){c.dispose();super.dispose();} @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Search Users')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:c,onSubmitted:(_)=>setState((){}),decoration:InputDecoration(labelText:'Search by exact name',suffixIcon:IconButton(onPressed:()=>setState((){}),icon:const Icon(Icons.search)),filled:true)),const SizedBox(height:12),if(c.text.trim().isNotEmpty)StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').where('name',isEqualTo:c.text.trim()).limit(20).snapshots(),builder:(context,s){final docs=s.data?.docs??[];if(docs.isEmpty)return const Padding(padding:EdgeInsets.all(20),child:Text('No users found'));return Column(children:docs.map((d)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text((d.data()['name']??'User').toString()),onTap:()=>openPage(context,UserProfilePage(uid:d.id)))).toList());})]));}
class DiamondWithdrawalPage extends StatefulWidget { const DiamondWithdrawalPage({super.key}); @override State<DiamondWithdrawalPage> createState()=>_DiamondWithdrawalPageState(); }
class _DiamondWithdrawalPageState extends State<DiamondWithdrawalPage> { final amount=TextEditingController(); final upi=TextEditingController(); bool loading=false; @override void dispose(){amount.dispose();upi.dispose();super.dispose();} Future<void> request()async{final u=FirebaseAuth.instance.currentUser;if(u==null)return;final n=int.tryParse(amount.text.trim())??0;if(n<=0){msg(context,'Enter diamonds to withdraw');return;}if(upi.text.trim().isEmpty){msg(context,'Enter UPI ID');return;}setState(()=>loading=true);try{final ref=FirebaseFirestore.instance.collection('users').doc(u.uid);await FirebaseFirestore.instance.runTransaction((tx)async{final snap=await tx.get(ref);final d=snap.data()?['diamonds'];final balance=d is num?d.toInt():0;if(n>balance)throw Exception('Not enough diamonds');final req=FirebaseFirestore.instance.collection('diamond_withdrawals').doc();tx.update(ref,{'diamonds':balance-n,'updatedAt':FieldValue.serverTimestamp()});tx.set(req,{'uid':u.uid,'diamonds':n,'upiId':upi.text.trim(),'status':'pending','createdAt':FieldValue.serverTimestamp()});});if(mounted){amount.clear();msg(context,'Withdrawal request submitted');}}catch(e){if(mounted)msg(context,e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>loading=false);}} @override Widget build(BuildContext context){final u=FirebaseAuth.instance.currentUser!;return Scaffold(appBar:AppBar(title:const Text('Diamond Withdrawal')),body:ListView(padding:const EdgeInsets.all(20),children:[StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),builder:(context,s){final d=s.data?.data();final b=d?['diamonds'] is num?(d!['diamonds'] as num).toInt():0;return Card(child:ListTile(title:const Text('Available Diamonds'),subtitle:Text('$b 💎',style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900))));}),const SizedBox(height:14),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Diamonds to withdraw',prefixIcon:Icon(Icons.diamond_outlined),filled:true)),const SizedBox(height:14),TextField(controller:upi,decoration:const InputDecoration(labelText:'UPI ID',prefixIcon:Icon(Icons.account_balance_wallet_outlined),filled:true)),const SizedBox(height:20),SizedBox(height:52,child:FilledButton(onPressed:loading?null:request,child:Text(loading?'Submitting...':'Request Withdrawal')))]));}
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
                  final amount = int.tryParse(controller.text.trim()) ?? 0;
                  if (amount <= 0) {
                    msg(context, 'Enter a valid withdrawal amount');
                    return;
                  }
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Withdrawal request'),
                      content: Text('Withdrawal request for ₹$amount has been submitted.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
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
              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(title: Text('Language', style: TextStyle(fontWeight: FontWeight.w900))),
                      for (final language in ['English', 'Hindi', 'Bangla'])
                        ListTile(
                          title: Text(language),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            msg(context, '$language selected');
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          menu(
            context,
            'Privacy & Security',
            Icons.security,
            null,
            onTap: () {
              openPage(context, const FeaturePage(title: 'Privacy & Security', icon: '🔐', items: ['Privacy controls', 'Blocked users', 'Security information']));
            },
          ),

          menu(
            context,
            'Help & Support',
            Icons.help_outline,
            null,
            onTap: () {
              openPage(context, const FeaturePage(title: 'Help & Support', icon: '❓', items: ['Frequently asked questions', 'Report a problem', 'Contact support']));
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
          await ref.set({'uid': user.uid, 'name': 'WikaLive User', 'phone': user.phoneNumber ?? phone.text.trim(), 'coins': 0, 'diamonds': 0, 'bio': '', 'country': 'India', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
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
  const FeaturePage({super.key, required this.title, this.icon = '✨', this.items = const ['Information', 'Open feature']});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF241332), Color(0xFF9A4B82)]), borderRadius: BorderRadius.circular(24)), child: Column(children: [Text(icon, style: const TextStyle(fontSize: 48)), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const SizedBox.shrink()])),
      const SizedBox(height: 16),
      ...items.map((item) => Card(child: ListTile(leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B55E8)), title: Text(item, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => openPage(context, SimplePage(title: item, items: [item, 'This section is available in WikaLive.', 'Use the options on this page to continue.']))))),
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
