import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await GoogleSignIn.instance.initialize(
    serverClientId:
        '3472205178-9u0i8qco4otu0qgmm6e9gabh4st49j1r.apps.googleusercontent.com',
  );

  runApp(const WikaLiveApp());
}

const bg = Color(0xFFF7F5FC);
const card = Colors.white;
const soft = Color(0xFFF0ECF8);
const primary = Color(0xFF8B3FD9);
const primaryDark = Color(0xFF5B1C9C);
const accent = Color(0xFFE94D9A);
const int kZegoAppId = 1236782539;
const String kZegoAppSign = String.fromEnvironment('ZEGO_APP_SIGN');

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
        colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, backgroundColor: bg, surfaceTintColor: Colors.transparent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: primary, width: 1.4)),
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
      final googleUser =
          await GoogleSignIn.instance.authenticate();

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

        final existing = await ref.get();

        if (!existing.exists) {
          await ref.set({
            'uid': user.uid,
            'name': user.displayName ?? 'WikaLive User',
            'email': user.email ?? '',
            'coins': 0,
            'diamonds': 0,
            'bio': '',
            'country': 'India',
            'gender': null,
            'photos': [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      msg(context, e.message ?? 'Google sign-in failed');
    } catch (e) {
      msg(context, 'Google sign-in failed: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void openPhoneLogin() {
    openPage(context, const PhoneLoginPage());
  }

  Future<void> resetPassword() async {
    final controller = TextEditingController(text: email.text.trim());

    try {
      final value = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF17132D),
            title: const Text(
              'Reset password',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email address',
                labelStyle: const TextStyle(color: Color(0xFFAAA5C5)),
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFFC178FF)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x445F27FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFC178FF), width: 1.4),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Send reset link'),
              ),
            ],
          );
        },
      );

      if (value == null || value.trim().isEmpty) return;
      final resetEmail = value.trim();

      if (!resetEmail.contains('@')) {
        if (mounted) msg(context, 'Enter a valid email address');
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmail);

      if (mounted) {
        msg(context, 'Password reset link sent to $resetEmail');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        msg(context, 'No account found for this email');
      } else if (e.code == 'invalid-email') {
        msg(context, 'Enter a valid email address');
      } else {
        msg(context, e.message ?? 'Could not send password reset email');
      }
    } catch (e) {
      if (mounted) msg(context, 'Could not send password reset email');
    } finally {
      controller.dispose();
    }
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

    if (!login) {
      final password = pass.text;
      final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
      final hasNumber = RegExp(r'\d').hasMatch(password);
      if (password.length < 8 || !hasLetter || !hasNumber) {
        msg(context, 'Password must be 8+ characters and contain letters + numbers');
        return;
      }
    } else if (pass.text.length < 6) {
      msg(context, 'Password must be at least 6 characters');
      return;
    }

    setState(() => loading = true);

    try {
      if (login) {
        final normalizedEmail = email.text.trim().toLowerCase();
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalizedEmail,
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
        final normalizedEmail = email.text.trim().toLowerCase();
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: normalizedEmail,
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
          'email': normalizedEmail,
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

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        text = 'Email ya password galat hai. Registered account ka exact password use karo.';
      } else if (e.code == 'user-not-found') {
        text = 'Is email se account registered nahi hai.';
      } else if (e.code == 'user-disabled') {
        text = 'Ye account disabled hai.';
      } else if (e.code == 'too-many-requests') {
        text = 'Too many login attempts. Thodi der baad try karo.';
      } else if (e.code == 'network-request-failed') {
        text = 'Internet connection check karo.';
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
      backgroundColor: const Color(0xFF070516),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF160A35),
              Color(0xFF08061A),
              Color(0xFF02020A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C4DFF), Color(0xFFFF42B7)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x995F27FF),
                          blurRadius: 32,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'WikaLive',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  login
                      ? 'Welcome back. Enter your world.'
                      : 'Create your profile and go live.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFAAA5C5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141029),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x332F255D)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _authTab(
                          'Login',
                          login,
                          () => setState(() => login = true),
                        ),
                      ),
                      Expanded(
                        child: _authTab(
                          'Create account',
                          !login,
                          () => setState(() => login = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (!login) ...[
                  _darkField(
                    name,
                    'Name',
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    dropdownColor: const Color(0xFF17132D),
                    style: const TextStyle(color: Colors.white),
                    decoration: _darkDecoration(
                      'Gender',
                      Icons.wc_rounded,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Male',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem(
                        value: 'Female',
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (v) => setState(() => gender = v),
                  ),
                  const SizedBox(height: 12),
                ],

                _darkField(
                  email,
                  'Email address',
                  Icons.mail_outline_rounded,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _darkField(
                  pass,
                  'Password',
                  Icons.lock_outline_rounded,
                  obscure: obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFAAA5C5),
                    ),
                  ),
                ),

                if (login)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : resetPassword,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFFC178FF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),

                SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8D43FF), Color(0xFFFF3FB4)],
                      ),
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x665C20FF),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: loading ? null : submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              login ? 'Login to WikaLive' : 'Create WikaLive ID',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0x332D2844))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: const TextStyle(
                          color: Color(0xFF77728E),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0x332D2844))),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _socialButton(
                        Icons.g_mobiledata_rounded,
                        'Google',
                        loading ? null : signInWithGoogle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _socialButton(
                        Icons.phone_rounded,
                        'Phone',
                        loading ? null : openPhoneLogin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'By continuing, you agree to WikaLive Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6F6A83),
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _authTab(String title, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF803FFF), Color(0xFFD03CFF)],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF9690AE),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _darkDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9C96B3)),
      prefixIcon: Icon(icon, color: const Color(0xFFB66BFF)),
      filled: true,
      fillColor: const Color(0xFF131027),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x332D2850)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9A4DFF), width: 1.2),
      ),
    );
  }

  Widget _darkField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: _darkDecoration(label, icon).copyWith(
        suffixIcon: suffix,
      ),
    );
  }

  Widget _socialButton(
    IconData icon,
    String title,
    VoidCallback? onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: const Color(0xFF131027),
        side: const BorderSide(color: Color(0x443E3561)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
        elevation: 0,
        shadowColor: const Color(0x22000000),
        selectedIndex: index,
        indicatorColor: const Color(0xFFEEDFFF),
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
  static const _tabs = <String>[
    'Follow',
    'Popular',
    'Explore',
    'Nearby',
    'Beauty',
    'Country',
    'New Host',
  ];

  String selected = 'Follow';
  String selectedCountry = 'India';
  String period = 'Today';

  Query<Map<String, dynamic>> _liveQuery() {
    // Use the users directory as the live registry.  Hosts write their
    // current liveId/isLive state when the real ZEGO host room is active.
    // A simple single-field query keeps this realtime and avoids requiring
    // a composite Firestore index.
    return FirebaseFirestore.instance
        .collection('users')
        .where('isLive', isEqualTo: true);
  }

  num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value') ?? 0;
  }

  DateTime _timestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Preview-only hosts used when Firestore has no live users yet.
  /// They disappear automatically as soon as real live-host documents exist.
  List<Map<String, dynamic>> _demoHosts() {
    return [
      {
        'name': 'Sweetie', 'country': 'India', 'viewers': 2500,
        'giftReceived': 25400000, 'beautyScore': 98, 'qualityScore': 97,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'photoUrl': 'https://i.pravatar.cc/900?img=47',
        'latitude': 20.35, 'longitude': 85.82,
      },
      {
        'name': 'Angel', 'country': 'Indonesia', 'viewers': 1800,
        'giftReceived': 18200000, 'beautyScore': 96, 'qualityScore': 95,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'photoUrl': 'https://i.pravatar.cc/900?img=32',
        'latitude': 20.38, 'longitude': 85.84,
      },
      {
        'name': 'Nisha', 'country': 'Pakistan', 'viewers': 1300,
        'giftReceived': 12100000, 'beautyScore': 94, 'qualityScore': 93,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'photoUrl': 'https://i.pravatar.cc/900?img=49',
        'latitude': 20.30, 'longitude': 85.79,
      },
      {
        'name': 'Riya', 'country': 'India', 'viewers': 980,
        'giftReceived': 8200000, 'beautyScore': 92, 'qualityScore': 91,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
        'photoUrl': 'https://i.pravatar.cc/900?img=44',
        'latitude': 20.40, 'longitude': 85.80,
      },
      {
        'name': 'Pooja', 'country': 'India', 'viewers': 760,
        'giftReceived': 6100000, 'beautyScore': 90, 'qualityScore': 89,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'photoUrl': 'https://i.pravatar.cc/900?img=45',
        'latitude': 20.33, 'longitude': 85.88,
      },
      {
        'name': 'Tina', 'country': 'Bangladesh', 'viewers': 640,
        'giftReceived': 5400000, 'beautyScore': 95, 'qualityScore': 94,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 6))),
        'photoUrl': 'https://i.pravatar.cc/900?img=12',
        'latitude': 20.31, 'longitude': 85.86,
      },
      {
        'name': 'Sara', 'country': 'Thailand', 'viewers': 520,
        'giftReceived': 4200000, 'beautyScore': 97, 'qualityScore': 96,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'photoUrl': 'https://i.pravatar.cc/900?img=25',
        'latitude': 20.36, 'longitude': 85.81,
      },
      {
        'name': 'Alina', 'country': 'USA', 'viewers': 430,
        'giftReceived': 3500000, 'beautyScore': 91, 'qualityScore': 92,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'photoUrl': 'https://i.pravatar.cc/900?img=5',
        'latitude': 20.34, 'longitude': 85.83,
      },
    ];
  }

  Widget _demoContent(BuildContext context, String empty) {
    var hosts = _demoHosts();
    if (selected == 'Country') {
      hosts = hosts.where((h) => h['country'].toString().toLowerCase() == selectedCountry.toLowerCase()).toList();
    } else if (selected == 'Popular') {
      hosts.sort((a, b) => ((b['giftReceived'] as num) + (b['viewers'] as num) * 1000).compareTo((a['giftReceived'] as num) + (a['viewers'] as num) * 1000));
    } else if (selected == 'Beauty') {
      hosts.sort((a, b) => (b['beautyScore'] as num).compareTo(a['beautyScore'] as num));
    } else if (selected == 'New Host') {
      hosts.sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
    } else if (selected == 'Explore') {
      hosts.sort((a, b) => (b['viewers'] as num).compareTo(a['viewers'] as num));
    }

    if (selected == 'Nearby') {
      return _demoGrid(context, hosts, 'No live host found within 50 km.');
    }
    return _demoGrid(context, hosts, empty);
  }

  Widget _demoGrid(BuildContext context, List<Map<String, dynamic>> hosts, String empty) {
    if (hosts.isEmpty) {
      return _stateCard(icon: Icons.live_tv_outlined, title: empty, subtitle: 'Check another section or come back later.');
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: hosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .70,
      ),
      itemBuilder: (context, index) => _liveCard(context, {...hosts[index], 'isDemo': true}),
    );
  }

  Future<Set<String>> _followingIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return <String>{};
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortHosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result = [...docs];
    if (selected == 'Popular') {
      result.sort((a, b) {
        final scoreA = _number(a.data()['giftReceived']) * 1000 +
            _number(a.data()['viewers']);
        final scoreB = _number(b.data()['giftReceived']) * 1000 +
            _number(b.data()['viewers']);
        return scoreB.compareTo(scoreA);
      });
    } else if (selected == 'Explore') {
      result.sort((a, b) {
        final scoreA = _number(a.data()['viewers']) +
            _number(a.data()['giftReceived']) * .25;
        final scoreB = _number(b.data()['viewers']) +
            _number(b.data()['giftReceived']) * .25;
        return scoreB.compareTo(scoreA);
      });
    } else if (selected == 'Beauty') {
      result.sort((a, b) => _number(
            b.data()['beautyScore'] ?? b.data()['qualityScore'],
          ).compareTo(
            _number(a.data()['beautyScore'] ?? a.data()['qualityScore']),
          ));
    } else if (selected == 'New Host') {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      result.removeWhere((d) => _timestamp(d.data()['createdAt']).isBefore(cutoff));
      result.sort((a, b) => _timestamp(b.data()['createdAt'])
          .compareTo(_timestamp(a.data()['createdAt'])));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070813),
      body: SafeArea(
        child: Column(
          children: [
            _tabsBar(context),
            if (selected == 'Popular' || selected == 'Beauty' || selected == 'New Host')
              _periodBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _liveQuery().snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _stateCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load live hosts',
                      subtitle: snapshot.error.toString(),
                    );
                  }

                  var docs = _sortHosts(snapshot.data?.docs ?? []);

                  // Preview mode: show realistic sample hosts until real live users exist.
                  if (docs.isEmpty) {
                    return _demoContent(context, selected == 'Follow' ? 'No followed host is live right now.' : 'No live hosts found.');
                  }

                  if (selected == 'Follow') {
                    return FutureBuilder<Set<String>>(
                      future: _followingIds(),
                      builder: (context, following) {
                        if (following.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final ids = following.data ?? <String>{};
                        final followed = docs.where((d) => ids.contains(d.id)).toList();
                        return _content(context, followed, 'No followed host is live right now.');
                      },
                    );
                  }

                  if (selected == 'Country') {
                    docs = docs.where((d) {
                      return (d.data()['country'] ?? '').toString().toLowerCase() ==
                          selectedCountry.toLowerCase();
                    }).toList();
                    return _content(
                      context,
                      docs,
                      'No live host found in $selectedCountry.',
                      countryMode: true,
                    );
                  }

                  if (selected == 'Nearby') {
                    return _nearby(context, docs);
                  }

                  return _content(context, docs, 'No live hosts found.');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryDark, accent]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0x338B3FD9), blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WikaLive', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('Live now • Connect with people', style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _roundAction(Icons.search_rounded, () => openPage(context, const UserSearchPage())),
          const SizedBox(width: 8),
          _roundAction(Icons.emoji_events_outlined, () => openPage(context, const RankingPage())),
        ],
      ),
    );
  }

  Widget _roundAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE8DDF2)),
          ),
          child: Icon(icon, color: primaryDark),
        ),
      ),
    );
  }

  Widget _tabsBar(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: const BoxDecoration(
        color: Color(0xFF070813),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 8),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, index) {
                final tab = _tabs[index];
                final active = selected == tab;
                return GestureDetector(
                  onTap: () {
                    setState(() => selected = tab);
                    if (tab == 'Country') _chooseCountry();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(colors: [Color(0xFF7B2CFF), Color(0xFFFF2FAF)])
                          : null,
                      color: active ? null : const Color(0xFF111426),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? const Color(0xFFB75CFF) : const Color(0xFF292D4A),
                      ),
                      boxShadow: active
                          ? const [BoxShadow(color: Color(0x663F00FF), blurRadius: 12, offset: Offset(0, 3))]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (active) ...[
                            const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            tab,
                            style: TextStyle(
                              color: active ? Colors.white : const Color(0xFFE4E5F0),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          _darkRoundAction(Icons.search_rounded, () => openPage(context, const UserSearchPage())),
          const SizedBox(width: 6),
          _darkRoundAction(Icons.videocam_rounded, () => openPage(context, const StartLivePage())),
          const SizedBox(width: 6),
          _darkRoundAction(Icons.emoji_events_outlined, () => openPage(context, const RankingPage())),
        ],
      ),
    );
  }

  Widget _darkRoundAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF111426),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF7D38D8)),
            boxShadow: const [BoxShadow(color: Color(0x332D00FF), blurRadius: 10)],
          ),
          child: Icon(icon, color: const Color(0xFFD88CFF), size: 23),
        ),
      ),
    );
  }

  Widget _periodBar() {
    final options = ['Today', 'Week', 'Month'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selected == 'Beauty' ? 'Top quality live' : selected == 'New Host' ? 'Joined in the last 7 days' : 'Top live hosts',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: const Color(0xFF111426), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF292D4A))),
            child: Row(
              children: options.map((item) {
                final active = period == item;
                return GestureDetector(
                  onTap: () => setState(() => period = item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(color: active ? const Color(0xFF4B2374) : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    child: Text(item, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : const Color(0xFF8F93A8))),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseCountry() async {
    const countries = [
      'India', 'Bangladesh', 'Nepal', 'Pakistan', 'Sri Lanka',
      'UAE', 'Saudi Arabia', 'Indonesia', 'Malaysia',
    ];
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text('Choose country', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              ...countries.map((country) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF0E4F9),
                      child: Text(_flagFor(country)),
                    ),
                    title: Text(country, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: country == selectedCountry ? const Icon(Icons.check_circle, color: primary) : null,
                    onTap: () => Navigator.pop(sheetContext, country),
                  )),
            ],
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() => selectedCountry = result);
  }

  String _flagFor(String country) {
    const flags = {
      'India': '🇮🇳', 'Bangladesh': '🇧🇩', 'Nepal': '🇳🇵', 'Pakistan': '🇵🇰',
      'Sri Lanka': '🇱🇰', 'UAE': '🇦🇪', 'Saudi Arabia': '🇸🇦',
      'Indonesia': '🇮🇩', 'Malaysia': '🇲🇾',
    };
    return flags[country] ?? '🌍';
  }

  Widget _content(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String empty, {
    bool countryMode = false,
  }) {
    if (countryMode) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: InkWell(
              onTap: _chooseCountry,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF171129), Color(0xFF54227A)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x221F0D33), blurRadius: 14, offset: Offset(0, 6))],
                ),
                child: Row(children: [
                  Text(_flagFor(selectedCountry), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('$selectedCountry Live', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _grid(context, docs, empty)),
        ],
      );
    }
    return _grid(context, docs, empty);
  }

  Widget _grid(BuildContext context, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String empty) {
    if (docs.isEmpty) {
      return _stateCard(icon: Icons.live_tv_outlined, title: empty, subtitle: 'Check another section or come back later.');
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: docs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .70,
      ),
      itemBuilder: (context, index) {
        final data = docs[index].data();
        return _liveCard(context, data);
      },
    );
  }

  Widget _liveCard(BuildContext context, Map<String, dynamic> data) {
    final photos = data['photos'];
    final photo = photos is List && photos.isNotEmpty
        ? photos.first.toString()
        : (data['photoUrl'] ?? '').toString();
    final name = (data['name'] ?? 'Host').toString();
    final isDemo = data['isDemo'] == true;
    final country = (data['country'] ?? 'Unknown').toString();
    final viewers = data['viewers'] ?? 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          if (isDemo) {
            _showDemoLiveNotice(context, name);
            return;
          }
          final liveId = (data['liveId'] ?? '').toString().trim();
          if (liveId.isEmpty) {
            _showDemoLiveNotice(context, name, missingLiveId: true);
            return;
          }
          openPage(
            context,
            LiveRoomPage(
              host: name,
              viewers: '$viewers viewers',
              photoUrl: photo,
              liveId: liveId,
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 7))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                photo.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF321546), Color(0xFFB75EE7)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                        child: const Icon(Icons.person_rounded, color: Colors.white70, size: 72),
                      )
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF321546), Color(0xFFB75EE7)])),
                          child: const Icon(Icons.person_rounded, color: Colors.white70, size: 72),
                        ),
                      ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD9000000)],
                    ),
                  ),
                ),
                Positioned(top: 10, left: 10, child: _liveBadge()),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [const Icon(Icons.remove_red_eye_outlined, size: 13, color: Colors.white), const SizedBox(width: 4), Text('$viewers', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))]),
                  ),
                ),
                Positioned(
                  left: 11,
                  right: 11,
                  bottom: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Row(children: [Text(_flagFor(country), style: const TextStyle(fontSize: 13)), const SizedBox(width: 5), Expanded(child: Text(country, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _liveBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF3D78), Color(0xFFE63CC5)]),
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [BoxShadow(color: Color(0x55FF3D78), blurRadius: 9)],
        ),
        child: const Row(children: [Icon(Icons.circle, size: 7, color: Colors.white), SizedBox(width: 5), Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7))]),
      );

  Widget _stateCard({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: const Color(0xFF111426), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF292D4A))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 46, color: primary),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8F93A8), fontSize: 12, height: 1.4)),
          ]),
        ),
      ),
    );
  }

  Widget _nearby(BuildContext context, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return _stateCard(icon: Icons.login_rounded, title: 'Please login again', subtitle: 'Your account session is no longer available.');
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(me.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final mine = snapshot.data?.data() ?? {};
        final lat = _number(mine['latitude']);
        final lon = _number(mine['longitude']);
        if (lat == 0 && lon == 0) {
          return _stateCard(icon: Icons.location_on_outlined, title: 'Location needed', subtitle: 'Allow location and save your location to discover live hosts within 50 km.');
        }
        final nearby = docs.where((doc) {
          final x = doc.data();
          final a = _number(x['latitude']);
          final b = _number(x['longitude']);
          if (a == 0 && b == 0) return false;
          final dx = (a - lat).abs() * 111;
          final dy = (b - lon).abs() * 111;
          return (dx * dx + dy * dy) <= 2500;
        }).toList();
        return _grid(context, nearby, 'No live host found within 50 km.');
      },
    );
  }
}

class CountryLivePage extends StatelessWidget {
  const CountryLivePage({super.key});

  static const countries = <Map<String, String>>[
    {'flag': '🇮🇳', 'name': 'India'},
    {'flag': '🇧🇩', 'name': 'Bangladesh'},
    {'flag': '🇵🇰', 'name': 'Pakistan'},
    {'flag': '🇳🇵', 'name': 'Nepal'},
    {'flag': '🇱🇰', 'name': 'Sri Lanka'},
    {'flag': '🇦🇪', 'name': 'UAE'},
    {'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'flag': '🇮🇩', 'name': 'Indonesia'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Country Live')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: countries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: .9,
        ),
        itemBuilder: (context, index) {
          final country = countries[index];
          return InkWell(
            onTap: () => openPage(
              context,
              CountryHostsPage(country: country['name']!),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8DDF2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    country['flag']!,
                    style: const TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    country['name']!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CountryHostsPage extends StatelessWidget {
  final String country;

  const CountryHostsPage({
    super.key,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$country Live')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isLive', isEqualTo: true)
            .where('country', isEqualTo: country)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load $country live hosts'));
          }
          return _HostList(docs: snapshot.data?.docs ?? []);
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
    if (docs.isEmpty) {
      return const Center(child: Text('No live hosts'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final x = docs[index].data();
        final photo = (x['photoUrl'] ?? '').toString();
        final name = (x['name'] ?? 'Host').toString();
        final viewers = x['viewers'] ?? 0;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(name),
            subtitle: Text('LIVE • $viewers viewers'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              final liveId = (x['liveId'] ?? '').toString().trim();
              if (liveId.isEmpty) {
                _showDemoLiveNotice(context, name, missingLiveId: true);
                return;
              }
              openPage(
                context,
                LiveRoomPage(
                  host: name,
                  viewers: '$viewers viewers',
                  photoUrl: photo,
                  liveId: liveId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  static const rooms = [
    ['Angel\'s Party', 'Let\'s talk & have fun 💕', '1.2K', 'Music', 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=900'],
    ['Sweet Voice Room', 'Good vibes only ✨', '856', 'Voice', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=900'],
    ['Music Vibes', 'Sing with me 🎵', '672', 'Music', 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=900'],
    ['Girls Talk', 'Make new friends 💕', '432', 'Chat', 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=900'],
    ['Friends Party', 'Make new friends 💕', '389', 'Chat', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=900'],
    ['Chill Zone', 'Relax and talk ☕', '298', 'Chill', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=900'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050713),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          children: [
            Row(children: [
              _topTab('Live', false),
              _topTab('Party', true),
              _topTab('Music', false),
              _topTab('PK', false),
              const Spacer(),
              _iconButton(Icons.search_rounded, () => openPage(context, const FeaturePage(title: 'Search Party'))),
              const SizedBox(width: 6),
              _iconButton(Icons.notifications_none_rounded, () => openPage(context, const FeaturePage(title: 'Party Notifications'))),
            ]),
            const SizedBox(height: 16),
            _partyHero(context),
            const SizedBox(height: 12),
            _filterRow(),
            const SizedBox(height: 8),
            _sortRow(),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: .72,
              ),
              itemBuilder: (context, i) => _partyCard(context, rooms[i]),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => openPage(context, const FeaturePage(title: 'Party Ranking', icon: '🏆', items: ['Top Party Rooms', 'Top Hosts', 'Weekly Ranking'])),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF28115B), Color(0xFF761B83)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x55C75CFF)),
                ),
                child: const Row(children: [
                  Text('🏆', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Party Ranking', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Top party rooms this week', style: TextStyle(color: Color(0xFFBDB6D9), fontSize: 12)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: Colors.white),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topTab(String text, bool active) => Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Text(text, style: TextStyle(color: active ? Colors.white : const Color(0xFF8D91A8), fontSize: 16, fontWeight: active ? FontWeight.w900 : FontWeight.w600)),
      );

  Widget _iconButton(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF111629), shape: BoxShape.circle, border: Border.all(color: const Color(0x223E486A))), child: Icon(icon, color: Colors.white, size: 22)),
      );

  Widget _partyHero(BuildContext context) => Container(
        height: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF160B36), Color(0xFF681B8B), Color(0xFFE72C9B)]),
          border: Border.all(color: const Color(0x55E75AFF)),
        ),
        child: Stack(children: [
          const Positioned(right: 16, top: 12, child: Icon(Icons.mic_rounded, color: Color(0x77FFFFFF), size: 76)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Party Live', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Voice • Chat • Music • Make Friends', style: TextStyle(color: Color(0xFFD9CBE9), fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => openPage(context, const CreatePartyPage()),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create Party'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF02BA6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              ),
            ]),
          ),
        ]),
      );

  Widget _filterRow() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: ['All', 'Hot', 'Music', 'Chat', 'PK'].map((x) => Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10), decoration: BoxDecoration(color: x == 'All' ? const Color(0xFFE72BA1) : const Color(0xFF111629), borderRadius: BorderRadius.circular(22), border: Border.all(color: x == 'All' ? const Color(0x00FFFFFF) : const Color(0x223E486A))), child: Text(x, style: TextStyle(color: x == 'All' ? Colors.white : const Color(0xFFA7AAC0), fontWeight: FontWeight.w800)))).toList()),
      );

  Widget _sortRow() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text('Popular', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          SizedBox(width: 24),
          Text('Following', style: TextStyle(color: Color(0xFF8F93A8), fontWeight: FontWeight.w700)),
          SizedBox(width: 24),
          Text('Nearby', style: TextStyle(color: Color(0xFF8F93A8), fontWeight: FontWeight.w700)),
          SizedBox(width: 24),
          Text('Latest', style: TextStyle(color: Color(0xFF8F93A8), fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _partyCard(BuildContext context, List<String> r) => InkWell(
        onTap: () => openPage(context, PartyRoomPage(title: r[0])),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF0E1221), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0x33464B70))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Stack(children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(r[4], width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF20243A), child: const Center(child: Icon(Icons.groups_rounded, color: Colors.white54, size: 48))))),
                Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE82D67), borderRadius: BorderRadius.circular(9)), child: const Row(children: [Icon(Icons.mic_rounded, color: Colors.white, size: 13), SizedBox(width: 3), Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))]))),
                Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(9)), child: Text('👥 ${r[2]}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
                Positioned(left: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xAA000000), borderRadius: BorderRadius.circular(8)), child: Text(r[3], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
              ]),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(10, 9, 10, 11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r[0], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Text(r[1], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8E93A9), fontSize: 10)),
              const SizedBox(height: 8),
              Row(children: const [CircleAvatar(radius: 9, backgroundColor: Color(0xFFE82D9B), child: Icon(Icons.person, color: Colors.white, size: 11)), SizedBox(width: 5), Text('Join now', style: TextStyle(color: Color(0xFFF044B1), fontSize: 11, fontWeight: FontWeight.w800))]),
            ])),
          ]),
        ),
      );
}

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  static const posts = [
    ['Tina 💕', 'Good morning everyone! ☀️ Have a nice day 💕', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=900', '1.2K', '320'],
    ['Angel 👑', 'New look 💄 What do you think?', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=900', '856', '210'],
    ['Riya ✓', 'Chill time ☕💜', 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=900', '642', '128'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050713),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          children: [
            _tabs(),
            const SizedBox(height: 14),
            _composer(context),
            const SizedBox(height: 14),
            ...posts.map((p) => _post(context, p)),
          ],
        ),
      ),
    );
  }

  Widget _tabs() => Row(children: [
        _tab('Following', true), _tab('Popular', false), _tab('Nearby', false), _tab('Latest', false),
        const Spacer(),
        const Icon(Icons.search_rounded, color: Colors.white, size: 23),
        const SizedBox(width: 12),
        const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 23),
      ]);

  Widget _tab(String t, bool active) => Padding(padding: const EdgeInsets.only(right: 18), child: Text(t, style: TextStyle(color: active ? Colors.white : const Color(0xFF8D91A8), fontSize: 15, fontWeight: active ? FontWeight.w900 : FontWeight.w600)));

  Widget _composer(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(color: const Color(0xFF0E1221), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x223E486A))),
        child: Column(children: [
          Row(children: [const CircleAvatar(radius: 22, backgroundColor: Color(0xFF3C3158), child: Icon(Icons.person, color: Colors.white)), const SizedBox(width: 10), Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: const Color(0xFF171B2C), borderRadius: BorderRadius.circular(22)), child: const Text('Share your moment...', style: TextStyle(color: Color(0xFF858A9F), fontSize: 13)))), const SizedBox(width: 8), FilledButton(onPressed: () => openPage(context, const FeaturePage(title: 'Create Moment', icon: '📸', items: ['Add photo', 'Add video', 'Write a caption', 'Publish moment'])), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE72B9E), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11)), child: const Text('Post'))]),
          const SizedBox(height: 12),
          Row(children: const [Icon(Icons.photo_outlined, color: Color(0xFF9E69FF)), SizedBox(width: 6), Text('Photo', style: TextStyle(color: Color(0xFFA5A8B8), fontSize: 12)), SizedBox(width: 18), Icon(Icons.videocam_outlined, color: Color(0xFF4BC8FF)), SizedBox(width: 6), Text('Video', style: TextStyle(color: Color(0xFFA5A8B8), fontSize: 12)), SizedBox(width: 18), Icon(Icons.text_fields_rounded, color: Color(0xFFFF69B9)), SizedBox(width: 6), Text('Text', style: TextStyle(color: Color(0xFFA5A8B8), fontSize: 12)), SizedBox(width: 18), Icon(Icons.live_tv_outlined, color: Color(0xFFFFB45B)), SizedBox(width: 6), Text('Live', style: TextStyle(color: Color(0xFFA5A8B8), fontSize: 12))]),
        ]),
      );

  Widget _post(BuildContext context, List<String> p) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(color: const Color(0xFF0E1221), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x223E486A))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const CircleAvatar(radius: 20, backgroundColor: Color(0xFF3C3158), child: Icon(Icons.person, color: Colors.white, size: 20)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), const SizedBox(height: 2), const Text('2 hours ago', style: TextStyle(color: Color(0xFF7D8298), fontSize: 11))])), OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF043B0), side: const BorderSide(color: Color(0x99F043B0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)), child: const Text('+ Follow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), const SizedBox(width: 4), const Icon(Icons.more_horiz_rounded, color: Color(0xFF9A9EB0))]),
          const SizedBox(height: 10),
          Text(p[1], style: const TextStyle(color: Color(0xFFE7E8F0), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(p[2], height: 245, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 245, color: const Color(0xFF20243A), child: const Center(child: Icon(Icons.image_outlined, color: Colors.white54, size: 48))))),
          const SizedBox(height: 9),
          Row(children: [const Icon(Icons.favorite_rounded, color: Color(0xFFF12D93), size: 21), const SizedBox(width: 5), Text(p[3], style: const TextStyle(color: Color(0xFFB9BCCE), fontSize: 12)), const SizedBox(width: 22), const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFB9BCCE), size: 20), const SizedBox(width: 5), Text(p[4], style: const TextStyle(color: Color(0xFFB9BCCE), fontSize: 12)), const Spacer(), const Icon(Icons.share_outlined, color: Color(0xFFB9BCCE), size: 20), const SizedBox(width: 5), const Text('Share', style: TextStyle(color: Color(0xFFB9BCCE), fontSize: 12))]),
        ]),
      );
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const chats = [
    ['Tina 💕', 'Hey... are you there? 😊', '2m', '1'],
    ['Riya', 'Let\'s video call now 📹', '10m', '2'],
    ['Angel', 'sent you a gift 🎁', '25m', '1'],
    ['Sofia', 'Can we be friends? 💕', '1h', ''],
    ['Official ✓', 'New party event is live!', '3h', ''],
    ['Alina', 'Are you free now?', '5h', ''],
    ['Jenny', 'Photo', '8h', ''],
    ['Nana', 'Miss you 💋', '12h', ''],
    ['Raj', 'Let\'s chat sometime 😊', '1d', ''],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050713),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          children: [
            Row(children: [_pill('Chats', true, '12'), _pill('Friends', false, ''), _pill('Group', false, ''), _pill('System', false, '3')]),
            const SizedBox(height: 14),
            Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFF111629), borderRadius: BorderRadius.circular(25), border: Border.all(color: const Color(0x223E486A))), child: const Row(children: [Icon(Icons.search_rounded, color: Color(0xFF777D96)), SizedBox(width: 9), Text('Search messages, users...', style: TextStyle(color: Color(0xFF777D96), fontSize: 13)), Spacer(), Icon(Icons.tune_rounded, color: Color(0xFF9DA1B4), size: 20)])),
            const SizedBox(height: 15),
            _stories(context),
            const SizedBox(height: 15),
            ...chats.map((c) => _chatRow(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, bool active, String badge) => Padding(padding: const EdgeInsets.only(right: 8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: active ? const Color(0xFFE72B9E) : const Color(0xFF111629), borderRadius: BorderRadius.circular(22), border: Border.all(color: active ? const Color(0x00FFFFFF) : const Color(0x223E486A))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(text, style: TextStyle(color: active ? Colors.white : const Color(0xFFA2A6B8), fontWeight: FontWeight.w800)), if (badge.isNotEmpty) ...[const SizedBox(width: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: const BoxDecoration(color: Color(0xFFFF276F), shape: BoxShape.circle), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)))]])));

  Widget _stories(BuildContext context) => SizedBox(height: 92, child: ListView(scrollDirection: Axis.horizontal, children: [
        _story(context, true, 'My Story'), _story(context, false, 'Tina'), _story(context, false, 'Riya'), _story(context, false, 'Sofia'), _story(context, false, 'Nana'),
      ]));

  Widget _story(BuildContext context, bool add, String name) => Container(width: 70, margin: const EdgeInsets.only(right: 12), child: Column(children: [
        Container(width: 58, height: 58, padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFE72B9E), Color(0xFF7B4DFF)])), child: CircleAvatar(backgroundColor: const Color(0xFF20243A), child: add ? const Icon(Icons.add_rounded, color: Colors.white, size: 28) : const Icon(Icons.person, color: Colors.white))),
        const SizedBox(height: 6), Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFBFC2D1), fontSize: 11, fontWeight: FontWeight.w700)),
      ]));

  Widget _chatRow(BuildContext context, List<String> c) => InkWell(
        onTap: () => openPage(context, ChatPage(name: c[0], initial: c[0].isNotEmpty ? c[0][0].toUpperCase() : '?')),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Stack(children: [const CircleAvatar(radius: 27, backgroundColor: Color(0xFF292E46), child: Icon(Icons.person, color: Colors.white, size: 25)), if (c[0].contains('Official')) Positioned(right: 0, bottom: 0, child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFF8B5CFF), shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, color: Colors.white, size: 11))) ]),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(height: 5), Text(c[1], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8C91A7), fontSize: 12, fontWeight: FontWeight.w600))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(c[2], style: const TextStyle(color: Color(0xFF7F849A), fontSize: 10)), if (c[3].isNotEmpty) ...[const SizedBox(height: 7), Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFFF2772), shape: BoxShape.circle), alignment: Alignment.center, child: Text(c[3], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)))]]),
          ]),
        ),
      );
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
        final d = snap.data?.data() ?? <String, dynamic>{};
        final user = FirebaseAuth.instance.currentUser;
        final name = (d['name'] ?? user?.displayName ?? 'WikaLive User').toString();
        final bio = (d['bio'] ?? '').toString().trim();
        final country = (d['country'] ?? 'India').toString();
        final gender = (d['gender'] ?? '').toString();
        final birthday = (d['birthday'] ?? '').toString();
        final language = (d['language'] ?? '').toString();
        final level = d['level'] is num ? (d['level'] as num).toInt() : 1;
        final coins = d['coins'] is num ? (d['coins'] as num).toInt() : 0;
        final diamonds = d['diamonds'] is num ? (d['diamonds'] as num).toInt() : 0;
        final rawPhotos = d['photos'];
        final photos = rawPhotos is List
            ? rawPhotos.map((e) => e.toString()).where((e) => e.isNotEmpty).take(5).toList()
            : <String>[];
        final photo = photos.isNotEmpty
            ? photos.first
            : (d['photoUrl'] ?? user?.photoURL ?? '').toString();
        final shortId = uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFF07091D),
          body: Stack(
            children: [
              const Positioned.fill(child: _MeBackground()),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'My Space',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        _neonIconButton(
                          Icons.edit_rounded,
                          () => openPage(context, const EditProfilePage()),
                        ),
                        const SizedBox(width: 10),
                        _neonIconButton(
                          Icons.settings_rounded,
                          () => openPage(context, const SettingsPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _profileHeader(
                      context,
                      name: name,
                      id: shortId,
                      bio: bio,
                      photo: photo,
                      country: country,
                      gender: gender,
                      level: level,
                    ),
                    const SizedBox(height: 16),
                    _statsRow(context, uid),
                    const SizedBox(height: 14),
                    _balanceRow(context, coins, diamonds, level),
                    const SizedBox(height: 16),
                    _mySpaceCard(context),
                    const SizedBox(height: 14),
                    _infoTile(
                      context,
                      Icons.person_rounded,
                      'Personal Information',
                      birthday.isEmpty && gender.isEmpty && language.isEmpty
                          ? 'Birthday, gender, country, language'
                          : [
                              if (birthday.isNotEmpty) birthday,
                              if (gender.isNotEmpty) gender,
                              country,
                              if (language.isNotEmpty) language,
                            ].join('  •  '),
                      const EditProfilePage(),
                    ),
                    const SizedBox(height: 10),
                    _photosTile(context, photos),
                    const SizedBox(height: 10),
                    _infoTile(
                      context,
                      Icons.edit_note_rounded,
                      'About Me',
                      bio.isEmpty ? 'Tell people something about you' : bio,
                      const EditProfilePage(),
                    ),
                    const SizedBox(height: 10),
                    _infoTile(
                      context,
                      Icons.verified_user_rounded,
                      'Verification',
                      'Verify your account and unlock more features',
                      const FeaturePage(
                        title: 'Verification',
                        icon: '✓',
                        items: [
                          'Verification status',
                          'Identity verification',
                          'Safety information',
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4C73),
                        side: const BorderSide(color: Color(0xFFFF3E69), width: 1.3),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _neonIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0x121A1D46),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0x554C56B8)),
          boxShadow: const [
            BoxShadow(color: Color(0x331C1DFF), blurRadius: 18),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 23),
      ),
    );
  }

  Widget _profileHeader(
    BuildContext context, {
    required String name,
    required String id,
    required String bio,
    required String photo,
    required String country,
    required String gender,
    required int level,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10133B),
            Color(0xFF151047),
            Color(0xFF280D49),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x664D43B5)),
        boxShadow: const [
          BoxShadow(color: Color(0x552A13A4), blurRadius: 30, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFD66BFF), Color(0xFF5E7BFF), Color(0xFFFF4DB7)],
                      ),
                    ),
                    child: ClipOval(
                      child: photo.isEmpty
                          ? Container(
                              color: const Color(0xFF171B43),
                              child: const Icon(Icons.person_rounded, color: Colors.white54, size: 48),
                            )
                          : Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF171B43),
                                child: const Icon(Icons.person_rounded, color: Colors.white54, size: 48),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: () => openPage(context, const EditProfilePage()),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: const BoxDecoration(
                          color: Color(0xFF9B45FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Color(0xFF37BFFF), size: 19),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text('ID: $id', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                        const SizedBox(width: 7),
                        InkWell(
                          onTap: () => Clipboard.setData(ClipboardData(text: id)),
                          child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio.isEmpty ? 'Tap to add bio...' : bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _profilePill(Icons.workspace_premium_rounded, 'Lv.$level'),
                        _profilePill(Icons.public_rounded, country),
                        if (gender.isNotEmpty) _profilePill(Icons.wc_rounded, gender),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.circle, color: Color(0xFF24E5B0), size: 10),
              const SizedBox(width: 6),
              const Text('Online', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                'LEVEL $level',
                style: const TextStyle(color: Color(0xFFFFD76B), fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (level % 100) / 100,
              minHeight: 6,
              backgroundColor: const Color(0x332E346F),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB84CFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x171E255A),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x334F5AB8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD8B8FF), size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x223F4A9E)),
      ),
      child: Row(
        children: [
          _darkStat(context, uid, 'moments', 'Moments', const MomentsScreen()),
          _statDivider(),
          _darkStat(context, uid, 'visitors', 'Visitors', const VisitorsPage()),
          _statDivider(),
          _darkStat(context, uid, 'likes', 'Likes', null),
          _statDivider(),
          _darkStat(context, uid, 'giftReceived', 'Gifts', null),
        ],
      ),
    );
  }

  Widget _darkStat(BuildContext context, String uid, String field, String label, Widget? page) {
    return Expanded(
      child: InkWell(
        onTap: page == null ? null : () => openPage(context, page),
        borderRadius: BorderRadius.circular(12),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: (field == 'moments' || field == 'visitors')
              ? FirebaseFirestore.instance.collection('users').doc(uid).collection(field).snapshots()
              : null,
          builder: (context, snap) {
            final d = snap.data?.docs.length ?? 0;
            return Column(
              children: [
                Text(
                  '$d',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 34, color: const Color(0x224E5AAB));

  Widget _balanceRow(BuildContext context, int coins, int diamonds, int level) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111532), Color(0xFF17163F), Color(0xFF251044)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x774F35B8)),
        boxShadow: const [BoxShadow(color: Color(0x402A0D65), blurRadius: 22)],
      ),
      child: Row(
        children: [
          Expanded(
            child: _balanceItem(
              Icons.monetization_on_rounded,
              'Coins',
              '$coins',
              const Color(0xFFFFD84D),
              () => openPage(context, const WalletPage()),
            ),
          ),
          Container(width: 1, height: 55, color: const Color(0x334F55A5)),
          Expanded(
            child: _balanceItem(
              Icons.diamond_rounded,
              'Diamonds',
              '$diamonds',
              const Color(0xFFC887FF),
              () => openPage(context, const DiamondWithdrawalPage()),
            ),
          ),
          Container(width: 1, height: 55, color: const Color(0x334F55A5)),
          Expanded(
            child: _balanceItem(
              Icons.workspace_premium_rounded,
              'My Level',
              'Lv.$level',
              const Color(0xFFFFD15C),
              () => openPage(context, const FeaturePage(title: 'My Level', icon: '👑', items: ['Level progress', 'Level rewards', 'How to level up'])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceItem(IconData icon, String title, String value, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mySpaceCard(BuildContext context) {
    final tools = <_MeTool>[
      _MeTool(Icons.auto_awesome_rounded, 'Moments', const MomentsScreen()),
      _MeTool(Icons.workspace_premium_rounded, 'My Level', const FeaturePage(title: 'My Level', icon: '👑', items: ['Level progress', 'Level rewards', 'How to level up'])),
      _MeTool(Icons.favorite_rounded, 'Fans Club', const FeaturePage(title: 'Fans Club', icon: '💖', items: ['My fans', 'Club level', 'Club rewards'])),
      _MeTool(Icons.backpack_rounded, 'Backpack', const FeaturePage(title: 'Backpack', icon: '🎒', items: ['My items', 'Frames', 'Effects'])),
      _MeTool(Icons.account_balance_wallet_rounded, 'Wallet', const WalletPage()),
      _MeTool(Icons.videocam_rounded, 'Live History', const FeaturePage(title: 'Live History', icon: '🎥', items: ['My live history', 'Live duration', 'Viewer history'])),
      _MeTool(Icons.shield_rounded, 'Account Security', const FeaturePage(title: 'Account Security', icon: '🛡️', items: ['Password', 'Login activity', 'Blocked users'])),
      _MeTool(Icons.settings_rounded, 'Settings', const SettingsPage()),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x443F4CA6)),
        boxShadow: const [BoxShadow(color: Color(0x35150A4A), blurRadius: 24)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x332D1B6F),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0x665D45DD)),
                ),
                child: const Icon(Icons.apps_rounded, color: Color(0xFFD18AFF)),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text('My Space', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              ),
              InkWell(
                onTap: () => openPage(context, const FeaturePage(title: 'My Space', icon: '✦', items: ['Moments', 'My Level', 'Fans Club', 'Backpack', 'Wallet', 'Live History', 'Account Security', 'Settings'])),
                borderRadius: BorderRadius.circular(10),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View all', style: TextStyle(color: Color(0xFFFFD75D), fontSize: 12, fontWeight: FontWeight.w800)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.white70),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 7,
              mainAxisSpacing: 8,
              childAspectRatio: .92,
            ),
            itemBuilder: (context, i) {
              final tool = tools[i];
              return InkWell(
                onTap: () => openPage(context, tool.page),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x161B2454), Color(0x0D171A3A)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0x333F4DA0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x221C1B65),
                          boxShadow: const [BoxShadow(color: Color(0x552E19B9), blurRadius: 16)],
                        ),
                        child: Icon(tool.icon, color: const Color(0xD9D184FF), size: 27),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, IconData icon, String title, String subtitle, Widget page) {
    return InkWell(
      onTap: () => openPage(context, page),
      borderRadius: BorderRadius.circular(20),
      child: _darkTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        color: const Color(0xFF8D57FF),
      ),
    );
  }

  Widget _photosTile(BuildContext context, List<String> photos) {
    return InkWell(
      onTap: () => openPage(context, const EditProfilePage()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x333F4DA0)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0x33291B70),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.photo_library_rounded, color: Color(0xC88B5BFF)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Photos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Add and manage your profile photos', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                ],
              ),
            ),
            if (photos.isNotEmpty)
              SizedBox(
                width: 92,
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length > 2 ? 2 : photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 5),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      photos[i],
                      width: 42,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 42,
                        height: 48,
                        color: const Color(0x221F2552),
                        child: const Icon(Icons.person, color: Colors.white38, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _darkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x333F4DA0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: .16), blurRadius: 18),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _MeTool {
  final IconData icon;
  final String label;
  final Widget page;
  const _MeTool(this.icon, this.label, this.page);
}

class _MeBackground extends StatelessWidget {
  const _MeBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 310,
              height: 310,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x663D22FF), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -150,
            child: Container(
              width: 340,
              height: 340,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x664F12D8), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x663C17B7), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ],
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

void _showDemoLiveNotice(BuildContext context, String name, {bool missingLiveId = false}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Preview Live'),
      content: Text(
        missingLiveId
            ? '$name is marked live, but this live room has no valid live ID yet.'
            : '$name is a preview host. This card is only for UI testing. Start a real live from Go Live to publish camera video.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class LiveRoomPage extends StatelessWidget {
  final String host;
  final String viewers;
  final String? photoUrl;
  final String liveId;

  const LiveRoomPage({
    super.key,
    required this.host,
    required this.viewers,
    required this.liveId,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Please login again.', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    if (kZegoAppSign.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'ZEGO AppSign is missing from the release build.\nAdd ZEGO_APP_SIGN to GitHub Secrets and pass it with --dart-define.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return ZegoUIKitPrebuiltLiveStreaming(
      appID: kZegoAppId,
      appSign: kZegoAppSign,
      userID: user.uid,
      userName: (user.displayName?.trim().isNotEmpty == true)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'WikaLive User'),
      liveID: liveId,
      config: (ZegoUIKitPrebuiltLiveStreamingConfig.audience(plugins: [ZegoUIKitSignalingPlugin()])
        ..video = ZegoUIKitVideoConfig.preset720P()
        ..audioVideoView = ZegoLiveStreamingAudioVideoViewConfig(
          isVideoMirror: false,
          useVideoViewAspectFill: true,
        )
        ..coHost = ZegoLiveStreamingCoHostConfig(maxCoHostCount: 3)
        ..duration = ZegoLiveStreamingDurationConfig(isVisible: false)
        ..topMenuBar = ZegoLiveStreamingTopMenuBarConfig(
          buttons: const [],
          showCloseButton: false,
          hostAvatarBuilder: (_) => const SizedBox.shrink(),
        )
        ..bottomMenuBar = ZegoLiveStreamingBottomMenuBarConfig(
          showInRoomMessageButton: false,
          hostButtons: const [],
          coHostButtons: const [],
          audienceButtons: const [],
        )
        ..inRoomMessage = ZegoLiveStreamingInRoomMessageConfig(
          visible: false,
        )
        ..foreground = _GuestCallOverlay(isHost: false, hostName: host, liveId: liveId, hostUid: null, hostPhotoUrl: photoUrl)),
      events: ZegoUIKitPrebuiltLiveStreamingEvents(
        onEnded: (event, defaultAction) {
          defaultAction();
        },
      ),
    );
  }
}

class StartLivePage extends StatefulWidget {
  const StartLivePage({super.key});

  @override
  State<StartLivePage> createState() => _StartLivePageState();
}

class _StartLivePageState extends State<StartLivePage> {
  int step = 0;
  bool starting = false;
  bool rulesAccepted = false;
  bool allowGuest = true;
  bool allowComments = true;
  bool showLocation = false;
  bool beautyOn = true;
  String category = 'Chat';
  String title = '';
  XFile? cover;

  final titleController = TextEditingController();

  static const rules = <String>[
    'Respect everyone. Harassment, threats and hateful behaviour are not allowed.',
    'Sexual, nude or exploitative content is strictly prohibited.',
    'Do not share private personal information or encourage unsafe behaviour.',
    'Do not stream illegal activity, dangerous acts or violent content.',
    'Only adults may host. Keep the room safe and welcoming for viewers.',
  ];

  static const categories = <String>[
    'Chat',
    'Music',
    'Talent',
    'Daily',
    'PK',
    'Party',
    'Other',
  ];

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (picked != null && mounted) setState(() => cover = picked);
  }

  Future<void> _launchLive() async {
    if (starting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      msg(context, 'Please login again.');
      return;
    }
    if (kZegoAppSign.trim().isEmpty) {
      msg(context, 'ZEGO AppSign is missing. Check GitHub Secret ZEGO_APP_SIGN.');
      return;
    }
    final liveTitle = titleController.text.trim().isEmpty
        ? 'Welcome to my WikaLive'
        : titleController.text.trim();

    setState(() => starting = true);
    final sessionStartedAt = DateTime.now();
    final liveId = 'wl_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
    String name = (user.displayName?.trim().isNotEmpty == true)
        ? user.displayName!.trim()
        : (user.email?.split('@').first ?? 'WikaLive User');
    String country = 'India';
    String photo = user.photoURL ?? '';
    String? coverUrl;

    try {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 6));
        final data = snap.data() ?? <String, dynamic>{};
        name = ((data['name'] ?? name).toString()).trim();
        country = (data['country'] ?? country).toString();
        photo = (data['photoUrl'] ?? photo).toString();
      } catch (_) {}

      if (cover != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('live_covers')
              .child(user.uid)
              .child('$liveId.jpg');
          await ref.putFile(File(cover!.path)).timeout(const Duration(seconds: 20));
          coverUrl = await ref.getDownloadURL().timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('WikaLive cover upload skipped: $e');
        }
      }

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => RealHostLivePage(
            liveId: liveId,
            name: name,
            photoUrl: photo,
            liveTitle: liveTitle,
            category: category,
            coverUrl: coverUrl,
            allowGuest: allowGuest,
            allowComments: allowComments,
            showLocation: showLocation,
          ),
        ),
      );

      final liveDuration = DateTime.now().difference(sessionStartedAt);

      // Clear the live directory BEFORE opening the ended-summary screen.
      // This prevents other phones from seeing the host as live while the
      // host is already on the summary page.
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isLive': false,
          'liveId': FieldValue.delete(),
          'liveEndedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
      } catch (_) {}

      if (mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => LiveSummaryPage(
              hostName: name,
              duration: liveDuration,
              gifts: 0,
              viewers: 1,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        msg(context, 'Live start failed: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  void _next() {
    if (step == 0) {
      setState(() => step = 1);
    } else if (step == 1) {
      if (!rulesAccepted) {
        msg(context, 'Please accept the live rules first.');
        return;
      }
      setState(() => step = 2);
    } else if (step == 2) {
      title = titleController.text.trim();
      setState(() => step = 3);
    } else {
      _launchLive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          const ['Upload cover', 'Live rules', 'Enter live title', 'Before going live'][step],
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: List.generate(4, (i) {
                  final active = i <= step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFD65CFF) : const Color(0xFF272536),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF39C8), Color(0xFF7B35FF)]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    onPressed: starting ? null : _next,
                    child: Text(
                      step == 3 ? (starting ? 'STARTING LIVE…' : 'START LIVE') : 'NEXT',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case 0:
        return _coverStep();
      case 1:
        return _rulesStep();
      case 2:
        return _titleStep();
      default:
        return _readyStep();
    }
  }

  Widget _brand() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x553F1A70), blurRadius: 25)]),
          child: Image.asset('assets/wikalive_logo.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _coverStep() {
    return ListView(
      key: const ValueKey('cover'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      children: [
        _brand(),
        const Text('Upload your cover', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('A clear cover helps viewers know what your live is about.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9B98A8), height: 1.4)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickCover,
          child: Container(
            height: 310,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF7D43A6), width: 1.2),
              color: const Color(0xFF111019),
            ),
            clipBehavior: Clip.antiAlias,
            child: cover == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_a_photo_rounded, color: Color(0xFFE56BFF), size: 52), SizedBox(height: 12), Text('Tap to choose a cover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('JPG / PNG', style: TextStyle(color: Color(0xFF898493), fontSize: 12))])
                : Stack(fit: StackFit.expand, children: [Image.file(File(cover!.path), fit: BoxFit.cover), Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(12), color: Colors.black54, child: const Text('Tap to change', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))))]),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF111019), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF29243A))),
          child: const Row(children: [Icon(Icons.verified_user_outlined, color: Color(0xFFD56CFF)), SizedBox(width: 10), Expanded(child: Text('Use your own clear photo. Do not upload misleading, private or unsafe images.', style: TextStyle(color: Color(0xFFB7B2C2), fontSize: 12, height: 1.4)))]),
        ),
      ],
    );
  }

  Widget _rulesStep() {
    return ListView(
      key: const ValueKey('rules'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      children: [
        _brand(),
        const Text('Please follow the live rules', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('These rules keep WikaLive safe for hosts and viewers.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9692A3))),
        const SizedBox(height: 18),
        ...List.generate(rules.length, (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF15131D), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFF2B2638))),
          child: Row(children: [Container(width: 28, height: 28, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFCA3A), Color(0xFFFF6E6E)])), child: Text('${i + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900))), const SizedBox(width: 11), Expanded(child: Text(rules[i], style: const TextStyle(color: Color(0xFFE9E7EF), fontSize: 13, height: 1.35)))]),
        )),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: rulesAccepted,
          onChanged: (v) => setState(() => rulesAccepted = v ?? false),
          activeColor: const Color(0xFFD34FFF),
          title: const Text('I have read and agree to the live rules.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _titleStep() {
    return ListView(
      key: const ValueKey('title'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      children: [
        _brand(),
        Row(children: [
          Container(width: 74, height: 92, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF181521)), child: cover == null ? Image.asset('assets/wikalive_logo.png', fit: BoxFit.cover) : Image.file(File(cover!.path), fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: titleController, maxLength: 30, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700), decoration: InputDecoration(hintText: 'Please enter the live title', hintStyle: const TextStyle(color: Color(0xFF777281)), counterStyle: const TextStyle(color: Color(0xFF777281)), filled: true, fillColor: const Color(0xFF17151F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none)))),
        ]),
        const SizedBox(height: 18),
        const Text('Choose category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: categories.map((x) {
          final active = category == x;
          return ChoiceChip(label: Text(x), selected: active, onSelected: (_) => setState(() => category = x), selectedColor: const Color(0xFF9A3DFF), backgroundColor: const Color(0xFF16141F), labelStyle: TextStyle(color: active ? Colors.white : const Color(0xFFB8B3C0), fontWeight: FontWeight.w800), side: BorderSide(color: active ? const Color(0xFFE66BFF) : const Color(0xFF2C2739)));
        }).toList()),
        const SizedBox(height: 18),
        _switchTile('Allow guest join', allowGuest, (v) => setState(() => allowGuest = v), Icons.people_alt_outlined),
        _switchTile('Allow comments', allowComments, (v) => setState(() => allowComments = v), Icons.chat_bubble_outline_rounded),
        _switchTile('Show location', showLocation, (v) => setState(() => showLocation = v), Icons.location_on_outlined),
      ],
    );
  }

  Widget _switchTile(String text, bool value, ValueChanged<bool> onChanged, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(color: const Color(0xFF15131D), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFF2B2638))),
      child: SwitchListTile(secondary: Icon(icon, color: const Color(0xFFC96BFF)), title: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), value: value, onChanged: onChanged, activeColor: const Color(0xFFD64CFF)),
    );
  }

  Widget _readyStep() {
    return ListView(
      key: const ValueKey('ready'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      children: [
        _brand(),
        Container(
          height: 360,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: Colors.black, border: Border.all(color: const Color(0xFF6E3D91))),
          child: Stack(fit: StackFit.expand, children: [
            if (cover != null) Image.file(File(cover!.path), fit: BoxFit.cover) else Image.asset('assets/wikalive_logo.png', fit: BoxFit.cover),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC07070D)]))),
            Positioned(left: 18, right: 18, bottom: 22, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ready to go live?', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(titleController.text.trim().isEmpty ? 'A wonderful live is about to start!' : titleController.text.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE5E0EA), fontSize: 13))]))
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: _previewTool(Icons.auto_awesome_rounded, 'Beauty', beautyOn, () => setState(() => beautyOn = !beautyOn))), const SizedBox(width: 10), Expanded(child: _previewTool(Icons.tune_rounded, 'Filters', false, () => msg(context, 'Filters will open here.'))), const SizedBox(width: 10), Expanded(child: _previewTool(Icons.emoji_emotions_outlined, 'Stickers', false, () => msg(context, 'Stickers will open here.')))]),
      ],
    );
  }

  Widget _previewTool(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8), decoration: BoxDecoration(color: const Color(0xFF15131D), borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? const Color(0xFFD95CFF) : const Color(0xFF2A2535))), child: Column(children: [Icon(icon, color: active ? const Color(0xFFD95CFF) : Colors.white70), const SizedBox(height: 5), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))])));
  }
}

class RealHostLivePage extends StatefulWidget {
  final String liveId;
  final String name;
  final String? photoUrl;
  final String liveTitle;
  final String category;
  final String? coverUrl;
  final bool allowGuest;
  final bool allowComments;
  final bool showLocation;

  const RealHostLivePage({
    super.key,
    required this.liveId,
    required this.name,
    this.photoUrl,
    this.liveTitle = '',
    this.category = 'Chat',
    this.coverUrl,
    this.allowGuest = true,
    this.allowComments = true,
    this.showLocation = false,
  });

  @override
  State<RealHostLivePage> createState() => _RealHostLivePageState();
}

class _RealHostLivePageState extends State<RealHostLivePage> {
  bool _markedLive = false;
  bool _closingFromUser = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markLive();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _markLive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _markedLive) return;
    _markedLive = true;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    String country = 'India';
    String photo = widget.photoUrl ?? user.photoURL ?? '';
    String name = widget.name;

    // Do not make the live directory depend on a profile read.
    // Publish the minimum live record immediately, then enrich it if possible.
    try {
      await ref.set({
        'uid': user.uid,
        'isLive': true,
        'liveId': widget.liveId,
        'liveStartedAt': FieldValue.serverTimestamp(),
        'viewers': 1,
        'liveDiamonds': 0,
        'liveGiftCount': 0,
        'name': name,
        'country': country,
        'photoUrl': photo,
        'liveTitle': widget.liveTitle,
        'category': widget.category,
        'coverUrl': widget.coverUrl ?? '',
        'allowGuest': widget.allowGuest,
        'allowComments': widget.allowComments,
        'showLocation': widget.showLocation,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('WikaLive live-directory publish failed: $e');
      return;
    }

    try {
      final profile = await ref.get().timeout(const Duration(seconds: 5));
      final data = profile.data() ?? <String, dynamic>{};
      country = (data['country'] ?? country).toString();
      photo = (data['photoUrl'] ?? photo).toString();
      name = (data['name'] ?? name).toString();
      await ref.set({
        'name': name,
        'country': country,
        'photoUrl': photo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('WikaLive profile enrichment skipped: $e');
    }
  }

  Future<void> _end() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isLive': false,
        'liveId': FieldValue.delete(),
        'liveStartedAt': FieldValue.delete(),
        'viewers': 0,
        'liveDiamonds': 0,
        'liveGiftCount': 0,
        'liveEndedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('WikaLive live-directory cleanup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || kZegoAppSign.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'ZEGO configuration missing.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final config = ZegoUIKitPrebuiltLiveStreamingConfig.host(plugins: [ZegoUIKitSignalingPlugin()])
      ..video = ZegoUIKitVideoConfig.preset720P()
      ..turnOnCameraWhenJoining = true
      ..turnOnMicrophoneWhenJoining = true
      ..useFrontFacingCamera = true
      ..audioVideoView = ZegoLiveStreamingAudioVideoViewConfig(
        isVideoMirror: true,
        useVideoViewAspectFill: true,
      )
      ..preview = ZegoLiveStreamingPreviewConfig(
        showPreviewForHost: false,
      )
      ..coHost = ZegoLiveStreamingCoHostConfig(maxCoHostCount: 3)
      // The custom WikaLive overlay owns the visible room controls.
      // ZEGO's own duration/member controls stay hidden to prevent duplicates.
      ..duration = ZegoLiveStreamingDurationConfig(isVisible: false)
      ..memberButton = ZegoLiveStreamingMemberButtonConfig(
        builder: (_) => const SizedBox.shrink(),
      )
      ..topMenuBar = ZegoLiveStreamingTopMenuBarConfig(
        buttons: const [],
        showCloseButton: false,
        hostAvatarBuilder: (_) => const SizedBox.shrink(),
      )
      ..bottomMenuBar = ZegoLiveStreamingBottomMenuBarConfig(
        showInRoomMessageButton: false,
        hostButtons: const [],
        coHostButtons: const [],
        audienceButtons: const [],
      )
      ..inRoomMessage = ZegoLiveStreamingInRoomMessageConfig(
        visible: false,
        showFakeMessage: false,
      );
    config.foreground = _GuestCallOverlay(
      isHost: true,
      hostName: widget.name,
      liveId: widget.liveId,
      hostUid: user.uid,
      hostPhotoUrl: widget.photoUrl ?? user.photoURL,
    );

    return ZegoUIKitPrebuiltLiveStreaming(
      appID: kZegoAppId,
      appSign: kZegoAppSign,
      userID: user.uid,
      userName: widget.name,
      liveID: widget.liveId,
      config: config,
      events: ZegoUIKitPrebuiltLiveStreamingEvents(
        onLeaveConfirmation: (
          ZegoLiveStreamingLeaveConfirmationEvent event,
          Future<bool> Function() defaultAction,
        ) async {
          // Guard against a second leave request while ZEGO is already
          // transitioning out of the room. This prevents the confirmation
          // dialog from appearing twice.
          if (_closingFromUser) return true;

          final close = await showDialog<bool>(
            context: event.context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF15131D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: const Text(
                'End the livestream?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
              content: const Text(
                'Are you sure you want to end this live?\n\nCancel keeps you live. End Live closes the room.',
                style: TextStyle(color: Color(0xFFB7BBCB), height: 1.45),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('End Live'),
                ),
              ],
            ),
          );

          if (close != true) return false;

          _closingFromUser = true;
          await _end();
          // Only this one defaultAction is allowed to leave the ZEGO page.
          // onEnded below deliberately does not navigate when this flag is set.
          return await defaultAction();
        },
        onEnded: (event, defaultAction) async {
          await _end();
          if (!_closingFromUser) {
            _closingFromUser = true;
            defaultAction();
          }
        },
        onError: (error) {
          debugPrint('ZEGO host live error: $error');
        },
      ),
    );
  }
}

class LiveSummaryPage extends StatelessWidget {
  final String hostName;
  final Duration duration;
  final int gifts;
  final int viewers;

  const LiveSummaryPage({
    super.key,
    required this.hostName,
    required this.duration,
    required this.gifts,
    required this.viewers,
  });

  String _durationText(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0912),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Livestream has ended',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFB78BFF), width: 2),
                      gradient: const LinearGradient(colors: [Color(0xFF3B3151), Color(0xFF171320)]),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFFB9A8D2), size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hostName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Live session • ${_durationText(duration)}', style: const TextStyle(color: Color(0xFFA9A1B4), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('This session\'s income', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF241B2F), Color(0xFF15111D)]),
                  border: Border.all(color: const Color(0xFF6D4C82)),
                  boxShadow: const [BoxShadow(color: Color(0x552B0B40), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    const _PremiumIncomeIcon(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Income', style: TextStyle(color: Color(0xFFB9AFCA), fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('$gifts', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          const Text('Gifts received this session', style: TextStyle(color: Color(0xFF8E859C), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.18,
                children: [
                  _statCard('Gifts', '$gifts', Icons.card_giftcard_rounded),
                  _statCard('Viewers', '$viewers', Icons.people_alt_rounded),
                  _statCard('Duration', _durationText(duration), Icons.timer_outlined),
                  _statCard('Gift senders', '0', Icons.favorite_rounded),
                  _statCard('New followers', '0', Icons.person_add_alt_1_rounded),
                  _statCard('Peak viewers', '$viewers', Icons.trending_up_rounded),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF15111C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30263A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFB86DFF), size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text('Real gift earnings will appear here when WikaLive wallet and gift transactions are connected.', style: TextStyle(color: Color(0xFFA79CAF), fontSize: 12, height: 1.35))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFFE04BFF), Color(0xFF8A4DFF)]),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('DONE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF15111C), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF30263A))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: const Color(0xFFE48CFF), size: 20),
        const SizedBox(height: 6),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF968C9F), fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _PremiumIncomeIcon extends StatelessWidget {
  const _PremiumIncomeIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFD86B), Color(0xFFC56BFF)]),
        boxShadow: const [BoxShadow(color: Color(0x66D89BFF), blurRadius: 18, spreadRadius: 2)],
      ),
      child: Center(
        child: Container(
          width: 57,
          height: 57,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1420), border: Border.all(color: const Color(0xFFFFD978), width: 2)),
          child: const Stack(alignment: Alignment.center, children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFD978), size: 34),
            Positioned(bottom: 8, right: 7, child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFF0B0), size: 11)),
          ]),
        ),
      ),
    );
  }
}

class _GiftOption {
  final String name;
  final int cost;
  final IconData icon;
  final Color color;

  const _GiftOption(this.name, this.cost, this.icon, this.color);
}

const _giftOptions = <_GiftOption>[
  _GiftOption('Heart', 10, Icons.favorite_rounded, Color(0xFFFF4FA8)),
  _GiftOption('Rose', 50, Icons.local_florist_rounded, Color(0xFFFF6B8A)),
  _GiftOption('Crown', 100, Icons.workspace_premium_rounded, Color(0xFFFFC94A)),
  _GiftOption('Diamond', 500, Icons.diamond_rounded, Color(0xFFB56CFF)),
  _GiftOption('Star', 1000, Icons.star_rounded, Color(0xFF5CC8FF)),
  _GiftOption('Luxury', 5000, Icons.auto_awesome_rounded, Color(0xFFFF4DB8)),
];

class _GuestCallOverlay extends StatefulWidget {
  final bool isHost;
  final String hostName;
  final String liveId;
  final String? hostUid;
  final String? hostPhotoUrl;

  const _GuestCallOverlay({
    required this.isHost,
    required this.hostName,
    required this.liveId,
    required this.hostUid,
    this.hostPhotoUrl,
  });

  @override
  State<_GuestCallOverlay> createState() => _GuestCallOverlayState();
}

class _GuestCallOverlayState extends State<_GuestCallOverlay> {
  final _chatController = TextEditingController();
  bool micOn = true;
  bool beautyOn = true;
  int hearts = 0;
  String? _resolvedHostUid;
  bool _resolvingHost = false;

  ZegoUIKitPrebuiltLiveStreamingController get zego =>
      ZegoUIKitPrebuiltLiveStreamingController();

  @override
  void initState() {
    super.initState();
    _resolvedHostUid = widget.hostUid;
    if (_resolvedHostUid == null && widget.liveId.isNotEmpty) {
      _resolveHost();
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _resolveHost() async {
    if (_resolvingHost || widget.liveId.isEmpty) return;
    _resolvingHost = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('liveId', isEqualTo: widget.liveId)
          .where('isLive', isEqualTo: true)
          .limit(1)
          .get();
      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        setState(() => _resolvedHostUid = snap.docs.first.id);
      }
    } catch (e) {
      debugPrint('WikaLive host resolve skipped: $e');
    } finally {
      _resolvingHost = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    try {
      await zego.message.send(text);
      _chatController.clear();
    } catch (e) {
      if (mounted) msg(context, 'Message could not be sent');
    }
  }

  void _toggleMic() {
    zego.audioVideo.microphone.switchState();
    if (mounted) setState(() => micOn = !micOn);
  }

  void _toggleBeauty() {
    final next = !beautyOn;
    ZegoUIKit().enableBeauty(next);
    if (mounted) setState(() => beautyOn = next);
  }

  void _sendHeart() {
    if (!mounted) return;
    setState(() => hearts = (hearts + 1).clamp(0, 7));
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted && hearts > 0) setState(() => hearts--);
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _rankStream(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('live_gift_ranking')
          .orderBy('diamondsSent', descending: true)
          .limit(3)
          .snapshots();

  String _shortNumber(num n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toInt().toString();
  }

  String _photo(Map<String, dynamic> data, String? fallback) {
    return (data['photoUrl'] ?? fallback ?? '').toString().trim();
  }

  Widget _avatar({String? url, String? name, double radius = 22}) {
    final clean = (url ?? '').trim();
    if (clean.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(clean));
    }
    final safeName = (name ?? '?').trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF242039),
      child: Text(
        safeName.isEmpty ? '?' : safeName.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * .72,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final bottom = media.padding.bottom;

    return StreamBuilder<List<ZegoUIKitUser>>(
      stream: zego.user.stream(includeFakeUser: false),
      builder: (context, roomSnapshot) {
        final roomUsers = roomSnapshot.data ?? const <ZegoUIKitUser>[];
        final selfId = FirebaseAuth.instance.currentUser?.uid;
        final audienceCount = roomUsers.where((u) => u.id != selfId).length;
        final guests = roomUsers
            .where((u) => u.id != selfId && (u.camera.value || u.microphone.value))
            .take(3)
            .toList();

        return Stack(
          fit: StackFit.expand,
          children: [
            // Reference layout: host identity at top-left, guardian badge in the
            // top-center (scaled down + host card narrowed so they never overlap),
            // ranking supporters beside it, then viewers and close.
            Positioned(
              top: top + 14,
              left: 10,
              child: SizedBox(
                width: media.size.width * .33,
                child: _hostCard(),
              ),
            ),
            Positioned(
              top: top + 2,
              left: media.size.width * .355,
              child: SizedBox(
                width: 112,
                height: 112,
                child: _guardianBadge(),
              ),
            ),
            Positioned(
              top: top + 8,
              left: media.size.width * .52,
              width: media.size.width * .24,
              height: 92,
              child: ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: _rankingUsersOnly(),
                ),
              ),
            ),
            Positioned(
              top: top + 18,
              right: 62,
              child: _glass(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                radius: 22,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      _shortNumber(audienceCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: top + 16,
              right: 10,
              child: _roundGlass(Icons.close_rounded, 48, () => _confirmClose(context)),
            ),

            // TOP 1 CONTRIBUTION + LIVE DIAMONDS
            Positioned(
              top: top + 118,
              left: 14,
              child: _topContributionCard(),
            ),
            Positioned(
              top: top + 118,
              right: 12,
              child: _liveDiamondCard(),
            ),

            // FUNCTIONAL ZEGO GUEST/CO-HOST CONTROL — moved up, just under the
            // Top-1/diamonds pill row, instead of floating mid-screen.
            Positioned(
              right: 12,
              top: top + (media.size.height * .387),
              child: _guestArea(context, guests),
            ),

            // REAL ZEGO CHAT. No hard-coded fake messages.
            Positioned(
              left: 14,
              right: media.size.width * .35,
              bottom: bottom + 210,
              child: StreamBuilder<List<ZegoInRoomMessage>>(
                stream: zego.message.stream(includeFakeMessage: false),
                builder: (context, messageSnapshot) {
                  final messages = messageSnapshot.data ?? const <ZegoInRoomMessage>[];
                  final visible = messages.length > 4
                      ? messages.sublist(messages.length - 4)
                      : messages;
                  if (visible.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: visible.map(_messageRow).toList(),
                  );
                },
              ),
            ),

            // WELCOME MESSAGE ABOVE INPUT
            Positioned(
              left: 14,
              right: media.size.width * .35,
              bottom: bottom + 166,
              child: _welcomePill(),
            ),

            // HEARTS
            Positioned(
              right: 15,
              bottom: bottom + 178,
              child: IgnorePointer(
                child: SizedBox(
                  width: 54,
                  height: 330,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: List.generate(hearts, (index) {
                      final offsets = <double>[0, 54, 111, 168, 226, 280, 318];
                      final sizes = <double>[43, 39, 46, 37, 44, 40, 42];
                      return Positioned(
                        bottom: offsets[index.clamp(0, offsets.length - 1)],
                        right: index.isEven ? 0 : 8,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: const Color(0xFFFF36B8),
                          size: sizes[index.clamp(0, sizes.length - 1)],
                          shadows: const [
                            Shadow(color: Color(0xFFB000FF), blurRadius: 14),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Cover only ZEGO's internal bottom message-entry surface. The custom
            // WikaLive input and toolbar are painted after this layer, so they stay
            // fully interactive while the built-in white entry field cannot show.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottom + 92,
              child: AbsorbPointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x66000000),
                        Color(0xF5000000),
                      ],
                      stops: [0.0, 0.28, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // CUSTOM CHAT INPUT
            Positioned(
              left: 14,
              right: media.size.width * .53,
              bottom: bottom + 50,
              child: _chatInput(),
            ),

            // CUSTOM BOTTOM TOOLBAR: MORE / BEAUTY / MIC / GIFT
            Positioned(
              left: media.size.width * .50,
              right: 8,
              bottom: bottom + 48,
              child: _bottomControls(),
            ),
          ],
        );
      },
    );
  }

  Widget _hostCard() {
    final uid = _resolvedHostUid;
    if (uid == null) {
      return _hostIdentity(
        widget.hostName.isEmpty ? 'WikaLive Host' : widget.hostName,
        widget.hostPhotoUrl ?? '',
        32,
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream(uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final name = (data['name'] ?? widget.hostName).toString();
        final level = data['level'] is num ? (data['level'] as num).toInt() : 32;
        final photo = _photo(data, widget.hostPhotoUrl);
        return _hostIdentity(name, photo, level);
      },
    );
  }

  Widget _hostIdentity(String name, String photo, int level) {
    return _glass(
      padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
      radius: 31,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _avatar(url: photo, name: name, radius: 25),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27E47D),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF101015), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name.isEmpty ? 'WikaLive Host' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.shield_rounded, color: Color(0xFFFFD33D), size: 21),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7135D8), Color(0xFFAA3DFF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        'Lv.$level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingUsersOnly() {
    final uid = _resolvedHostUid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _rankStream(uid),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(docs.length, (index) {
            final d = docs[index].data();
            final name = (d['name'] ?? 'User').toString();
            final photo = (d['photoUrl'] ?? '').toString();
            final level = d['level'] is num ? (d['level'] as num).toInt() : 1;
            return _rankDataAvatar(index + 1, name, photo, level);
          }),
        );
      },
    );
  }

  Widget _rankDataAvatar(int rank, String name, String photo, int level) {
    final ring = rank == 1
        ? const Color(0xFFFFD23E)
        : rank == 2
            ? const Color(0xFF7EDCFF)
            : const Color(0xFFFF9A63);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: -11,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: ring,
                  size: 22,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 5)],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 2),
                ),
                child: _avatar(url: photo, name: name, radius: 18),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Lv.$level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardianBadge() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 112,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                top: 24,
                child: Transform.rotate(
                  angle: -.18,
                  child: const Icon(
                    Icons.keyboard_double_arrow_left_rounded,
                    color: Color(0xFF8D35FF),
                    size: 42,
                    shadows: [
                      Shadow(color: Color(0xFFB63CFF), blurRadius: 14),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 24,
                child: Transform.rotate(
                  angle: .18,
                  child: const Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    color: Color(0xFF8D35FF),
                    size: 42,
                    shadows: [
                      Shadow(color: Color(0xFFB63CFF), blurRadius: 14),
                    ],
                  ),
                ),
              ),
              Container(
                width: 72,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFEED2FF), Color(0xFF7130E7), Color(0xFF21063D)],
                  ),
                  border: Border.all(color: const Color(0xFFE8B4FF), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xD28E3CFF), blurRadius: 22, spreadRadius: 3),
                    BoxShadow(color: Color(0x667F35FF), blurRadius: 36),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 58),
                    Icon(Icons.star_rounded, color: Color(0xFFD8A6FF), size: 26),
                  ],
                ),
              ),
              const Positioned(
                top: 2,
                child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFE7B7FF), size: 18),
              ),
            ],
          ),
        ),
        const Text(
          'GUARDIAN',
          style: TextStyle(
            color: Color(0xFFE7B8FF),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Color(0xFF9C35FF), blurRadius: 9)],
          ),
        ),
      ],
    );
  }

  Widget _liveDiamondCard() {
    final uid = _resolvedHostUid;
    if (uid == null) return _diamondPill(0);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream(uid),
      builder: (context, snapshot) {
        final d = snapshot.data?.data() ?? <String, dynamic>{};
        final value = d['liveDiamonds'] is num ? (d['liveDiamonds'] as num).toInt() : 0;
        return _diamondPill(value);
      },
    );
  }

  Widget _diamondPill(int value) {
    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, color: Color(0xFFD34CFF), size: 24),
          const SizedBox(width: 7),
          Text(
            _shortNumber(value),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 9),
          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 21),
        ],
      ),
    );
  }

  Widget _topContributionCard() {
    final uid = _resolvedHostUid;
    if (uid == null) return _topContributionPill(0);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _rankStream(uid),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) return _topContributionPill(0);
        final top = docs.first.data();
        final value = top['diamondsSent'] is num ? (top['diamondsSent'] as num).toInt() : 0;
        return _topContributionPill(value);
      },
    );
  }

  Widget _topContributionPill(int value) {
    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      radius: 23,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF673E), size: 23),
          const SizedBox(width: 7),
          const Text('Top 1', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          const Icon(Icons.diamond_rounded, color: Color(0xFFD34CFF), size: 21),
          const SizedBox(width: 4),
          Text(_shortNumber(value), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _guestArea(BuildContext context, List<ZegoUIKitUser> guests) {
    if (guests.isEmpty) return _guestSlot(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...guests.map((u) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.30),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white54),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _avatar(name: u.name, radius: 21),
                    const SizedBox(height: 2),
                    Text(
                      u.name.isEmpty ? 'Guest' : u.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            )),
        if (guests.length < 3) _guestSlot(context, compact: true),
      ],
    );
  }

  Widget _guestSlot(BuildContext context, {bool compact = false}) {
    return InkWell(
      onTap: () => _openGuestPicker(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: compact ? 60 : 126,
        height: compact ? 60 : 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.23),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.78), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: compact ? 28 : 48),
            const SizedBox(height: 1),
            Text(
              'Guest',
              style: TextStyle(color: Colors.white, fontSize: compact ? 9 : 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageRow(ZegoInRoomMessage message) {
    final uid = message.user.id;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream(uid),
      builder: (context, snapshot) {
        final d = snapshot.data?.data() ?? <String, dynamic>{};
        final level = d['level'] is num ? (d['level'] as num).toInt() : 1;
        final photo = _photo(d, null);
        return _chatBubble(
          message.user.name.isEmpty ? 'User' : message.user.name,
          message.message,
          photo,
          level,
        );
      },
    );
  }

  Widget _chatBubble(String name, String message, String photo, int level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
      decoration: BoxDecoration(
        color: const Color(0xB817171B),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _avatar(url: photo, name: name, radius: 27),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF315FE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 9),
                          const SizedBox(width: 2),
                          Text('Lv.$level', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomePill() {
    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      radius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_rounded, color: Color(0xFFD93CFF), size: 23),
          const SizedBox(width: 7),
          const Flexible(
            child: Text(
              'Welcome to WikaLive! Be kind and respectful! ❤️',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatInput() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xD916161A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(.16)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Say something...',
                hintStyle: TextStyle(color: Color(0xFFA9A6B0), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 17),
              ),
            ),
          ),
          InkWell(
            onTap: () => _sendHeart(),
            borderRadius: BorderRadius.circular(24),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 13),
              child: Icon(Icons.emoji_emotions_outlined, color: Colors.white, size: 25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _bottomButton(Icons.more_horiz_rounded, 'More', () => _openMoreTools(context)),
        _bottomButton(Icons.auto_awesome_rounded, 'Beauty', _toggleBeauty, active: beautyOn),
        _bottomButton(micOn ? Icons.mic_rounded : Icons.mic_off_rounded, 'Mic', _toggleMic, active: micOn),
        _bottomGift(() => _showGift(context)),
      ],
    );
  }

  Widget _glass({required Widget child, EdgeInsetsGeometry? padding, double radius = 20}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xC916171B),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(.13)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
      ),
      child: child,
    );
  }

  Widget _roundGlass(IconData icon, double size, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xC916171B),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(.18)),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
        ),
        child: Icon(icon, color: Colors.white, size: size * .52),
      ),
    );
  }

  Widget _bottomButton(IconData icon, String label, VoidCallback onTap, {bool active = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(34),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xD817181D),
                shape: BoxShape.circle,
                border: Border.all(color: active ? Colors.white.withOpacity(.16) : const Color(0xFFFF55B8)),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 13)],
              ),
              child: Icon(icon, color: active ? Colors.white : const Color(0xFFFF55B8), size: 29),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomGift(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(34),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9A25FF), Color(0xFFFF29AE)],
                ),
                border: Border.all(color: Colors.white.withOpacity(.5)),
                boxShadow: const [
                  BoxShadow(color: Color(0xCCB523FF), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 4),
            const Text('Gift', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Future<void> _showGift(BuildContext context) async {
    final hostUid = _resolvedHostUid;
    if (hostUid == null || hostUid.isEmpty) {
      msg(context, 'Host connection is still loading');
      return;
    }
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null || sender.uid == hostUid) {
      msg(context, 'A host cannot send a gift to their own room');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101016),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Send a gift', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Diamonds are transferred to the host as live income.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 14),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('users').doc(sender.uid).snapshots(),
                  builder: (context, snapshot) {
                    final d = snapshot.data?.data() ?? <String, dynamic>{};
                    final coins = d['coins'] is num ? (d['coins'] as num).toInt() : 0;
                    return Text('Your coins: ${_shortNumber(coins)}', style: const TextStyle(color: Color(0xFFFFD75C), fontWeight: FontWeight.w900));
                  },
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _giftOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.05),
                  itemBuilder: (context, index) {
                    final gift = _giftOptions[index];
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _sendGift(gift);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(color: const Color(0xFF191720), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF302B3A))),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(gift.icon, color: gift.color, size: 28),
                          const SizedBox(height: 4),
                          Text(gift.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('${gift.cost} 💎', style: const TextStyle(color: Color(0xFFFFD75C), fontSize: 10, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendGift(_GiftOption gift) async {
    final sender = FirebaseAuth.instance.currentUser;
    final hostUid = _resolvedHostUid;
    if (sender == null || hostUid == null || hostUid.isEmpty) return;

    final senderRef = FirebaseFirestore.instance.collection('users').doc(sender.uid);
    final hostRef = FirebaseFirestore.instance.collection('users').doc(hostUid);
    final rankRef = hostRef.collection('live_gift_ranking').doc(sender.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final senderSnap = await tx.get(senderRef);
        final hostSnap = await tx.get(hostRef);
        final rankSnap = await tx.get(rankRef);

        final senderData = senderSnap.data() ?? <String, dynamic>{};
        final hostData = hostSnap.data() ?? <String, dynamic>{};
        final rankData = rankSnap.data() ?? <String, dynamic>{};
        final coins = senderData['coins'] is num ? (senderData['coins'] as num).toInt() : 0;
        if (coins < gift.cost) throw Exception('Not enough coins. Recharge coins first.');

        final currentLiveDiamonds = hostData['liveDiamonds'] is num ? (hostData['liveDiamonds'] as num).toInt() : 0;
        final currentGiftCount = hostData['liveGiftCount'] is num ? (hostData['liveGiftCount'] as num).toInt() : 0;
        final sent = rankData['diamondsSent'] is num ? (rankData['diamondsSent'] as num).toInt() : 0;
        final senderName = (senderData['name'] ?? sender.displayName ?? 'WikaLive User').toString();
        final senderPhoto = (senderData['photoUrl'] ?? sender.photoURL ?? '').toString();
        final senderLevel = senderData['level'] is num ? (senderData['level'] as num).toInt() : 1;

        tx.update(senderRef, {'coins': coins - gift.cost, 'updatedAt': FieldValue.serverTimestamp()});
        tx.set(hostRef, {
          'liveDiamonds': currentLiveDiamonds + gift.cost,
          'liveGiftCount': currentGiftCount + 1,
          'giftReceived': FieldValue.increment(gift.cost),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        tx.set(rankRef, {
          'uid': sender.uid,
          'name': senderName,
          'photoUrl': senderPhoto,
          'level': senderLevel,
          'diamondsSent': sent + gift.cost,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final transactionRef = FirebaseFirestore.instance.collection('gift_transactions').doc();
        tx.set(transactionRef, {
          'liveId': widget.liveId,
          'hostUid': hostUid,
          'senderUid': sender.uid,
          'senderName': senderName,
          'gift': gift.name,
          'diamonds': gift.cost,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      _sendHeart();
      if (mounted) msg(context, '${gift.name} sent to the host');
    } catch (e) {
      if (mounted) msg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmClose(BuildContext context) async {
    if (!widget.isHost) {
      Navigator.of(context).maybePop();
      return;
    }
    final close = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15131D),
        title: const Text('End the livestream?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end this live?', style: TextStyle(color: Color(0xFFB7BBCB))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('End Live')),
        ],
      ),
    );
    if (close == true && context.mounted) await zego.leave(context, showConfirmation: false);
  }

  Future<void> _openGuestPicker(BuildContext context) async {
    final controller = zego;
    final currentId = FirebaseAuth.instance.currentUser?.uid;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11101A),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: StreamBuilder<List<ZegoUIKitUser>>(
          stream: controller.user.stream(includeFakeUser: false),
          builder: (context, snapshot) {
            final users = (snapshot.data ?? <ZegoUIKitUser>[]).where((u) => u.id != currentId).toList();
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Invite a guest', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  if (users.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Text('No viewers available yet.', style: TextStyle(color: Color(0xFFAAA6B6))))
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          return ListTile(
                            leading: _avatar(name: u.name, radius: 22),
                            title: Text(u.name.isEmpty ? 'WikaLive User' : u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            trailing: FilledButton(
                              onPressed: widget.isHost
                                  ? () async {
                                      await controller.coHost.hostSendCoHostInvitationToAudience(u, withToast: true);
                                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                                    }
                                  : () async {
                                      await controller.coHost.audienceSendCoHostRequest(withToast: true);
                                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                                    },
                              child: Text(widget.isHost ? 'Invite' : 'Join'),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openMoreTools(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F0E16),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('More tools', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))),
              _toolSection('Room tools', [
                _sheetTool(Icons.analytics_outlined, 'Live data', () => msg(sheetContext, 'Live data is updating in real time.')),
                _sheetTool(Icons.face_retouching_natural_rounded, 'Beauty', () { _toggleBeauty(); Navigator.pop(sheetContext); }),
                _sheetTool(Icons.auto_awesome_rounded, 'Effects', () => msg(sheetContext, 'Effects panel ready.')),
                _sheetTool(Icons.emoji_emotions_outlined, 'Stickers', () => msg(sheetContext, 'Stickers panel ready.')),
                _sheetTool(Icons.music_note_rounded, 'Music', () => msg(sheetContext, 'Music tools will open here.')),
                _sheetTool(Icons.lock_outline_rounded, 'Privacy', () => msg(sheetContext, 'Privacy settings will open here.')),
                _sheetTool(Icons.block_outlined, 'Blocked words', () => msg(sheetContext, 'Blocked words settings will open here.')),
                _sheetTool(Icons.chat_bubble_outline_rounded, 'Chat settings', () => msg(sheetContext, 'Public chat settings will open here.')),
              ]),
              const SizedBox(height: 18),
              _toolSection('Basic tools', [
                _sheetTool(Icons.share_outlined, 'Share', () => Clipboard.setData(const ClipboardData(text: 'WikaLive live room'))),
                _sheetTool(Icons.mic_rounded, 'Microphone', _toggleMic),
                _sheetTool(Icons.flip_camera_android_rounded, 'Mirror', () => msg(sheetContext, 'Mirror control ready.')),
                _sheetTool(Icons.tune_rounded, 'Effect settings', () => msg(sheetContext, 'Effect settings ready.')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolSection(String title, List<Widget> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: Color(0xFFBDB8CA), fontSize: 12, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: items),
  ]);

  Widget _sheetTool(IconData icon, String title, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      width: 82,
      height: 76,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF191720), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF302B3A))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 5),
        Text(title, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
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
      backgroundColor: const Color(0xFF070812),
      appBar: AppBar(
        title: const Text('Become a Host'),
        backgroundColor: const Color(0xFF070812),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 24),
          Container(width: 86, height: 86, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x553F1A70), blurRadius: 25)]), child: Image.asset('assets/wikalive_logo.png', fit: BoxFit.cover)),
          const SizedBox(height: 16),
          const Text('Go Live on WikaLive', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text('Start your camera live, talk with viewers, receive gifts and invite co-hosts.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9CA1B5), height: 1.5)),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => openPage(context, const StartLivePage()),
            icon: const Icon(Icons.videocam_rounded),
            label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('GO LIVE NOW', style: TextStyle(fontWeight: FontWeight.w900))),
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
    if (u == null) return const Scaffold(body: Center(child: Text('Please login again')));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => openPage(context, const EditProfilePage()), icon: const Icon(Icons.edit_rounded)),
          IconButton(onPressed: () => openPage(context, const SettingsPage()), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() ?? <String, dynamic>{};
          final name = (d['name'] ?? u.displayName ?? 'WikaLive User').toString();
          final bio = (d['bio'] ?? '').toString().trim();
          final country = (d['country'] ?? 'India').toString();
          final gender = (d['gender'] ?? '').toString();
          final birthday = (d['birthday'] ?? '').toString();
          final language = (d['language'] ?? '').toString();
          final tag = (d['tag'] ?? '').toString();
          final level = d['level'] is num ? (d['level'] as num).toInt() : 1;
          final id = u.uid.length > 8 ? u.uid.substring(0, 8).toUpperCase() : u.uid.toUpperCase();
          final raw = d['photos'];
          final photos = raw is List ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).take(5).toList() : <String>[];
          final photoUrl = (d['photoUrl'] ?? u.photoURL ?? '').toString();
          if (photos.isEmpty && photoUrl.isNotEmpty) photos.add(photoUrl);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF21152F), Color(0xFF62317E), Color(0xFFA8478D)]),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [BoxShadow(color: Color(0x351D1030), blurRadius: 24, offset: Offset(0, 11))],
                ),
                child: Row(children: [
                  Stack(children: [
                    Container(width: 90, height: 90, padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFD36B), Color(0xFFFF55B7)])), child: ClipOval(child: photoUrl.isEmpty ? Container(color: const Color(0xFFE8D8F6), child: const Icon(Icons.person_rounded, color: primary, size: 48)) : Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8D8F6), child: const Icon(Icons.person_rounded, color: primary, size: 48))))),
                    Positioned(right: 0, bottom: 0, child: InkWell(onTap: () => openPage(context, const EditProfilePage()), child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: primary, size: 17)))),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900))), const SizedBox(width: 6), const Icon(Icons.verified_rounded, color: Color(0xFF53C9FF), size: 19)]),
                    const SizedBox(height: 5),
                    Text('ID: $id', style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    Wrap(spacing: 6, runSpacing: 6, children: [_pill(Icons.workspace_premium_rounded, 'LV.$level'), _pill(Icons.public_rounded, country), if (gender.isNotEmpty) _pill(Icons.wc_rounded, gender)]),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),
              _card(context, 'About me', Icons.edit_note_rounded, bio.isEmpty ? 'Tell people something about you.' : bio, () => openPage(context, const EditProfilePage())),
              const SizedBox(height: 12),
              _cardWidget('Personal information', Icons.person_outline_rounded, Wrap(spacing: 8, runSpacing: 8, children: [if (birthday.isNotEmpty) _chip(Icons.cake_outlined, birthday), if (gender.isNotEmpty) _chip(Icons.wc_rounded, gender), _chip(Icons.public_rounded, country), if (language.isNotEmpty) _chip(Icons.language_rounded, language), if (tag.isNotEmpty) _chip(Icons.local_offer_outlined, tag)]), () => openPage(context, const EditProfilePage())),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFE2F8), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.photo_library_outlined, color: primary)),
                    const SizedBox(width: 11),
                    const Expanded(child: Text('My photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                    TextButton.icon(onPressed: () => openPage(context, const EditProfilePage()), icon: const Icon(Icons.add_photo_alternate_outlined, size: 18), label: const Text('Manage')),
                  ]),
                  const SizedBox(height: 12),
                  if (photos.isEmpty)
                    InkWell(
                      onTap: () => openPage(context, const EditProfilePage()),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 128,
                        decoration: BoxDecoration(color: const Color(0xFFF8F4FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2D8E8))),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, color: primary, size: 32),
                          SizedBox(height: 7),
                          Text('Add photos to your profile', style: TextStyle(color: Color(0xFF6E6478), fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    )
                  else
                    SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photos[i],
                            width: 118,
                            height: 118,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 118,
                              height: 118,
                              color: soft,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              _card(context, 'Edit profile', Icons.edit_rounded, 'Change your name, DP, bio, birthday, country, language and photos.', () => openPage(context, const EditProfilePage())),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(11)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF5EFF9), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: primary, size: 15),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4E4757))),
      ]),
    );
  }

  Widget _card(BuildContext context, String title, IconData icon, String text, VoidCallback onTap) {
    return _cardWidget(
      title,
      icon,
      Text(text, style: const TextStyle(color: Color(0xFF5D5766), fontWeight: FontWeight.w600, height: 1.45)),
      onTap,
    );
  }

  Widget _cardWidget(String title, IconData icon, Widget child, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x09000000), blurRadius: 12, offset: Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFE2F8), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: primary, size: 22)),
            const SizedBox(width: 11),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
            const Icon(Icons.chevron_right_rounded),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

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

  Widget _userIdDisplay() {
    final u = FirebaseAuth.instance.currentUser;
    final id = u == null
        ? ''
        : (u.uid.length > 8 ? u.uid.substring(0, 8).toUpperCase() : u.uid.toUpperCase());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, color: Color(0xFF77717F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User ID',
                    style: TextStyle(
                      color: Color(0xFF77717F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    id,
                    style: const TextStyle(
                      color: Color(0xFF29252F),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy User ID',
              onPressed: id.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: id));
                      if (mounted) msg(context, 'User ID copied');
                    },
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF77717F), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF77717F), size: 18),
          ],
        ),
      ),
    );
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
            _userIdDisplay(),
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

  Color get accent => const Color(0xFFD56CFF);

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
      backgroundColor: const Color(0xFF07091D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07091D),
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
                          style: TextStyle(color: type == x ? Colors.white : Color(0x99FFFFFF), fontSize: 16, fontWeight: FontWeight.w800),
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
                    decoration: BoxDecoration(color: period == x ? const Color(0xFF7A35D6) : Colors.transparent, borderRadius: BorderRadius.circular(25)),
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
                      decoration: BoxDecoration(color: const Color(0x111C1E4A), borderRadius: BorderRadius.circular(24), border: Border.all(color: accent.withOpacity(.22))),
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
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF2A1B58), i == 1 ? const Color(0xFF7A35D6) : const Color(0xFF3C286B)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: const Color(0xFFB66CFF), width: 1.4),
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
        decoration: BoxDecoration(color: const Color(0x111C1E4A), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          SizedBox(width: 38, child: Text('$rank', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w800))),
          CircleAvatar(radius: 30, backgroundImage: url.isNotEmpty ? NetworkImage(url) : null, child: url.isEmpty ? const Icon(Icons.person) : null),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((d['name'] ?? 'User').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${d['countryFlag'] ?? '🌍'}  ${d['title'] ?? 'WikaLive User'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  bool notifications = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07091D),
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
        _settingsSection('GENERAL', [
          _settingsTile(Icons.notifications_rounded, 'Notifications', 'Control alerts and live notifications', trailing: Switch(value: notifications, onChanged: (v) => setState(() => notifications = v))),
          _settingsTile(Icons.language_rounded, 'Language', 'English', onTap: () => _languageSheet(context)),
          _settingsTile(Icons.privacy_tip_rounded, 'Privacy', 'Profile and interaction controls', onTap: () => openPage(context, const FeaturePage(title: 'Privacy', icon: '🔐', items: ['Profile visibility', 'Blocked users', 'Interaction controls']))),
        ]),
        const SizedBox(height: 14),
        _settingsSection('SUPPORT', [
          _settingsTile(Icons.help_outline_rounded, 'Help & Support', 'Get help with WikaLive', onTap: () => openPage(context, const FeaturePage(title: 'Help & Support', icon: '❓', items: ['FAQs', 'Report a problem', 'Contact support']))),
          _settingsTile(Icons.info_outline_rounded, 'About WikaLive', 'App information', onTap: () => openPage(context, const SimplePage(title: 'About WikaLive', items: ['Version 1.0.0', 'Terms of Service', 'Privacy Policy', 'Community Guidelines']))),
        ]),
        const SizedBox(height: 18),
        OutlinedButton.icon(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded), label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w900)), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF4C73), side: const BorderSide(color: Color(0xFFFF3E69)), minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
      ]),
    );
  }

  Widget _settingsSection(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(color: Color(0xFF8E84A4), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
    Container(decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x334A4FA0))), child: Column(children: children)),
  ]);

  Widget _settingsTile(IconData icon, String title, String sub, {VoidCallback? onTap, Widget? trailing}) => ListTile(
    onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0x222D1B6F), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFFD184FF))),
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    subtitle: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.white54),
  );

  void _languageSheet(BuildContext context) {
    showModalBottomSheet<void>(context: context, backgroundColor: const Color(0xFF101333), builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(18), child: Text('Language', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
      for (final language in ['English', 'Hindi', 'Bangla', 'Urdu', 'Arabic']) ListTile(title: Text(language, style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(sheetContext); msg(context, '$language selected'); }),
      const SizedBox(height: 8),
    ])));
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



class KingOfKingsPage extends StatefulWidget {
  const KingOfKingsPage({super.key});
  @override
  State<KingOfKingsPage> createState() => _KingOfKingsPageState();
}

class _KingOfKingsPageState extends State<KingOfKingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  void _open(BuildContext context, String title, String subtitle, IconData icon,
      List<String> items) {
    openPage(
      context,
      RoyalDetailPage(
        title: title,
        subtitle: subtitle,
        icon: icon,
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0912),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0912),
        foregroundColor: Colors.white,
        title: const Text('King of Kings',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => Container(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF170D20), Color(0xFF4B1856), Color(0xFFAA3D8F)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB33CFF)
                        .withOpacity(.12 + (_glow.value * .12)),
                    blurRadius: 30 + (_glow.value * 15),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Text('♛', style: TextStyle(fontSize: 58, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('KING OF KINGS',
                      style: TextStyle(color: Colors.white, fontSize: 25,
                          fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  SizedBox(height: 7),
                  Text('Royal status • privileges • rankings • rewards',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFEAD8F0), fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (uid != null)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snap) {
                final d = snap.data?.data() ?? {};
                final diamonds = d['diamonds'] is num ? (d['diamonds'] as num).toInt() : 0;
                final level = d['level'] is num ? (d['level'] as num).toInt() : 1;
                final gifts = d['giftReceived'] is num ? (d['giftReceived'] as num).toInt() : 0;
                return _royalStats(level, diamonds, gifts);
              },
            ),
          const SizedBox(height: 18),
          _royalSection('MY ROYAL STATUS', [
            _royalTile(context, Icons.workspace_premium_rounded, 'My Level & Status',
                'Level, progress, title and benefits', () => _open(context, 'My Level & Status', 'Your current royal progression', Icons.workspace_premium_rounded,
                    ['Current level', 'Level progress', 'Current title', 'Level benefits', 'Level history'])),
            _royalTile(context, Icons.diamond_rounded, 'Diamond Benefits',
                'Diamond balance, benefits and history', () => _open(context, 'Diamond Benefits', 'Your diamond-related benefits', Icons.diamond_rounded,
                    ['Diamond balance', 'Benefits', 'Reward rules', 'Diamond history'])),
          ]),
          const SizedBox(height: 14),
          _royalSection('PRIVILEGES', [
            _royalTile(context, Icons.card_giftcard_rounded, 'Exclusive Gifts',
                'Special gifts and collection', () => _open(context, 'Exclusive Gifts', 'Special gifts available to eligible users', Icons.card_giftcard_rounded,
                    ['Special gifts', 'Gift collection', 'Gift history'])),
            _royalTile(context, Icons.auto_awesome_rounded, 'VIP Privileges',
                'Badge, frame and special access', () => _open(context, 'VIP Privileges', 'Your VIP benefits', Icons.auto_awesome_rounded,
                    ['VIP badge', 'Profile frame', 'Room privileges', 'Special access'])),
            _royalTile(context, Icons.shield_rounded, 'Guardian Privileges',
                'Guardian status and host protection', () => _open(context, 'Guardian Privileges', 'Guardian tools and history', Icons.shield_rounded,
                    ['Guardian status', 'Guard a host', 'Guardian benefits', 'Guardian history'])),
          ]),
          const SizedBox(height: 14),
          _royalSection('RANKING & REWARDS', [
            _royalTile(context, Icons.emoji_events_rounded, 'King Ranking',
                'Global, country and time-based rankings', () => openPage(context, const RankingPage())),
            _royalTile(context, Icons.calendar_month_rounded, 'Daily / Weekly Rewards',
                'See reward rules and claim status', () => _open(context, 'Royal Rewards', 'Daily and weekly reward information', Icons.calendar_month_rounded,
                    ['Daily rewards', 'Weekly rewards', 'Claimed rewards', 'Reward history', 'Reward rules'])),
          ]),
        ],
      ),
    );
  }

  Widget _royalStats(int level, int diamonds, int gifts) => Row(
        children: [
          Expanded(child: _stat('LEVEL', '$level', Icons.bolt_rounded)),
          const SizedBox(width: 9),
          Expanded(child: _stat('DIAMONDS', '$diamonds', Icons.diamond_rounded)),
          const SizedBox(width: 9),
          Expanded(child: _stat('GIFTS', '$gifts', Icons.card_giftcard_rounded)),
        ],
      );

  Widget _stat(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF17111D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF392844)),
        ),
        child: Column(children: [
          Icon(icon, color: const Color(0xFFD68CFF), size: 21),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: const TextStyle(color: Color(0xFF9E91A5), fontSize: 9, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _royalSection(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: const TextStyle(color: Color(0xFF8F8197), fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
          ),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF151019), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF2B2131))),
            child: Column(children: children),
          ),
        ],
      );

  Widget _royalTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback tap) => ListTile(
        onTap: tap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFF281B30), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFFD06AFF))),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8F8494), fontSize: 11, fontWeight: FontWeight.w600))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8391)),
      );
}

class InviteEarnPage extends StatefulWidget {
  const InviteEarnPage({super.key});
  @override
  State<InviteEarnPage> createState() => _InviteEarnPageState();
}

class _InviteEarnPageState extends State<InviteEarnPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() { _glow.dispose(); super.dispose(); }

  String _inviteCode() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'WIKA';
    final clean = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return 'WIKA${clean.length > 6 ? clean.substring(0, 6) : clean}';
  }

  void _open(BuildContext context, String title, IconData icon, List<String> items) => openPage(
        context,
        InviteDetailPage(title: title, icon: icon, items: items, inviteCode: _inviteCode()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0912),
      appBar: AppBar(backgroundColor: const Color(0xFF0D0912), foregroundColor: Colors.white,
          title: const Text('Invite & Earn', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        AnimatedBuilder(animation: _glow, builder: (_, __) => Container(
          padding: const EdgeInsets.fromLTRB(22, 27, 22, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF170D20), Color(0xFF4B1856), Color(0xFFAA3D8F)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: const Color(0xFFFF4DAA).withOpacity(.10 + _glow.value * .12), blurRadius: 28 + _glow.value * 14)],
          ),
          child: Column(children: const [
            Text('🎁', style: TextStyle(fontSize: 55)),
            SizedBox(height: 8),
            Text('INVITE & EARN', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 1)),
            SizedBox(height: 7),
            Text('Invite friends • track referrals • view rewards', textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFEAD8F0), fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        )),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF151019), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF2B2131))),
          child: Row(children: [
            const Icon(Icons.link_rounded, color: Color(0xFFD06AFF)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MY INVITE CODE', style: TextStyle(color: Color(0xFF8F8197), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 3), Text(_inviteCode(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ])),
            IconButton(onPressed: () { Clipboard.setData(ClipboardData(text: _inviteCode())); msg(context, 'Invite code copied'); }, icon: const Icon(Icons.copy_rounded, color: Colors.white)),
          ])),
        const SizedBox(height: 16),
        _inviteSection('INVITE', [
          _inviteTile(context, Icons.person_add_alt_1_rounded, 'Invite Friends', 'Share your invite code and link', () => _open(context, 'Invite Friends', Icons.person_add_alt_1_rounded, ['My invite code', 'Share invite', 'Invite contacts', 'Copy invite code'])),
          _inviteTile(context, Icons.link_rounded, 'My Invite Code', 'Copy your personal referral code', () => _open(context, 'My Invite Code', Icons.link_rounded, ['Your invite code', 'Copy code', 'Share invite link'])),
        ]),
        const SizedBox(height: 14),
        _inviteSection('EARNINGS', [
          _inviteTile(context, Icons.account_balance_wallet_rounded, 'Referral Earnings', 'Track eligible referral rewards', () => _open(context, 'Referral Earnings', Icons.account_balance_wallet_rounded, ['Total earnings', 'Pending rewards', 'Available rewards', 'Earnings history'])),
          _inviteTile(context, Icons.card_giftcard_rounded, 'Reward Rules', 'See requirements before earning', () => _open(context, 'Reward Rules', Icons.card_giftcard_rounded, ['Invite requirements', 'Reward levels', 'Claim rules', 'Terms'])),
        ]),
        const SizedBox(height: 14),
        _inviteSection('HISTORY', [
          _inviteTile(context, Icons.people_alt_rounded, 'Invited Users', 'See users connected through your code', () => _open(context, 'Invited Users', Icons.people_alt_rounded, ['All invited users', 'Joined users', 'Pending users'])),
          _inviteTile(context, Icons.history_rounded, 'Invitation History', 'Track invitation and reward status', () => _open(context, 'Invitation History', Icons.history_rounded, ['Invitation history', 'Reward history', 'Status'])),
        ]),
      ]),
    );
  }

  Widget _inviteSection(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(color: Color(0xFF8F8197), fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w900))),
    Container(decoration: BoxDecoration(color: const Color(0xFF151019), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF2B2131))), child: Column(children: children)),
  ]);

  Widget _inviteTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback tap) => ListTile(
    onTap: tap, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFF281B30), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFFD06AFF))),
    title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
    subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8F8494), fontSize: 11, fontWeight: FontWeight.w600))),
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8391)),
  );
}

class RoyalDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> items;
  const RoyalDetailPage({super.key, required this.title, required this.subtitle, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0912),
    appBar: AppBar(backgroundColor: const Color(0xFF0D0912), foregroundColor: Colors.white, title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF241332), Color(0xFF8B347E)]), borderRadius: BorderRadius.circular(26)), child: Column(children: [Icon(icon, color: Colors.white, size: 48), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFEAD8F0), fontSize: 12))])),
      const SizedBox(height: 14),
      ...items.map((item) => Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: const Color(0xFF151019), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2B2131))), child: ListTile(leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD06AFF)), title: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8391)), onTap: () => msg(context, '$item opened')))),
    ]),
  );
}

class InviteDetailPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final String inviteCode;
  const InviteDetailPage({super.key, required this.title, required this.icon, required this.items, required this.inviteCode});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0912),
    appBar: AppBar(backgroundColor: const Color(0xFF0D0912), foregroundColor: Colors.white, title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF241332), Color(0xFF8B347E)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [Icon(icon, color: Colors.white, size: 38), const SizedBox(width: 14), Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)))])),
      const SizedBox(height: 14),
      if (title == 'My Invite Code' || title == 'Invite Friends') Container(padding: const EdgeInsets.all(18), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF151019), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2B2131))), child: Column(children: [const Text('YOUR INVITE CODE', style: TextStyle(color: Color(0xFF8F8197), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(height: 5), Text(inviteCode, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)), const SizedBox(height: 10), FilledButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: inviteCode)); msg(context, 'Invite code copied'); }, icon: const Icon(Icons.copy_rounded), label: const Text('Copy code'))])),
      ...items.map((item) => Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: const Color(0xFF151019), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2B2131))), child: ListTile(leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD06AFF)), title: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8391)), onTap: () => msg(context, '$item opened')))),
    ]),
  );
}

class FeaturePage extends StatelessWidget {
  final String title;
  final String icon;
  final List<String> items;
  const FeaturePage({super.key, required this.title, this.icon = '✨', this.items = const ['Information', 'Open feature']});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07091D),
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF151947), Color(0xFF3B135D), Color(0xFF702B8F)]),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x664D43B5)),
            boxShadow: const [BoxShadow(color: Color(0x552A13A4), blurRadius: 28)],
          ),
          child: Column(children: [Text(icon, style: const TextStyle(fontSize: 48)), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(_subtitle(title), textAlign: TextAlign.center, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12, fontWeight: FontWeight.w600))]),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x334A4FA0))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0x222D1B6F), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD184FF))),
            title: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () => openPage(context, SimplePage(title: item, items: [item, 'This WikaLive section is ready for its connected data and actions.'])),
          ),
        )),
      ]),
    );
  }

  static String _subtitle(String title) {
    switch (title) {
      case 'My Level': return 'Track your level, XP and unlocked privileges';
      case 'Fans Club': return 'Manage fans, club level and fan benefits';
      case 'Backpack': return 'Your gifts, frames and special effects';
      case 'Live History': return 'Review your past live sessions and performance';
      case 'Account Security': return 'Protect your account and review login activity';
      case 'Verification': return 'Account verification and safety information';
      default: return 'Manage your WikaLive feature';
    }
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  final List<String> items;
  const SimplePage({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF07091D),
    appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 30), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x334A4FA0))), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
      const SizedBox(height: 12),
      ...items.map((item) => Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0x334A4FA0))), child: ListTile(leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD184FF)), title: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54), onTap: () => msg(context, '$item opened')))),
    ]),
  );
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

// Restored supporting pages preserved from the working WikaLive build.
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
      return const Scaffold(body: Center(child: Text('Please login again')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF07091D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final d = snapshot.data?.data() ?? {};
          final coins = d['coins'] is num ? (d['coins'] as num).toInt() : 0;
          final diamonds = d['diamonds'] is num ? (d['diamonds'] as num).toInt() : 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3C20A0), Color(0xFFB33DDB)]),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [BoxShadow(color: Color(0x553C20A0), blurRadius: 28)],
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('MY BALANCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Text('$coins', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    const Text('Coins', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  ])),
                  Column(children: [const Icon(Icons.diamond_rounded, color: Color(0xFFBDE8FF), size: 40), const SizedBox(height: 4), Text('$diamonds', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const Text('Diamonds', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _walletButton(context, 'Recharge', Icons.add_circle_rounded, const RechargePage())),
                const SizedBox(width: 10),
                Expanded(child: _walletButton(context, 'Withdraw', Icons.account_balance_wallet_rounded, const DiamondWithdrawalPage())),
              ]),
              const SizedBox(height: 18),
              _walletSection('TRANSACTIONS', [
                _walletTile(context, Icons.receipt_long_rounded, 'Transaction History', 'View wallet activity', const SimplePage(title: 'Transaction History', items: ['Recharge history', 'Gift spending', 'Balance changes'])),
                _walletTile(context, Icons.payments_rounded, 'Withdrawal Records', 'Track diamond withdrawals', const SimplePage(title: 'Withdrawal Records', items: ['Pending requests', 'Completed withdrawals', 'Rejected requests'])),
                _walletTile(context, Icons.credit_card_rounded, 'Payment Methods', 'Manage payment options', const SimplePage(title: 'Payment Methods', items: ['UPI', 'Bank account', 'Payment verification'])),
                _walletTile(context, Icons.help_outline_rounded, 'Help Center', 'Wallet and payment support', const SimplePage(title: 'Wallet Help', items: ['Recharge help', 'Withdrawal help', 'Payment support'])),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _walletButton(BuildContext c, String label, IconData icon, Widget page) => SizedBox(height: 52, child: OutlinedButton.icon(
    onPressed: () => openPage(c, page), icon: Icon(icon), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x665E5BFF)), backgroundColor: const Color(0x151A1D46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
  ));

  Widget _walletSection(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(color: Color(0xFF8E84A4), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
    Container(decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x334A4FA0))), child: Column(children: children)),
  ]);

  Widget _walletTile(BuildContext c, IconData icon, String title, String sub, Widget page) => ListTile(
    onTap: () => openPage(c, page), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0x222D1B6F), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFFD184FF))),
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    subtitle: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
  );
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

