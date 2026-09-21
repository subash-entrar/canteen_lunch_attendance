class ApiHeaders {
  Future<Map<String, String>> build() async {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }
}
