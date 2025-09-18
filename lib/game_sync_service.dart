import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game_session.dart';

class GameSyncService {
  static const String baseUrl = 'http://webmo.fr/optimise32_app25/api.php';
  static const Duration pollInterval = Duration(seconds: 3);
  
  Timer? _pollTimer;
  final Map<String, DateTime> _lastUpdated = {};
  
  // Callbacks pour notifier les changements
  Function(GameSession)? addSession;
  Function(GameSession)? updateSession;
  
  static final GameSyncService _instance = GameSyncService._internal();
  factory GameSyncService() => _instance;
  GameSyncService._internal();
  
  Future<Map<String, dynamic>> _makeRequest(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
      
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
  
  Future<void> createGame(String playerName) async {
    final result = await _makeRequest({
      'action': 'create_game',
    });

    if (!result['success']) {
      throw Exception(result['error'] ?? 'Erreur inconnue');
    }

    final session = GameSession(playerName, result['game_code']);
    addSession!(session);
    await sendGameUpdate(session);
  }
  
  Future<void> joinGame(String playerName, String gameCode) async {
    final result = await _makeRequest({
      'action': 'join_game',
      'game_code': gameCode
    });
    
    if (!result['success']) {
      throw Exception(result['error'] ?? 'Impossible de rejoindre la partie');
    }
    
    final session = GameSession.fromJson(result['game_data']);
    session.addPlayer(playerName);
    session.localPlayer = session.players.length - 1;
    addSession!(session);
    await sendGameUpdate(session);
  }
  
  Future<void> sendGameUpdate(GameSession session) async {
    if (!session.isOnline) return;
    
    final result = await _makeRequest({
      'action': 'update_game',
      'game_code': session.id!,
      'game_data': session.toJson(localSave: false),
    });
    
    if (!result['success']) {
      throw Exception(result['error'] ?? 'Erreur lors de l\'envoi');
    }
  }

  Future<void> syncGames(List<GameSession> sessions) async {
    // Préparer la liste des sessions à synchroniser avec leurs timestamps
    final sessionInfos = sessions
        .where((s) => s.isOnline && !s.isGameOver)
        .map((s) => {
          'game_code': s.id!,
          'updated_at': s.updatedAt.toIso8601String(),
        })
        .toList();
    
    if (sessionInfos.isEmpty) return;
    
    final result = await _makeRequest({
      'action': 'sync_games',
      'sessions': sessionInfos,
    });
    
    if (!result['success']) {
      throw Exception(result['error'] ?? 'Erreur de synchronisation');
    }
    
    // Traiter les sessions mises à jour
    final updatedGames = result['updated_games'] as List<dynamic>? ?? [];
    
    for (final gameData in updatedGames) {
      try {
        updateSession!(GameSession.fromJson(gameData));
      } catch (e) {
        throw Exception('Erreur lors de la mise à jour de ${gameData['game_code']}: $e');
      }
    }
  }
  
  void startPolling(List<GameSession> sessions) {
    stopPolling();
    
    _pollTimer = Timer.periodic(pollInterval, (timer) async {
      try {
        await syncGames(sessions);
      } catch (e) {
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