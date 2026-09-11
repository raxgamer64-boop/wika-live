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
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
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
          PartyScreen(),
          Center(
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          MeScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF11111B),
        selectedIndex: selected,
        onDestinationSelected: (index) {
          setState(() {
            selected = index;
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

class PartyScreen extends StatelessWidget {
  const PartyScreen({super.key});

  final List<Map<String, dynamic>> rooms = const [
    {
      'title': 'Night Vibes',
      'host': 'Mia',
      'members': 8,
      'category': 'Chat',
      'color': 0xFF5E35B1,
    },
    {
      'title': 'Music Lounge',
      'host': 'Luna',
      'members': 6,
      'category': 'Music',
      'color': 0xFF7B1FA2,
    },
    {
      'title': 'Friends Zone',
      'host': 'Sofia',
      'members': 10,
      'category': 'Friends',
      'color': 0xFF3949AB,
    },
    {
      'title': 'Fun & Games',
      'host': 'Emma',
      'members': 5,
      'category': 'Games',
      'color': 0xFF00897B,
    },
    {
      'title': 'Chill Room',
      'host': 'Nina',
      'members': 7,
      'category': 'Chat',
      'color': 0xFF6A1B9A,
    },
    {
      'title': 'Late Night',
      'host': 'Ava',
      'members': 9,
      'category': 'Talk',
      'color': 0xFF4527A0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Row(
            children: [
              const Text(
                'Party Rooms',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: PartySearchDelegate(rooms),
                  );
                },
                icon: const Icon(Icons.search),
              ),
              FilledButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF171722),
                    isScrollControlled: true,
                    builder: (_) => const CreatePartySheet(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            children: const [
              _PartyCategory(
                text: 'All',
                active: true,
              ),
              _PartyCategory(text: 'Popular'),
              _PartyCategory(text: 'Music'),
              _PartyCategory(text: 'Chat'),
              _PartyCategory(text: 'Games'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.86,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];

              return _PartyRoomCard(
                title: room['title'],
                host: room['host'],
                members: room['members'],
                category: room['category'],
                color: room['color'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartyRoomPage(
                        title: room['title'],
                        host: room['host'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PartyCategory extends StatelessWidget {
  final String text;
  final bool active;

  const _PartyCategory({
    required this.text,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF29263D)
            : const Color(0xFF171722),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}

class _PartyRoomCard extends StatelessWidget {
  final String title;
  final String host;
  final int members;
  final String category;
  final int color;
  final VoidCallback onTap;

  const _PartyRoomCard({
    required this.title,
    required this.host,
    required this.members,
    required this.category,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(color),
              const Color(0xFF0F0F18),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'PARTY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.groups,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white24,
                child: const Icon(
                  Icons.person,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Host: $host',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 17,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$members members',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category,
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
      ),
    );
  }
}

class PartyRoomPage extends StatefulWidget {
  final String title;
  final String host;

  const PartyRoomPage({
    super.key,
    required this.title,
    required this.host,
  });

  @override
  State<PartyRoomPage> createState() => _PartyRoomPageState();
}

class _PartyRoomPageState extends State<PartyRoomPage> {
  bool micOn = true;
  bool speakerOn = true;

  final messageController = TextEditingController();

  final List<Map<String, String>> messages = [
    {
      'name': 'Mia',
      'message': 'Welcome everyone! 👋',
    },
    {
      'name': 'Luna',
      'message': 'Hello guys ❤️',
    },
    {
      'name': 'Sofia',
      'message': 'Let’s have fun!',
    },
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
      messages.add({
        'name': 'You',
        'message': text,
      });
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10101A),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF171722),
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.report_outlined),
                        title: const Text('Report room'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.share_outlined),
                        title: const Text('Share room'),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5E35B1),
                  Color(0xFF171722),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'Party Room',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hosted by ${widget.host}',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 210,
                  child: GridView.count(
                    crossAxisCount: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      const _PartySeat(
                        name: 'Host',
                        icon: Icons.star,
                        host: true,
                      ),
                      const _PartySeat(
                        name: 'Luna',
                        icon: Icons.person,
                      ),
                      const _PartySeat(
                        name: 'Sofia',
                        icon: Icons.person,
                      ),
                      const _PartySeat(
                        name: 'Emma',
                        icon: Icons.person,
                      ),
                      const _PartySeat(
                        name: 'Nina',
                        icon: Icons.person,
                      ),
                      const _PartySeat(
                        name: 'Ava',
                        icon: Icons.person,
                      ),
                      const _PartySeat(
                        name: 'Empty',
                        icon: Icons.add,
                        empty: true,
                      ),
                      const _PartySeat(
                        name: 'Empty',
                        icon: Icons.add,
                        empty: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Text(
                  'Live Chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      micOn = !micOn;
                    });
                  },
                  icon: Icon(
                    micOn ? Icons.mic : Icons.mic_off,
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
                        ? Icons.volume_up
                        : Icons.volume_off,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final item = messages[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFF4D3A82),
                        child: const Icon(
                          Icons.person,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${item['name']}  ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: item['message'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
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
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Say something...',
                        filled: true,
                        fillColor: const Color(0xFF171722),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF5E35B1),
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(Icons.send),
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

class _PartySeat extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool host;
  final bool empty;

  const _PartySeat({
    required this.name,
    required this.icon,
    this.host = false,
    this.empty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: empty
                  ? Colors.white10
                  : host
                      ? Colors.amber.withOpacity(0.22)
                      : Colors.white10,
              border: Border.all(
                color: host ? Colors.amber : Colors.white12,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: host
                    ? Colors.amber
                    : Colors.white70,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class CreatePartySheet extends StatefulWidget {
  const CreatePartySheet({super.key});

  @override
  State<CreatePartySheet> createState() => _CreatePartySheetState();
}

class _CreatePartySheetState extends State<CreatePartySheet> {
  final titleController = TextEditingController();

  String category = 'Chat';
  bool publicRoom = true;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Party',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Party name',
              filled: true,
              fillColor: const Color(0xFF10101A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: category,
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: const Color(0xFF10101A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Chat',
                child: Text('Chat'),
              ),
              DropdownMenuItem(
                value: 'Music',
                child: Text('Music'),
              ),
              DropdownMenuItem(
                value: 'Games',
                child: Text('Games'),
              ),
              DropdownMenuItem(
                value: 'Talk',
                child: Text('Talk'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  category = value;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public room'),
            value: publicRoom,
            onChanged: (value) {
              setState(() {
                publicRoom = value;
              });
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a party name'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${titleController.text.trim()} created',
                    ),
                  ),
                );
              },
              child: const Text(
                'Create Party',
                style: TextStyle(
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

class PartySearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> rooms;

  PartySearchDelegate(this.rooms);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final result = rooms.where((room) {
      final title = room['title'].toString().toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    return _searchList(context, result);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final result = rooms.where((room) {
      final title = room['title'].toString().toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    return _searchList(context, result);
  }

  Widget _searchList(
    BuildContext context,
    List<Map<String, dynamic>> result,
  ) {
    if (result.isEmpty) {
      return const Center(
        child: Text('No party found'),
      );
    }

    return ListView.builder(
      itemCount: result.length,
      itemBuilder: (context, index) {
        final room = result[index];

        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.groups),
          ),
          title: Text(room['title']),
          subtitle: Text(
            'Hosted by ${room['host']}',
          ),
          onTap: () {
            close(context, room['title']);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PartyRoomPage(
                  title: room['title'],
                  host: room['host'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  final List<Map<String, dynamic>> hosts = const [
    {
      'name': 'Mia',
      'viewers': '2.4K',
    },
    {
      'name': 'Luna',
      'viewers': '1.8K',
    },
    {
      'name': 'Sofia',
      'viewers': '3.1K',
    },
    {
      'name': 'Emma',
      'viewers': '956',
    },
    {
      'name': 'Nina',
      'viewers': '1.2K',
    },
    {
      'name': 'Ava',
      'viewers': '780',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back),
              ),
              const Text(
                'Live',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: const [
              _LiveCategory(
                text: 'For You',
                active: true,
              ),
              _LiveCategory(text: 'Popular'),
              _LiveCategory(text: 'New'),
              _LiveCategory(text: 'PK'),
              _LiveCategory(text: 'Music'),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Live Now',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 25),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: hosts.length,
            itemBuilder: (context, index) {
              final host = hosts[index];

              return _LiveHostCard(
                name: host['name'],
                viewers: host['viewers'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveRoomPage(
                        hostName: host['name'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LiveCategory extends StatelessWidget {
  final String text;
  final bool active;

  const _LiveCategory({
    required this.text,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF29263D)
            : const Color(0xFF171722),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: active ? Colors.white : Colors.white70,
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
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5B2DC2),
              Color(0xFF11111B),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF543C96),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$viewers viewers',
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
      ),
    );
  }
}

class LiveRoomPage extends StatefulWidget {
  final String hostName;

  const LiveRoomPage({
    super.key,
    required this.hostName,
  });

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  bool following = false;

  final chatController = TextEditingController();

  final List<Map<String, String>> messages = [
    {
      'name': 'Luna',
      'message': 'Hello everyone ❤️',
    },
    {
      'name': 'Mia',
      'message': 'Welcome to my live!',
    },
    {
      'name': 'Sofia',
      'message': 'Nice live 🔥',
    },
  ];

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = chatController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({
        'name': 'You',
        'message': text,
      });
    });

    chatController.clear();
  }

  void showGifts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171722),
      builder: (_) {
        final gifts = [
          ['❤️', 'Heart', '10'],
          ['🌹', 'Rose', '50'],
          ['🎁', 'Gift', '100'],
          ['💎', 'Diamond', '500'],
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Send Gift',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: gifts.map((gift) {
                    return Expanded(
                      child: _GiftItem(
                        emoji: gift[0],
                        name: gift[1],
                        coins: gift[2],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5B2DC2),
                      Color(0xFF080810),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.white30,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 15,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.hostName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
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
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFF0B0B12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        10,
                        14,
                        5,
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Live Chat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '2.4K viewers',
                            style: const TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _ChatMessage(
                            name: messages[index]['name']!,
                            message: messages[index]['message']!,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        5,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: chatController,
                              decoration: InputDecoration(
                                hintText: 'Say something...',
                                filled: true,
                                fillColor: const Color(0xFF171722),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: showGifts,
                            icon: const Icon(
                              Icons.card_giftcard,
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor:
                                const Color(0xFF5E35B1),
                            child: IconButton(
                              onPressed: sendMessage,
                              icon: const Icon(Icons.send),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF493783),
            child: Icon(
              Icons.person,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$name  ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: message,
                    style: const TextStyle(
                      color: Colors.white70,
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
  final String coins;

  const _GiftItem({
    required this.emoji,
    required this.name,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 38),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$coins coins',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to WikaLive',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Watch live, join parties and connect with people.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 35),
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
                        builder: (_) => const StandaloneLivePage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MenuCard(
                  icon: Icons.groups,
                  title: 'Party',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StandalonePartyPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          const Text(
            'Popular Live',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 390,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _popularCard(context, 'Mia'),
                _popularCard(context, 'Luna'),
                _popularCard(context, 'Sofia'),
                _popularCard(context, 'Emma'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _popularCard(
    BuildContext context,
    String name,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveRoomPage(
              hostName: name,
            ),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5B2DC2),
              Color(0xFF080810),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white24,
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFF171722),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 58,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StandaloneLivePage extends StatelessWidget {
  const StandaloneLivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: LiveScreen(),
      ),
    );
  }
}

class StandalonePartyPage extends StatelessWidget {
  const StandalonePartyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: PartyScreen(),
      ),
    );
  }
}

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 35),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFF493783),
            child: Icon(
              Icons.person,
              size: 55,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Wika User',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '@wikauser',
            style: TextStyle(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: const [
              Expanded(
                child: _ProfileStat(
                  number: '0',
                  label: 'Following',
                ),
              ),
              Expanded(
                child: _ProfileStat(
                  number: '0',
                  label: 'Followers',
                ),
              ),
              Expanded(
                child: _ProfileStat(
                  number: '0',
                  label: 'Gifts',
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _ProfileButton(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            onTap: null,
          ),
          _ProfileButton(
            icon: Icons.card_giftcard_outlined,
            title: 'My Gifts',
            onTap: null,
          ),
          _ProfileButton(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: null,
          ),
          _ProfileButton(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String number;
  final String label;

  const _ProfileStat({
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _ProfileButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171722),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
        ),
        onTap: onTap,
      ),
    );
  }
}
