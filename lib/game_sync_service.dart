import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game_session.dart';

class GameSyncService {
  static const String baseUrl = 'http://app.microclic.com/api.php';
  static const Duration pollInterval = Duration(seconds: 5);
  
  Timer? _pollTimer;
  final Map<String, DateTime> _lastUpdated = {};
  
  Function(GameSession)? addSession;
  Function(GameSession)? updateSession;
  
  static final GameSyncService _instance = GameSyncService._internal();
  factory GameSyncService() => _instance;
  GameSyncService._internal();
  
  Future<Map<String, dynamic>> _makeRequest(Map<String, dynamic> data) async {
    try {
      jsonEncode(data);
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Erreur serveur: ${response.statusCode}';
        throw Exception(errorMessage);
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }
  
  Future<void> createGame(String playerName) async {
    final result = await _makeRequest({
      'action': 'create_game',
    });

    final session = GameSession(playerName, result['game_code']);
    addSession!(session);
    await sendGameUpdate(session, isWaiting: true);
  }
  
  Future<void> joinGame(String playerName, String gameCode) async {
    final result = await _makeRequest({
      'action': 'join_game',
      'game_code': gameCode
    });
    
    final session = GameSession.fromJson(jsonDecode(result['game_data']));
    session.localPlayer = session.players.length;
    session.addPlayer(playerName);
    addSession!(session);
    await sendGameUpdate(session);
  }
  
  Future<void> sendGameUpdate(GameSession session, {bool isWaiting = false}) async {
    if (!session.isOnline) return;

    await _makeRequest({
      'action': 'update_game',
      'game_code': session.id!,
      'game_status': isWaiting ? 'waiting' : (session.isGameOver ? 'finished' : 'running'),
      'game_data': jsonEncode(session.toJson(localSave: false)),
      'updated_at': session.updatedAt.toString(),
    });
  }

  Future<void> leaveGame(String gameCode) async {
    await _makeRequest({
      'action': 'leave_game',
      'game_code': gameCode
    });
  }

  Future<void> syncGames(List<GameSession> sessions) async {
    final sessionInfos = sessions
        .where((s) => s.isOnline && !s.isGameOver)
        .map((s) => {
          'game_code': s.id!,
          'updated_at': s.updatedAt.toString().substring(0, 19) // Trim microseconds
        })
        .toList();

    if (sessionInfos.isEmpty) return;

    final result = await _makeRequest({
      'action': 'sync_games',
      'sessions': sessionInfos,
    });

    final updatedGames = result['updated_games'] as List<dynamic>? ?? [];

    for (final gameData in updatedGames) {
      if (gameData['status'] == 'deleted') {
        final session = sessions.where((s) => s.id == gameData['game_code']).first;
        session.isGameOver = true;
        session.id = null; // Marquer comme partie locale
        continue;
      }

      final session = GameSession.fromJson(jsonDecode(gameData));
      try {
        updateSession!(session);
      } catch (e) {
        throw Exception('Erreur lors de la mise à jour de ${session.id}: $e');
      }
    }
  }
  
  void startPolling(List<GameSession> sessions) {
    stopPolling();
    
    _pollTimer = Timer.periodic(pollInterval, (timer) async {
      try {
        await syncGames(sessions);
      } catch (e) {
        // La gestion des erreurs reste ici, car elle est liée à la boucle de synchronisation
        throw Exception('Erreur de synchronisation globale: $e');
      }
    });
  }
  
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  
  void dispose() {
    stopPolling();
    _lastUpdated.clear();
  }
}