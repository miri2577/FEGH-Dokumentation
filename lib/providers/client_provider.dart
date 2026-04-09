import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/secure_storage_service.dart';

/// Spezialisierter Provider fuer Klientenverwaltung.
class ClientProvider extends ChangeNotifier {
  final SecureStorageService _storage;
  List<Client> _clients = [];

  ClientProvider(this._storage);

  List<Client> get clients => _clients;
  int get totalClients => _clients.length;

  Future<void> loadClients() async {
    _clients = await _storage.loadClients();
    notifyListeners();
  }

  Future<bool> addClient(Client client) async {
    try {
      await _storage.saveClient(client);
      _clients.add(client);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ClientProvider] addClient error: $e');
      return false;
    }
  }

  Future<bool> updateClient(Client client) async {
    try {
      await _storage.saveClient(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index >= 0) _clients[index] = client;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ClientProvider] updateClient error: $e');
      return false;
    }
  }

  Future<bool> deleteClient(String clientId) async {
    try {
      await _storage.deleteClient(clientId);
      _clients.removeWhere((c) => c.id == clientId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ClientProvider] deleteClient error: $e');
      return false;
    }
  }

  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;
    final lower = query.toLowerCase();
    return _clients.where((c) =>
      c.name.toLowerCase().contains(lower) ||
      (c.vorname?.toLowerCase().contains(lower) ?? false) ||
      (c.nachname?.toLowerCase().contains(lower) ?? false) ||
      (c.klientenId?.toLowerCase().contains(lower) ?? false)
    ).toList();
  }

  /// Klienten im roten Bereich (>90% Stundenverbrauch)
  int get clientsInRedZone => _clients.where((c) {
    if (c.fachleistungsstunden == null || c.fachleistungsstunden == 0) return false;
    return (c.verbrauchteStunden / c.fachleistungsstunden!) > 0.9;
  }).length;

  /// Klienten im gelben Bereich (75-90%)
  int get clientsInYellowZone => _clients.where((c) {
    if (c.fachleistungsstunden == null || c.fachleistungsstunden == 0) return false;
    final ratio = c.verbrauchteStunden / c.fachleistungsstunden!;
    return ratio > 0.75 && ratio <= 0.9;
  }).length;

  /// Klienten im gruenen Bereich (<75%)
  int get clientsInGreenZone => _clients.where((c) {
    if (c.fachleistungsstunden == null || c.fachleistungsstunden == 0) return true;
    return (c.verbrauchteStunden / c.fachleistungsstunden!) <= 0.75;
  }).length;
}
