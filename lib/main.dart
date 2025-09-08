
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'state.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Request Workflow',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          titleTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      home: const Gate(),
    );
  }
}

// ----- UI helpers (gradient background + glass cards) -----
const LinearGradient kAppGradient = LinearGradient(
  colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: kAppGradient),
      child: child,
    );
  }
}

BoxDecoration glassDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
    ],
  );
}

class Gate extends ConsumerStatefulWidget {
  const Gate({super.key});
  @override
  ConsumerState<Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<Gate> {
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final role = sp.getString('role');
    final id = sp.getString('id');
    if (role != null && id != null) {
      ref.read(authProvider.notifier).state = AuthState(role, id);
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth == null) return const LoginScreen();
    return auth.role == 'enduser' ? const EndUserHome() : const ReceiverHome();
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String role = 'enduser';
  final userIdCtrl = TextEditingController(text: 'user-1');
  final receiverIdCtrl = TextEditingController(text: 'receiver-1');

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('role', role);
    final idToSave = role == 'enduser' ? userIdCtrl.text : receiverIdCtrl.text;
    await sp.setString('id', idToSave);
    ref.read(authProvider.notifier).state = AuthState(role, idToSave);
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Gate()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: glassDecoration(),
                  child: const Icon(Icons.description_rounded, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('Request App', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 28),
                Container(
                  width: 380,
                  padding: const EdgeInsets.all(16),
                  decoration: glassDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Select Role', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'enduser', label: Text('End User')),
                          ButtonSegment(value: 'receiver', label: Text('Receiver')),
                        ],
                        selected: {role},
                        onSelectionChanged: (s) => setState(() => role = s.first),
                      ),
                      const SizedBox(height: 16),
                      if (role == 'enduser') ...[
                        const Text('User ID', style: TextStyle(color: Colors.white70)),
                        TextField(controller: userIdCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'user-1')),
                      ] else ...[
                        const Text('Receiver ID', style: TextStyle(color: Colors.white70)),
                        TextField(controller: receiverIdCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'receiver-1 or receiver-2')),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.login), label: const Text('Login')),
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
}

class EndUserHome extends ConsumerWidget {
  const EndUserHome({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('End User'),
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: kAppGradient)),
          actions: [
            IconButton(
              tooltip: 'Switch Account',
              icon: const Icon(Icons.switch_account),
              onPressed: () async {
                final sp = await SharedPreferences.getInstance();
                await sp.remove('role');
                await sp.remove('id');
                ref.read(authProvider.notifier).state = null;
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            )
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Create'), Tab(text: 'My Requests')]),
        ),
        body: const TabBarView(children: [CreateRequestScreen(), MyRequestsScreen()]),
      ),
    );
  }
}

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});
  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final items = [
    {'name': 'Item A', 'sel': false},
    {'name': 'Item B', 'sel': false},
    {'name': 'Item C', 'sel': false},
  ];
  bool busy = false;

  Future<void> _submit() async {
    final auth = ref.read(authProvider)!;
    final api = ref.read(apiProvider);
    final selected = items.where((e) => e['sel'] == true).map((e) => e['name'] as String).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one item')));
      return;
    }
    setState(() => busy = true);
    try {
      await api.createRequest(userId: auth.id, items: selected);
      // Refresh requests immediately for a smoother UX
      ref.invalidate(requestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted')));
        setState(() { for (final e in items) { e['sel'] = false; } });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        ...items.map((e) => CheckboxListTile(
          value: e['sel'] as bool,
          title: Text(e['name'] as String),
          onChanged: (v) => setState(() => e['sel'] = v ?? false),
        )),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : _submit,
          icon: const Icon(Icons.send),
          label: const Text('Submit Request'),
        )
      ]),
    );
  }
}

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});
  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  String selected = 'All';
  Color _chipColor(String s) {
    switch (s) {
      case 'Confirmed': return Colors.green;
      case 'Partially Fulfilled': return Colors.orange;
      default: return Colors.amber;
    }
  }
  @override
  Widget build(BuildContext context) {
    final asyncReqs = ref.watch(requestsProvider);
    return asyncReqs.when(
      data: (list) {
        final filtered = selected == 'All' ? list : list.where((r) => r.status == selected).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'All', label: Text('All')),
                  ButtonSegment(value: 'Pending', label: Text('Pending')),
                  ButtonSegment(value: 'Confirmed', label: Text('Confirmed')),
                  ButtonSegment(value: 'Partially Fulfilled', label: Text('Partial')),
                ],
                selected: {selected},
                onSelectionChanged: (s) => setState(() => selected = s.first),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final r = filtered[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.all(18),
                    decoration: glassDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request #${r.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Chip(label: Text(r.status), backgroundColor: _chipColor(r.status), labelStyle: const TextStyle(color: Colors.white)),
                        ]),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class ReceiverHome extends ConsumerStatefulWidget {
  const ReceiverHome({super.key});
  @override
  ConsumerState<ReceiverHome> createState() => _ReceiverHomeState();
}

class _ReceiverHomeState extends ConsumerState<ReceiverHome> {
  String selected = 'All';
  @override
  Widget build(BuildContext context) {
    final asyncReqs = ref.watch(requestsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receiver'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: kAppGradient)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Switch Receiver',
            onSelected: (value) async {
              final sp = await SharedPreferences.getInstance();
              if (value == 'logout') {
                await sp.remove('role');
                await sp.remove('id');
                ref.read(authProvider.notifier).state = null;
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
                return;
              }
              await sp.setString('role', 'receiver');
              await sp.setString('id', value);
              ref.read(authProvider.notifier).state = AuthState('receiver', value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'receiver-1', child: Text('receiver-1')),
              PopupMenuItem(value: 'receiver-2', child: Text('receiver-2')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout to Login')),
            ],
          ),
        ],
      ),
      body: asyncReqs.when(
        data: (list) {
          final filtered = selected == 'All' ? list : list.where((r) => r.status == selected).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Pending', label: Text('Pending')),
                    ButtonSegment(value: 'Confirmed', label: Text('Confirmed')),
                    ButtonSegment(value: 'Partially Fulfilled', label: Text('Partial')),
                  ],
                  selected: {selected},
                  onSelectionChanged: (s) => setState(() => selected = s.first),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    return ListTile(
                      title: Text('Request #${r.id} • ${r.status}'),
                      subtitle: Text('${r.items.length} items'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiverReviewScreen(r))),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class ReceiverReviewScreen extends ConsumerStatefulWidget {
  final RequestModel req;
  const ReceiverReviewScreen(this.req, {super.key});
  @override
  ConsumerState<ReceiverReviewScreen> createState() => _ReceiverReviewScreenState();
}

class _ReceiverReviewScreenState extends ConsumerState<ReceiverReviewScreen> {
  // choice: null = unchanged, 0 = Available, 1 = Not
  late List<int?> choice;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    // Use int? to avoid bool/null cast issues in web
    choice = List<int?>.generate(widget.req.items.length, (_) => null, growable: true);
  }

  Future<void> _submit() async {
    final api = ref.read(apiProvider);
    final auth = ref.read(authProvider)!; // receiver
    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < choice.length; i++) {
      final c = choice[i];
      if (c != null) results.add({ 'index': i, 'available': c == 0 });
    }
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mark at least one item')));
      return;
    }
    setState(() => busy = true);
    try {
      await api.submitConfirmation(requestId: widget.req.id, receiverId: auth.id, results: results);
      // Ensure lists refresh for both roles after confirmation
      ref.invalidate(requestsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review #${widget.req.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...List.generate(widget.req.items.length, (i) {
              final it = widget.req.items[i];
              return Card(
                child: ListTile(
                  title: Text(it.name),
                  subtitle: Text('Current: ${it.status}'),
                  trailing: ToggleButtons(
                    isSelected: [choice[i] == 0, choice[i] == 1],
                    onPressed: (idx) {
                      setState(() => choice[i] = idx);
                    },
                    children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Available')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Not'))],
                  ),
                ),
              );
            }),
            const Spacer(),
            FilledButton.icon(onPressed: busy ? null : _submit, icon: const Icon(Icons.check), label: const Text('Submit Results')),
          ],
        ),
      ),
    );
  }
}
