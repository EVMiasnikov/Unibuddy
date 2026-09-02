import 'package:flutter/foundation.dart';

import '../models/buddy_request.dart';
import '../services/chat_service.dart';
import '../services/request_service.dart';

class RequestController extends ChangeNotifier {
  final RequestService _requestService;
  final ChatService _chatService;

  RequestController({RequestService? requestService, ChatService? chatService})
    : _requestService = requestService ?? RequestService(),
      _chatService = chatService ?? ChatService();

  bool _isLoading = false;
  String? _errorMessage;

  List<BuddyRequest> _myRequests = [];
  List<BuddyRequest> _offers = [];
  List<BuddyRequest> _myTasks = [];

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<BuddyRequest> get myRequests => List.unmodifiable(_myRequests);

  List<BuddyRequest> get offers => List.unmodifiable(_offers);

  List<BuddyRequest> get myTasks => List.unmodifiable(_myTasks);

  // =========================================================
  // CREATE REQUEST
  // =========================================================

  Future<bool> createRequest(BuddyRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestService.createRequest(request);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // =========================================================
  // MY REQUESTS
  // =========================================================

  Future<void> loadMyRequests(String requesterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myRequests = await _requestService.getMyRequests(requesterId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // OFFERS
  // =========================================================

  Future<void> loadOffers(String currentUserId, String? currentUserCity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (currentUserCity == null || currentUserCity.trim().isEmpty) {
      _offers = [];

      _errorMessage =
          'Please add your city in your profile before viewing offers.';

      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _offers = await _requestService.getPublicRequests(
        currentUserId,
        currentUserCity,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // ACCEPT REQUEST + CREATE CHAT
  // =========================================================

  Future<bool> acceptRequest({
    required BuddyRequest request,
    required String buddyId,
    required String buddyName,
  }) async {
    if (request.id == null) {
      _errorMessage = 'This request does not have a valid ID.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Mark the request as accepted first.
      await _requestService.acceptRequest(
        requestId: request.id!,
        buddyId: buddyId,
      );

      // 2. Automatically create the chat room for this request.
      await _chatService.createConversation(
        request: request,
        buddyId: buddyId,
        buddyName: buddyName,
      );

      // 3. Remove it from the offers board after successful acceptance.
      _offers.removeWhere((item) => item.id == request.id);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // MY TASKS
  // =========================================================

  Future<void> loadMyTasks(String buddyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myTasks = await _requestService.getMyTasks(buddyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // =========================================================
  // DELETE PENDING REQUEST
  // =========================================================

  Future<bool> deleteRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestService.deleteRequest(requestId);

      _myRequests.removeWhere((request) => request.id == requestId);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // CANCEL ACCEPTED REQUEST
  // =========================================================

  Future<bool> cancelRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestService.cancelRequest(requestId);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // COMPLETE ACCEPTED REQUEST
  // =========================================================

  Future<bool> completeRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestService.completeRequest(requestId);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // FEEDBACK
  // =========================================================

  Future<bool> submitRequesterFeedback({
    required String requestId,
    required int rating,
    required String feedback,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestService.submitRequesterFeedback(
        requestId: requestId,
        rating: rating,
        feedback: feedback,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitBuddyFeedback({
    required String requestId,
    required int rating,
    required String feedback,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestService.submitBuddyFeedback(
        requestId: requestId,
        rating: rating,
        feedback: feedback,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
