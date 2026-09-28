import 'package:flutter/material.dart';

void main() => runApp(const WikaLiveApp());

const kPink = Color(0xFFFF3B81);
const kPurple = Color(0xFF8D4DFF);
const kDark = Color(0xFF0B0B12);
const kCard = Color(0xFF171722);
const kMuted = Color(0xFF8D8D9A);

class WikaLiveApp extends StatelessWidget {
  const WikaLiveApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WikaLive',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: kDark),
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
  final pages = const [HomePage(), ExplorePage(), PartyPage(), InboxPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111119), indicatorColor: kPink.withOpacity(.16),
        selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'Party'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _topBar(context)),
        SliverToBoxAdapter(child: _tabs(context, ['Follow', 'Popular', 'New', 'Beauty', 'Nearby'])),
        SliverToBoxAdapter(child: _hero()),
        SliverPadding(padding: const EdgeInsets.fromLTRB(12, 14, 12, 24), sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .78),
          itemCount: 8, itemBuilder: (_, i) => _liveCard(context, i),
        )),
      ])),
    );
  }
}

Widget _topBar(BuildContext context) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
  child: Row(children: [
    Container(width: 38, height: 38, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kPink, kPurple])), child: const Icon(Icons.play_arrow_rounded, size: 24)),
    const SizedBox(width: 10), const Expanded(child: Text('WikaLive', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
    IconButton(onPressed: () => _push(context, const SearchPage()), icon: const Icon(Icons.search_rounded)),
    IconButton(onPressed: () => _push(context, const RechargePage()), icon: const Icon(Icons.diamond_outlined)),
  ]),
);

Widget _tabs(BuildContext context, List<String> labels) => SizedBox(height: 45, child: ListView.separated(
  padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: labels.length,
  separatorBuilder: (_, __) => const SizedBox(width: 20), itemBuilder: (_, i) => Center(child: Text(labels[i], style: TextStyle(fontSize: 15, fontWeight: i == 1 ? FontWeight.w800 : FontWeight.w500, color: i == 1 ? Colors.white : kMuted))),
));

Widget _hero() => Container(
  height: 150, margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: AssetImage('assets/bg_home.png'), fit: BoxFit.cover)),
  child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
    const Text('LIVE NOW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
    const SizedBox(height: 3), const Text('Meet creators live', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    const SizedBox(height: 7), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(30)), child: const Text('Discover • Follow • Connect', style: TextStyle(fontSize: 12))),
  ])),
);

Widget _liveCard(BuildContext context, int i) => GestureDetector(
  onTap: () => _push(context, LiveRoomPage(index: i)),
  child: Container(decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.05))), child: Stack(children: [
    Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset('assets/bg_live_hot_tai.png', fit: BoxFit.cover))),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(.8)])))),
    Positioned(top: 9, left: 9, child: _pill('LIVE', kPink)),
    Positioned(top: 9, right: 9, child: _pill('${120 + i * 37}', Colors.black54)),
    Positioned(left: 12, right: 12, bottom: 11, child: Row(children: [
      _avatar(34), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(['Maya Live','Jerry World','Ayesha','Riya Star','Nora','Mimi','Zoya','Anaya'][i], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const Text('Live room', style: TextStyle(color: Colors.white70, fontSize: 11))])),
      const Icon(Icons.favorite, size: 17, color: kPink),
    ])),
  ])),
);

Widget _pill(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.85), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)));
Widget _avatar(double size) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24), image: const DecorationImage(image: AssetImage('assets/default_circle_head.webp'), fit: BoxFit.cover)));

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: CustomScrollView(slivers: [
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Expanded(child: Text('Explore', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))), IconButton(onPressed: () => _push(context, const SearchPage()), icon: const Icon(Icons.search))]))),
    SliverToBoxAdapter(child: _quickGrid(context)),
    SliverToBoxAdapter(child: _sectionTitle('Top Hosts', 'View all')),
    SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 14), sliver: SliverList.builder(itemCount: 8, itemBuilder: (_, i) => _hostRow(context, i))),
  ])));
}
Widget _quickGrid(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [
  Expanded(child: _quick(context, 'Nearby', Icons.location_on_outlined, const NearbyPage())), const SizedBox(width: 10), Expanded(child: _quick(context, 'Country', Icons.public, const CountryPage())), const SizedBox(width: 10), Expanded(child: _quick(context, 'Beauty', Icons.auto_awesome, const BeautyPage())),
]));
Widget _quick(BuildContext context, String t, IconData icon, Widget page) => GestureDetector(onTap: () => _push(context, page), child: Container(padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)), child: Column(children: [Icon(icon, color: kPink, size: 27), const SizedBox(height: 8), Text(t, style: const TextStyle(fontWeight: FontWeight.w700))])));
Widget _sectionTitle(String a, String b) => Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 12), child: Row(children: [Expanded(child: Text(a, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), Text(b, style: const TextStyle(color: kMuted, fontSize: 12))]));
Widget _hostRow(BuildContext context, int i) => ListTile(onTap: () => _push(context, LiveRoomPage(index: i)), contentPadding: const EdgeInsets.symmetric(vertical: 5), leading: _avatar(52), title: Text(['Maya Live','Jerry World','Ayesha','Riya Star','Nora','Mimi','Zoya','Anaya'][i], style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${800 + i * 120} viewers • Live now', style: const TextStyle(color: kMuted)), trailing: const Icon(Icons.chevron_right));

class NearbyPage extends StatelessWidget { const NearbyPage({super.key}); @override Widget build(BuildContext context) => _simpleListPage('Nearby • 50 km', Icons.location_on, 'Hosts near you'); }
class CountryPage extends StatelessWidget { const CountryPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Country')), body: GridView.count(padding: const EdgeInsets.all(16), crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, children: ['India','Bangladesh','Nepal','Pakistan','UAE','Indonesia','Thailand','Malaysia','Philippines','USA','UK','Canada'].map((e) => Container(decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)), child: Center(child: Text(e, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)))).toList())); }
Widget _simpleListPage(String title, IconData icon, String subtitle) => Builder(builder: (context) => Scaffold(appBar: AppBar(title: Text(title)), body: ListView.builder(padding: const EdgeInsets.all(14), itemCount: 10, itemBuilder: (_, i) => Card(color: kCard, child: ListTile(onTap: () => _push(context, LiveRoomPage(index: i)), leading: CircleAvatar(backgroundColor: kPurple.withOpacity(.2), child: Icon(icon, color: kPink)), title: Text(['Maya Live','Jerry World','Ayesha','Riya Star','Nora','Mimi','Zoya','Anaya','Luna','Sana'][i]), subtitle: Text(subtitle), trailing: const Icon(Icons.play_circle_fill, color: kPink))))));

class LiveRoomPage extends StatefulWidget { final int index; const LiveRoomPage({super.key, this.index = 0}); @override State<LiveRoomPage> createState() => _LiveRoomPageState(); }
class _LiveRoomPageState extends State<LiveRoomPage> {
  final TextEditingController chat = TextEditingController();
  @override Widget build(BuildContext context) => Scaffold(body: Stack(children: [
    Positioned.fill(child: Image.asset('assets/bg_live_location.png', fit: BoxFit.cover)),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.3), Colors.transparent, Colors.black.withOpacity(.86)])))),
    SafeArea(child: Stack(children: [
      Positioned(top: 12, left: 12, child: _hostChip()),
      Positioned(top: 12, right: 8, child: Row(children: [_roomIcon(Icons.share_outlined, () {}), _roomIcon(Icons.card_giftcard, () => _sheet(context, const GiftSheet())), _roomIcon(Icons.more_horiz, () => _sheet(context, const RoomMoreSheet()))])),
      Positioned(left: 12, top: 130, child: Column(children: [_roomIcon(Icons.cameraswitch_outlined, () {}), _roomIcon(Icons.mic_none, () {}), _roomIcon(Icons.auto_awesome, () => _sheet(context, const BeautySheet()))])),
      Positioned(top: 84, left: 0, right: 0, child: Center(child: GestureDetector(onTap: () => _push(context, const GuardianPage()), child: Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFFFFD86B), Color(0xFF8B3DFF), Colors.transparent]), boxShadow: [BoxShadow(color: kPurple.withOpacity(.6), blurRadius: 24)]), child: const Icon(Icons.shield, size: 42, color: Colors.white))))),
      Positioned(left: 12, right: 12, bottom: 84, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_supportStrip(), const SizedBox(height: 8), ...['Welcome to the live room','Hello everyone 👋','Send a gift to support the host'].map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)), child: Text(e, style: const TextStyle(fontSize: 12)))))])),
      Positioned(left: 12, right: 12, bottom: 18, child: Row(children: [Expanded(child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24)), child: TextField(controller: chat, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Say something…', hintStyle: TextStyle(color: Colors.white60), border: InputBorder.none)))), const SizedBox(width: 8), _roomIcon(Icons.card_giftcard, () => _sheet(context, const GiftSheet())), _roomIcon(Icons.people_alt_outlined, () => _sheet(context, const ViewersSheet())), _roomIcon(Icons.emoji_events_outlined, () => _push(context, const RankingPage()))])),
    ])),
  ]));
  Widget _hostChip() => Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)), child: Row(children: [_avatar(42), const SizedBox(width: 8), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('jerry ki duniya', style: TextStyle(fontWeight: FontWeight.w800)), Text('● Online  •  Lv.32', style: TextStyle(fontSize: 10, color: Colors.greenAccent))]), const SizedBox(width: 7), const Icon(Icons.verified, color: Color(0xFFFFD54F), size: 19)]));
  Widget _supportStrip() => SizedBox(height: 50, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 7, separatorBuilder: (_, __) => const SizedBox(width: 6), itemBuilder: (_, i) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24)), child: Row(children: [_avatar(30), const SizedBox(width: 5), Text('${(i + 1) * 240} 💎', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))])));
}
Widget _roomIcon(IconData icon, VoidCallback onTap) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GestureDetector(onTap: onTap, child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white12)), child: Icon(icon, size: 21))));

class GiftSheet extends StatelessWidget { const GiftSheet({super.key}); @override Widget build(BuildContext context) => _sheetBase(context, 'Gifts', GridView.builder(padding: const EdgeInsets.all(16), shrinkWrap: true, itemCount: 12, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: .8), itemBuilder: (_, i) => Column(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.card_giftcard, color: kPink)), const SizedBox(height: 6), Text('${(i + 1) * 10}', style: const TextStyle(fontSize: 11))]))); }
class ViewersSheet extends StatelessWidget { const ViewersSheet({super.key}); @override Widget build(BuildContext context) => _sheetBase(context, 'Viewers', ListView.builder(shrinkWrap: true, itemCount: 8, itemBuilder: (_, i) => ListTile(leading: _avatar(42), title: Text('Viewer ${i + 1}'), subtitle: Text('ID: 100${i + 230}'), trailing: const Icon(Icons.person_add_alt_1, color: kPink)))); }
class RoomMoreSheet extends StatelessWidget { const RoomMoreSheet({super.key}); @override Widget build(BuildContext context) => _sheetBase(context, 'More', Column(children: [ListTile(leading: const Icon(Icons.report_outlined), title: const Text('Report')), ListTile(leading: const Icon(Icons.block_outlined), title: const Text('Block')), ListTile(leading: const Icon(Icons.share_outlined), title: const Text('Share')), ListTile(leading: const Icon(Icons.info_outline), title: const Text('Live information'))])); }
class BeautySheet extends StatelessWidget { const BeautySheet({super.key}); @override Widget build(BuildContext context) => _sheetBase(context, 'Beauty', Column(children: [_slider('Smooth'), _slider('Whitening'), _slider('Face'), _slider('Eyes'), _slider('Makeup')])); }
Widget _slider(String label) => Row(children: [SizedBox(width: 85, child: Text(label)), const Expanded(child: Slider(value: .6, onChanged: null))]);
Widget _sheetBase(BuildContext context, String title, Widget child) => SafeArea(child: Padding(padding: const EdgeInsets.only(top: 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8))), Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))])), child])));
void _sheet(BuildContext context, Widget child) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF15151F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))), builder: (_) => child);

class GuardianPage extends StatelessWidget { const GuardianPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Guardian')), body: CustomScrollView(slivers: [SliverToBoxAdapter(child: Container(height: 250, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg_guard_rank_top.webp'), fit: BoxFit.cover)), child: const Center(child: Icon(Icons.shield, size: 90, color: Color(0xFFFFD76A))))), SliverToBoxAdapter(child: _sectionTitle('Guardian ranking', 'View all')), SliverList.builder(itemCount: 10, itemBuilder: (_, i) => ListTile(leading: _avatar(48), title: Text('Guardian ${i + 1}'), subtitle: Text('Support ${1000 - i * 63} 💎'), trailing: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: kPink))))])); }
class RankingPage extends StatelessWidget { const RankingPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Ranking')), body: ListView.builder(padding: const EdgeInsets.all(14), itemCount: 20, itemBuilder: (_, i) => Card(color: kCard, child: ListTile(leading: Stack(children: [_avatar(50), Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 9, backgroundColor: kPink, child: Text('${i + 1}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)))]), title: Text('Wika User ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${(20 - i) * 1250} diamonds sent'), trailing: const Icon(Icons.chevron_right))))); }

class BeautyPage extends StatelessWidget { const BeautyPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Beauty')), body: Column(children: [Expanded(child: Container(margin: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), image: const DecorationImage(image: AssetImage('assets/bg_live_location.png'), fit: BoxFit.cover)), child: const Center(child: Icon(Icons.auto_aw
