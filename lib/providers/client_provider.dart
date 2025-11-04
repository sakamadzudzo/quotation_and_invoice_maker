import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/database_service.dart';

class ClientProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Client> _clients = [];
  bool _isLoading = false;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _clients = await _databaseService.getClients();
      // Sort by creation date, newest first
      _clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading clients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addClient(Client client) async {
    try {
      final id = await _databaseService.insertClient(client);
      final newClient = client.copyWith(id: id);
      _clients.add(newClient);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding client: $e');
      return false;
    }
  }

  Future<bool> updateClient(Client client) async {
    try {
      await _databaseService.updateClient(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating client: $e');
      return false;
    }
  }

  Future<bool> deleteClient(int id) async {
    try {
      await _databaseService.deleteClient(id);
      _clients.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting client: $e');
      return false;
    }
  }

  Client? getClientById(int id) {
    return _clients.where((c) => c.id == id).firstOrNull;
  }
}