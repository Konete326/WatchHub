import 'package:flutter/material.dart';
import '../models/support_ticket.dart';
import '../models/canned_response.dart';
import '../services/support_service.dart';

class SupportProvider with ChangeNotifier {
  final SupportService _supportService = SupportService();

  List<SupportTicket> _tickets = [];
  List<SupportTicket> get tickets => _tickets;

  List<CannedResponse> _cannedResponses = [];
  List<CannedResponse> get cannedResponses => _cannedResponses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  Future<void> fetchUserTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _supportService.getUserTickets();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCannedResponses() async {
    try {
      _cannedResponses = await _supportService.getCannedResponses();
      notifyListeners();
    } catch (e) {
      print('Error fetching canned responses: $e');
    }
  }

  Future<void> fetchStats() async {
    try {
      _stats = await _supportService.getSupportStats();
      notifyListeners();
    } catch (e) {
      print('Error fetching support stats: $e');
    }
  }

  Future<SupportTicket> getTicketDetail(String id) async {
    return await _supportService.getTicketById(id);
  }

  Future<bool> createTicket({
    required String subject,
    required String message,
    String priority = 'MEDIUM',
    String? category,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supportService.createTicket(
        subject: subject,
        message: message,
        priority: priority,
        category: category,
      );
      await fetchUserTickets();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> replyToTicket({
    required String ticketId,
    required String message,
    bool isAdmin = false,
    String? senderName,
  }) async {
    try {
      await _supportService.addMessageToTicket(
        ticketId: ticketId,
        message: message,
        isAdmin: isAdmin,
        senderName: senderName,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> resolveTicket(String ticketId, {String? reason}) async {
    try {
      await _supportService.resolveTicket(ticketId, reason: reason);
      notifyListeners();
    } catch (e) {
      print('Error resolving ticket: $e');
    }
  }

  Future<void> assignTicket(String ticketId, String adminId) async {
    try {
      await _supportService.assignTicket(ticketId, adminId);
      notifyListeners();
    } catch (e) {
      print('Error assigning ticket: $e');
    }
  }
}
