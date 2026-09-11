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
  bool isLogin = true;
  bool obscurePassword = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        (!isLogin && nameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 55),
              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFF171722),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Center(
                child: Text(
                  'WikaLive',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  isLogin
                      ? 'Login to continue'
                      : 'Create your WikaLive account',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (!isLogin) ...[
                const Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: const Color(0xFF171722),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: const Color(0xFF171722),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF171722),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    isLogin ? 'Login' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'Create a new account'
                        : 'Already have an account? Login',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HOME ====================

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
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: selected,
        children: const [
          HomeScreen(),
          LiveScreen(),
          Center(
            child: Text(
              'Party',
              style: TextStyle(fontSize: 30),
            ),
          ),
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
          setState(() => selected = i);
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

// ==================== HOME SCREEN ====================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to WikaLive',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch live, join parties and connect with people.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _MenuCard(
                  icon: Icons.live_tv,
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
              const SizedBox(width: 12),
              Expanded(
                child: _MenuCard(
                  icon: Icons.groups,
                  title: 'Party',
                  onTap: () {},
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

          const SizedBox(height: 14),

          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  width: 145,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.black87,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 10,
                        top: 10,
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
                      const Positioned(
                        left: 12,
                        bottom: 14,
                        child: Text(
                          'Live Host',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          color: const Color(0xFF171722),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LIVE SECTION ====================

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
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hosts.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.72,
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
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF29293A)
            : const Color(0xFF171722),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade700,
              const Color(0xFF11111A),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
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

            const Center(
              child: CircleAvatar(
                radius: 34,
                child: Icon(
                  Icons.person,
                  size: 38,
                ),
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        viewers,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
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

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) {
      return;
    }

    messageController.clear();
    FocusScope.of(context).unfocus();
  }

  void openGifts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171722),
      builder: (_) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send Gift',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    _GiftItem(
                      icon: Icons.favorite,
                      name: 'Heart',
                    ),
                    _GiftItem(
                      icon: Icons.star,
                      name: 'Star',
                    ),
                    _GiftItem(
                      icon: Icons.card_giftcard,
                      name: 'Gift',
                    ),
                  ],
                ),
                SizedBox(height: 20),
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
      resizeToAvoidBottomInset: true,
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
                      const Color(0xFF09090E),
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
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),

                  const SizedBox(width: 8),

                  const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hostName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white12,
                    ),
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
              bottom: 76,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: const [
                  _ChatMessage(
                    name: 'Alex',
                    message: 'Hello 👋',
                  ),
                  _ChatMessage(
                    name: 'Sam',
                    message: 'Nice live!',
                  ),
                ],
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Say something...',
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF29293A),
                    ),
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),

                  const SizedBox(width: 4),

                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF29293A),
                    ),
                    onPressed: openGifts,
                    icon: const Icon(Icons.card_giftcard),
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

class _ChatMessage extends StatelessWidget {
  final String name;
  final String message;

  const _ChatMessage({
    required this.name,
    required this.message,
  });

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
        child: Text('$name: $message'),
      ),
    );
  }
}

class _GiftItem extends StatelessWidget {
  final IconData icon;
  final String name;

  const _GiftItem({
    required this.icon,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          child: Icon(
            icon,
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        Text(name),
      ],
    );
  }
}

// ==================== ME ====================

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        CircleAvatar(
          radius: 48,
          child: Icon(
            Icons.person,
            size: 50,
          ),
        ),

        SizedBox(height: 14),

        Center(
          child: Text(
            'WikaLive User',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 25),

        _ProfileButton(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wallet',
        ),

        _ProfileButton(
          icon: Icons.card_giftcard,
          title: 'My Gifts',
        ),

        _ProfileButton(
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
