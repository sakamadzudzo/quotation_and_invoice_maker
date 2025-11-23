import '../models/client.dart';
import '../services/database_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'i_client_repository.dart';

/// Concrete implementation of client data operations.
///
/// This repository handles all client-related database operations,
/// providing a clean abstraction over the data layer.
class ClientRepository implements IClientRepository {
  final DatabaseService _databaseService;

  ClientRepository(this._databaseService);

  @override
  Future<List<Client>> getClients() async {
    try {
      return await _databaseService.getClients();
    } catch (e) {
      throw RepositoryException('Failed to fetch clients', e);
    }
  }

  @override
  Future<Client?> getClientById(int id) async {
    try {
      final clients = await _databaseService.getClients();
      return clients.where((c) => c.id == id).firstOrNull;
    } catch (e) {
      throw RepositoryException('Failed to fetch client with id: $id', e);
    }
  }

  @override
  Future<int> insertClient(Client client) async {
    try {
      return await _databaseService.insertClient(client);
    } catch (e) {
      throw RepositoryException('Failed to insert client', e);
    }
  }

  @override
  Future<int> updateClient(Client client) async {
    try {
      return await _databaseService.updateClient(client);
    } catch (e) {
      throw RepositoryException('Failed to update client', e);
    }
  }

  @override
  Future<int> deleteClient(int id) async {
    try {
      return await _databaseService.deleteClient(id);
    } catch (e) {
      throw RepositoryException('Failed to delete client', e);
    }
  }
}