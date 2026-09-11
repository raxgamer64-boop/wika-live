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
        scaffoldBackgroundColor: const Color(0xFF0B0B12),
        useMaterial3: true,
      ),
      home: const AuthPage(),
    );
  }
}

// ==================== LOGIN / SIGNUP ====================

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool loginMode = true;
  bool obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void submit() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        (!loginMode && nameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 25),
              const Icon(Icons.play_circle_fill_rounded, size: 72),
              const SizedBox(height: 14),
              const Text(
                'WikaLive',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                loginMode
                    ? 'Welcome back! Sign in to continue.'
                    : 'Create your WikaLive account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 35),

              if (!loginMode) ...[
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: const Color(0xFF171722),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: const Color(0xFF171722),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF171722),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: submit,
                  child: Text(
                    loginMode ? 'Login' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: () {
                  setState(() {
                    loginMode = !loginMode;
                    emailController.clear();
                    passwordController.clear();
                    nameController.clear();
                  });
                },
                child: Text(
                  loginMode
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
}

// ==================== MAIN NAVIGATION ====================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;

  final titles = [
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
        backgroundColor: const Color(0xFF0B0B12),
        title: Text(
          titles[selected],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: IndexedStack(
        index: selected,
        children: const [
          HomeScreen(),
          LiveScreen(),
          PartyScreen(),
          Center(
            child: Text(
              'Messages',
              style: TextStyle(fontSize: 30),
            ),
          ),
          MeScreen(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF11111A),
        indicatorColor: const Color(0xFF29293A),
        selectedIndex: selected,
        onDestinationSelected: (i) {
          setState(() {
            selected = i;
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

// ==================== HOME ====================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to WikaLive',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch live, join parties and connect with people.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: _MenuCard(
                  icon: Icons.live_tv_rounded,
                  title: 'Live',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MenuCard(
                  icon: Icons.groups_rounded,
                  title: 'Party',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartyScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 35),

          const Text(
            'Popular Live',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 360,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 270,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF5C2CC9),
                          Color(0xFF0B0B12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(18),
                    alignment: Alignment.bottomLeft,
                    child: const Text(
                      'Live Host',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFF171722),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LIVE ====================

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  static const hosts = [
    ('Mia', '2.4K viewers'),
    ('Luna', '1.8K viewers'),
    ('Sofia', '3.1K viewers'),
    ('Emma', '956 viewers'),
    ('Nina', '1.2K viewers'),
    ('Ava', '2.0K viewers'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B12),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Live',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _LiveCategory(
                    title: 'For You',
                    selected: true,
                  ),
                  _LiveCategory(title: 'Popular'),
                  _LiveCategory(title: 'New'),
                  _LiveCategory(title: 'PK'),
                  _LiveCategory(title: 'Music'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Live Now',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hosts.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final host = hosts[index];

                return _LiveHostCard(
                  name: host.$1,
                  viewers: host.$2,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveRoomPage(
                          hostName: host.$1,
                          viewers: host.$2,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCategory extends StatelessWidget {
  final String title;
  final bool selected;

  const _LiveCategory({
    required this.title,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF29293A)
            : const Color(0xFF171722),
        borderRadius: BorderRadius.circular(25),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}

class _LiveHostCard extends StatelessWidget {
  final String name;
  final String viewers;
  final VoidCallback onTap;

  const _LiveHostCard({
    required this.name,
    required this.viewers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5C2CC9),
              Color(0xFF11111A),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white12,
                  child: const Icon(
                    Icons.person,
                    size: 55,
                  ),
                ),
              ),
            ),

            Text(
              name,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(
                  Icons.remove_red_eye_outlined,
                  size: 19,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  viewers,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LIVE ROOM ====================

class LiveRoomPage extends StatefulWidget {
  final String hostName;
  final String viewers;

  const LiveRoomPage({
    super.key,
    required this.hostName,
    required this.viewers,
  });

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  bool following = false;
  final messageController = TextEditingController();

  final List<String> messages = [
    'Welcome to the live!',
    'Hello 👋',
    'Nice live ❤️',
    'Welcome everyone!',
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(text);
      messageController.clear();
    });
  }

  void showGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15151F),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Gift',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _GiftItem(
                      emoji: '❤️',
                      name: 'Heart',
                      price: '10',
                    ),
                    _GiftItem(
                      emoji: '🌹',
                      name: 'Rose',
                      price: '20',
                    ),
                    _GiftItem(
                      emoji: '💎',
                      name: 'Diamond',
                      price: '100',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.hostName),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 330,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5C2CC9),
                  Color(0xFF11111A),
                ],
              ),
            ),
            child: const Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white12,
                child: Icon(
                  Icons.person,
                  size: 60,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hostName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        widget.viewers,
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),

                FilledButton(
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

          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        child: Icon(
                          Icons.person,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          messages[index],
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                10,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: showGiftSheet,
                    icon: const Icon(
                      Icons.card_giftcard_rounded,
                    ),
                  ),

                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Say something...',
                        filled: true,
                        fillColor:
                            const Color(0xFF171721),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
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

class _GiftItem extends StatelessWidget {
  final String emoji;
  final String name;
  final String price;

  const _GiftItem({
    required this.emoji,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF232332),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PARTY ====================

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  static const rooms = [
    ('Chill & Chat', 'Mia', '8/12', '1.2K'),
    ('Friends Zone', 'Luna', '6/12', '856'),
    ('Music Night', 'Sofia', '10/12', '2.1K'),
    ('Late Night', 'Emma', '4/12', '642'),
    ('Fun Room', 'Nina', '7/12', '931'),
    ('Talk Time', 'Ava', '3/12', '420'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _PartyCategory(
                    title: 'For You',
                    selected: true,
                  ),
                  _PartyCategory(title: 'Popular'),
                  _PartyCategory(title: 'New'),
                  _PartyCategory(title: 'Music'),
                  _PartyCategory(title: 'Friends'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Party Rooms',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CreatePartyPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),

            const SizedBox(height: 18),

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final room = rooms[index];

                return _PartyRoomCard(
                  roomName: room.$1,
                  hostName: room.$2,
                  members: room.$3,
                  viewers: room.$4,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartyRoomPage(
                          roomName: room.$1,
                          hostName: room.$2,
                          members: room.$3,
                          viewers: room.$4,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyCategory extends StatelessWidget {
  final String title;
  final bool selected;

  const _PartyCategory({
    required this.title,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF29293A)
            : const Color(0xFF171722),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color:
              selected ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}

class _PartyRoomCard extends StatelessWidget {
  final String roomName;
  final String hostName;
  final String members;
  final String viewers;
  final VoidCallback onTap;

  const _PartyRoomCard({
    required this.roomName,
    required this.hostName,
    required this.members,
    required this.viewers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5C2CC9),
              Color(0xFF171722),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ROOM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.groups_rounded,
                  size: 20,
                ),
              ],
            ),

            Expanded(
              child: Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white12,
                  child: const Icon(
                    Icons.groups,
                    size: 42,
                  ),
                ),
              ),
            ),

            Text(
              roomName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Host: $hostName',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  members,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.remove_red_eye_outlined,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  viewers,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PARTY ROOM ====================

class PartyRoomPage extends StatefulWidget {
  final String roomName;
  final String hostName;
  final String members;
  final String viewers;

  const PartyRoomPage({
    super.key,
    required this.roomName,
    required this.hostName,
    required this.members,
    required this.viewers,
  });

  @override
  State<PartyRoomPage> createState() =>
      _PartyRoomPageState();
}

class _PartyRoomPageState
    extends State<PartyRoomPage> {
  bool joined = false;
  bool micOn = true;
  bool speakerOn = true;

  final messageController = TextEditingController();

  final List<String> messages = [
    'Welcome to the party!',
    'Mia joined the room',
    'Luna: Hello everyone 👋',
    'Sofia sent a ❤️',
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(text);
      messageController.clear();
    });
  }

  void showGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15151F),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Gift',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: const [
                    _PartyGift(
                      emoji: '❤️',
                      name: 'Heart',
                      price: '10 coins',
                    ),
                    _PartyGift(
                      emoji: '🌹',
                      name: 'Rose',
                      price: '20 coins',
                    ),
                    _PartyGift(
                      emoji: '💎',
                      name: 'Diamond',
                      price: '100 coins',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B12),
        title: Text(
          widget.roomName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              12,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171722),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 27,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hostName,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            '${widget.members} members • ${widget.viewers} watching',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    FilledButton(
                      onPressed: () {
                        setState(() {
                          joined = !joined;
                        });
                      },
                      child: Text(
                        joined ? 'Joined' : 'Join',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: const [
                    _Seat(
                      icon: Icons.person,
                      label: 'Host',
                    ),
                    _Seat(
                      icon: Icons.person,
                      label: 'Mia',
                    ),
                    _Seat(
                      icon: Icons.person,
                      label: 'Luna',
                    ),
                    _Seat(
                      icon: Icons.person_add_alt_1,
                      label: 'Empty',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _PartyChat(
                  text: messages[index],
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                10,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        micOn = !micOn;
                      });
                    },
                    icon: Icon(
                      micOn
                          ? Icons.mic_rounded
                          : Icons.mic_off_rounded,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        speakerOn = !speakerOn;
                      });
                    },
                    icon: Icon(
                      speakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                    ),
                  ),

                  IconButton(
                    onPressed: showGiftSheet,
                    icon: const Icon(
                      Icons.card_giftcard_rounded,
                    ),
                  ),

                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Say something...',
                        filled: true,
                        fillColor:
                            const Color(0xFF171721),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
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

class _Seat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Seat({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white12,
          child: Icon(
            icon,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _PartyChat extends StatelessWidget {
  final String text;

  const _PartyChat({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            child: Icon(
              Icons.person,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyGift extends StatelessWidget {
  final String emoji;
  final String name;
  final String price;

  const _PartyGift({
    required this.emoji,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF232332),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CREATE PARTY ====================

class CreatePartyPage extends StatefulWidget {
  const CreatePartyPage({super.key});

  @override
  State<CreatePartyPage> createState() =>
      _CreatePartyPageState();
}

class _CreatePartyPageState
    extends State<CreatePartyPage> {
  final nameController = TextEditingController();

  String type = 'Public';

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void create() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a party name'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PartyRoomPage(
          roomName: name,
          hostName: 'You',
          members: '1/12',
          viewers: '1',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Party'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Start your own party room',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Invite people and chat together.',
            style: TextStyle(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Party name',
              hintText: 'e.g. Friends Zone',
              filled: true,
              fillColor: const Color(0xFF171721),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            value: type,
            decoration: InputDecoration(
              labelText: 'Room type',
              filled: true,
              fillColor: const Color(0xFF171721),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Public',
                child: Text('Public'),
              ),
              DropdownMenuItem(
                value: 'Friends',
                child: Text('Friends only'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                type = value ?? 'Public';
              });
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: create,
              icon: const Icon(
                Icons.groups_rounded,
              ),
              label: const Text(
                'Create Party',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ME / PROFILE ====================

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 48,
          child: Icon(
            Icons.person,
            size: 50,
          ),
        ),

        const SizedBox(height: 14),

        const Center(
          child: Text(
            'WikaLive User',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 25),

        const _ProfileButton(
          icon:
              Icons.account_balance_wallet_outlined,
          title: 'Wallet',
        ),

        const _ProfileButton(
          icon: Icons.card_giftcard,
          title: 'My Gifts',
        ),

        const _ProfileButton(
          icon: Icons.settings_outlined,
          title: 'Settings',
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ProfileButton({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        tileColor: const Color(0xFF171722),
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () {},
      ),
    );
  }
}
