class UsernameGenerator{

  static String generateUsername(String base) {

    final random = DateTime.now().millisecondsSinceEpoch.remainder(10000);
    // \W matches any non-word character only A-z  || a-z
    return '${base.toLowerCase().replaceAll(RegExp(r'\W+'), '')}$random';
  }



}