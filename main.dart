import 'dart:math';

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
  @override State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  String section = 'Follow';
  final sections = const ['Follow','Popular','Explore','Nearby','Beauty','Country','New Host'];

  Query<Map<String,dynamic>> _base() => FirebaseFirestore.instance.collection('users').where('isLive',isEqualTo:true);
  num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
  DateTime _date(dynamic v) => v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

  Stream<List<QueryDocumentSnapshot<Map<String,dynamic>>>> _hosts() => _base().snapshots().map((s){
    final list=[...s.docs];
    if(section=='Popular'||section=='Explore') list.sort((a,b)=>_num(b.data()['giftReceived']).compareTo(_num(a.data()['giftReceived'])));
    if(section=='Beauty') list.sort((a,b)=>_num(b.data()['beautyScore']??b.data()['qualityScore']).compareTo(_num(a.data()['beautyScore']??a.data()['qualityScore'])));
    if(section=='New Host') { final cutoff=DateTime.now().subtract(const Duration(days:7)); list.removeWhere((d){final v=d.data()['createdAt']; return v is! Timestamp || _date(v).isBefore(cutoff);}); list.sort((a,b)=>_date(b.data()['createdAt']).compareTo(_date(a.data()['createdAt']))); }
    return list;
  });

  Future<Set<String>> _followingIds() async {
    final uid=FirebaseAuth.instance.currentUser?.uid; if(uid==null)return {};
    final s=await FirebaseFirestore.instance.collection('users').doc(uid).collection('following').get();
    return s.docs.map((d)=>d.id).toSet();
  }

  @override Widget build(BuildContext context) {
    return SafeArea(child: Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,8,16,4),child:Row(children:[
        const Expanded(child:Text('WikaLive',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900))),
        _circleAction(Icons.search_rounded,()=>openPage(context,const UserSearchPage())),const SizedBox(width:8),
        _circleAction(Icons.leaderboard_rounded,()=>openPage(context,const RankingPage())),
      ])),
      const SizedBox(height:6),
      SizedBox(height:54,child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:16),scrollDirection:Axis.horizontal,itemCount:sections.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(c,i){final x=sections[i];return ChoiceChip(label:Text(x),selected:section==x,onSelected:(_){setState(()=>section=x);if(x=='Country')openPage(context,const CountryLivePage());});})),
      _liveBanner(context),
      Expanded(child:StreamBuilder<List<QueryDocumentSnapshot<Map<String,dynamic>>>>(stream:_hosts(),builder:(context,snap){
        if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        var docs=snap.data??[];
        if(section=='Follow') return FutureBuilder<Set<String>>(future:_followingIds(),builder:(c,f){final ids=f.data??{};return _hostGrid(c,docs.where((d)=>ids.contains(d.id)).toList(),'No followed host is live right now.');});
        if(section=='Nearby') return _nearby(context,docs);
        return _hostGrid(context,docs,'No live hosts found.');
      }))
    ]));
  }

  Widget _circleAction(IconData icon,VoidCallback tap)=>InkWell(onTap:tap,borderRadius:BorderRadius.circular(22),child:Container(width:44,height:44,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),boxShadow:const[BoxShadow(color:Color(0x16000000),blurRadius:14)]),child:Icon(icon)));

  Widget _liveBanner(BuildContext context)=>Container(margin:const EdgeInsets.fromLTRB(16,6,16,10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF6D2BEA),Color(0xFFE44FA8)]),borderRadius:BorderRadius.circular(22),boxShadow:const[BoxShadow(color:Color(0x3D7B31D5),blurRadius:18,offset:Offset(0,8))]),child:Row(children:[
    Container(width:52,height:52,decoration:BoxDecoration(color:Colors.white.withAlpha(35),shape:BoxShape.circle),child:const Icon(Icons.live_tv_rounded,color:Colors.white,size:28)),const SizedBox(width:12),
    const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('LIVE NOW',style:TextStyle(color:Color(0xFFFFE27A),fontSize:11,fontWeight:FontWeight.w900,letterSpacing:1.3)),SizedBox(height:3),Text('Meet hosts • Watch • Chat • Gift',style:TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900)),SizedBox(height:2),Text('Real-time rooms from your community',style:TextStyle(color:Colors.white70,fontSize:11))])),
    IconButton(onPressed:()=>openPage(context,const HostPage()),icon:const Icon(Icons.add_circle_rounded,color:Colors.white,size:31))
  ]));

  Widget _hostGrid(BuildContext c,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs,String empty)=>docs.isEmpty?Center(child:Text(empty)):GridView.builder(padding:const EdgeInsets.fromLTRB(16,2,16,20),itemCount:docs.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.68),itemBuilder:(c,i){final d=docs[i];final x=d.data();final photos=x['photos'] is List?(x['photos'] as List):[];final photo=photos.isNotEmpty?photos.first.toString():(x['photoUrl']??'').toString();final name=(x['name']??'Host').toString();final viewers=x['viewers']??0;return InkWell(onTap:()=>openPage(c,LiveRoomPage(host:name,viewers:'$viewers viewers')),borderRadius:BorderRadius.circular(22),child:ClipRRect(borderRadius:BorderRadius.circular(22),child:Stack(fit:StackFit.expand,children:[
    photo.isEmpty?Container(color:const Color(0xFFE9DDF4),child:const Icon(Icons.person_rounded,size:70,color:Color(0xFF8052A6))):Image.network(photo,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:const Color(0xFFE9DDF4),child:const Icon(Icons.person_rounded,size:70))),
    const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.center,colors:[Color(0x55000000),Colors.transparent]))),
    const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.center,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xF0000000)]))),
    Positioned(top:9,left:9,child:_pill('LIVE',const Color(0xFFE83F83))),Positioned(top:8,right:8,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:5),decoration:BoxDecoration(color:Colors.black45,borderRadius:BorderRadius.circular(12)),child:Text('${x['countryFlag']??'🌍'}',style:const TextStyle(fontSize:14)))),
    Positioned(left:11,right:11,bottom:11,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:5),Row(children:[const Icon(Icons.remove_red_eye_outlined,color:Colors.white70,size:14),const SizedBox(width:4),Text('$viewers watching',style:const TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700)),const Spacer(),const Icon(Icons.card_giftcard_rounded,color:Color(0xFFFFD76A),size:17)])]))
  ])));});

  Widget _pill(String text,Color color)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(9)),child:Text(text,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)));

  Widget _nearby(BuildContext c,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs){final me=FirebaseAuth.instance.currentUser;if(me==null)return _hostGrid(c,[],'Please login again.');return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(future:FirebaseFirestore.instance.collection('users').doc(me.uid).get(),builder:(c,s){final m=s.data?.data()??{};final lat=_num(m['latitude']);final lon=_num(m['longitude']);if(lat==0&&lon==0)return const Center(child:Padding(padding:EdgeInsets.all(30),child:Text('Nearby needs your saved location.')));final near=docs.where((d){final x=d.data();final a=_num(x['latitude']);final b=_num(x['longitude']);if(a==0&&b==0)return false;final dx=(a-lat).abs()*111;final dy=(b-lon).abs()*111;return(dx*dx+dy*dy)<2500;}).toList();return _hostGrid(c,near,'No live host found within 50 km.');});}
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
    ['hotty hot 🔥', 'Make Friends', '31'],
    ['SINGH Agency', 'Music Party', '4'],
    ["Suman's room", 'Gossip', '3'],
    ["Suhani's room", 'Emotional Share', '2'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Row(children: [
            const Expanded(child: Text('Party', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900))),
            _top(Icons.search_rounded, () => openPage(context, const FeaturePage(title: 'Search Party'))),
            const SizedBox(width: 8),
            _top(Icons.add_rounded, () => openPage(context, const CreatePartyPage())),
          ]),
          const SizedBox(height: 14),
          Container(
            height: 150,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF25123D), Color(0xFF8A3E8F)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('PARTY WORLD', style: TextStyle(color: Color(0xFFFFD76A), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    SizedBox(height: 6),
                    Text('Talk • Sing • Play • Make friends', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('Join a room and meet your next friend.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Text('🎤', style: TextStyle(fontSize: 65)),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Popular', 'PK Battle', 'Music', 'Chat', 'Event'].map((x) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(x), selected: x == 'Popular', onSelected: (_) {}),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          ...rooms.map((room) => _room(context, room)),
        ],
      ),
    );
  }

  Widget _top(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Icon(icon)),
  );

  Widget _room(BuildContext context, List<String> room) => InkWell(
    onTap: () => openPage(context, PartyRoomPage(title: room[0])),
    borderRadius: BorderRadius.circular(20),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 5))]),
      child: Row(children: [
        Container(
          width: 82, height: 82,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFC65C), Color(0xFFE957B4)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 42),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🇮🇳  ${room[0]}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(room[1], style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFE8F5), borderRadius: BorderRadius.circular(12)), child: Text(room[1], style: const TextStyle(color: Color(0xFFD84F9F), fontSize: 11, fontWeight: FontWeight.w800))),
            const Spacer(),
            Text('👥 ${room[2]}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
        ])),
      ]),
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
  @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const SizedBox.shrink();return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),builder:(context,snap){final d=snap.data?.data()??{};final u=FirebaseAuth.instance.currentUser;final name=(d['name']??u?.displayName??'WikaLive User').toString();final coins=d['coins'] is num?(d['coins'] as num).toInt():0;final diamonds=d['diamonds'] is num?(d['diamonds'] as num).toInt():0;final id=uid.length>8?uid.substring(0,8).toUpperCase():uid.toUpperCase();final photo=(d['photoUrl']??'').toString();return Container(color:const Color(0xFFF7F6FB),child:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,26),children:[
    Row(children:[const Expanded(child:Text('Me',style:TextStyle(fontSize:29,fontWeight:FontWeight.w900))),_icon(Icons.settings_rounded,()=>openPage(context,const SettingsPage()))]),const SizedBox(height:12),
    InkWell(onTap:()=>openPage(context,const ProfilePage()),borderRadius:BorderRadius.circular(26),child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF241536),Color(0xFF70408E),Color(0xFFB64F9E)]),borderRadius:BorderRadius.circular(26)),child:Row(children:[CircleAvatar(radius:39,backgroundImage:photo.isNotEmpty?NetworkImage(photo):null,backgroundColor:const Color(0xFFE8D7F8),child:photo.isEmpty?const Icon(Icons.person_rounded,size:42,color:Color(0xFF65418A)):null),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text('ID: $id',style:const TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:10),Row(children:[_tag('🇮🇳'),const SizedBox(width:6),_tag('LV 1'),const SizedBox(width:6),_tag('Edit profile')])])),const Icon(Icons.chevron_right_rounded,color:Colors.white70)]))),
    const SizedBox(height:12),
    _stats(context,uid),const SizedBox(height:12),
    Row(children:[Expanded(child:_walletCard(context,'🪙','Coins','$coins',const RechargePage())),const SizedBox(width:10),Expanded(child:_walletCard(context,'💎','Diamonds','$diamonds',const DiamondWithdrawalPage()))]),const SizedBox(height:12),
    _creatorCard(context),const SizedBox(height:16),
    const Text('Creator & Social',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:9),
    _menuGrid(context,[['🎮','Games',const GameCenterPage()],['🎁','Gifts',const GiftsPage()],['🎥','Go Live',const HostPage()],['🏆','Ranking',const RankingPage()],['👥','Friends',const FriendsPage()],['❤️','Followers',const FollowersPage()],['➕','Following',const FollowingPage()],['👀','Visitors',const VisitorsPage()]]),const SizedBox(height:16),
    const Text('Support',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:9),
    _support(context),const SizedBox(height:12),const Center(child:Text('WikaLive • Your space, your story',style:TextStyle(color:Color(0xFFAAA6B4),fontSize:11,fontWeight:FontWeight.w600)))
  ])));});}
  Widget _icon(IconData i,VoidCallback t)=>InkWell(onTap:t,borderRadius:BorderRadius.circular(15),child:Container(width:44,height:44,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),child:Icon(i)));
  Widget _tag(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(10)),child:Text(t,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w800)));
  Widget _stats(BuildContext context,String uid)=>Container(padding:const EdgeInsets.symmetric(vertical:15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(21)),child:Row(children:[_count(context,uid,'friends','Friends',const FriendsPage()),_line(),_count(context,uid,'following','Following',const FollowingPage()),_line(),_count(context,uid,'followers','Followers',const FollowersPage()),_line(),_count(context,uid,'visitors','Visitors',const VisitorsPage())]));
  Widget _count(BuildContext c,String uid,String sub,String label,Widget page)=>Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').doc(uid).collection(sub).snapshots(),builder:(c,s)=>InkWell(onTap:()=>openPage(c,page),child:Column(children:[Text('${s.data?.size??0}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(label,style:const TextStyle(fontSize:10,color:Colors.black45,fontWeight:FontWeight.w700))]))));
  Widget _line()=>Container(width:1,height:30,color:const Color(0xFFEDEAF1));
  Widget _walletCard(BuildContext c,String emoji,String title,String value,Widget page)=>InkWell(onTap:()=>openPage(c,page),borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),boxShadow:const[BoxShadow(color:Color(0x0C000000),blurRadius:12)]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(emoji,style:const TextStyle(fontSize:25)),const SizedBox(height:6),Text(title,style:const TextStyle(color:Colors.black45,fontSize:11,fontWeight:FontWeight.w700)),Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:7),Text(title=='Coins'?'Recharge':'Withdraw',style:const TextStyle(color:Color(0xFF9B55E8),fontSize:11,fontWeight:FontWeight.w900))])));
  Widget _creatorCard(BuildContext context) {
    return InkWell(
      onTap: () => openPage(context, const HostPage()),
      borderRadius: BorderRadius.circular(21),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF1E4FF), Colors.white]),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: const Color(0xFFE1C7FF), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.videocam_rounded, color: Color(0xFF7A42A9), size: 27),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Become a Creator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('Go live, build followers and earn Diamonds.', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          const Icon(Icons.chevron_right_rounded),
        ]),
      ),
    );
  }
  Widget _menuGrid(BuildContext c,List<List<dynamic>> items)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:items.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,childAspectRatio:.9,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(c,i)=>InkWell(onTap:()=>openPage(c,items[i][2] as Widget),borderRadius:BorderRadius.circular(17),child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(items[i][0] as String,style:const TextStyle(fontSize:25)),const SizedBox(height:7),Text(items[i][1] as String,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800))]))));
  Widget _support(BuildContext c)=>Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(children:[menu(c,'Customer Service',Icons.headset_mic_rounded,const FeaturePage(title:'Customer Service',icon:'🎧',items:['Contact support','Account help','Report a problem'])),menu(c,'Help & Feedback',Icons.help_outline_rounded,const FeaturePage(title:'Help & Feedback',icon:'💬',items:['FAQ','Send feedback','Report content']))]));
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
    final u=FirebaseAuth.instance.currentUser;
    if(u==null)return const Scaffold(body:Center(child:Text('Please login again')));
    return Scaffold(
      appBar:AppBar(title:const Text('Profile'),actions:[IconButton(onPressed:()=>openPage(context,const EditProfilePage()),icon:const Icon(Icons.edit_rounded))]),
      body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
        stream:FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),
        builder:(context,snap){
          final d=snap.data?.data()??{};
          final raw=d['photos'];
          final photos=raw is List?raw.map((e)=>e.toString()).where((e)=>e.isNotEmpty).take(5).toList():<String>[];
          if(photos.isEmpty && (d['photoUrl']??'').toString().isNotEmpty)photos.add(d['photoUrl'].toString());
          return ListView(children:[
            SizedBox(height:280,child:photos.isEmpty?Container(color:soft,child:const Icon(Icons.person,size:100)):PageView.builder(itemCount:photos.length,itemBuilder:(c,i)=>Image.network(photos[i],fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:soft,child:const Icon(Icons.person,size:100))))),
            Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text((d['name']??u.displayName??'WikaLive User').toString(),style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),
              const SizedBox(height:7),Text((d['bio']??'').toString(),style:const TextStyle(color:Colors.black54)),
              const SizedBox(height:16),Wrap(spacing:8,runSpacing:8,children:[_info('Gender',d['gender']),_info('Birthday',d['birthday']),_info('Tag',d['tag']),_info('Language',d['language']),_info('Country',d['country'])]),
              const SizedBox(height:22),Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>openPage(context,const FollowingPage()),icon:const Icon(Icons.person_add_alt_1),label:const Text('Following'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:()=>openPage(context,const FollowersPage()),icon:const Icon(Icons.people_alt_outlined),label:const Text('Followers')))])
            ]))
          ]);
        },
      ),
    );
  }
  Widget _info(String a,d)=>d==null||'$d'.isEmpty?const SizedBox.shrink():Chip(label:Text('$a: $d'));
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
  final types = const ['Live', 'Sender', 'Party', 'Game'];
  final periods = const ['Hourly', 'Daily', 'Weekly'];

  String get field {
    switch (type) {
      case 'Sender': return 'giftSent';
      case 'Party': return 'partyGiftReceived';
      case 'Game': return 'gameSpent';
      default: return 'giftReceived';
    }
  }

  Color get accent => type == 'Game' ? const Color(0xFF3E5BFF) : const Color(0xFFFFB52E);

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
                          x == 'Live' ? '💗 Live' : x == 'Sender' ? '💰 Sender' : x == 'Party' ? '🏠 Party' : '🎮 Game',
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


int _gameInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Future<void> _finishGame({
  required int stake,
  required int reward,
  required String gameType,
  required String result,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final safeReward = reward < 0 ? 0 : reward;
  final db = FirebaseFirestore.instance;
  final userRef = db.collection('users').doc(uid);

  await db.runTransaction((tx) async {
    final snap = await tx.get(userRef);
    final data = snap.data() ?? <String, dynamic>{};
    final coins = _gameInt(data['coins']);

    tx.set(
      userRef,
      {
        'coins': coins + safeReward,
        'gameWon': FieldValue.increment(safeReward),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    tx.set(
      db.collection('game_events').doc(),
      {
        'uid': uid,
        'gameType': gameType,
        'stake': stake,
        'reward': safeReward,
        'result': result,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  });
}

abstract class _GameBaseState<T extends StatefulWidget> extends State<T> {
  bool busy = false;
  String result = '';

  Future<bool> start(int stake, String gameType) async {
    if (busy || stake < 0 || gameType.isEmpty) return false;
    setState(() {
      busy = true;
      result = '';
    });
    // WikaLive games are free-to-start. The legacy stake value is not charged.
    return true;
  }

  Future<void> finish(
    int stake,
    int reward,
    String gameType,
    String message,
  ) async {
    try {
      await _finishGame(
        stake: 0,
        reward: reward,
        gameType: gameType,
        result: message,
      );

      if (mounted) {
        setState(() {
          result = message;
          busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          result = 'Game result could not be saved.';
        });
        msg(context, 'Could not save game result');
      }
    }
  }
}

class GameCenterPage extends StatelessWidget {
  const GameCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0914),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Game Center', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Game history',
            onPressed: () => openPage(context, const GameHistoryPage()),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Gift Coins',
            onPressed: () => openPage(context, const CoinGiftPage()),
            icon: const Icon(Icons.card_giftcard_rounded),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _gameUserStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final coins = _gameInt(data['coins']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
            children: [
              _gameHero(context, coins),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2D1741), Color(0xFF17101F)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x55FFD76A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_open_rounded, color: Color(0xFFFFD76A), size: 21),
                    SizedBox(width: 10),
                    Expanded(child: Text('FREE PLAY', style: TextStyle(color: Color(0xFFFFD76A), fontWeight: FontWeight.w900, letterSpacing: 1))),
                    Text('No entry Coins', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Text('ALL GAMES', style: TextStyle(color: Color(0xFFFFD76A), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
                  TextButton.icon(
                    onPressed: () => openPage(context, const GameHistoryPage()),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('History'),
                  ),
                ],
              ),
              _gameTile(context, 'Lucky Spin', 'Spin the wheel for Coin rewards', '🎡', const Color(0xFFE94FA8), 50, const LuckySpinPage()),
              _gameTile(context, 'Roulette', 'Choose a color and spin the wheel', '🎰', const Color(0xFF9B59FF), 100, const RoulettePage()),
              _gameTile(context, 'Greedy', 'Open a treasure chest for Coins', '💎', const Color(0xFF16B9C7), 100, const GreedyChestPage()),
              _gameTile(context, 'Lucky Box', 'Choose a mystery box', '🎁', const Color(0xFFFF9F43), 200, const LuckyBoxPage()),
              _gameTile(context, 'Slot Machine', 'Match symbols on three reels', '🎰', const Color(0xFFFF5C7A), 100, const SlotMachinePage()),
              _gameTile(context, 'Dice', 'Roll three dice and match results', '🎲', const Color(0xFF4DA6FF), 100, const DiceGamePage()),
              _gameTile(context, 'Card Flip', 'Pick a card and reveal the reward', '🃏', const Color(0xFF8D7BFF), 150, const CardFlipPage()),
              _gameTile(context, 'Lucky Draw', 'Pick a number from the draw', '🎯', const Color(0xFF36D399), 100, const LuckyDrawPage()),
              _gameTile(context, 'Number Rush', 'Predict high or low', '🔢', const Color(0xFFFFC857), 75, const NumberRushPage()),
              _gameTile(context, 'Treasure Wheel', 'Premium multi-reward wheel', '👑', const Color(0xFFFFB52E), 250, const TreasureWheelPage()),
              const SizedBox(height: 10),
              _gameNote(),
            ],
          );
        },
      ),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _gameUserStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Widget _gameHero(BuildContext context, int coins) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A1E67), Color(0xFF171022), Color(0xFF0F0B18)]),
          border: Border.all(color: const Color(0x55FFD76A)),
          boxShadow: const [BoxShadow(color: Color(0x551E0B2E), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(children: [
              Container(width: 62, height: 62, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE28A), Color(0xFFFF9F43)])), child: const Center(child: Text('🪙', style: TextStyle(fontSize: 32)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('MY COINS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const SizedBox(height: 3), Text('$coins', style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900)), const Text('Free games • Win • Gift', style: TextStyle(color: Colors.white60, fontSize: 11))])),
            ]),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => openPage(context, const RechargePage()), icon: const Icon(Icons.add_circle_outline), label: const Text('Recharge'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: () => openPage(context, const CoinGiftPage()), icon: const Icon(Icons.card_giftcard_rounded), label: const Text('Gift Coins'))),
            ]),
          ],
        ),
      );

  Widget _gameTile(BuildContext context, String title, String subtitle, String emoji, Color accent, int entry, Widget page) => Container(
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(color: const Color(0xFF18121F), borderRadius: BorderRadius.circular(21), border: Border.all(color: accent.withAlpha(60))),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: () => openPage(context, page),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [accent, accent.withAlpha(100)]), boxShadow: [BoxShadow(color: accent.withAlpha(55), blurRadius: 15)]), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 31)))),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.25)), const SizedBox(height: 7), Text('FREE PLAY • WIN COINS', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900))])),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 26),
            ]),
          ),
        ),
      );

  Widget _gameNote() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF17111F), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0x33FFFFFF))),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, color: Color(0xFFFFD76A), size: 20), SizedBox(width: 10), Expanded(child: Text('WikaLive games are free to start. No Coins are charged as an entry fee. Any rewards are virtual Coins that stay inside the app and can be used for supported in-app gifting and features; they are not cash.', style: TextStyle(color: Colors.white60, height: 1.35, fontSize: 12)))]),
      );
}

class SlotMachinePage extends StatefulWidget {
  const SlotMachinePage({super.key});
  @override State<SlotMachinePage> createState() => _SlotMachinePageState();
}
class _SlotMachinePageState extends _GameBaseState<SlotMachinePage> {
  final Random rng = Random();
  final symbols = const ['🍒', '🍋', '⭐', '💎', '7️⃣'];
  List<String> reels = const ['🍒', '🍋', '⭐'];
  Future<void> play() async {
    if (!await start(100, 'Slot Machine')) return;
    setState(() => reels = List.generate(3, (_) => symbols[rng.nextInt(symbols.length)]));
    await Future.delayed(const Duration(milliseconds: 800));
    final same = reels[0] == reels[1] && reels[1] == reels[2];
    final pair = reels[0] == reels[1] || reels[1] == reels[2] || reels[0] == reels[2];
    final reward = same ? 700 : (pair ? 220 : 0);
    await finish(100, reward, 'Slot Machine', 'Reels ${reels.join(' ')} • Reward $reward Coins');
  }
  @override Widget build(BuildContext context) => _simpleGame(context, 'Slot Machine', '🎰', reels.join('  '), 100, play, result, busy);
}

class DiceGamePage extends StatefulWidget {
  const DiceGamePage({super.key});
  @override State<DiceGamePage> createState() => _DiceGamePageState();
}
class _DiceGamePageState extends _GameBaseState<DiceGamePage> {
  final Random rng = Random();
  List<int> dice = const [1, 1, 1];
  Future<void> roll() async {
    if (!await start(100, 'Dice')) return;
    setState(() => dice = List.generate(3, (_) => rng.nextInt(6) + 1));
    await Future.delayed(const Duration(milliseconds: 650));
    final sum = dice.reduce((a, b) => a + b);
    final triple = dice[0] == dice[1] && dice[1] == dice[2];
    final reward = triple ? 600 : (sum >= 14 ? 250 : (sum >= 10 ? 120 : 0));
    await finish(100, reward, 'Dice', 'Dice ${dice.join('-')} • Sum $sum • Reward $reward Coins');
  }
  @override Widget build(BuildContext context) => _simpleGame(context, 'Dice', '🎲', dice.join('   '), 100, roll, result, busy);
}

class CardFlipPage extends StatefulWidget {
  const CardFlipPage({super.key});
  @override State<CardFlipPage> createState() => _CardFlipPageState();
}
class _CardFlipPageState extends _GameBaseState<CardFlipPage> {
  final Random rng = Random();
  int selected = -1;
  String card = '❓';
  Future<void> pick(int index) async {
    if (busy) return;
    setState(() { selected = index; card = '✨'; });
    if (!await start(150, 'Card Flip')) return;
    await Future.delayed(const Duration(milliseconds: 650));
    final rewards = [0, 100, 200, 450, 900];
    final reward = rewards[rng.nextInt(rewards.length)];
    setState(() => card = reward == 0 ? '💔' : '💰');
    await finish(150, reward, 'Card Flip', 'Card ${index + 1} • Reward $reward Coins');
  }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF100B18), appBar: AppBar(backgroundColor: const Color(0xFF100B18), foregroundColor: Colors.white, title: const Text('Card Flip')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('Pick one card', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 18), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 5, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05), itemBuilder: (_, i) => InkWell(onTap: busy ? null : () => pick(i), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF5B247A), Color(0xFF1B1230)]), border: Border.all(color: selected == i ? const Color(0xFFFFD76A) : const Color(0x33444444), width: 2)), child: Center(child: Text(selected == i ? card : '🃏', style: const TextStyle(fontSize: 48))))),), const SizedBox(height: 20), if (result.isNotEmpty) Text(result, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD76A), fontWeight: FontWeight.w800))]));
}

class LuckyDrawPage extends StatefulWidget {
  const LuckyDrawPage({super.key});
  @override State<LuckyDrawPage> createState() => _LuckyDrawPageState();
}
class _LuckyDrawPageState extends _GameBaseState<LuckyDrawPage> {
  final Random rng = Random();
  int selected = 1;
  int drawn = 0;
  Future<void> draw() async {
    if (!await start(100, 'Lucky Draw')) return;
    setState(() => drawn = rng.nextInt(9) + 1);
    await Future.delayed(const Duration(milliseconds: 600));
    final reward = drawn == selected ? 700 : (drawn % 2 == selected % 2 ? 100 : 0);
    await finish(100, reward, 'Lucky Draw', 'Number $drawn • Reward $reward Coins');
  }
  @override Widget build(BuildContext context) => _simpleGame(context, 'Lucky Draw', '🎯', 'Pick $selected  •  Draw $drawn', 100, draw, result, busy, child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: List.generate(9, (i) => ChoiceChip(label: Text('${i + 1}'), selected: selected == i + 1, onSelected: busy ? null : (_) => setState(() => selected = i + 1)))));
}

class NumberRushPage extends StatefulWidget {
  const NumberRushPage({super.key});
  @override State<NumberRushPage> createState() => _NumberRushPageState();
}
class _NumberRushPageState extends _GameBaseState<NumberRushPage> {
  final Random rng = Random();
  String choice = 'HIGH';
  int number = 0;
  Future<void> play() async {
    if (!await start(75, 'Number Rush')) return;
    setState(() => number = rng.nextInt(100) + 1);
    await Future.delayed(const Duration(milliseconds: 550));
    final won = choice == 'HIGH' ? number >= 51 : number <= 50;
    final reward = won ? 140 : 0;
    await finish(75, reward, 'Number Rush', '$number • $choice • Reward $reward Coins');
  }
  @override Widget build(BuildContext context) => _simpleGame(context, 'Number Rush', '🔢', number == 0 ? '50 is the line' : 'Number $number', 75, play, result, busy, child: Row(children: [Expanded(child: ChoiceChip(label: const Text('LOW'), selected: choice == 'LOW', onSelected: busy ? null : (_) => setState(() => choice = 'LOW'))), const SizedBox(width: 10), Expanded(child: ChoiceChip(label: const Text('HIGH'), selected: choice == 'HIGH', onSelected: busy ? null : (_) => setState(() => choice = 'HIGH')))]));
}

class TreasureWheelPage extends StatefulWidget {
  const TreasureWheelPage({super.key});
  @override State<TreasureWheelPage> createState() => _TreasureWheelPageState();
}
class _TreasureWheelPageState extends _GameBaseState<TreasureWheelPage> {
  final Random rng = Random();
  double angle = 0;
  Future<void> spin() async {
    if (!await start(250, 'Treasure Wheel')) return;
    final rewards = [0, 100, 250, 400, 700, 1200];
    final index = rng.nextInt(rewards.length);
    final reward = rewards[index];
    setState(() => angle += pi * 10 + index * (2 * pi / rewards.length));
    await Future.delayed(const Duration(milliseconds: 1600));
    await finish(250, reward, 'Treasure Wheel', 'Wheel reward $reward Coins');
  }
  @override Widget build(BuildContext context) => _gameScaffold(context, 'Treasure Wheel', '👑', 250, angle, spin, result, busy);
}

Widget _simpleGame(BuildContext context, String title, String emoji, String center, int stake, VoidCallback action, String result, bool busy, {Widget? child}) => Scaffold(
  backgroundColor: const Color(0xFF100B18),
  appBar: AppBar(backgroundColor: const Color(0xFF100B18), foregroundColor: Colors.white, centerTitle: true, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
  body: ListView(padding: const EdgeInsets.all(20), children: [
    const SizedBox(height: 18),
    Container(height: 220, decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF48205D), Color(0xFF151020)]), border: Border.all(color: Color(0x44FFD76A))), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 65)), const SizedBox(height: 12), Text(center, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))]))),
    const SizedBox(height: 20),
    if (child != null) ...[child, const SizedBox(height: 18)],
    SizedBox(height: 54, child: FilledButton.icon(onPressed: busy ? null : action, icon: const Icon(Icons.play_arrow_rounded), label: Text(busy ? 'PLAYING...' : 'PLAY • $stake COINS'))),
    const SizedBox(height: 18),
    if (result.isNotEmpty) Text(result, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD76A), fontSize: 14, fontWeight: FontWeight.w800)),
  ]),
);

class CoinGiftPage extends StatefulWidget {
  const CoinGiftPage({super.key});
  @override State<CoinGiftPage> createState() => _CoinGiftPageState();
}
class _CoinGiftPageState extends State<CoinGiftPage> {
  final uidController = TextEditingController();
  final amountController = TextEditingController(text: '100');
  bool loading = false;
  Future<void> send() async {
    final from = FirebaseAuth.instance.currentUser?.uid;
    final to = uidController.text.trim();
    final amount = int.tryParse(amountController.text.trim()) ?? 0;
    if (from == null || to.isEmpty || amount <= 0 || from == to) { msg(context, 'Enter a valid recipient UID and amount'); return; }
    setState(() => loading = true);
    try {
      final db = FirebaseFirestore.instance;
      final sender = db.collection('users').doc(from);
      final receiver = db.collection('users').doc(to);
      await db.runTransaction((tx) async {
        final s = await tx.get(sender);
        final r = await tx.get(receiver);
        if (!r.exists) throw StateError('RECIPIENT_NOT_FOUND');
        final sc = _gameInt(s.data()?['coins']);
        if (sc < amount) throw StateError('INSUFFICIENT_COINS');
        tx.update(sender, {'coins': sc - amount, 'updatedAt': FieldValue.serverTimestamp()});
        tx.set(receiver, {'coins': _gameInt(r.data()?['coins']) + amount, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        tx.set(db.collection('coin_gifts').doc(), {'fromUid': from, 'toUid': to, 'amount': amount, 'source': 'game_winnings', 'createdAt': FieldValue.serverTimestamp()});
      });
      if (mounted) { msg(context, '$amount Coins gifted successfully'); Navigator.pop(context); }
    } catch (e) {
      if (mounted) msg(context, e.toString().contains('RECIPIENT_NOT_FOUND') ? 'Recipient not found' : e.toString().contains('INSUFFICIENT_COINS') ? 'Not enough Coins' : 'Gift failed');
    } finally { if (mounted) setState(() => loading = false); }
  }
  @override void dispose() { uidController.dispose(); amountController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF100B18), appBar: AppBar(backgroundColor: const Color(0xFF100B18), foregroundColor: Colors.white, title: const Text('Gift Coins')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('Send Coins to another WikaLive ID', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 20), TextField(controller: uidController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Recipient UID', filled: true)), const SizedBox(height: 14), TextField(controller: amountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Coins', filled: true)), const SizedBox(height: 22), SizedBox(height: 54, child: FilledButton.icon(onPressed: loading ? null : send, icon: const Icon(Icons.card_giftcard_rounded), label: Text(loading ? 'SENDING...' : 'SEND COINS')))]));
}

class LuckySpinPage extends StatefulWidget { const LuckySpinPage({super.key}); @override State<LuckySpinPage> createState() => _LuckySpinPageState(); }
class _LuckySpinPageState extends _GameBaseState<LuckySpinPage> {
  double angle = 0;
  final Random rng = Random();
  Future<void> spin() async {
    if (!await start(50, 'Lucky Spin')) return;
    final rewards = [0, 25, 50, 75, 100, 150, 250, 500];
    final reward = rewards[rng.nextInt(rewards.length)];
    final index = rewards.indexOf(reward);
    setState(() => angle += pi * 8 + (index * 2 * pi / rewards.length));
    await Future.delayed(const Duration(milliseconds: 1600));
    await finish(50, reward, 'Lucky Spin', 'Spin reward: $reward Coins');
  }
  @override Widget build(BuildContext context) => _gameScaffold(context, 'Lucky Spin', '🎡', 50, angle, spin, result, busy);
}

class RoulettePage extends StatefulWidget { const RoulettePage({super.key}); @override State<RoulettePage> createState() => _RoulettePageState(); }
class _RoulettePageState extends _GameBaseState<RoulettePage> {
  final Random rng = Random();
  String picked = 'RED';
  String landed = '—';
  Future<void> play() async {
    if (!await start(100, 'Roulette')) return;
    const outcomes = ['RED', 'BLACK', 'GREEN'];
    landed = outcomes[rng.nextInt(outcomes.length)];
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 900));
    final reward = landed == 'GREEN' ? 500 : (landed == picked ? 180 : 0);
    await finish(100, reward, 'Roulette', 'Landed $landed • Reward $reward');
  }
  @override Widget build(BuildContext context) => _rouletteScaffold(context, picked, landed, busy, (v) => setState(() => picked = v), play, result);
}

class GreedyChestPage extends StatefulWidget { const GreedyChestPage({super.key}); @override State<GreedyChestPage> createState() => _GreedyChestPageState(); }
class _GreedyChestPageState extends _GameBaseState<GreedyChestPage> {
  final Random rng = Random();
  Future<void> openChest() async {
    if (!await start(100, 'Greedy Chest')) return;
    final rewards = [0, 50, 100, 150, 250, 500];
    final reward = rewards[rng.nextInt(rewards.length)];
    await Future.delayed(const Duration(milliseconds: 700));
    await finish(100, reward, 'Greedy Chest', 'Chest reward: $reward Coins');
  }
  @override Widget build(BuildContext context) => _chestScaffold(context, 'Greedy Chest', '💎', 100, openChest, result, busy);
}

class LuckyBoxPage extends StatefulWidget { const LuckyBoxPage({super.key}); @override State<LuckyBoxPage> createState() => _LuckyBoxPageState(); }
class _LuckyBoxPageState extends _GameBaseState<LuckyBoxPage> {
  final Random rng = Random();
  int selected = -1;
  Future<void> choose(int box) async {
    if (busy) return;
    setState(() => selected = box);
    if (!await start(200, 'Lucky Box')) return;
    final rewards = [0, 100, 200, 350, 800];
    final reward = rewards[rng.nextInt(rewards.length)];
    await Future.delayed(const Duration(milliseconds: 650));
    await finish(200, reward, 'Lucky Box', 'Box ${box + 1} reward: $reward Coins');
  }
  @override Widget build(BuildContext context) => _boxScaffold(context, selected, busy, choose, result);
}

Widget _gameScaffold(BuildContext context, String title, String emoji, int stake, double angle, VoidCallback action, String result, bool busy) => Scaffold(
  backgroundColor: const Color(0xFF100B18), appBar: AppBar(backgroundColor: const Color(0xFF100B18), foregroundColor: Colors.white, centerTitle: true, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
  body: ListView(padding: const EdgeInsets.all(20), children: [
    const SizedBox(height: 20),
    Center(child: Stack(alignment: Alignment.topCenter, children: [
      Padding(padding: const EdgeInsets.only(top: 12), child: AnimatedRotation(turns: angle / (2 * pi), duration: const Duration(milliseconds: 1500), curve: Curves.easeOutCubic, child: Container(width: 260, height: 260, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Color(0xFFFF4D9D), Color(0xFF8E4DFF), Color(0xFFFFC857), Color(0xFF15C9C2), Color(0xFFFF4D9D)]), boxShadow: [BoxShadow(color: Color(0x66FF4D9D), blurRadius: 30)]), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 76)))))),
      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 42),
    ])),
    const SizedBox(height: 30),
    const Center(child: Text('FREE TO PLAY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))),
    const SizedBox(height: 16),
    FilledButton(onPressed: busy ? null : action, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: const Color(0xFFFF4D9D)), child: Text(busy ? 'SPINNING…' : 'SPIN NOW', style: const TextStyle(fontWeight: FontWeight.w900))),
    if (result.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 18), child: Center(child: Text(result, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD76A), fontSize: 17, fontWeight: FontWeight.w900)))),
  ]),
);

Widget _rouletteScaffold(
  BuildContext context,
  String picked,
  String landed,
  bool busy,
  ValueChanged<String> select,
  VoidCallback play,
  String result,
) {
  return Scaffold(
    backgroundColor: const Color(0xFF100B18),
    appBar: AppBar(
      backgroundColor: const Color(0xFF100B18),
      foregroundColor: Colors.white,
      centerTitle: true,
      title: const Text('Roulette Wheel', style: TextStyle(fontWeight: FontWeight.w900)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Container(
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [Color(0xFFE53E55), Color(0xFF111111), Color(0xFFE53E55), Color(0xFF111111), Color(0xFFE0B23F)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x554F35FF), blurRadius: 30)],
          ),
          child: Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF24162F)),
              child: Center(child: Text(landed, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Center(child: Text('Choose your color', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))),
        const SizedBox(height: 12),
        Row(
          children: ['RED', 'BLACK'].map((x) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: OutlinedButton(
                  onPressed: busy ? null : () => select(x),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: picked == x ? const Color(0xFFFFD76A) : Colors.white24),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(x),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : play,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: const Color(0xFF9B59FF)),
          child: Text(busy ? 'SPINNING…' : 'PLAY • 100 COINS', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        if (result.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Center(child: Text(result, style: const TextStyle(color: Color(0xFFFFD76A), fontWeight: FontWeight.w900))),
          ),
      ],
    ),
  );
}

Widget _chestScaffold(
  BuildContext context,
  String title,
  String emoji,
  int stake,
  VoidCallback action,
  String result,
  bool busy,
) {
  return Scaffold(
    backgroundColor: const Color(0xFF100B18),
    appBar: AppBar(
      backgroundColor: const Color(0xFF100B18),
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(scale: busy ? 1.12 : 1, duration: const Duration(milliseconds: 300), child: Text(emoji, style: const TextStyle(fontSize: 110))),
            const SizedBox(height: 24),
            const Text('A surprise reward is waiting', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Virtual Coins only', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : action,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: const Color(0xFF16B9C7)),
                child: Text(busy ? 'OPENING…' : 'OPEN • $stake COINS', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            if (result.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(result, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD76A), fontSize: 17, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _boxScaffold(
  BuildContext context,
  int selected,
  bool busy,
  Future<void> Function(int) choose,
  String result,
) {
  return Scaffold(
    backgroundColor: const Color(0xFF100B18),
    appBar: AppBar(
      backgroundColor: const Color(0xFF100B18),
      foregroundColor: Colors.white,
      centerTitle: true,
      title: const Text('Lucky Box', style: TextStyle(fontWeight: FontWeight.w900)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 25),
        const Center(child: Text('Pick one mystery box', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))),
        const SizedBox(height: 30),
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: InkWell(
                  onTap: busy ? null : () => choose(i),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selected == i
                            ? [const Color(0xFFFFC857), const Color(0xFFFF8C42)]
                            : [const Color(0xFF5C2A79), const Color(0xFF25152F)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: Text('🎁', style: TextStyle(fontSize: 54))),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('Free to play', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700))),
        if (result.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(child: Text(result, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD76A), fontSize: 17, fontWeight: FontWeight.w900))),
          ),
      ],
    ),
  );
}

class GameHistoryPage extends StatelessWidget {
  const GameHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login again')));
    }

    final stream = FirebaseFirestore.instance
        .collection('game_events')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Game History')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Game history unavailable. If Firestore asks for an index, create the suggested index.\n\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text('No games played yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = snap.data!.docs[i].data();
              final reward = _gameInt(d['reward']);
              return ListTile(
                tileColor: card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const CircleAvatar(child: Text('🎮')),
                title: Text('${d['gameType'] ?? 'Game'}'),
                subtitle: Text('Free play • ${d['result'] ?? ''}'),
                trailing: Text(
                  '+$reward',
                  style: TextStyle(
                    color: reward > 0 ? Colors.green : Colors.white54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
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
