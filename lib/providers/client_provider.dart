import '../../core/providers/base_provider.dart';
import '../../core/cache/cache_manager.dart';
import '../../repositories/i_client_repository.dart';
import '../models/client.dart';

/// Provider for managing client-related state and operations.
///
/// This provider handles all client CRUD operations and maintains
/// the application state for client data with caching support.
class ClientProvider extends BaseProvider {
  final IClientRepository _clientRepository;
  final CacheManager _cacheManager;
  List<Client> _clients = [];

  static const String _clientsCacheKey = 'clients_list';
  static const Duration _cacheDuration = Duration(hours: 1);

  ClientProvider(this._clientRepository, this._cacheManager);

  /// List of all clients, sorted by creation date (newest first).
  List<Client> get clients => _clients;

  /// Loads all clients from cache or repository.
  ///
  /// Attempts to load from cache first for better performance.
  /// Falls back to repository if cache is empty or expired.
  /// Updates the internal client list and sorts by creation date.
  ///
  /// [forceRefresh] - If true, bypasses cache and loads from repository
  Future<void> loadClients({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Try to load from cache first
      final cachedClients = await _cacheManager.get<List<Client>>(_clientsCacheKey);
      if (cachedClients != null) {
        _clients = cachedClients;
        notifyListeners();
        return;
      }
    }

    await executeWithLoading(() async {
      _clients = await _clientRepository.getClients();
      _clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Cache the result for future use
      await _cacheManager.set(_clientsCacheKey, _clients, ttl: _cacheDuration);
    });
  }

  /// Adds a new client to the repository and local state.
  ///
  /// [client] - The client to add
  /// Returns true if successful, false otherwise.
  Future<bool> addClient(Client client) async {
    final success = await executeOperation(() async {
      final id = await _clientRepository.insertClient(client);
      final newClient = client.copyWith(id: id);
      _clients.add(newClient);
    });

    // Invalidate cache when data changes
    if (success) {
      await _cacheManager.remove(_clientsCacheKey);
    }

    return success;
  }

  /// Updates an existing client in the repository and local state.
  ///
  /// [client] - The client to update (must have a valid ID)
  /// Returns true if successful, false otherwise.
  Future<bool> updateClient(Client client) async {
    final success = await executeOperation(() async {
      await _clientRepository.updateClient(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
      }
    });

    // Invalidate cache when data changes
    if (success) {
      await _cacheManager.remove(_clientsCacheKey);
    }

    return success;
  }

  /// Deletes a client from the repository and local state.
  ///
  /// [id] - The ID of the client to delete
  /// Returns true if successful, false otherwise.
  Future<bool> deleteClient(int id) async {
    final success = await executeOperation(() async {
      await _clientRepository.deleteClient(id);
      _clients.removeWhere((c) => c.id == id);
    });

    // Invalidate cache when data changes
    if (success) {
      await _cacheManager.remove(_clientsCacheKey);
    }

    return success;
  }

  /// Retrieves a client by its ID from the local state.
  ///
  /// [id] - The ID of the client to retrieve
  /// Returns the client if found, null otherwise.
  Client? getClientById(int id) {
    return _clients.where((c) => c.id == id).firstOrNull;
  }
}