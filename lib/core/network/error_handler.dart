class ErrorHandler {
  static String clean(dynamic e) {
    String errorString = e.toString();
    
    // Remove "Exception: "
    errorString = errorString.replaceAll('Exception: ', '');
    
    // Clean up ugly Dio network errors
    if (errorString.contains('DioException')) {
      if (errorString.contains('connection error') || 
          errorString.contains('SocketException') || 
          errorString.contains('Failed host lookup')) {
        return 'Network connection error. Please check your internet.';
      }
      if (errorString.contains('bad response')) {
        // If it's a generic bad response that wasn't caught by the custom backend error parser
        return 'Server error occurred. Please try again later.';
      }
      if (errorString.contains('connection timeout') || errorString.contains('receive timeout')) {
        return 'Connection timed out. Please try again.';
      }
      return 'A network error occurred.';
    }
    
    return errorString;
  }
}
