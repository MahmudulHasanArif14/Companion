class UsernameGenerator{

  static String generateUsername(String base) {

    final random = DateTime.now().millisecondsSinceEpoch.remainder(10000);
    return '${base.toLowerCase().replaceAll(RegExp(r'\W+'), '')}$random';
  }



}