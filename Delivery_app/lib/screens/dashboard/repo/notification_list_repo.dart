import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';

class NotificationListRepo {
  Future<dynamic> getAllNotifications({int? page, int? perPage}) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
      };

      final response = await ApiBaseHelper.getApi(
        url: notificationsApi,
        params: queryParameters,
        useAuthToken: true,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getUnreadCount() async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: '$notificationsApi/unread-count',
        useAuthToken: true,
        params: {},
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> markAsRead(String id) async {
    try {
      final response = await ApiBaseHelper.post(
        url: '$notificationsApi/$id/read',
        useAuthToken: true,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> markAsUnRead(String id) async {
    try {
      final response = await ApiBaseHelper.post(
        url: '$notificationsApi/$id/unread',
        useAuthToken: true,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> markAllRead() async {
    try {
      final response = await ApiBaseHelper.post(
        url: '$notificationsApi/mark-all-read',
        useAuthToken: true,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
