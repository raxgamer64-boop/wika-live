import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  String section = 'Follow';
  String period = 'Day';
  final sections = const ['Follow', 'Popular', 'Explore', 'Nearby', 'Beauty', 'Country', 'New Host'];

  Query<Map<String, dynamic>> _base() {
    return FirebaseFirestore.instance.collection('users').where('isLive', isEqualTo: true);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _hosts() {
    return _base().snapshots().map((s) {
      final list = [...s.docs];
      if (section == 'Popular' || section == 'Explore' || section == 'Beauty') {
        list.sort((a,b) => _num(b.data()['giftReceived']) .compareTo(_num(a.data()['giftReceived'])));
      }
      if (section == 'Beauty') {
        list.sort((a,b) => _num(b.data()['beautyScore'] ?? b.data()['qualityScore']).compareTo(_num(a.data()['beautyScore'] ?? a.data()['qualityScore'])));
      }
      if (section == 'New Host') {
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        list.removeWhere((d) {
          final v=d.data()['createdAt'];
          return v is! Timestamp || v.toDate().isBefore(cutoff);
        });
        list.sort((a,b) => _date(b.data()['createdAt']).compareTo(_date(a.data()['createdAt'])));
      }
      return list;
    });
  }

  num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
  DateTime _date(dynamic v) => v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

  Future<Set<String>> _followingIds() async {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return {};
    final s=await FirebaseFirestore.instance.collection('users').doc(uid).collection('following').get();
    return s.docs.map((d)=>d.id).toSet();
  }

  @override Widget build(BuildContext context) {
    return SafeArea(child: Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,8,16,8),child:Row(children:[
        Row(children:[
          Container(width:38,height:38,decoration:BoxDecoration(gradient:const LinearGradient(colors:[primary,accent]),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.play_arrow_rounded,color:Colors.white,size:24)),
          const SizedBox(width:10),
          const Text('WikaLive',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,letterSpacing:-.6)),
        ]),const Spacer(),
        _action(Icons.search_rounded,()=>openPage(context,const UserSearchPage())),const SizedBox(width:8),
        _action(Icons.workspace_premium_rounded,()=>openPage(context,const RankingPage())),
      ])),
      SizedBox(height:48,child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:16),scrollDirection:Axis.horizontal,itemCount:sections.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i)=>ChoiceChip(label:Text(sections[i]),selected:section==sections[i],onSelected:(_){setState(()=>section=sections[i]); if(sections[i]=='Country') openPage(context,const CountryLivePage());}))),
      Expanded(child: StreamBuilder<List<QueryDocumentSnapshot<Map<String,dynamic>>>>(stream:_hosts(),builder:(context,s){
        if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        var docs=s.data??[];
        if(section=='Follow') return FutureBuilder<Set<String>>(future:_followingIds(),builder:(c,f){
          final ids=f.data??{}; docs=docs.where((d)=>ids.contains(d.id)).toList(); return _grid(context,docs,'No followed host is live right now.');
        });
        if(section=='Nearby') return _nearby(context,docs);
        return _grid(context,docs,'No live hosts found.');
      }))
    ]));
  }
  Widget _action(IconData i,VoidCallback t)=>InkWell(onTap:t,borderRadius:BorderRadius.circular(22),child:Container(width:42,height:42,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),boxShadow:const [BoxShadow(color:Color(0x12000000),blurRadius:10)]),child:Icon(i)));
  Widget _grid(BuildContext c,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs,String empty)=>docs.isEmpty?Center(child:Text(empty)):GridView.builder(padding:const EdgeInsets.all(16),itemCount:docs.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.72),itemBuilder:(c,i){final d=docs[i];final x=d.data();final photo=(x['photos'] is List&& (x['photos'] as List).isNotEmpty)?(x['photos'] as List).first.toString():(x['photoUrl']??'').toString();return InkWell(onTap:()=>openPage(c,LiveRoomPage(host:(x['name']??'Host').toString(),viewers:'${x['viewers']??0} viewers')),borderRadius:BorderRadius.circular(18),child:ClipRRect(borderRadius:BorderRadius.circular(18),child:Stack(fit:StackFit.expand,children:[photo.isEmpty?Container(color:const Color(0xFFE8DDF3),child:const Icon(Icons.person,size:70)):Image.network(photo,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:const Color(0xFFE8DDF3),child:const Icon(Icons.person,size:70))),const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Colors.black87]))),Positioned(top:8,left:8,child:_badge('LIVE')),Positioned(left:10,right:10,bottom:10,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((x['name']??'Host').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text('${x['countryFlag']??'🌍'}  ${x['viewers']??0} watching',style:const TextStyle(color:Colors.white70,fontSize:12,fontWeight:FontWeight.w700))]))])));});
  Widget _badge(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:const Color(0xFFE83F83),borderRadius:BorderRadius.circular(9)),child:Text(t,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)));
  Widget _nearby(BuildContext c,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs){final me=FirebaseAuth.instance.currentUser; if(me==null)return _grid(c,[], 'Please login again.'); return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(future:FirebaseFirestore.instance.collection('users').doc(me.uid).get(),builder:(c,s){final m=s.data?.data()??{};final lat=_num(m['latitude']);final lon=_num(m['longitude']);if(lat==0&&lon==0)return const Center(child:Padding(padding:EdgeInsets.all(30),child:Text('Nearby live needs your location saved in your profile.')));final near=docs.where((d){final x=d.data();final a=_num(x['latitude']);final b=_num(x['longitude']);if(a==0&&b==0)return false;final dx=(a-lat).abs()*111;final dy=(b-lon).abs()*111;return (dx*dx+dy*dy)<2500;}).toList();return _grid(c,near,'No live host found within 50 km.');});}
}

class CountryLivePage extends StatelessWidget {
  const CountryLivePage({super.key});
  static const countries=['🇮🇳 India','🇧🇩 Bangladesh','🇵🇰 Pakistan','🇳🇵 Nepal','🇱🇰 Sri Lanka','🇦🇪 UAE','🇸🇦 Saudi Arabia','🇮🇩 Indonesia'];
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:const Text('Country Live')),body:GridView.builder(
      padding:const EdgeInsets.all(16), itemCount:countries.length,
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.9),
      itemBuilder:(c,i){
        final parts=countries[i].split(' ');
        return InkWell(onTap:()=>openPage(c,CountryHostsPage(country:countries[i].substring(5))),borderRadius:BorderRadius.circular(16),child:Container(
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(parts.first,style:const TextStyle(fontSize:30)),const SizedBox(height:6),Text(countries[i].substring(5),textAlign:TextAlign.center,maxLines:2,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800))]),
        ));
      },
    ));
  }
}

class CountryHostsPage extends StatelessWidget { final String country; const CountryHostsPage({super.key,required this.country}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('$country Live')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').where('isLive',isEqualTo:true).where('country',isEqualTo:country).snapshots(),builder:(c,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());final docs=s.data?.docs??[];return _HostList(docs:docs); })); }

class _HostList extends StatelessWidget { final List<QueryDocumentSnapshot<Map<String,dynamic>>> docs; const _HostList({required this.docs}); @override Widget build(BuildContext c)=>docs.isEmpty?const Center(child:Text('No live hosts')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:docs.length,itemBuilder:(c,i){final x=docs[i].data();return ListTile(leading:CircleAvatar(backgroundImage:(x['photoUrl']??'').toString().isNotEmpty?NetworkImage(x['photoUrl'].toString()):null,child:(x['photoUrl']??'').toString().isEmpty?const Icon(Icons.person):null),title:Text((x['name']??'Host').toString()),subtitle:Text('LIVE • ${x['viewers']??0} viewers'),onTap:()=>openPage(c,LiveRoomPage(host:(x['name']??'Host').toString(),viewers:'${x['viewers']??0} viewers')));}); }

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
      Row(children: [const Text('Party', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: () => openPage(context, const FeaturePage(title: 'Search Party')), icon: const Icon(Icons.search_rounded, size: 31)), const SizedBox(width: 6), IconButton(onPressed: () => openPage(context, const FeaturePage(title: 'Party Rewards', icon: '👑', items: ['Rewards', 'Rankings', 'Benefits'])), icon: const Text('👑', style: TextStyle(fontSize: 28))) ]),
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
        final diamonds = data['diamonds'] is num ? (data['diamonds'] as num).toInt() : 0;
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
                    _topIcon(Icons.search_rounded, onTap: () => openPage(context, const FeaturePage(title: 'Search'))),
                    const SizedBox(width: 10),
                    _topIcon(Icons.settings_rounded, onTap: () => openPage(context, const SettingsPage())),
                  ],
                ),
                const SizedBox(height: 14),
                _profileHero(context, name, shortId),
                const SizedBox(height: 14),
                _statsCard(context, uid),
                const SizedBox(height: 14),
                _kingCard(context),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _coinCard(context, coins)),
                    const SizedBox(width: 12),
                    Expanded(child: _gemCard(context, diamonds)),
                  ],
                ),
                const SizedBox(height: 14),
                _inviteCard(context),
                const SizedBox(height: 16),
                _sectionTitle('My Space', '6 tools'),
                const SizedBox(height: 9),
                _toolPanel(context, [
                  _Tool(Icons.calendar_month_rounded, 'Task', const Color(0xFFFF5E72)),
                  _Tool(Icons.favorite_rounded, 'Level', const Color(0xFFE63F9A)),
                  _Tool(Icons.auto_awesome_rounded, 'Fans Club', const Color(0xFFFF4D91)),
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

  Widget _profileHero(BuildContext context, String name, String id) {
    return InkWell(
      onTap: () => openPage(context, const ProfilePage()),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A1C43), Color(0xFF6B3D91), Color(0xFFB34D9B)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x301D1030), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: Row(
          children: [
            Container(width: 82, height: 82, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFFD37A), Color(0xFFFF6FB4)]), border: Border.all(color: Colors.white, width: 3)), padding: const EdgeInsets.all(4), child: const CircleAvatar(backgroundColor: Color(0xFFE8D7F8), child: Icon(Icons.person_rounded, color: Color(0xFF5B3A8F), size: 45))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))), const SizedBox(width: 7), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0x35FFFFFF), borderRadius: BorderRadius.circular(9)), child: const Text('LV.1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))) ]),
                const SizedBox(height: 7),
                Text('ID: $id', style: const TextStyle(color: Color(0xFFDCCFE9), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 9),
                Row(children: [_miniBadge('🇮🇳', 'India'), const SizedBox(width: 7), _miniBadge('♀', '18'), const SizedBox(width: 7), _miniBadge('✦', '11')]),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 28),
          ],
        ),
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

  Widget _statsCard(BuildContext context, String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 18, offset: Offset(0, 6))]),
      child: Row(children: [
        _countStat(context, uid, 'friends', 'Friends', const FriendsPage()),
        _divider(),
        _countStat(context, uid, 'following', 'Following', const FollowingPage()),
        _divider(),
        _countStat(context, uid, 'followers', 'Followers', const FollowersPage()),
        _divider(),
        _countStat(context, uid, 'visitors', 'Visitors', const VisitorsPage()),
      ]),
    );
  }

  Widget _statTap(BuildContext context, String value, String label, Widget page) {
    return Expanded(
      child: InkWell(onTap: () => openPage(context, page), child: Column(children: [Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF22202A))), const SizedBox(height: 4), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9994A3)))])),
    );
  }

  Widget _countStat(BuildContext context, String uid, String sub, String label, Widget page) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection(sub).snapshots(),
        builder: (context, snap) {
          final value = snap.data?.size ?? 0;
          return InkWell(onTap: () => openPage(context, page), child: Column(children: [Text('$value', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF22202A))), const SizedBox(height: 4), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9994A3)))]));
        },
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
      onTap: () => openPage(context, const KingOfKingsPage()),
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

  Widget _gemCard(BuildContext context, int diamonds) {
    return InkWell(
      onTap: () => openPage(context, const DiamondWithdrawalPage()),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF0E0FF), Color(0xFFE5D1FF)]), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x33FFFFFF)), child: const Center(child: Text('💎', style: TextStyle(fontSize: 30)))),
          const SizedBox(width: 10),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('DIAMONDS', style: TextStyle(fontSize: 11, letterSpacing: 1, color: Color(0xFF777083), fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('$diamonds', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))])),
          const Icon(Icons.account_balance_wallet_outlined, size: 20),
        ]),
      ),
    );
  }

  Widget _inviteCard(BuildContext context) {
    return InkWell(
      onTap: () => openPage(context, const InviteEarnPage()),
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
      case 'Backpack': return const FeaturePage(title: 'Backpack', icon: '🎒', items: ['My items', 'Frames', 'Effects']);
      case 'Dress Store': return const FeaturePage(title: 'Dress Store', icon: '🛍️', items: ['Frames', 'Effects', 'Name decorations', 'Limited items']);
      case 'Event Center': return const FeaturePage(title: 'Event Center', icon: '🎟️', items: ['Live events', 'Party events', 'Rank events', 'Event rewards']);
      case 'VIP': return const FeaturePage(title: 'VIP', icon: '👑', items: ['VIP membership', 'VIP privileges', 'VIP badge', 'VIP rewards']);
      case 'Guardian': return const FeaturePage(title: 'Guardian', icon: '🛡️', items: ['Guardian status', 'Guard a host', 'Guardian privileges']);
      case 'Join Agency': return const AgencyPage();
      case 'Real Person': return const FeaturePage(title: 'Real Person Detection', icon: '🕵️', items: ['Verification', 'Verification status', 'Safety information']);
      case 'Help & Feedback': return const FeaturePage(title: 'Help & Feedback', icon: '❓', items: ['Common questions', 'Report a problem', 'Send feedback', 'Safety help']);
      case 'Customer Service': return const FeaturePage(title: 'Customer Service', icon: '🎧', items: ['Online support', 'Account help', 'Payment support', 'Live support']);
      default: return FeaturePage(title: label, icon: '✨', items: ['Open $label', 'Information', 'Help']);
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
      return const Scaffold(body: Center(child: Text('Please login again')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5FC),
        surfaceTintColor: Colors.transparent,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => openPage(context, const EditProfilePage()),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => openPage(context, const SettingsPage()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final d = snap.data?.data() ?? <String, dynamic>{};
          final name = (d['name'] ?? u.displayName ?? 'WikaLive User').toString();
          final bio = (d['bio'] ?? '').toString().trim();
          final country = (d['country'] ?? 'India').toString();
          final gender = (d['gender'] ?? '').toString();
          final birthday = (d['birthday'] ?? '').toString();
          final language = (d['language'] ?? '').toString();
          final tag = (d['tag'] ?? '').toString();
          final level = d['level'] is num ? (d['level'] as num).toInt() : 1;
          final diamonds = d['diamonds'] is num ? (d['diamonds'] as num).toInt() : 0;
          final coins = d['coins'] is num ? (d['coins'] as num).toInt() : 0;
          final isLive = d['isLive'] == true;
          final id = u.uid.length > 8 ? u.uid.substring(0, 8).toUpperCase() : u.uid.toUpperCase();

          final raw = d['photos'];
          final photos = raw is List
              ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).take(5).toList()
              : <String>[];
          final photoUrl = (d['photoUrl'] ?? u.photoURL ?? '').toString();
          if (photos.isEmpty && photoUrl.isNotEmpty) photos.add(photoUrl);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
            children: [
              _hero(
                context,
                name: name,
                id: id,
                level: level,
                country: country,
                isLive: isLive,
                photo: photos.isNotEmpty ? photos.first : '',
              ),
              const SizedBox(height: 14),
              _identityCard(context, id: id, name: name, country: country),
              const SizedBox(height: 14),
              if (bio.isNotEmpty) ...[
                _sectionCard(
                  title: 'About me',
                  icon: Icons.auto_awesome_rounded,
                  child: Text(
                    bio,
                    style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF55505E), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _sectionCard(
                title: 'Personal information',
                icon: Icons.badge_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(Icons.public_rounded, country),
                    if (gender.isNotEmpty) _infoChip(Icons.wc_rounded, gender),
                    if (birthday.isNotEmpty) _infoChip(Icons.cake_outlined, birthday),
                    if (language.isNotEmpty) _infoChip(Icons.language_rounded, language),
                    if (tag.isNotEmpty) _infoChip(Icons.local_offer_outlined, tag),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'My photos',
                icon: Icons.photo_library_outlined,
                trailing: TextButton.icon(
                  onPressed: () => openPage(context, const EditProfilePage()),
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text('Manage'),
                ),
                child: photos.isEmpty
                    ? _emptyPhotos(context)
                    : SizedBox(
                        height: 118,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) => _photoTile(photos[index], index),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'My activity',
                icon: Icons.insights_rounded,
                child: Row(
                  children: [
                    _activityStat('Level', 'LV.$level'),
                    _verticalLine(),
                    _activityStat('Coins', _compactNumber(coins)),
                    _verticalLine(),
                    _activityStat('Diamonds', _compactNumber(diamonds)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'Quick access',
                icon: Icons.grid_view_rounded,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .95,
                  children: [
                    _quickAction(context, Icons.photo_camera_back_rounded, 'Moments', () => openPage(context, const MomentsScreen())),
                    _quickAction(context, Icons.workspace_premium_rounded, 'My Level', () => openPage(context, const FeaturePage(title: 'My Level', icon: '✨', items: ['Level progress', 'Level rewards', 'How to level up']))),
                    _quickAction(context, Icons.favorite_rounded, 'Fans Club', () => openPage(context, const FeaturePage(title: 'Fans Club', icon: '💖', items: ['My fans', 'Club level', 'Club rewards']))),
                    _quickAction(context, Icons.backpack_rounded, 'Backpack', () => openPage(context, const FeaturePage(title: 'Backpack', icon: '🎒', items: ['My items', 'Frames', 'Effects']))),
                    _quickAction(context, Icons.account_balance_wallet_rounded, 'Wallet', () => openPage(context, const WalletPage())),
                    _quickAction(context, Icons.settings_outlined, 'Settings', () => openPage(context, const SettingsPage())),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => openPage(context, const EditProfilePage()),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  side: const BorderSide(color: Color(0xFFD9CBE6)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(BuildContext context, {required String name, required String id, required int level, required String country, required bool isLive, required String photo}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF21152E), Color(0xFF5D287A), Color(0xFF9A3F85)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x301F102D), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(photo, size: 86),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900))),
                    if (isLive) ...[
                      const SizedBox(width: 7),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: const Color(0x33FF5C77), borderRadius: BorderRadius.circular(9)), child: const Text('LIVE', style: TextStyle(color: Color(0xFFFFA5B5), fontSize: 9, fontWeight: FontWeight.w900))),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Text('ID: $id', style: const TextStyle(color: Color(0xFFDCCBE6), fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 9),
                  Row(children: [
                    _heroPill(Icons.workspace_premium_rounded, 'LV.$level'),
                    const SizedBox(width: 7),
                    _heroPill(Icons.public_rounded, country),
                  ]),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(children: [
            Expanded(child: _heroAction(context, Icons.edit_rounded, 'Edit', () => openPage(context, const EditProfilePage()))),
            const SizedBox(width: 10),
            Expanded(child: _heroAction(context, Icons.ios_share_rounded, 'Share ID', () { Clipboard.setData(ClipboardData(text: id)); msg(context, 'ID copied'); })),
          ]),
        ],
      ),
    );
  }

  Widget _identityCard(BuildContext context, {required String id, required String name, required String country}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 6))]),
      child: Column(children: [
        Row(children: [const Icon(Icons.fingerprint_rounded, color: primary), const SizedBox(width: 10), const Expanded(child: Text('WikaLive ID', style: TextStyle(fontWeight: FontWeight.w800))), TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: id)); msg(context, 'ID copied'); }, icon: const Icon(Icons.copy_rounded, size: 17), label: const Text('Copy'))]),
        const SizedBox(height: 7),
        Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFF6F1FA), borderRadius: BorderRadius.circular(14)), child: Text(id, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1.4))),
      ]),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0E7F8), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: primary, size: 20)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))), if (trailing != null) trailing]),
        const SizedBox(height: 13),
        child,
      ]),
    );
  }

  Widget _avatar(String photo, {double size = 70}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFD66B), Color(0xFFFF6EB0)])),
      child: ClipOval(
        child: photo.isEmpty
            ? Container(color: const Color(0xFFE8D7F8), child: const Icon(Icons.person_rounded, color: Color(0xFF5B3A8F), size: 42))
            : Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8D7F8), child: const Icon(Icons.person_rounded, color: Color(0xFF5B3A8F), size: 42))),
      ),
    );
  }

  Widget _heroPill(IconData icon, String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: const Color(0x25FFFFFF), borderRadius: BorderRadius.circular(11)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white70, size: 14), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800))]));

  Widget _heroAction(BuildContext context, IconData icon, String label, VoidCallback onTap) => FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 17), label: Text(label), style: FilledButton.styleFrom(backgroundColor: const Color(0x22FFFFFF), foregroundColor: Colors.white, elevation: 0, minimumSize: const Size.fromHeight(43), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));

  Widget _infoChip(IconData icon, String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF6F1FA), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: primary), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4E4757)))]));

  Widget _emptyPhotos(BuildContext context) => InkWell(onTap: () => openPage(context, const EditProfilePage()), borderRadius: BorderRadius.circular(16), child: Container(height: 118, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF7F3FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE3D8EB))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: primary, size: 30), SizedBox(height: 7), Text('Add photos to your profile', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6E6478)))]));

  Widget _photoTile(String url, int index) => ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(children: [Image.network(url, width: 118, height: 118, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 118, height: 118, color: soft, child: const Icon(Icons.broken_image_outlined))), Positioned(left: 8, bottom: 7, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))))]));

  Widget _activityStat(String label, String value) => Expanded(child: Column(children: [Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF96909F), fontWeight: FontWeight.w700))]));

  Widget _verticalLine() => Container(width: 1, height: 34, color: const Color(0xFFEDE8F1));

  Widget _quickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(color: const Color(0xFFF8F5FA), borderRadius: BorderRadius.circular(16)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFE4F8), shape: BoxShape.circle), child: Icon(icon, color: primary, size: 22)), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800))])));

  String _compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    return '$value';
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
