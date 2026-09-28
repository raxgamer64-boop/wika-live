import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kPink = Color(0xFFFF3B81);
const kPurple = Color(0xFF8D4DFF);
const kDark = Color(0xFF090910);
const kPanel = Color(0xFF14141E);
const kPanel2 = Color(0xFF1B1B27);
const kMuted = Color(0xFF9292A3);
const kGold = Color(0xFFFFD36A);
const kCyan = Color(0xFF73D8FF);

Color a(Color c, double v) => c.withValues(alpha: v);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: kDark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const WikaLiveApp());
}

class WikaLiveApp extends StatelessWidget {
  const WikaLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WikaLive',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDark,
        colorScheme: ColorScheme.fromSeed(seedColor: kPink, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(
          backgroundColor: kDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const LiveHomePage(),
      const PartyPage(),
      const MomentsPage(),
      const InboxPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: _BottomBar(
        selected: tab,
        onChanged: (v) => setState(() => tab = v),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _BottomBar({required this.selected, required this.onChanged});

  static const labels = ['Live', 'Party', 'Moments', 'Message', 'Me'];
  static const icons = [
    Icons.live_tv_outlined,
    Icons.mic_none_rounded,
    Icons.play_circle_outline_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: a(const Color(0xFF111119), .98),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .04))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = selected == i;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: active ? 72 : 48,
                        height: 38,
                        decoration: BoxDecoration(
                          color: active ? a(kPink, .20) : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          icons[i],
                          size: 25,
                          color: active ? const Color(0xFFFFD8E6) : const Color(0xFFD8C9D1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          color: active ? const Color(0xFFFFE7F0) : const Color(0xFFD4C8D0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class LiveHomePage extends StatefulWidget {
  const LiveHomePage({super.key});
  @override State<LiveHomePage> createState() => _LiveHomePageState();
}

class _LiveHomePageState extends State<LiveHomePage> {
  int selected = 1;
  final tabs = ['Follow', 'Popular', 'New', 'Beauty', 'Nearby'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _homeHeader(context)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 27),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => selected = i),
                    child: Center(
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: selected == i ? FontWeight.w800 : FontWeight.w600,
                          color: selected == i ? Colors.white : kMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _homeBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 110),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .70,
                ),
                itemCount: 10,
                itemBuilder: (_, i) => _liveCard(context, i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _homeHeader(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 10, 7),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [kPink, kPurple]),
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 28),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('WikaLive', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        ),
        IconButton(
          onPressed: () => _push(context, const SearchPage()),
          icon: const Icon(Icons.search_rounded, size: 29),
        ),
        IconButton(
          onPressed: () => _push(context, const RechargePage()),
          icon: const Icon(Icons.diamond_outlined, size: 29, color: Color(0xFFEAD8E1)),
        ),
      ],
    ),
  );
}

Widget _homeBanner() {
  return Container(
    height: 158,
    margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      image: const DecorationImage(image: AssetImage('assets/bg_home.png'), fit: BoxFit.cover),
    ),
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a(kPurple, .25), a(kDark, .90)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('LIVE NOW', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70)),
          SizedBox(height: 5),
          Text('Meet creators live', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          SizedBox(height: 9),
          _DarkPill(text: 'Discover  •  Follow  •  Connect'),
        ],
      ),
    ),
  );
}

class _DarkPill extends StatelessWidget {
  final String text;
  const _DarkPill({required this.text});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    decoration: BoxDecoration(color: a(Colors.black, .62), borderRadius: BorderRadius.circular(22)),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
  );
}

Widget _liveCard(BuildContext context, int i) {
  const names = ['Maya Live', 'Jerry World', 'Ayesha', 'Riya Star', 'Nora Live', 'Mimi Star', 'Zoya', 'Anaya', 'Sana Live', 'Luna'];
  final images = [
    'assets/bg_live_hot_tai.png',
    'assets/bg_live_location.png',
    'assets/bg_live_hot_tai.png',
    'assets/bg_live_location.png',
  ];
  return GestureDetector(
    onTap: () => _push(context, LiveRoomPage(index: i)),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: a(Colors.white, .06)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(images[i % images.length], fit: BoxFit.cover)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [.02, .58, 1],
                  colors: [a(Colors.black, .05), a(Colors.black, .05), a(Colors.black, .92)],
                ),
              ),
            ),
          ),
          Positioned(top: 10, left: 10, child: _Tag('LIVE', kPink)),
          Positioned(top: 10, right: 10, child: _Tag('${120 + i * 37}', Colors.black87)),
          Positioned(
            left: 11, right: 11, bottom: 11,
            child: Row(
              children: [
                _avatar(39),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(names[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      const Text('Live room', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_rounded, color: kPink, size: 21),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  final String text; final Color color;
  const _Tag(this.text, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: a(color, .90), borderRadius: BorderRadius.circular(18)),
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
  );
}

Widget _avatar(double size) => Container(
  width: size, height: size,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white.withValues(alpha: .55), width: 1.3),
    image: const DecorationImage(image: AssetImage('assets/default_circle_head.webp'), fit: BoxFit.cover),
  ),
);

class PartyPage extends StatelessWidget {
  const PartyPage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _pageHeader(context, 'Party', Icons.search_rounded)),
            SliverToBoxAdapter(child: _partyBanner()),
            SliverToBoxAdapter(child: _chipTabs(['Popular', 'New', 'Follow', 'Nearby'])),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(13, 14, 13, 110),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 11, crossAxisSpacing: 11, childAspectRatio: 1.05,
                ),
                itemCount: 8,
                itemBuilder: (_, i) => _partyCard(context, i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _partyBanner() => Container(
  height: 145, margin: const EdgeInsets.fromLTRB(13, 5, 13, 5),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    gradient: const LinearGradient(colors: [Color(0xFF31133B), Color(0xFF15121E)]),
  ),
  child: Stack(children: [
    Positioned(right: -20, top: -30, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: a(kPink,.12)))),
    const Positioned(left: 19, top: 22, child: Text('PARTY', style: TextStyle(color: kPink, fontWeight: FontWeight.w900, letterSpacing: 2))),
    const Positioned(left: 19, top: 49, child: Text('Talk • Meet • Connect', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
    const Positioned(left: 19, bottom: 18, child: _DarkPill(text: 'Join a room')),
    Positioned(right: 28, bottom: 23, child: Icon(Icons.mic_external_on_rounded, size: 65, color: a(kPink,.7))),
  ]),
);

Widget _partyCard(BuildContext context, int i) {
  const rooms = ['Friends Night', 'Music Lounge', 'India Talk', 'Chill Zone', 'Love Cafe', 'Fun House', 'Late Night', 'New Friends'];
  return GestureDetector(
    onTap: () => _push(context, PartyRoomPage(roomIndex: i)),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: a(Colors.white,.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(colors: [a(kPurple,.35), a(kPink,.14)]),
            ),
            child: Stack(children: [
              Positioned(left: 13, top: 12, child: _avatar(48)),
              Positioned(left: 50, top: 37, child: _avatar(42)),
              Positioned(right: 12, top: 12, child: _Tag('${4 + i} seats', Colors.black87)),
              const Positioned(right: 12, bottom: 10, child: Icon(Icons.mic_rounded, color: kPink)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(rooms[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text('${120 + i * 31} online', style: const TextStyle(color: kMuted, fontSize: 11)),
      ]),
    ),
  );
}

class MomentsPage extends StatelessWidget {
  const MomentsPage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _pageHeader(context, 'Moments', Icons.camera_alt_outlined)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
              sliver: SliverList.builder(
                itemCount: 7,
                itemBuilder: (_, i) => _momentCard(context, i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _momentCard(BuildContext context, int i) {
  const names = ['Maya Live', 'Jerry World', 'Ayesha', 'Riya Star', 'Nora Live', 'Zoya', 'Sana'];
  return Container(
    margin: const EdgeInsets.only(bottom: 13),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [_avatar(44), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(names[i], style: const TextStyle(fontWeight: FontWeight.w900)), const Text('2h ago', style: TextStyle(color: kMuted, fontSize: 11)),
      ])), const Icon(Icons.more_horiz)]),
      const SizedBox(height: 10),
      Text(i.isEven ? 'Good vibes only ✨ Come join my live room tonight.' : 'A little moment from WikaLive 💕', style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: AspectRatio(
          aspectRatio: 1.28,
          child: Image.asset(i.isEven ? 'assets/bg_home.png' : 'assets/bg_live_location.png', fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        _action(Icons.favorite_border_rounded, '${320 + i * 51}'),
        _action(Icons.chat_bubble_outline_rounded, '${18 + i}'),
        _action(Icons.share_outlined, 'Share'),
      ]),
    ]),
  );
}

Widget _action(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(right: 20),
  child: Row(children: [Icon(icon, size: 20, color: const Color(0xFFE9DDE3)), const SizedBox(width: 5), Text(text, style: const TextStyle(color: kMuted, fontSize: 12))]),
);

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override Widget build(BuildContext context) {
    const names = ['Maya Live', 'Jerry World', 'Ayesha', 'Riya Star', 'Nora', 'Mimi'];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _pageHeader(context, 'Message', Icons.search_rounded)),
            SliverToBoxAdapter(child: _chipTabs(['Friends', 'Messages', 'System'])),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 110),
              sliver: SliverList.builder(
                itemCount: 12,
                itemBuilder: (_, i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  leading: Stack(children: [_avatar(54), Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: kDark, width: 2))))]),
                  title: Text(names[i % names.length], style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(i.isEven ? 'Tap to open chat' : 'Sent you a message', style: const TextStyle(color: kMuted)),
                  trailing: const Text('Now', style: TextStyle(color: kMuted, fontSize: 11)),
                  onTap: () => _push(context, ChatPage(name: names[i % names.length])),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String name;
  const ChatPage({super.key, this.name = 'Maya Live'});
  @override State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final c = TextEditingController();
  final messages = <String>['Hello 👋', 'Welcome to WikaLive', 'How are you?'];
  @override void dispose() { c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [_avatar(36), const SizedBox(width: 9), Text(widget.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))])),
    body: Column(children: [
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(14), itemCount: messages.length, itemBuilder: (_, i) => Align(
        alignment: i.isOdd ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: i.isOdd ? kPink : kPanel2, borderRadius: BorderRadius.circular(18)),
          child: Text(messages[i])),
      ))),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(10, 6, 10, 10), child: Row(children: [
        Expanded(child: TextField(controller: c, decoration: InputDecoration(hintText: 'Message', filled: true, fillColor: kPanel2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)))),
        const SizedBox(width: 8),
        IconButton(onPressed: () { if (c.text.trim().isNotEmpty) { setState(() { messages.add(c.text.trim()); c.clear(); }); } }, style: IconButton.styleFrom(backgroundColor: kPink), icon: const Icon(Icons.send_rounded)),
      ]))),
    ]),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override Widget build(BuildContext context) {
    final items = [
      _Service('Recharge', Icons.diamond_outlined, const RechargePage()),
      _Service('Withdraw', Icons.account_balance_wallet_outlined, const WithdrawPage()),
      _Service('Backpack', Icons.backpack_outlined, const BackpackPage()),
      _Service('Dress Store', Icons.auto_awesome_outlined, const DressStorePage()),
      _Service('Followers', Icons.people_outline_rounded, const PeoplePage(title: 'Followers')),
      _Service('Visitors', Icons.visibility_outlined, const PeoplePage(title: 'Visitors')),
      _Service('Guardian', Icons.shield_outlined, const GuardianPage()),
      _Service('Ranking', Icons.emoji_events_outlined, const RankingPage()),
      _Service('Host Center', Icons.live_tv_outlined, const HostCenterPage()),
      _Service('My Level', Icons.workspace_premium_outlined, const LevelPage()),
      _Service('VIP / SVIP', Icons.diamond_rounded, const VipPage()),
      _Service('Language', Icons.language_rounded, const LanguagePage()),
      _Service('Help & Feedback', Icons.help_outline_rounded, const HelpPage()),
      _Service('Settings', Icons.settings_outlined, const SettingsPage()),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _profileHeader(context)),
          SliverToBoxAdapter(child: _profileStats()),
          SliverToBoxAdapter(child: _sectionTitle('My services')),
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 2),
              leading: Icon(items[i].icon, color: kPink, size: 26),
              title: Text(items[i].title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFDCCDD5)),
              onTap: () => _push(context, items[i].page),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 105)),
        ]),
      ),
    );
  }
}

class _Service {
  final String title; final IconData icon; final Widget page;
  const _Service(this.title, this.icon, this.page);
}

Widget _profileHeader(BuildContext context) => Container(
  padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF281135), kDark])),
  child: Column(children: [
    Row(children: [
      _avatar(82),
      const SizedBox(width: 15),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Wika User', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        SizedBox(height: 3), Text('ID: 1000230', style: TextStyle(color: kMuted, fontSize: 16)),
        SizedBox(height: 7), Text('Live creator • India', style: TextStyle(color: Colors.white70)),
      ])),
      IconButton(onPressed: () => _push(context, const EditProfilePage()), icon: const Icon(Icons.edit_outlined, size: 25)),
    ]),
    const SizedBox(height: 20),
    Row(children: [_profileMetric('1.2K', 'Followers'), _profileMetric('320', 'Following'), _profileMetric('5.8K', 'Visitors')]),
  ]),
);

Widget _profileMetric(String value, String title) => Expanded(child: Column(children: [
  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
  const SizedBox(height: 3), Text(title, style: const TextStyle(color: kMuted)),
]));

Widget _profileStats() => Padding(
  padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
  child: Row(children: [
    _statBox('0', 'Diamonds'), const SizedBox(width: 10),
    _statBox('32', 'Level'), const SizedBox(width: 10),
    _statBox('0', 'SVIP'),
  ]),
);
Widget _statBox(String value, String title) => Expanded(child: Container(
  padding: const EdgeInsets.symmetric(vertical: 17),
  decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(18)),
  child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(title, style: const TextStyle(color: kMuted))]),
));

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override State<EditProfilePage> createState() => _EditProfilePageState();
}
class _EditProfilePageState extends State<EditProfilePage> {
  String gender = 'Not selected'; String language = 'English';
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Save'))]),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 30), children: [
      Center(child: Stack(children: [_avatar(104), Positioned(bottom: 0, right: 0, child: Container(width: 34, height: 34, decoration: const BoxDecoration(color: kPink, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 18)))])),
      const SizedBox(height: 25),
      _editRow(context, 'Name', 'Wika User', Icons.person_outline),
      _editRow(context, 'Bio', 'Live, connect and share moments.', Icons.edit_note_outlined),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.male_outlined, color: kPink), title: const Text('Gender'), subtitle: Text(gender), trailing: const Icon(Icons.chevron_right), onTap: () async { final v = await _choice(context, 'Gender', ['Male','Female','Other','Not selected']); if (v != null) setState(() => gender = v); }),
      _editRow(context, 'Birthday', 'Select birthday', Icons.cake_outlined),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.language, color: kPink), title: const Text('Language'), subtitle: Text(language), trailing: const Icon(Icons.chevron_right), onTap: () async { final v = await _choice(context, 'Language', ['English','Hindi','Bangla','Urdu']); if (v != null) setState(() => language = v); }),
      _editRow(context, 'Tags', 'Creator • Music • Chat', Icons.sell_outlined),
      _editRow(context, 'Country', 'India', Icons.public),
    ]),
  );
}

Widget _editRow(BuildContext context, String title, String value, IconData icon) => ListTile(
  contentPadding: EdgeInsets.zero, leading: Icon(icon, color: kPink), title: Text(title, style: const TextStyle(color: kMuted, fontSize: 12)), subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right),
  onTap: () {},
);

Future<String?> _choice(BuildContext context, String title, List<String> values) => showModalBottomSheet<String>(
  context: context, backgroundColor: kPanel, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [Padding(padding: const EdgeInsets.all(18), child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), ...values.map((v) => ListTile(title: Text(v), onTap: () => Navigator.pop(context, v))), const SizedBox(height: 10)])),
);

class RechargePage extends StatelessWidget {
  const RechargePage({super.key});
  @override Widget build(BuildContext context) {
    const diamonds = [100,550,1200,2500,5500,12000,25000,50000];
    const prices = [99,499,999,1999,3999,7999,14999,29999];
    return Scaffold(
      appBar: AppBar(title: const Text('Recharge'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.receipt_long_outlined))]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(height: 112, padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), image: const DecorationImage(image: AssetImage('assets/bg_mine_diamond.png'), fit: BoxFit.cover)), child: const Row(children: [
          Icon(Icons.diamond_rounded, size: 45, color: kCyan), SizedBox(width: 13),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('My Diamonds', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 2), Text('0', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))]),
        ])),
        const SizedBox(height: 20),
        const Text('Recharge', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 11),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: diamonds.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.28),
          itemBuilder: (_, i) => Container(decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(19), border: Border.all(color: i == 2 ? kPink : Colors.white10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.diamond_rounded, color: kCyan, size: 35), const SizedBox(height: 7), Text('${diamonds[i]}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 3), Text('₹${prices[i]}', style: const TextStyle(color: kPink, fontWeight: FontWeight.w800)),
          ])),
        ),
      ]),
    );
  }
}

class WithdrawPage extends StatelessWidget {
  const WithdrawPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diamond Withdrawal')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF321342), Color(0xFF171321)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Available Diamonds', style: TextStyle(color: Colors.white70)), SizedBox(height: 5), Text('0 💎', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)), SizedBox(height: 10), Text('Withdrawal is calculated from eligible diamond earnings.', style: TextStyle(color: kMuted)),
      ])),
      const SizedBox(height: 16),
      _formTile('Withdrawal method', 'Select payout method', Icons.account_balance_outlined),
      _formTile('Amount', 'Enter diamonds', Icons.diamond_outlined),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: kPink, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))), child: const Text('Withdraw Diamonds', style: TextStyle(fontWeight: FontWeight.w800))),
    ]),
  );
}

Widget _formTile(String title, String value, IconData icon) => Container(
  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15),
  decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(17)),
  child: Row(children: [Icon(icon, color: kPink), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: kMuted)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))])), const Icon(Icons.chevron_right)]),
);

class BackpackPage extends StatelessWidget {
  const BackpackPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backpack')),
    body: Column(children: [
      _chipTabs(['All', 'Frames', 'Entry', 'Vehicle', 'Gifts']),
      Expanded(child: GridView.builder(padding: const EdgeInsets.all(14), itemCount: 20, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: .78), itemBuilder: (_, i) => Column(children: [
        Container(height: 68, decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(17), border: Border.all(color: i < 5 ? a(kPink,.4) : Colors.white10)), child: const Center(child: Icon(Icons.card_giftcard_rounded, color: kPink, size: 29))),
        const SizedBox(height: 5), Text(i < 5 ? 'SVIP ${i + 1}' : 'Gift ${i + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      ]))),
    ]),
  );
}

class DressStorePage extends StatelessWidget {
  const DressStorePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dress Store')),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      const Text('Avatar Frames', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 18, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 11, crossAxisSpacing: 11, childAspectRatio: .90),
        itemBuilder: (_, i) => Container(decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(19), border: Border.all(color: i == 7 ? kPink : Colors.white10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: i < 4 ? const Color(0xFFE4C8A6) : kPink, width: 3), boxShadow: [BoxShadow(color: a(kPurple,.35), blurRadius: 12)]), child: Padding(padding: const EdgeInsets.all(5), child: _avatar(58))),
          const SizedBox(height: 7), Text('SVIP ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(i < 4 ? 'Free' : '${i * 1000} 💎', style: const TextStyle(color: kMuted, fontSize: 10)),
        ])),
      ),
      const SizedBox(height: 20), const Text('Other dress-up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 10),
      ...['Entry effects','Vehicle','Chat bubble','Profile card'].map((e) => _formTile(e, 'View items', Icons.auto_awesome_outlined)),
    ]),
  );
}

class GuardianPage extends StatelessWidget {
  const GuardianPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guardian')),
    body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Container(height: 245, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg_guard_rank_top.webp'), fit: BoxFit.cover)), child: const Center(child: Icon(Icons.shield_rounded, color: kGold, size: 90)))),
      SliverToBoxAdapter(child: _sectionTitle('Guardian ranking')),
      SliverList.builder(itemCount: 12, itemBuilder: (_, i) => ListTile(
        leading: Stack(children: [_avatar(50), Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 10, backgroundColor: kPink, child: Text('${i+1}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900))))]),
        title: Text('Guardian ${i+1}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${12000 - i * 470} diamonds support'),
        trailing: Text('#${i+1}', style: const TextStyle(color: kPink, fontWeight: FontWeight.w900)),
      )),
    ]),
  );
}

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ranking')),
    body: Column(children: [
      _chipTabs(['Daily', 'Weekly', 'Monthly', 'Rich']),
      Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12, 5, 12, 20), itemCount: 20, itemBuilder: (_, i) => Card(
        color: kPanel, elevation: 0, child: ListTile(
          leading: Stack(children: [_avatar(51), Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 10, backgroundColor: i < 3 ? kGold : kPink, child: Text('${i+1}', style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.w900))))]),
          title: Text('Wika User ${i+1}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${(20-i)*1250} diamonds sent'),
          trailing: const Icon(Icons.chevron_right),
        ),
      ))),
    ]),
  );
}

class HostCenterPage extends StatelessWidget {
  const HostCenterPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Host Center')),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(23), gradient: const LinearGradient(colors: [Color(0xFF3A1244), Color(0xFF15121C)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Host Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Grow your live room and track your earnings.', style: TextStyle(color: kMuted)),
      ])),
      const SizedBox(height: 15),
      Row(children: [_metricCard('Live time', '12h 32m'), const SizedBox(width: 10), _metricCard('Fans', '1.2K')]),
      const SizedBox(height: 10),
      Row(children: [_metricCard('Received', '38.5K 💎'), const SizedBox(width: 10), _metricCard('Level', '32')]),
      const SizedBox(height: 18),
      ...['Today tasks','Weekly target','Live records','Income records','Host rules'].map((e) => _formTile(e, 'Open', Icons.chevron_right_rounded)),
    ]),
  );
}
Widget _metricCard(String a1, String a2) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a1, style: const TextStyle(color: kMuted, fontSize: 12)), const SizedBox(height: 5), Text(a2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))])));

class LevelPage extends StatelessWidget {
  const LevelPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Level')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF35153E), Color(0xFF15121D)])), child: const Column(children: [Text('Lv.32', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)), SizedBox(height: 7), Text('Support / activity level', style: TextStyle(color: kMuted)), SizedBox(height: 18), LinearProgressIndicator(value: .72, minHeight: 8, borderRadius: BorderRadius.all(Radius.circular(8)), color: kPink, backgroundColor: Colors.white12), SizedBox(height: 10), Align(alignment: Alignment.centerRight, child: Text('7,200 / 10,000 XP', style: TextStyle(color: kMuted)))])),
      const SizedBox(height: 20), const Text('Level privileges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 10),
      ...['Profile badge','Chat badge','Entry effect','Exclusive frame','Ranking privilege'].map((e) => _formTile(e, 'Unlocked', Icons.workspace_premium_outlined)),
    ]),
  );
}

class VipPage extends StatelessWidget {
  const VipPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('VIP / SVIP')),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF4B164D), Color(0xFF15111A)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SVIP 0', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Unlock premium frames, effects and privileges.', style: TextStyle(color: kMuted))])),
      const SizedBox(height: 18),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 18, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.05), itemBuilder: (_, i) => Container(decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('SVIP ${i+1}', style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(i < 4 ? 'Basic' : 'Premium', style: const TextStyle(color: kMuted, fontSize: 10))]))),
    ]),
  );
}

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Language')), body: ListView(children: ['English','Hindi','Bangla','Urdu','Arabic','Indonesian'].map((e) => ListTile(title: Text(e), trailing: e == 'English' ? const Icon(Icons.check, color: kPink) : null, onTap: () => Navigator.pop(context))).toList()));
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Help & Feedback')), body: ListView(children: ['FAQ','Report a problem','Account help','Live room help','Payment help','Contact customer service'].map((e) => ListTile(title: Text(e), trailing: const Icon(Icons.chevron_right))).toList()));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(children: [
      _settingsGroup('Account', ['Account & security','Edit profile','Switch account']),
      _settingsGroup('Privacy', ['Privacy','Blocked users','Who can message me']),
      _settingsGroup('Notifications', ['Push notifications','Live notifications','Message notifications']),
      _settingsGroup('General', ['Language','Clear cache','About WikaLive','Terms & policies']),
      _settingsGroup('Account actions', ['Delete account','Log out']),
    ]),
  );
}
Widget _settingsGroup(String title, List<String> entries) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 6), child: Text(title, style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w800))),
  ...entries.map((e) => ListTile(title: Text(e), trailing: const Icon(Icons.chevron_right_rounded), onTap: () {})),
]);

class PeoplePage extends StatelessWidget {
  final String title;
  const PeoplePage({super.key, required this.title});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 6), itemCount: 20, itemBuilder: (_, i) => ListTile(
      leading: _avatar(50), title: Text('Wika ID ${1000200+i}', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(i.isEven ? 'Online now' : 'Last seen 2h ago', style: const TextStyle(color: kMuted)),
      trailing: i.isEven ? OutlinedButton(onPressed: () {}, child: const Text('Follow')) : null,
    )),
  );
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const TextField(autofocus: true, decoration: InputDecoration(hintText: 'Search ID, name or room', border: InputBorder.none))),
    body: ListView.builder(padding: const EdgeInsets.all(10), itemCount: 12, itemBuilder: (_, i) => ListTile(
      leading: _avatar(50), title: Text('Wika ID ${100100+i}', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(i.isEven ? 'Live creator' : 'Party room', style: const TextStyle(color: kMuted)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _push(context, i.isEven ? LiveRoomPage(index: i) : PartyRoomPage(roomIndex: i)),
    )),
  );
}

class CountryPage extends StatelessWidget {
  const CountryPage({super.key});
  @override Widget build(BuildContext context) {
    const countries = ['India','Bangladesh','Nepal','Pakistan','UAE','Indonesia','Thailand','Malaysia','Philippines','USA','UK','Canada'];
    return Scaffold(appBar: AppBar(title: const Text('Country')), body: GridView.builder(padding: const EdgeInsets.all(14), itemCount: countries.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10), itemBuilder: (_, i) => Container(decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(18)), child: Center(child: Text(countries[i], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))))));
  }
}

class BeautyPage extends StatelessWidget {
  const BeautyPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Beauty')),
    body: Column(children: [
      Expanded(child: Container(margin: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), image: const DecorationImage(image: AssetImage('assets/bg_live_location.png'), fit: BoxFit.cover)), child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 75, color: Colors.white)))),
      Container(padding: const EdgeInsets.fromLTRB(16, 4, 16, 20), child: Column(children: const [
        _BeautySlider('Smooth'), _BeautySlider('Whitening'), _BeautySlider('Face'), _BeautySlider('Eyes'), _BeautySlider('Makeup'),
      ])),
    ]),
  );
}
class _BeautySlider extends StatelessWidget {
  final String title; const _BeautySlider(this.title);
  @override Widget build(BuildContext context) => Row(children: [SizedBox(width: 85, child: Text(title)), const Expanded(child: Slider(value: .62, onChanged: null))]);
}

class LiveRoomPage extends StatefulWidget {
  final int index; const LiveRoomPage({super.key, this.index = 0});
  @override State<LiveRoomPage> createState() => _LiveRoomPageState();
}
class _LiveRoomPageState extends State<LiveRoomPage> {
  final chat = TextEditingController();
  bool mic = true; bool followed = false;
  @override void dispose() { chat.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(children: [
      Positioned.fill(child: Image.asset(widget.index.isEven ? 'assets/bg_live_location.png' : 'assets/bg_live_hot_tai.png', fit: BoxFit.cover)),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a(Colors.black,.42), Colors.transparent, a(Colors.black,.92)])))),
      SafeArea(child: Stack(children: [
        Positioned(top: 8, left: 10, right: 10, child: Row(children: [
          Expanded(child: _hostIdentity()),
          _roomButton(Icons.share_outlined, () {}),
          _roomButton(Icons.card_giftcard_rounded, () => _sheet(context, const GiftSheet())),
          _roomButton(Icons.more_horiz_rounded, () => _sheet(context, const RoomMoreSheet())),
        ])),
        Positioned(top: 76, left: 0, right: 0, child: Center(child: GestureDetector(onTap: () => _push(context, const GuardianPage()), child: Container(width: 82, height: 82, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [kGold, kPurple, Colors.transparent]), boxShadow: [BoxShadow(color: a(kPurple,.65), blurRadius: 25)]), child: const Icon(Icons.shield_rounded, size: 44))))),
        Positioned(left: 10, top: 145, child: Column(children: [
          _roomButton(Icons.cameraswitch_outlined, () {}),
          _roomButton(mic ? Icons.mic_rounded : Icons.mic_off_rounded, () => setState(() => mic = !mic)),
          _roomButton(Icons.auto_awesome_rounded, () => _sheet(context, const BeautySheet())),
        ])),
        Positioned(top: 122, right: 10, child: _roomButton(followed ? Icons.favorite_rounded : Icons.favorite_border_rounded, () => setState(() => followed = !followed), pink: true)),
        Positioned(left: 12, right: 12, bottom: 82, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _supportStrip(), const SizedBox(height: 6),
          _chatPill('Welcome to the live room'),
          _chatPill('Jerry World joined the room'),
          _chatPill('A gift was sent 💎'),
        ])),
        Positioned(left: 12, right: 12, bottom: 15, child: Row(children: [
          Expanded(child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: a(Colors.black,.60), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white12)), child: TextField(controller: chat, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Say something…', hintStyle: TextStyle(color: Colors.white60), border: InputBorder.none)))),
          _roomButton(Icons.card_giftcard_rounded, () => _sheet(context, const GiftSheet())),
          _roomButton(Icons.people_alt_outlined, () => _sheet(context, const ViewersSheet())),
          _roomButton(Icons.emoji_events_outlined, () => _push(context, const RankingPage())),
        ])),
      ])),
    ]),
  );

  Widget _hostIdentity() => Container(
    padding: const EdgeInsets.all(6), margin: const EdgeInsets.only(right: 4),
    decoration: BoxDecoration(color: a(Colors.black,.62), borderRadius: BorderRadius.circular(29), border: Border.all(color: Colors.white12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _avatar(42), const SizedBox(width: 8),
      const Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('jerry ki duniya', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        Text('● Online  •  Lv.32', style: TextStyle(fontSize: 9, color: Colors.greenAccent)),
      ])),
      const SizedBox(width: 6), const Icon(Icons.verified_rounded, color: kGold, size: 18),
    ]),
  );

  Widget _supportStrip() => SizedBox(height: 47, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 8, separatorBuilder: (_, __) => const SizedBox(width: 5), itemBuilder: (_, i) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: a(Colors.black,.55), borderRadius: BorderRadius.circular(24)), child: Row(children: [_avatar(30), const SizedBox(width: 5), Text('${(i+1)*240} 💎', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))])));)

  Widget _chatPill(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: a(Colors.black,.47), borderRadius: BorderRadius.circular(14)), child: Text(text, style: const TextStyle(fontSize: 11))));
}

Widget _roomButton(IconData icon, VoidCallback onTap, {bool pink = false}) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 3),
  child: GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: a(Colors.black,.55), shape: BoxShape.circle, border: Border.all(color: Colors.white12)), child: Icon(icon, size: 20, color: pink ? kPink : Colors.white))),
);

class PartyRoomPage extends StatefulWidget {
  final int roomIndex; const PartyRoomPage({super.key, this.roomIndex = 0});
  @override State<PartyRoomPage> createState() => _PartyRoomPageState();
}
class _PartyRoomPageState extends State<PartyRoomPage> {
  int selectedSeat = -1;
  bool mic = false;
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF110E18),
    body: Stack(children: [
      Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A1239), Color(0xFF0D0D14)])))),
      SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 8, 8, 4), child: Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(child: Row(children: [_avatar(39), const SizedBox(width: 8), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Friends Night', style: TextStyle(fontWeight: FontWeight.w900)), Text('ID: 1000230 • 328 online', style: TextStyle(fontSize: 10, color: kMuted))])])),
          _roomButton(Icons.share_outlined, () {}),
          _roomButton(Icons.more_horiz, () => _sheet(context, const RoomMoreSheet())),
        ])),
        Container(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), decoration: BoxDecoration(color: a(Colors.black,.32), borderRadius: BorderRadius.circular(18)), child: const Row(children: [Icon(Icons.campaign_outlined, color: kPink, size: 19), SizedBox(width: 8), Expanded(child: Text('Welcome to WikaLive Party Room • Be kind & have fun', style: TextStyle(fontSize: 11)))])),
        Expanded(child: GridView.builder(padding: const EdgeInsets.fromLTRB(13, 14, 13, 8), itemCount: 8, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 13, crossAxisSpacing: 10, childAspectRatio: .78), itemBuilder: (_, i) => _seat(context, i))),
        Container(height: 105, padding: const EdgeInsets.fromLTRB(12, 6, 12, 8), decoration: BoxDecoration(color: a(Colors.black,.35), border: const Border(top: BorderSide(color: Colors.white10)),), child: Column(children: [
          SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: const [
            _MiniMessage('Maya: Hello 👋'), SizedBox(width: 7), _MiniMessage('Jerry sent a gift 💎'), SizedBox(width: 7), _MiniMessage('Welcome!'),
          ])),
          const Spacer(),
          Row(children: [
            Expanded(child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: a(Colors.white,.08), borderRadius: BorderRadius.circular(24)), child: const Align(alignment: Alignment.centerLeft, child: Text('Say something…', style: TextStyle(color: Colors.white60, fontSize: 12))))),
            _roomButton(Icons.card_giftcard_rounded, () => _sheet(context, const GiftSheet())),
            _roomButton(mic ? Icons.mic_rounded : Icons.mic_off_rounded, () => setState(() => mic = !mic)),
            _roomButton(Icons.settings_outlined, () => _sheet(context, const PartySettingsSheet())),
          ]),
        ])),
      ])),
    ]),
  );

  Widget _seat(BuildContext context, int i) {
    final host = i == 0; final selected = selectedSeat == i;
    return GestureDetector(
      onTap: () => setState(() => selectedSeat = i),
      child: Column(children: [
        Expanded(child: Stack(alignment: Alignment.center, children: [
          Container(width: double.infinity, decoration: BoxDecoration(color: selected ? a(kPink,.18) : a(Colors.white,.055), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? kPink : Colors.white10, width: selected ? 1.5 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _avatar(57), const SizedBox(height: 5), Text(host ? 'Host' : (i < 4 ? 'Seat ${i+1}' : 'Empty'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
          ])),
          if (host) const Positioned(top: 5, child: _Tag('HOST', kPink)),
          if (!host && i > 3) const Positioned(child: Icon(Icons.add_circle_outline_rounded, color: Colors.white54, size: 24)),
        ])),
      ]),
    );
  }
}

class _MiniMessage extends StatelessWidget {
  final String text; const _MiniMessage(this.text);
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: a(Colors.white,.07), borderRadius: BorderRadius.circular(16)), child: Text(text, style: const TextStyle(fontSize: 10)));
}

class GiftSheet extends StatelessWidget {
  const GiftSheet({super.key});
  @override
  Widget build(BuildContext context) => _sheetFrame(
    context,
    'Gifts',
    Column(
      children: [
        _chipTabs(['Popular','Love','Lucky','Party']),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: 16,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: .76,
            ),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Column(
                children: [
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: a(kPink, .08),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: kPink, size: 31),
                  ),
                  const SizedBox(height: 5),
                  Text('Gift ${i+1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  Text('${(i+1)*10} 💎', style: const TextStyle(color: kMuted, fontSize: 9)),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ViewersSheet extends StatelessWidget {
  const ViewersSheet({super.key});
  @override Widget build(BuildContext context) => _sheetFrame(context, 'Viewers', ListView.builder(padding: const EdgeInsets.only(bottom: 20), itemCount: 12, itemBuilder: (_, i) => ListTile(leading: _avatar(43), title: Text('Wika ID ${1000230+i}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Online now', style: TextStyle(color: kMuted)), trailing: const Icon(Icons.person_add_alt_1, color: kPink))));
}

class RoomMoreSheet extends StatelessWidget {
  const RoomMoreSheet({super.key});
  @override Widget build(BuildContext context) => _sheetFrame(context, 'More', Column(mainAxisSize: MainAxisSize.min, children: [
    _moreAction(Icons.report_outlined, 'Report'),
    _moreAction(Icons.block_outlined, 'Block'),
    _moreAction(Icons.share_outlined, 'Share'),
    _moreAction(Icons.info_outline, 'Live information'),
    _moreAction(Icons.remove_circle_outline, 'Minimize room'),
    _moreAction(Icons.logout_rounded, 'Exit room', danger: true),
  ]));
}
Widget _moreAction(IconData icon, String title, {bool danger = false}) => ListTile(leading: Icon(icon, color: danger ? kPink : Colors.white70), title: Text(title), onTap: () {});

class BeautySheet extends StatelessWidget {
  const BeautySheet({super.key});
  @override Widget build(BuildContext context) => _sheetFrame(context, 'Beauty', const Column(children: [
    _BeautySlider('Smooth'), _BeautySlider('Whitening'), _BeautySlider('Face'), _BeautySlider('Eyes'), _BeautySlider('Makeup'),
  ]));
}

class PartySettingsSheet extends StatelessWidget {
  const PartySettingsSheet({super.key});
  @override Widget build(BuildContext context) => _sheetFrame(context, 'Party settings', Column(mainAxisSize: MainAxisSize.min, children: [
    _moreAction(Icons.mic_none_rounded, 'Mic settings'),
    _moreAction(Icons.volume_up_outlined, 'Speaker'),
    _moreAction(Icons.lock_outline, 'Room privacy'),
    _moreAction(Icons.people_outline, 'Seat management'),
  ]));
}

Widget _sheetFrame(BuildContext context, String title, Widget child) => SafeArea(child: Padding(padding: const EdgeInsets.only(top: 9), child: Column(mainAxisSize: MainAxisSize.min, children: [
  Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(9))),
  Padding(padding: const EdgeInsets.fromLTRB(16, 13, 10, 8), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))])),
  Flexible(child: child),
])));

void _sheet(BuildContext context, Widget child) => showModalBottomSheet(
  context: context, isScrollControlled: true, backgroundColor: kPanel,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
  builder: (_) => child,
);

class _chipTabs extends StatelessWidget {
  final List<String> labels; const _chipTabs(this.labels);
  @override Widget build(BuildContext context) => SizedBox(height: 46, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 14), scrollDirection: Axis.horizontal, itemCount: labels.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9), decoration: BoxDecoration(color: i == 0 ? a(kPink,.18) : kPanel, borderRadius: BorderRadius.circular(22), border: Border.all(color: i == 0 ? a(kPink,.55) : Colors.white10)), child: Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: i == 0 ? const Color(0xFFFFD7E5) : Colors.white70)))));
}

Widget _pageHeader(BuildContext context, String title, IconData actionIcon) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 14, 10, 6),
  child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900))), IconButton(onPressed: () => _push(context, const SearchPage()), icon: Icon(actionIcon, size: 26))]),
);

Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 9), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)));

void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
