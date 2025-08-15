
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseHelperProvider extends ChangeNotifier {
  // global Instance of supabase
  final supBaseInstance = Supabase.instance.client;

  //encapsulation data
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

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
