import 'package:flutter/material.dart';

void main() => runApp(const WikaLiveApp());

const kPink = Color(0xFFFF3B81);
const kPurple = Color(0xFF7B42F6);
const kDeepPurple = Color(0xFF35104D);
const kDark = Color(0xFF0B0910);
const kDark2 = Color(0xFF17121D);
const kCard = Color(0xFF211A28);
const kMuted = Color(0xFF8F8897);
const kGold = Color(0xFFFFC83D);
const kGreen = Color(0xFF32D583);
const kCream = Color(0xFFFFF8EE);

Color a(Color c, double v) => c.withValues(alpha: v);

class WikaUser {
  String name;
  String id;
  String bio;
  bool followed;
  int followers;
  int visitors;
  WikaUser(this.name, this.id, {this.bio = 'Live creator • WikaLive', this.followed = false, this.followers = 1200, this.visitors = 5800});
}

class AppStore extends ChangeNotifier {
  static final AppStore instance = AppStore._();
  AppStore._();

  int diamonds = 0;
  int level = 32;
  int svip = 0;
  int sent = 0;
  int received = 0;
  bool notifications = true;
  bool floatingLive = true;
  bool privateAccount = false;
  bool onlineStatus = true;
  String language = 'English';
  String name = 'Wika User';
  String bio = 'Live creator • India';
  String gender = 'Male';
  String birthday = '2000/02/21';
  final List<String> tags = ['Creator', 'Music', 'Chat'];
  final List<WikaUser> users = [
    WikaUser('Shri Shri Roy', '1000230', followers: 83400),
    WikaUser('Maya Live', '1000231', followers: 57400),
    WikaUser('Jerry World', '1000232', followers: 36200),
    WikaUser('Ayesha', '1000233', followers: 28400),
    WikaUser('Riya Star', '1000234', followers: 19800),
    WikaUser('Anaya', '1000235', followers: 15400),
    WikaUser('Mishi Raj', '1000236', followers: 12200),
    WikaUser('Nora Live', '1000237', followers: 9600),
  ];

  void toggleFollow(int i) {
    final u = users[i % users.length];
    u.followed = !u.followed;
    u.followers += u.followed ? 1 : -1;
    notifyListeners();
  }

  void addDiamonds(int amount) {
    diamonds += amount;
    notifyListeners();
  }

  void sendGift(int price) {
    if (diamonds < price) return;
    diamonds -= price;
    sent += price;
    received += price ~/ 2;
    notifyListeners();
  }

  void saveProfile({String? newName, String? newBio, String? newGender, String? newBirthday}) {
    if (newName != null && newName.trim().isNotEmpty) name = newName.trim();
    if (newBio != null && newBio.trim().isNotEmpty) bio = newBio.trim();
    if (newGender != null) gender = newGender;
    if (newBirthday != null) birthday = newBirthday;
    notifyListeners();
  }
}

class WikaLiveApp extends StatelessWidget {
  const WikaLiveApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WikaLive',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8F7FA),
          colorScheme: ColorScheme.fromSeed(seedColor: kPink, brightness: Brightness.light),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Color(0xFF18141D)),
        ),
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  final pages = const [LivePage(), PartyPage(), MomentsPage(), InboxPage(), MePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: a(kPink, .13),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.mic_none_rounded), selectedIcon: Icon(Icons.mic_rounded), label: 'Party'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'Moments'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Message'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

class LivePage extends StatefulWidget {
  const LivePage({super.key});
  @override State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  int selected = 1;
  final tabs = const ['Follow', 'Popular', 'New', 'Beauty', 'Nearby'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _feedHeader(context)),
            SliverToBoxAdapter(child: _categoryTabs(tabs, selected, (i) => setState(() => selected = i))),
            SliverToBoxAdapter(child: _countryStrip(context)),
            SliverToBoxAdapter(child: _promoBanner()),
            SliverToBoxAdapter(child: _section('Live creators', 'See all')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .73),
                itemCount: AppStore.instance.users.length,
                itemBuilder: (_, i) => _liveCard(context, i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _feedHeader(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 10, 2),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kPink, kPurple])), child: const Icon(Icons.play_arrow_rounded, color: Colors.white)),
      const SizedBox(width: 9),
      const Expanded(child: Text('WikaLive', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
      IconButton(onPressed: () => _push(context, const SearchPage()), icon: const Icon(Icons.search_rounded)),
      IconButton(onPressed: () => _push(context, const RechargePage()), icon: const Icon(Icons.diamond_outlined, color: kPink)),
    ]),
  );
}

Widget _categoryTabs(List<String> labels, int selected, ValueChanged<int> onTap) {
  return SizedBox(
    height: 48,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14), scrollDirection: Axis.horizontal, itemCount: labels.length,
      separatorBuilder: (_, __) => const SizedBox(width: 22),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onTap(i),
        child: Center(child: Text(labels[i], style: TextStyle(fontSize: 15, fontWeight: i == selected ? FontWeight.w900 : FontWeight.w600, color: i == selected ? const Color(0xFF242029) : kMuted))),
      ),
    ),
  );
}

Widget _countryStrip(BuildContext context) {
  const flags = ['🌐', '🇮🇳', '🇧🇩', '🇳🇵', '🇵🇭', '🇮🇩'];
  return SizedBox(
    height: 40,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      scrollDirection: Axis.horizontal,
      itemCount: flags.length,
      separatorBuilder: (_, __) => const SizedBox(width: 9),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _push(context, const CountryPage()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAE5EE)),
          ),
          child: Center(child: Text(flags[i], style: const TextStyle(fontSize: 17))),
        ),
      ),
    ),
  );
}

Widget _promoBanner() {
  return Container(
    height: 92,
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: const DecorationImage(image: AssetImage('assets/bg_home.png'), fit: BoxFit.cover)),
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(colors: [a(kPurple, .78), a(const Color(0xFF150A1E), .72)])),
      padding: const EdgeInsets.all(14),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text('LUCKY BLESSING', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)), SizedBox(height: 2), Text('x1000 Bonus', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))]),
    ),
  );
}

Widget _section(String title, String action) => Padding(padding: const EdgeInsets.fromLTRB(14, 7, 14, 9), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Text(action, style: const TextStyle(color: kPink, fontWeight: FontWeight.w700))]));

Widget _liveCard(BuildContext context, int i) {
  final u = AppStore.instance.users[i % AppStore.instance.users.length];
  final backgrounds = ['assets/bg_live_hot_tai.png', 'assets/bg_live_location.png', 'assets/bg_home.png'];
  return GestureDetector(
    onTap: () => _push(context, LiveRoomPage(index: i)),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(children: [
        Positioned.fill(child: Image.asset(backgrounds[i % backgrounds.length], fit: BoxFit.cover)),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, a(Colors.black, .84)])))),
        Positioned(top: 8, left: 8, child: _tag('LIVE', kPink)),
        Positioned(top: 8, right: 8, child: _tag('${120 + i * 37}', Colors.black87)),
        Positioned(left: 10, right: 10, bottom: 10, child: Row(children: [
          _avatar(35), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), Text('${u.followers ~/ 1000}K fans', style: const TextStyle(color: Colors.white70, fontSize: 10))])),
          GestureDetector(onTap: () => AppStore.instance.toggleFollow(i), child: Icon(u.followed ? Icons.favorite : Icons.favorite_border, color: kPink, size: 22)),
        ])),
      ]),
    ),
  );
}

Widget _tag(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)));

Widget _avatar(double size) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white70, width: 1.5), image: const DecorationImage(image: AssetImage('assets/default_circle_head.webp'), fit: BoxFit.cover)));

class PartyPage extends StatelessWidget {
  const PartyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 10, 4), child: Row(children: [const Expanded(child: Text('Party', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900))), IconButton(onPressed: () => _push(context, const SearchPage()), icon: const Icon(Icons.search)), const Icon(Icons.card_giftcard, color: kPink)]))),
      SliverToBoxAdapter(child: _partyTabs()),
      SliverToBoxAdapter(child: _partyBanner()),
      SliverToBoxAdapter(child: _section('Popular rooms', 'More')),
      SliverPadding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 22), sliver: SliverGrid.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.06), itemCount: 8, itemBuilder: (_, i) => _partyCard(context, i))),
    ])));
  }
}

Widget _partyTabs() => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), child: Row(children: const [_MiniTab('Popular', true), SizedBox(width: 18), _MiniTab('PK Battle', false), SizedBox(width: 18), _MiniTab('Event', false), SizedBox(width: 18), _MiniTab('Friends', false)]));

class _MiniTab extends StatelessWidget { final String text; final bool active; const _MiniTab(this.text, this.active); @override Widget build(BuildContext context) => Text(text, style: TextStyle(color: active ? kPink : kMuted, fontWeight: active ? FontWeight.w900 : FontWeight.w600)); }

Widget _partyBanner() => Container(
  height: 92,
  margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(15),
    gradient: const LinearGradient(colors: [Color(0xFF4A1D68), Color(0xFF15101A)]),
  ),
  child: Row(
    children: [
      const SizedBox(width: 15),
      const Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PARTY ROOM', style: TextStyle(color: Colors.white70, fontSize: 11)),
            SizedBox(height: 4),
            Text('Voice • Seats • Friends', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      Container(
        width: 74,
        height: 74,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(shape: BoxShape.circle, color: a(kPink, .18)),
        child: const Icon(Icons.mic_rounded, color: kPink, size: 36),
      ),
    ],
  ),
);

Widget _partyCard(BuildContext context, int i) {
  return GestureDetector(
    onTap: () => _push(context, PartyRoomPage(index: i)),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFEAE5EE))),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.asset(i.isEven ? 'assets/bg_live_location.png' : 'assets/bg_home.png', fit: BoxFit.cover),
                  ),
                ),
                Positioned(top: 7, left: 7, child: _tag('PARTY', kPurple)),
                Positioned(bottom: 7, left: 7, child: Text('🇮🇳 ${i % 3 == 0 ? 'India' : 'Friends'}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                _avatar(29),
                const SizedBox(width: 7),
                const Expanded(child: Text("Jerry's room", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800))),
                Text('${4 + i}', style: const TextStyle(color: kMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});
  @override State<MomentsPage> createState() => _MomentsPageState();
}
class _MomentsPageState extends State<MomentsPage> {
  final liked = <int>{};
  @override Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 4), child: Row(children: [const Expanded(child: Text('Moments', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900))), IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined))]))),
      SliverList.builder(itemCount: 6, itemBuilder: (_, i) => _moment(context, i)),
    ])));
  }
  Widget _moment(BuildContext context, int i) {
    return Card(margin: const EdgeInsets.fromLTRB(10, 5, 10, 10), color: Colors.white, elevation: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.all(12), child: Row(children: [_avatar(40), const SizedBox(width: 9), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sona • Follow', style: TextStyle(fontWeight: FontWeight.w900)), Text('Just now', style: TextStyle(color: kMuted, fontSize: 11))])), const Icon(Icons.more_horiz)])), GestureDetector(onDoubleTap: () => setState(() => liked.add(i)), child: AspectRatio(aspectRatio: .9, child: Stack(children: [Positioned.fill(child: Image.asset(i.isEven ? 'assets/bg_live_hot_tai.png' : 'assets/bg_live_location.png', fit: BoxFit.cover)), if (liked.contains(i)) const Center(child: Icon(Icons.favorite, color: Colors.white, size: 90))]))), Padding(padding: const EdgeInsets.fromLTRB(12, 9, 12, 12), child: Row(children: [IconButton(onPressed: () => setState(() => liked.contains(i) ? liked.remove(i) : liked.add(i)), icon: Icon(liked.contains(i) ? Icons.favorite : Icons.favorite_border, color: liked.contains(i) ? kPink : null)), const Text('232'), const SizedBox(width: 18), const Icon(Icons.chat_bubble_outline, size: 20), const Text('47'), const SizedBox(width: 18), const Icon(Icons.share_outlined, size: 20), const Text('1')]))]));
  }
}

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override Widget build(BuildContext context) {
    final names = ['Jerry World', 'Maya Live', 'Ayesha', 'Riya Star', 'Nora', 'Mishi Raj'];
    return Scaffold(body: SafeArea(child: Column(children: [Padding(padding: const EdgeInsets.fromLTRB(14, 10, 10, 5), child: Row(children: [const Expanded(child: Text('Message', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900))), IconButton(onPressed: () => _push(context, const SearchPage()), icon: const Icon(Icons.search))])), const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Row(children: [Expanded(child: _InboxChip('Friends', true)), Expanded(child: _InboxChip('Greeting', false)), Expanded(child: _InboxChip('System', false))])), Expanded(child: ListView.builder(itemCount: 12, padding: const EdgeInsets.only(top: 8), itemBuilder: (_, i) => ListTile(leading: _avatar(50), title: Text(names[i % names.length], style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Welcome to WikaLive • Tap to chat', style: TextStyle(color: kMuted)), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Now', style: TextStyle(fontSize: 10, color: kMuted)), if (i % 3 == 0) Container(margin: const EdgeInsets.only(top: 4), width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: kPink))]), onTap: () => _push(context, ChatPage(name: names[i % names.length])))))])));
  }
}
class _InboxChip extends StatelessWidget { final String t; final bool active; const _InboxChip(this.t, this.active); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: active ? a(kPink, .12) : Colors.transparent, borderRadius: BorderRadius.circular(18)), child: Center(child: Text(t, style: TextStyle(color: active ? kPink : kMuted, fontWeight: FontWeight.w800)))); }

class ChatPage extends StatefulWidget {
  final String name;
  const ChatPage({super.key, this.name = 'Maya Live'});
  @override State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final messages = <String>['Hello 👋', 'Hi! Welcome to WikaLive', 'Send a gift and say hello 🎁'];
  @override void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(children: [_avatar(34), const SizedBox(width: 8), Text(widget.name)])),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (_, i) => Align(
                alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: i.isEven ? const Color(0xFFEFEAF2) : kPink,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(messages[i], style: TextStyle(color: i.isEven ? Colors.black87 : Colors.white)),
                ),
              ),
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
                      decoration: InputDecoration(
                        hintText: 'Say something…',
                        filled: true,
                        fillColor: const Color(0xFFF0EDF2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() {
                          messages.add(controller.text.trim());
                          controller.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.send_rounded, color: kPink),
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

class MePage extends StatelessWidget {
  const MePage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: AnimatedBuilder(animation: AppStore.instance, builder: (_, __) => ListView(padding: EdgeInsets.zero, children: [
      _meHeader(context),
      _meStats(),
      const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 8), child: Text('My services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
      _service(context, Icons.diamond_outlined, 'Recharge', 'Buy diamonds', const RechargePage()),
      _service(context, Icons.account_balance_wallet_outlined, 'Withdraw', 'Withdraw diamonds', const WithdrawalPage()),
      _service(context, Icons.backpack_outlined, 'Backpack', 'Items & frames', const BackpackPage()),
      _service(context, Icons.people_outline, 'Followers', 'See followers', const FollowersPage()),
      _service(context, Icons.visibility_outlined, 'Visitors', 'Recent visitors', const VisitorsPage()),
      _service(context, Icons.shield_outlined, 'Guardian', 'Guardian center', const GuardianPage()),
      _service(context, Icons.emoji_events_outlined, 'Ranking', 'Daily / weekly / monthly', const RankingPage()),
      _service(context, Icons.workspace_premium_outlined, 'VIP / SVIP', 'Privileges & frames', const VipPage()),
      _service(context, Icons.mic_outlined, 'Host Center', 'Creator tools', const HostCenterPage()),
      _service(context, Icons.language_outlined, 'Language', AppStore.instance.language, const LanguagePage()),
      _service(context, Icons.help_outline, 'Help & Feedback', 'Support', const HelpPage()),
      _service(context, Icons.settings_outlined, 'Settings', 'Account, privacy, notifications', const SettingsPage()),
      const SizedBox(height: 25),
    ]))));
  }
}

Widget _meHeader(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(18, 18, 18, 20), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF31103E), Color(0xFF0D0A12)])), child: Row(children: [_avatar(92), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppStore.instance.name, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), Text('ID: 1000230', style: const TextStyle(color: Colors.white70, fontSize: 16)), const SizedBox(height: 4), Text(AppStore.instance.bio, style: const TextStyle(color: Colors.white70))])), IconButton(onPressed: () => _push(context, const EditProfilePage()), icon: const Icon(Icons.edit_outlined, color: Colors.white))]));

Widget _meStats() => Padding(padding: const EdgeInsets.all(14), child: Row(children: [_stat('Followers', '1.2K'), const SizedBox(width: 9), _stat('Following', '320'), const SizedBox(width: 9), _stat('Visitors', '5.8K')]));
Widget _stat(String title, String value) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(title, style: const TextStyle(color: kMuted, fontSize: 11))])));
Widget _service(BuildContext context, IconData icon, String title, String sub, Widget page) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 1), leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: a(kPink, .1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: kPink)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(sub, style: const TextStyle(color: kMuted, fontSize: 11)), trailing: const Icon(Icons.chevron_right), onTap: () => _push(context, page));

class EditProfilePage extends StatefulWidget { const EditProfilePage({super.key}); @override State<EditProfilePage> createState() => _EditProfilePageState(); }
class _EditProfilePageState extends State<EditProfilePage> {
  late final name = TextEditingController(text: AppStore.instance.name);
  late final bio = TextEditingController(text: AppStore.instance.bio);
  String gender = AppStore.instance.gender;
  String birthday = AppStore.instance.birthday;
  @override void dispose() { name.dispose(); bio.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Edit information'), actions: [TextButton(onPressed: () { AppStore.instance.saveProfile(newName: name.text, newBio: bio.text, newGender: gender, newBirthday: birthday); Navigator.pop(context); }, child: const Text('Save'))]), body: ListView(padding: const EdgeInsets.all(16), children: [Center(child: Stack(children: [_avatar(104), Positioned(bottom: 0, right: 0, child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: kPink, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 17)))])), const SizedBox(height: 20), TextField(controller: name, decoration: const InputDecoration(labelText: 'Nickname', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12), TextField(controller: bio, maxLines: 2, decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.edit_note))), const SizedBox(height: 10), DropdownButtonFormField<String>(value: gender, decoration: const InputDecoration(labelText: 'Gender'), items: const ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => gender = v ?? gender)), ListTile(contentPadding: EdgeInsets.zero, title: const Text('Birthday'), subtitle: Text(birthday), trailing: const Icon(Icons.chevron_right), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(1970), lastDate: DateTime.now(), initialDate: DateTime(2000, 2, 21)); if (d != null) setState(() => birthday = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'); }), const Divider(), const Text('Tags', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Wrap(spacing: 7, children: AppStore.instance.tags.map((e) => Chip(label: Text(e))).toList())]));
}

class FollowersPage extends StatelessWidget { const FollowersPage({super.key}); @override Widget build(BuildContext context) => _peoplePage(context, 'Followers'); }
class VisitorsPage extends StatelessWidget { const VisitorsPage({super.key}); @override Widget build(BuildContext context) => _peoplePage(context, 'Visitors'); }
Widget _peoplePage(BuildContext context, String title) => Scaffold(appBar: AppBar(title: Text(title)), body: ListView.builder(itemCount: AppStore.instance.users.length, itemBuilder: (_, i) { final u = AppStore.instance.users[i]; return ListTile(leading: _avatar(50), title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('ID: ${u.id}'), trailing: OutlinedButton(onPressed: () => AppStore.instance.toggleFollow(i), child: Text(u.followed ? 'Following' : 'Follow'))); }));

class RechargePage extends StatelessWidget {
  const RechargePage({super.key});
  @override Widget build(BuildContext context) {
    const packs = [(3500, '₹55'), (15000, '₹220'), (40000, '₹550'), (90000, '₹1,100'), (200000, '₹2,200'), (500000, '₹5,500')];
    return Scaffold(appBar: AppBar(title: const Text('Recharge'), actions: [AnimatedBuilder(animation: AppStore.instance, builder: (_, __) => Padding(padding: const EdgeInsets.only(right: 15), child: Center(child: Text('${AppStore.instance.diamonds} 💎', style: const TextStyle(fontWeight: FontWeight.w900)))))]), body: ListView(padding: const EdgeInsets.all(14), children: [Container(height: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF4B1164), Color(0xFF1C1025)])), padding: const EdgeInsets.all(18), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('STARTER PACK', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)), SizedBox(height: 7), Text('Great Start', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)), Spacer(), Text('Bonus diamonds • VIP • EXP', style: TextStyle(color: Colors.white70))])), const SizedBox(height: 14), const Text('Diamond recharge', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 9), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55), itemCount: packs.length, itemBuilder: (_, i) => _RechargeCard(amount: packs[i].$1, price: packs[i].$2))]));
  }
}
class _RechargeCard extends StatelessWidget { final int amount; final String price; const _RechargeCard({required this.amount, required this.price}); @override Widget build(BuildContext context) => InkWell(onTap: () { AppStore.instance.addDiamonds(amount); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $amount diamonds'))); }, borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E1EB))), padding: const EdgeInsets.all(12), child: Row(children: [Container(width: 43, height: 43, decoration: BoxDecoration(color: a(kPink, .1), shape: BoxShape.circle), child: const Icon(Icons.diamond, color: kPink)), const SizedBox(width: 8), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$amount', style: const TextStyle(fontWeight: FontWeight.w900)), Text(price, style: const TextStyle(color: kPink, fontWeight: FontWeight.w900))]))]))); }

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});
  @override State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final amount = TextEditingController();
  @override void dispose() { amount.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diamond withdrawal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kDark2, borderRadius: BorderRadius.circular(20)),
            child: AnimatedBuilder(
              animation: AppStore.instance,
              builder: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available diamonds', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text('${AppStore.instance.diamonds} 💎', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diamonds to withdraw', prefixIcon: Icon(Icons.diamond_outlined))),
          const SizedBox(height: 12),
          const Text('Payout method', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const _PaymentTile(title: 'UPI', sub: 'yourname@upi', icon: Icons.account_balance),
          const _PaymentTile(title: 'Bank account', sub: 'Add bank details', icon: Icons.account_balance_wallet),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(amount.text) ?? 0;
              if (n <= 0 || n > AppStore.instance.diamonds) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid diamond amount')));
                return;
              }
              AppStore.instance.diamonds -= n;
              AppStore.instance.notifyListeners();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted')));
            },
            child: const Padding(padding: EdgeInsets.all(13), child: Text('Submit withdrawal')),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget { final String title, sub; final IconData icon; const _PaymentTile({required this.title, required this.sub, required this.icon}); @override Widget build(BuildContext context) => Card(elevation: 0, child: ListTile(leading: Icon(icon, color: kPink), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(sub, style: const TextStyle(color: kMuted)), trailing: const Radio(value: true, groupValue: true, onChanged: null))); }

class BackpackPage extends StatefulWidget {
  const BackpackPage({super.key});
  @override State<BackpackPage> createState() => _BackpackPageState();
}

class _BackpackPageState extends State<BackpackPage> {
  int selected = 0;
  final categories = ['All', 'Frame', 'Entry', 'Bubble', 'Vehicle'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backpack')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(label: Text(categories[i]), selected: selected == i, onSelected: (_) => setState(() => selected = i)),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .9),
              itemCount: 12,
              itemBuilder: (_, i) => _ItemCard(index: i, selected: i == selected, onTap: () => setState(() => selected = i)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _ItemCard({required this.index, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? kPink : const Color(0xFFE9E3EC), width: selected ? 2 : 1)),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: [a(kPurple, .25), a(kPink, .15)])), child: Icon(index % 2 == 0 ? Icons.auto_awesome : Icons.workspace_premium, color: kPink, size: 48))),
            const SizedBox(height: 8),
            Text('SVIP Frame ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(selected ? 'Equipped' : 'Tap to equip', style: TextStyle(color: selected ? kPink : kMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class GuardianPage extends StatefulWidget {
  const GuardianPage({super.key});
  @override State<GuardianPage> createState() => _GuardianPageState();
}

class _GuardianPageState extends State<GuardianPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian')),
      body: Column(
        children: [
          Container(
            height: 125,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: AssetImage('assets/bg_guard_rank_top.webp'), fit: BoxFit.cover)),
            child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield, color: Colors.white, size: 45), Text('Guardian Center', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))])),
          ),
          _categoryTabs(const ['My Guardian', 'Ranking', 'Tasks'], tab, (i) => setState(() => tab = i)),
          Expanded(child: tab == 0 ? _guardianList() : tab == 1 ? const RankingPage(guardianMode: true) : _guardianTasks()),
        ],
      ),
    );
  }
}

Widget _guardianList() => ListView.builder(
  itemCount: 8,
  itemBuilder: (_, i) => ListTile(
    leading: CircleAvatar(backgroundColor: a(kPurple, .2), child: const Icon(Icons.shield, color: kPurple)),
    title: Text('Guardian ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text('${1200 + i * 500} contribution'),
    trailing: FilledButton(onPressed: () {}, child: const Text('View')),
  ),
);

Widget _guardianTasks() => ListView(
  padding: const EdgeInsets.all(14),
  children: [
    const Text('Guardian tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    for (final t in ['Send gifts', 'Watch live', 'Follow creators', 'Complete profile'])
      Card(child: ListTile(leading: const Icon(Icons.task_alt, color: kPink), title: Text(t), subtitle: const Text('Progress 60%'), trailing: const Text('Claim'))),
  ],
);

class RankingPage extends StatefulWidget {
  final bool guardianMode;
  const RankingPage({super.key, this.guardianMode = false});
  @override State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.guardianMode ? 'Guardian Ranking' : 'Ranking')),
      body: Column(
        children: [
          _categoryTabs(const ['Daily', 'Weekly', 'Monthly'], tab, (i) => setState(() => tab = i)),
          Expanded(
            child: ListView.builder(
              itemCount: 15,
              itemBuilder: (_, i) => ListTile(
                leading: Stack(children: [
                  _avatar(52),
                  if (i < 3)
                    Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 10, backgroundColor: i == 0 ? kGold : Colors.grey, child: Text('${i + 1}', style: const TextStyle(fontSize: 9, color: Colors.white)))),
                ]),
                title: Text(i == 0 ? 'Jerry World' : 'Wika User ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${(15 - i) * 2400} diamonds'),
                trailing: Text('${(15 - i) * 2400} 💎', style: const TextStyle(color: kPink, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BeautyPage extends StatefulWidget { const BeautyPage({super.key}); @override State<BeautyPage> createState() => _BeautyPageState(); }
class _BeautyPageState extends State<BeautyPage> { double smooth = .65, bright = .45, tone = .35; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Beauty')), body: Column(children: [Expanded(child: Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), image: const DecorationImage(image: AssetImage('assets/bg_live_hot_tai.png'), fit: BoxFit.cover)), child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 60)))), Container(padding: const EdgeInsets.fromLTRB(16, 10, 16, 20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: Column(children: [_slider('Smooth', smooth, (v) => setState(() => smooth = v)), _slider('Bright', bright, (v) => setState(() => bright = v)), _slider('Tone', tone, (v) => setState(() => tone = v)), Row(children: [Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Apply'))), const SizedBox(width: 10), OutlinedButton(onPressed: () => setState(() { smooth = .65; bright = .45; tone = .35; }), child: const Text('Reset'))])]))])); }
Widget _slider(String t, double v, ValueChanged<double> on) => Row(children: [SizedBox(width: 70, child: Text(t)), Expanded(child: Slider(value: v, onChanged: on, activeColor: kPink))]);

class NearbyPage extends StatelessWidget { const NearbyPage({super.key}); @override Widget build(BuildContext context) => _creatorListPage('Nearby', 'Creators within 50 km'); }
class CountryPage extends StatelessWidget { const CountryPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Country')), body: ListView(padding: const EdgeInsets.all(12), children: const [_Country('🇮🇳', 'India'), _Country('🇧🇩', 'Bangladesh'), _Country('🇳🇵', 'Nepal'), _Country('🇵🇭', 'Philippines'), _Country('🇮🇩', 'Indonesia'), _Country('🌐', 'All countries')])); }
class _Country extends StatelessWidget { final String flag, name; const _Country(this.flag, this.name); @override Widget build(BuildContext context) => ListTile(leading: Text(flag, style: const TextStyle(fontSize: 26)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pop(context)); }
Widget _creatorListPage(String title, String sub) => Builder(builder: (context) => Scaffold(appBar: AppBar(title: Text(title)), body: ListView(padding: const EdgeInsets.all(12), children: [Padding(padding: const EdgeInsets.all(6), child: Text(sub, style: const TextStyle(color: kMuted))), for (int i = 0; i < AppStore.instance.users.length; i++) ListTile(leading: _avatar(52), title: Text(AppStore.instance.users[i].name, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('ID: ${AppStore.instance.users[i].id}'), trailing: FilledButton(onPressed: () => _push(context, LiveRoomPage(index: i)), child: const Text('Live')))])));

class VipPage extends StatelessWidget { const VipPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('VIP')), body: ListView(padding: const EdgeInsets.all(14), children: [Container(height: 180, padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFFFFD95A), Color(0xFFB66A05)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Current level', style: TextStyle(color: Colors.black54)), const SizedBox(height: 5), const Text('VIP 0', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black)), const Spacer(), Text('${AppStore.instance.diamonds}/10000 diamonds', style: const TextStyle(color: Colors.black87)), const SizedBox(height: 8), LinearProgressIndicator(value: (AppStore.instance.diamonds / 10000).clamp(0, 1).toDouble(), color: Colors.black, backgroundColor: Colors.black12)])), const SizedBox(height: 18), const Text('VIP privileges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 10), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, childAspectRatio: .8, children: List.generate(9, (i) => Column(children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: a(kGold, .17), borderRadius: BorderRadius.circular(18)), child: Icon(i % 2 == 0 ? Icons.workspace_premium : Icons.auto_awesome, color: kGold, size: 32)), const SizedBox(height: 6), Text(['VIP Special', 'Badge', 'Avatar frame', 'Mic frame', 'Followers', 'Entry effect', 'Chat bubble', 'Gift effect', 'Stay tuned'][i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))]))), const SizedBox(height: 12), FilledButton(onPressed: () => _push(context, const RechargePage()), child: const Text('Recharge to upgrade'))])); }

class HostCenterPage extends StatelessWidget { const HostCenterPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Host Center')), body: ListView(padding: const EdgeInsets.all(14), children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: kDark2, borderRadius: BorderRadius.circular(20)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Creator dashboard', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Track live time, gifts, fans and tasks', style: TextStyle(color: Colors.white70))])), const SizedBox(height: 12), Row(children: [_hostStat('Live time', '02:36'), _hostStat('Gifts', '${AppStore.instance.received}'), _hostStat('Fans', '1.2K')]), const SizedBox(height: 15), for (final e in ['Start live', 'Live data', 'Host tasks', 'Fan club', 'Income record', 'Host rules']) Card(child: ListTile(leading: const Icon(Icons.live_tv, color: kPink), title: Text(e, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right), onTap: () { if (e == 'Start live') _push(context, const LiveRoomPage(index: 0, isHost: true)); }))])); }
Widget _hostStat(String a1, String a2) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Column(children: [Text(a2, style: const TextStyle(fontWeight: FontWeight.w900)), Text(a1, style: const TextStyle(color: kMuted, fontSize: 10))])));

class LanguagePage extends StatelessWidget { const LanguagePage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Language')), body: ListView(children: ['English', 'Hindi', 'বাংলা', 'Nepali', 'Indonesian'].map((e) => ListTile(title: Text(e), trailing: AppStore.instance.language == e ? const Icon(Icons.check, color: kPink) : null, onTap: () { AppStore.instance.language = e; AppStore.instance.notifyListeners(); Navigator.pop(context); })).toList())); }
class HelpPage extends StatelessWidget { const HelpPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Help & Feedback')), body: ListView(children: const [ListTile(leading: Icon(Icons.help_outline), title: Text('FAQ')), ListTile(leading: Icon(Icons.support_agent), title: Text('Customer Service')), ListTile(leading: Icon(Icons.feedback_outlined), title: Text('Feedback')), ListTile(leading: Icon(Icons.report_problem_outlined), title: Text('Report a problem'))])); }

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(children: [
    _settingSwitch('Notifications', AppStore.instance.notifications, (v) { AppStore.instance.notifications = v; AppStore.instance.notifyListeners(); }),
    _settingSwitch('Floating live', AppStore.instance.floatingLive, (v) { AppStore.instance.floatingLive = v; AppStore.instance.notifyListeners(); }),
    _settingSwitch('Online status', AppStore.instance.onlineStatus, (v) { AppStore.instance.onlineStatus = v; AppStore.instance.notifyListeners(); }),
    _settingSwitch('Private account', AppStore.instance.privateAccount, (v) { AppStore.instance.privateAccount = v; AppStore.instance.notifyListeners(); }),
    ListTile(leading: const Icon(Icons.security), title: const Text('Account & security'), trailing: const Icon(Icons.chevron_right), onTap: () => _push(context, const SecurityPage())),
    ListTile(leading: const Icon(Icons.block), title: const Text('Blocked users'), trailing: const Icon(Icons.chevron_right), onTap: () => _push(context, const BlockedPage())),
    ListTile(leading: const Icon(Icons.language), title: const Text('Language'), subtitle: Text(AppStore.instance.language), trailing: const Icon(Icons.chevron_right), onTap: () => _push(context, const LanguagePage())),
    ListTile(leading: const Icon(Icons.info_outline), title: const Text('About WikaLive'), trailing: const Icon(Icons.chevron_right), onTap: () => _push(context, const AboutPage())),
    ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Delete account', style: TextStyle(color: Colors.red)), onTap: () => _confirm(context, 'Delete account', 'This demo action cannot be undone.')),
    ListTile(leading: const Icon(Icons.logout), title: const Text('Log out'), onTap: () => _confirm(context, 'Log out', 'You will return to the login screen.')),
  ]));
}
Widget _settingSwitch(String title, bool value, ValueChanged<bool> on) => SwitchListTile(title: Text(title), value: value, activeColor: kPink, onChanged: on);
class SecurityPage extends StatelessWidget { const SecurityPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Account & security')), body: ListView(children: const [ListTile(title: Text('Wika ID'), subtitle: Text('1000230')), ListTile(title: Text('Phone'), subtitle: Text('Not connected')), ListTile(title: Text('Email'), subtitle: Text('Not connected')), ListTile(title: Text('Password'), subtitle: Text('••••••••')), ListTile(title: Text('Login devices'), trailing: Icon(Icons.chevron_right))])); }
class BlockedPage extends StatelessWidget { const BlockedPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Blocked users')), body: const Center(child: Text('No blocked users'))); }
class AboutPage extends StatelessWidget { const AboutPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('About WikaLive')), body: const Padding(padding: EdgeInsets.all(20), child: Column(children: [Icon(Icons.play_circle, size: 70, color: kPink), SizedBox(height: 12), Text('WikaLive', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text('Version 0.1.0', style: TextStyle(color: kMuted)), SizedBox(height: 20), Text('Live, party, moments and messages in one place.')]))); }

class SearchPage extends StatefulWidget { const SearchPage({super.key}); @override State<SearchPage> createState() => _SearchPageState(); }
class _SearchPageState extends State<SearchPage> { String q = ''; @override Widget build(BuildContext context) { final list = AppStore.instance.users.where((u) => q.isEmpty || u.name.toLowerCase().contains(q.toLowerCase()) || u.id.contains(q)).toList(); return Scaffold(appBar: AppBar(title: TextField(autofocus: true, decoration: const InputDecoration(hintText: 'Search ID, name or room', border: InputBorder.none), onChanged: (v) => setState(() => q = v))), body: ListView.builder(itemCount: list.length, itemBuilder: (_, i) { final u = list[i]; final idx = AppStore.instance.users.indexOf(u); return ListTile(leading: _avatar(48), title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('ID: ${u.id} • ${u.followers} fans'), trailing: const Icon(Icons.chevron_right), onTap: () => _push(context, LiveRoomPage(index: idx < 0 ? 0 : idx))); })); } }

class LiveRoomPage extends StatefulWidget {
  final int index;
  final bool isHost;
  const LiveRoomPage({super.key, required this.index, this.isHost = false});
  @override State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  final chat = <String>['Welcome to the live room 👋', 'Jerry joined the room', 'Hello everyone ❤️'];
  final input = TextEditingController();
  int viewers = 120;
  bool mic = true;
  bool camera = true;
  @override void dispose() { input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final u = AppStore.instance.users[widget.index % AppStore.instance.users.length];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/bg_live_hot_tai.png', fit: BoxFit.cover)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black38, Colors.transparent, Colors.black.withValues(alpha: .82)])))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(28)),
                        child: Row(children: [_avatar(39), const SizedBox(width: 7), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), const Text('Lv.32 • Online', style: TextStyle(color: Colors.white70, fontSize: 9))])]),
                      ),
                      const Spacer(),
                      _roomTopButton(Icons.share_outlined, () {}),
                      _roomTopButton(Icons.card_giftcard, () => _sheet(context, const GiftSheet())),
                      _roomTopButton(Icons.more_horiz, () => _sheet(context, const RoomMoreSheet())),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    separatorBuilder: (_, __) => const SizedBox(width: 5),
                    itemBuilder: (_, i) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(22)),
                      child: Row(children: [_avatar(31), const SizedBox(width: 4), Text('${(i + 1) * 500} 💎', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))]),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 82),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * .75,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: a(kPurple, .78), borderRadius: BorderRadius.circular(14)), child: const Text('Lucky Blessing • x1000 Bonus', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                            const SizedBox(height: 7),
                            for (final m in chat.take(5)) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(m, style: const TextStyle(color: Colors.white, fontSize: 12, shadows: [Shadow(blurRadius: 3, color: Colors.black)]))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
                  child: Row(
                    children: [
                      _roomIcon(camera ? Icons.videocam : Icons.videocam_off, () => setState(() => camera = !camera)),
                      _roomIcon(mic ? Icons.mic : Icons.mic_off, () => setState(() => mic = !mic)),
                      _roomIcon(Icons.auto_awesome, () => _sheet(context, const BeautySheet())),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: TextField(
                            controller: input,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Say something…',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black45,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                              suffixIcon: IconButton(onPressed: () { if (input.text.trim().isNotEmpty) setState(() { chat.add(input.text.trim()); input.clear(); }); }, icon: const Icon(Icons.send, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                      _roomIcon(Icons.people_alt_outlined, () => _sheet(context, const ViewersSheet())),
                      _roomIcon(Icons.card_giftcard, () => _sheet(context, const GiftSheet())),
                      _roomIcon(Icons.menu, () => _sheet(context, const RoomMoreSheet())),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(top: MediaQuery.of(context).padding.top + 72, left: 10, child: Column(children: [_verticalRoomButton(Icons.cameraswitch, () => setState(() => camera = !camera)), _verticalRoomButton(Icons.shield_outlined, () => _push(context, const GuardianPage())), _verticalRoomButton(Icons.emoji_events_outlined, () => _push(context, const RankingPage()))])),
          Positioned(top: MediaQuery.of(context).padding.top + 75, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(18)), child: Row(children: [const Icon(Icons.visibility_outlined, color: Colors.white70, size: 16), const SizedBox(width: 4), Text('$viewers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]))),
        ],
      ),
    );
  }
  Widget _roomIcon(IconData icon, VoidCallback on) => IconButton(onPressed: on, icon: Icon(icon, color: Colors.white));
  Widget _verticalRoomButton(IconData icon, VoidCallback on) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(onPressed: on, icon: Icon(icon, color: Colors.white, size: 19))));
  Widget _roomTopButton(IconData icon, VoidCallback on) => IconButton(onPressed: on, icon: Icon(icon, color: Colors.white));
}

class GiftSheet extends StatelessWidget { const GiftSheet({super.key}); @override Widget build(BuildContext context) { final gifts = [('Rose', 10, Icons.local_florist), ('Heart', 50, Icons.favorite), ('Crown', 200, Icons.workspace_premium), ('Rocket', 500, Icons.rocket_launch), ('Castle', 1000, Icons.castle), ('Diamond', 5000, Icons.diamond)]; return _sheetBase(context, 'Gifts', GridView.builder(shrinkWrap: true, itemCount: gifts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: .95), itemBuilder: (_, i) { final g = gifts[i]; return InkWell(onTap: () { AppStore.instance.sendGift(g.$2); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent ${g.$1}'))); }, child: Column(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: a(kPink, .1), borderRadius: BorderRadius.circular(18)), child: Icon(g.$3, color: kPink, size: 30)), const SizedBox(height: 4), Text(g.$1, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${g.$2} 💎', style: const TextStyle(color: kMuted, fontSize: 10))])); })); } }
class ViewersSheet extends StatelessWidget { const ViewersSheet({super.key}); @override Widget build(BuildContext context) => _sheetBase(context, 'Viewers', ListView.builder(shrinkWrap: true, itemCount: 12, itemBuilder: (_, i) => ListTile(leading: _avatar(42), title: Text('Wika ID ${1002000 + i}'), subtitle: const Text('Watching now'), trailing: const Icon(Icons.favorite_border, color: kPink)))); }
class RoomMoreSheet extends StatelessWidget { const RoomMoreSheet({super.key}); @override Widget build(BuildContext context) => _sheetBase(context, 'Room', Column(mainAxisSize: MainAxisSize.min, children: [_sheetAction(context, Icons.person_add_alt_1, 'Follow host'), _sheetAction(context, Icons.shield_outlined, 'Guardian'), _sheetAction(context, Icons.emoji_events_outlined, 'Ranking'), _sheetAction(context, Icons.flag_outlined, 'Report'), _sheetAction(context, Icons.remove_circle_outline, 'Minimize'), _sheetAction(context, Icons.exit_to_app, 'Exit room', close: true)])); }
Widget _sheetAction(BuildContext context, IconData icon, String title, {bool close = false}) => ListTile(leading: Icon(icon, color: kPink), title: Text(title), onTap: () { if (close) Navigator.pop(context); });
class BeautySheet extends StatefulWidget { const BeautySheet({super.key}); @override State<BeautySheet> createState() => _BeautySheetState(); }
class _BeautySheetState extends State<BeautySheet> { double v = .5; @override Widget build(BuildContext context) => _sheetBase(context, 'Beauty', Column(mainAxisSize: MainAxisSize.min, children: [_slider('Smooth', v, (x) => setState(() => v = x)), _slider('Whiten', v, (x) => setState(() => v = x)), _slider('Face', v, (x) => setState(() => v = x)), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Apply'))])); }
Widget _slider(String title, double value, ValueChanged<double> onChanged) => Row(children: [SizedBox(width: 70, child: Text(title)), Expanded(child: Slider(value: value, onChanged: onChanged, activeColor: kPink))]);

Widget _sheetBase(BuildContext context, String title, Widget child) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)))), const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12), child])));
void _sheet(BuildContext context, Widget child) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, showDragHandle: false, builder: (_) => child);

class PartyRoomPage extends StatefulWidget {
  final int index;
  const PartyRoomPage({super.key, this.index = 0});
  @override State<PartyRoomPage> createState() => _PartyRoomPageState();
}

class _PartyRoomPageState extends State<PartyRoomPage> {
  final seats = List<bool>.filled(8, false);
  final chat = <String>['Jerry joined room', 'Hello everyone 👋', 'Welcome to the party'];
  bool mic = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1032),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(widget.index.isEven ? 'assets/bg_live_location.png' : 'assets/bg_home.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: a(const Color(0xFF130A1F), .45))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                  child: Row(children: [_avatar(45), const SizedBox(width: 7), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Jerry's room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), Text('Ranking: 31 • 27.0K', style: TextStyle(color: Colors.white70, fontSize: 10))])), _roomTop(Icons.card_giftcard, () => _sheet(context, const GiftSheet())), _roomTop(Icons.more_horiz, () => _sheet(context, const RoomMoreSheet()))]),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: a(kGold, .8), borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [Icon(Icons.emoji_events, color: Colors.black87, size: 18), SizedBox(width: 6), Expanded(child: Text('Congratulations to our top supporter!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)))]),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 25, 15, 5),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 10, childAspectRatio: .75),
                    itemCount: 8,
                    itemBuilder: (_, i) => _seat(i),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [for (final m in chat.take(5)) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(m, style: const TextStyle(color: Colors.white, fontSize: 11, shadows: [Shadow(blurRadius: 3, color: Colors.black)])))]),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
                    child: Row(children: [_partyButton(mic ? Icons.mic : Icons.mic_off, () => setState(() => mic = !mic)), Expanded(child: Container(height: 43, margin: const EdgeInsets.symmetric(horizontal: 5), padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(25)), child: const Align(alignment: Alignment.centerLeft, child: Text('Say something…', style: TextStyle(color: Colors.white70))))), _partyButton(Icons.people_alt_outlined, () => _sheet(context, const ViewersSheet())), _partyButton(Icons.card_giftcard, () => _sheet(context, const GiftSheet())), _partyButton(Icons.menu, () => _sheet(context, const RoomMoreSheet()))]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seat(int i) => GestureDetector(
    onTap: () => setState(() => seats[i] = !seats[i]),
    child: Column(
      children: [
        Stack(children: [
          Container(width: 63, height: 63, decoration: BoxDecoration(shape: BoxShape.circle, color: a(Colors.white, .12), border: Border.all(color: seats[i] ? kPink : Colors.white24, width: 2)), child: seats[i] ? _avatar(60) : const Icon(Icons.add, color: Colors.white70, size: 25)),
          if (i == 0) Positioned(top: -3, right: -3, child: Container(width: 23, height: 23, decoration: const BoxDecoration(shape: BoxShape.circle, color: kGold), child: const Icon(Icons.crown, size: 13, color: Colors.black))),
        ]),
        const SizedBox(height: 4),
        Text(i == 0 ? 'Host' : seats[i] ? 'Wika ID' : 'Join', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
        if (seats[i]) const Text('7.3K 💎', style: TextStyle(color: Colors.white70, fontSize: 8)),
      ],
    ),
  );

  Widget _partyButton(IconData icon, VoidCallback on) => IconButton(onPressed: on, icon: Icon(icon, color: Colors.white));
  Widget _roomTop(IconData icon, VoidCallback on) => IconButton(onPressed: on, icon: Icon(icon, color: Colors.white));
}

class SecurityPlaceholder extends StatelessWidget { const SecurityPlaceholder({super.key}); @override Widget build(BuildContext context) => const SizedBox.shrink(); }

void _confirm(BuildContext context, String title, String body) => showDialog(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(body), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Confirm'))]));
void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
