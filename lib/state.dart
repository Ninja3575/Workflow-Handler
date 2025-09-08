import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'models.dart';

// ----- Auth (very simple role memory) -----
class AuthState {
  final String role; // 'enduser' | 'receiver'
  final String id;   // userId or receiverId
  const AuthState(this.role, this.id);
}

final baseUrlProvider = Provider<String>((_) => 'http://localhost:4000');
final apiProvider = Provider<ApiService>((ref) => ApiService(ref.watch(baseUrlProvider)));
final authProvider = StateProvider<AuthState?>((_) => null);

// ----- Requests list with polling -----
class RequestsNotifier extends AsyncNotifier<List<RequestModel>> {
  Timer? _timer;
  @override
  Future<List<RequestModel>> build() async {
    // Watch auth so list refreshes when user/receiver switches
    ref.watch(authProvider);
    _startPolling();
    return _fetch();
  }

  ApiService get _api => ref.read(apiProvider);
  AuthState? get _auth => ref.read(authProvider);

  Future<List<RequestModel>> _fetch() async {
    final a = _auth;
    if (a == null) return [];
    if (a.role == 'enduser') {
      return _api.fetchEndUserRequests(a.id);
    } else {
      return _api.fetchReceiverRequests(a.id);
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      state = AsyncData(await _fetch());
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

final requestsProvider = AsyncNotifierProvider<RequestsNotifier, List<RequestModel>>(() => RequestsNotifier());
