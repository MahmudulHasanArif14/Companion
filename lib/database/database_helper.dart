
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseHelperProvider extends ChangeNotifier {
  // global Instance of supabase
  final supBaseInstance = Supabase.instance.client;

  //encapsulation data
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  Map<String,dynamic>? _userInfo;
  Map<String,dynamic>? get userInfo => _userInfo;



  // data fetching or not status
  bool _isLoading = false;
  bool get isLoading => _isLoading;


  //data fetch error
  String? _error;
  String? get error => _error;




  Future<void> fetchSpecificUser(String userName) async {

    _profile = null;
    notifyListeners();

    _setLoading(true);
    try {


      final currentUser = supBaseInstance.auth.currentUser;
      if(currentUser==null) return;
      final currentUserId = currentUser.id;

    final data = await supBaseInstance
        .from('profiles')
        .select('*')
        .eq('username', userName)
        .neq('id', currentUserId)
        .maybeSingle();

      if (data != null) {
        print('User found: ${data['username']}');
        _profile = data;
        _error = null;
        notifyListeners();
      } else {
        print('No user found with that username');
      }


    } catch (e) {
      _error = "Failed to fetch profile: $e";
    } finally {
      _setLoading(false);
    }
  }





  Future<void> fetchUserInfo() async {

    _userInfo = null;
    notifyListeners();

    _setLoading(true);
    try {

      final currentUser = supBaseInstance.auth.currentUser;
      if(currentUser==null) return;
      final currentUserId = currentUser.id;

      final data = await supBaseInstance
          .from('profiles')
          .select('*')
          .eq('id', currentUserId).maybeSingle();

      if (data != null) {
        if (kDebugMode) {
          print('User found: ${data['username']}');
        }
        _userInfo = data;
        _error = null;
        notifyListeners();
      } else {
        print('No user found with that username');
      }


    } catch (e) {
      _error = "Failed to fetch profile: $e";
    } finally {
      _setLoading(false);
    }
  }







  /// Update a specific field for the current user
  Future<void> updateUserField(String fieldKey, dynamic newValue) async {
    final userId = supBaseInstance.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supBaseInstance
          .from('profiles')
          .update({fieldKey: newValue})
          .eq('id', userId);



      notifyListeners();

      if (response == null) {
        _error = "Failed to update $fieldKey: ${response.error!.message}";
      } else {
        _error = null;
      }
    } catch (e) {
      _error = "Failed to update field: $e";
    }
  }




























  /// Handle loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearData() {
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }





}
