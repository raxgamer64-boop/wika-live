import 'package:flutter/material.dart';

void main() {
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
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthPage(),
    );
  }
}

/* ========================= AUTH ========================= */

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool login = true;
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();

  void submit() {
    if ((login && email.text.isEmpty) ||
        password.text.isEmpty ||
        (!login && name.text.isEmpty)) {
      _message(context, 'Please fill all required fields');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.live_tv_rounded,
                  size: 70,
                  color: Colors.pink,
                ),
                const SizedBox(height: 12),
                const Text(
                  'WikaLive',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  login ? 'Welcome back' : 'Create your account',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 35),
                if (!login)
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (!login) const SizedBox(height: 15),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: submit,
                    child: Text(login ? 'Login' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    setState(() => login = !login);
                  },
                  child: Text(
                    login
                        ? 'Create a new account'
                        : 'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================= HOME ========================= */

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
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => index = i);
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'WikaLive',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _open(context, const NotificationsPage()),
                icon: const Icon(Icons.notifications_none),
              ),
              IconButton(
                onPressed: () => _open(context, const WalletPage()),
                icon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFFFF416C)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to WikaLive',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text('Watch live. Join parties. Meet people.'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _homeCard(
                  context,
                  Icons.live_tv,
                  'Live',
                  const LiveScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _homeCard(
                  context,
                  Icons.groups,
                  'Party',
                  const PartyScreen(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Popular Live',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            ['Mia', '2.4K viewers'],
            ['Luna', '1.8K viewers'],
            ['Sofia', '1.2K viewers'],
          ].map(
            (x) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(x[0]),
                subtitle: Text(x[1]),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  context,
                  LiveRoomPage(host: x[0]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _homeCard(
  BuildContext context,
  IconData icon,
  String title,
  Widget page,
) {
  return InkWell(
    onTap: () => _open(context, page),
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF19191F),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.pink),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

/* ========================= LIVE ========================= */

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  final hosts = const [
    ['Mia', '2.4K'],
    ['Luna', '1.8K'],
    ['Sofia', '1.2K'],
    ['Emma', '980'],
    ['Nina', '760'],
    ['Ava', '620'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 10),
            child: Row(
              children: [
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.search),
              ],
            ),
          ),
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                'For You',
                'Popular',
                'New',
                'PK',
                'Music',
              ].map(
                (x) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Chip(label: Text(x)),
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Live Now',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: hosts.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .78,
              ),
              itemBuilder: (_, i) {
                final h = hosts[i];
                return InkWell(
                  onTap: () => _open(
                    context,
                    LiveRoomPage(host: h[0]),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.pink.shade900,
                          Colors.deepPurple.shade900,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.white38,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  h[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text('${h[1]} 👁'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LiveRoomPage extends StatefulWidget {
  final String host;

  const LiveRoomPage({
    super.key,
    required this.host,
  });

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  bool following = false;
  final controller = TextEditingController();

  final messages = [
    'Welcome to the live ❤️',
    'Hello everyone!',
    'Nice live 🔥',
  ];

  void send() {
    if (controller.text.trim().isEmpty) return;
    setState(() {
      messages.add(controller.text.trim());
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.host),
        actions: [
          IconButton(
            onPressed: () => _message(context, 'Share opened'),
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () => _message(context, 'Report option'),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF301934),
                  Color(0xFF6A1B9A),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 100,
                color: Colors.white30,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.host,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() => following = !following);
                  },
                  child: Text(
                    following ? 'Following' : 'Follow',
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(messages[i]),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _openGiftSheet(context),
                  icon: const Icon(
                    Icons.card_giftcard,
                    color: Colors.pink,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Say something...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================= PARTY ========================= */

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  final rooms = const [
    'Music Party',
    'Fun & Chat',
    'Night Party',
    'Friends Room',
    'Gaming Party',
    'Talk Room',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 10, 10),
            child: Row(
              children: [
                const Text(
                  'Party',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _open(
                    context,
                    const CreatePartyPage(),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rooms.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, i) {
                return InkWell(
                  onTap: () => _open(
                    context,
                    PartyRoomPage(room: rooms[i]),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFF19191F),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.groups,
                          size: 48,
                          color: Colors.purpleAccent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          rooms[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '12 people',
                          style: TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePartyPage extends StatefulWidget {
  const CreatePartyPage({super.key});

  @override
  State<CreatePartyPage> createState() => _CreatePartyPageState();
}

class _CreatePartyPageState extends State<CreatePartyPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Party')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Party name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) {
                    _message(context, 'Enter party name');
                    return;
                  }
                  _message(
                    context,
                    'Party created: ${controller.text.trim()}',
                  );
                  Navigator.pop(context);
                },
                child: const Text('Create Party'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartyRoomPage extends StatefulWidget {
  final String room;

  const PartyRoomPage({
    super.key,
    required this.room,
  });

  @override
  State<PartyRoomPage> createState() => _PartyRoomPageState();
}

class _PartyRoomPageState extends State<PartyRoomPage> {
  bool mic = false;
  bool speaker = true;
  final controller = TextEditingController();

  final chats = [
    'Welcome everyone 🎉',
    'Hello 👋',
    'Let’s party!',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room),
        actions: [
          IconButton(
            onPressed: () => _message(context, 'Share opened'),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 210,
            width: double.infinity,
            color: const Color(0xFF171722),
            child: const Center(
              child: Icon(
                Icons.groups,
                size: 90,
                color: Colors.white30,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _roundButton(
                  mic ? Icons.mic : Icons.mic_off,
                  () => setState(() => mic = !mic),
                ),
                _roundButton(
                  speaker
                      ? Icons.volume_up
                      : Icons.volume_off,
                  () => setState(
                    () => speaker = !speaker,
                  ),
                ),
                _roundButton(
                  Icons.card_giftcard,
                  () => _openGiftSheet(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: chats.length,
              itemBuilder: (_, i) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6),
                child: Text(chats[i]),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    setState(() {
                      chats.add(controller.text.trim());
                      controller.clear();
                    });
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _roundButton(
  IconData icon,
  VoidCallback action,
) {
  return CircleAvatar(
    radius: 25,
    child: IconButton(
      onPressed: action,
      icon: Icon(icon),
    ),
  );
}

/* ========================= MESSAGES ========================= */

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  final people = const [
    ['Mia', 'Hey 👋'],
    ['Luna', 'Hello!'],
    ['Sofia', 'How are you?'],
    ['Emma', 'Nice to meet you'],
    ['Nina', 'Hi 😊'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: people.length,
              itemBuilder: (_, i) {
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(people[i][0]),
                  subtitle: Text(people[i][1]),
                  trailing:
                      const Icon(Icons.chevron_right),
                  onTap: () => _open(
                    context,
                    ChatPage(name: people[i][0]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String name;

  const ChatPage({
    super.key,
    required this.name,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();

  final messages = [
    'Hello 👋',
    'How are you?',
  ];

  void send() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      messages.add(controller.text.trim());
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(.25),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Text(messages[i]),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================= ME ========================= */

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 15),
          const Center(
            child: CircleAvatar(
              radius: 48,
              child: Icon(Icons.person, size: 50),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Wika User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Center(
            child: Text(
              '@wikauser',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 25),
          _menu(context, Icons.person_outline, 'My Profile',
              const ProfilePage()),
          _menu(
            context,
            Icons.account_balance_wallet_outlined,
            'Wallet',
            const WalletPage(),
          ),
          _menu(
            context,
            Icons.card_giftcard,
            'My Gifts',
            const GiftsPage(),
          ),
          _menu(
            context,
            Icons.live_tv,
            'Become a Host',
            const HostPage(),
          ),
          _menu(
            context,
            Icons.business,
            'Agency',
            const AgencyPage(),
          ),
          _menu(
            context,
            Icons.settings_outlined,
            'Settings',
            const SettingsPage(),
          ),
        ],
      ),
    );
  }
}

Widget _menu(
  BuildContext context,
  IconData icon,
  String title,
  Widget page,
) {
  return Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context, page),
    ),
  );
}

/* ========================= PROFILE ========================= */

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final name = TextEditingController(text: 'Wika User');
  final bio = TextEditingController(
    text: 'Welcome to my WikaLive profile ❤️',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 55),
            ),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: bio,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              _message(context, 'Profile saved');
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}

/* ========================= WALLET ========================= */

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8E2DE2),
                  Color(0xFFFF416C),
                ],
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'My Coins',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text(
                  '12,500',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Coins'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _open(
              context,
              const CoinPackagesPage(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Buy Coins'),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Gift History'),
            onTap: () => _message(
              context,
              'Gift history opened',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Withdraw'),
            onTap: () => _open(
              context,
              const WithdrawalPage(),
            ),
          ),
        ],
      ),
    );
  }
}

class CoinPackagesPage extends StatelessWidget {
  const CoinPackagesPage({super.key});

  final packages = const [
    ['100 Coins', '₹10'],
    ['500 Coins', '₹50'],
    ['1,000 Coins', '₹100'],
    ['5,000 Coins', '₹500'],
    ['10,000 Coins', '₹1,000'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy Coins')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: packages.length,
        itemBuilder: (_, i) {
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.monetization_on,
                color: Colors.amber,
              ),
              title: Text(packages[i][0]),
              subtitle: Text(packages[i][1]),
              trailing: FilledButton(
                onPressed: () => _message(
                  context,
                  'Payment screen will open here',
                ),
                child: const Text('Buy'),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ========================= GIFTS ========================= */

class GiftsPage extends StatelessWidget {
  const GiftsPage({super.key});

  final gifts = const [
    '❤️',
    '🌹',
    '💎',
    '🔥',
    '👑',
    '🎁',
    '🚀',
    '💰',
    '⭐',
    '🍫',
    '🎂',
    '🦋',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Gifts')),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: gifts.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) {
          return Card(
            child: Center(
              child: Text(
                gifts[i],
                style: const TextStyle(fontSize: 42),
              ),
            ),
          );
        },
      ),
    );
  }
}

void _openGiftSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) {
      final gifts = ['❤️', '🌹', '💎', '🔥', '👑', '🎁'];

      return Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: gifts.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemBuilder: (ctx, i) {
            return InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _message(
                  context,
                  '${gifts[i]} Gift sent',
                );
              },
              child: Center(
                child: Text(
                  gifts[i],
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/* ========================= HOST ========================= */

class HostPage extends StatelessWidget {
  const HostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Host')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.live_tv,
            size: 80,
            color: Colors.pink,
          ),
          const SizedBox(height: 20),
          const Text(
            'Become a WikaLive Host',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Go live, interact with viewers and earn from gifts.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: () {
              _message(
                context,
                'Host application opened',
              );
            },
            child: const Text('Apply as Host'),
          ),
        ],
      ),
    );
  }
}

/* ========================= AGENCY ========================= */

class AgencyPage extends StatelessWidget {
  const AgencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agency')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.business),
              title: const Text('My Agency'),
              subtitle: const Text('No agency joined'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Invitations'),
              subtitle: const Text('No pending invitations'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('My Hosts'),
              subtitle: const Text('0 hosts'),
            ),
          ),
          const SizedBox(height: 15),
          FilledButton(
            onPressed: () {
              _message(
                context,
                'Agency joining screen opened',
              );
            },
            child: const Text('Join Agency'),
          ),
        ],
      ),
    );
  }
}

/* ========================= WITHDRAWAL ========================= */

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});

  @override
  State<WithdrawalPage> createState() =>
      _WithdrawalPageState();
}

class _WithdrawalPageState
    extends State<WithdrawalPage> {
  final amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF19191F),
            ),
            child: const Column(
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.white54),
                ),
                SizedBox(height: 8),
                Text(
                  '₹0',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Withdrawal amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              if (amount.text.isEmpty) {
                _message(
                  context,
                  'Enter withdrawal amount',
                );
                return;
              }

              _message(
                context,
                'Withdrawal request submitted',
              );
            },
            child: const Text('Request Withdrawal'),
          ),
        ],
      ),
    );
  }
}

/* ========================= NOTIFICATIONS ========================= */

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Mia started a live',
      'You received a new message',
      'Your agency invitation is waiting',
      'Welcome to WikaLive ❤️',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.notifications),
            ),
            title: Text(items[i]),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}

/* ========================= SETTINGS ========================= */

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: notifications,
            onChanged: (v) {
              setState(() => notifications = v);
            },
            title: const Text('Notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            onTap: () => _message(
              context,
              'Language selection opened',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security'),
            onTap: () => _message(
              context,
              'Privacy & Security opened',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () => _message(
              context,
              'Help & Support opened',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthPage(),
                ),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ========================= HELPERS ========================= */

void _open(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text)),
    );
}
