import '../models/client.dart';

/// Abstract interface for client data operations.
///
/// This interface defines the contract for client-related data access operations,
/// separating business logic from data persistence concerns.
abstract class IClientRepository {
  /// Retrieves all clients from the data source.
  ///
  /// Returns a list of clients sorted by creation date (newest first).
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Client>> getClients();

  /// Retrieves a specific client by its ID.
  ///
  /// [id] - The unique identifier of the client
  /// Returns the client if found, null otherwise.
  /// Throws [RepositoryException] if the operation fails.
  Future<Client?> getClientById(int id);

  /// Inserts a new client into the data source.
  ///
  /// [client] - The client to insert
  /// Returns the ID of the newly inserted client.
  /// Throws [RepositoryException] if the operation fails.
  Future<int> insertClient(Client client);

  /// Updates an existing client in the data source.
  ///
  /// [client] - The client to update (must have a valid ID)
  /// Returns the number of rows affected.
  /// Throws [RepositoryException] if the operation fails.
  Future<int> updateClient(Client client);

  /// Deletes a client from the data source.
  ///
  /// [id] - The unique identifier of the client to delete
  /// Returns the number of rows affected.
  /// Throws [RepositoryException] if the operation fails.
  Future<int> deleteClient(int id);
}