class AppDateUtils {
  static int compareRocDate(String a, String b) {
    return a.compareTo(b);
  }

  static List<String> sortDesc(List<String> dates) {
    final copied = [...dates];

    copied.sort((a, b) => b.compareTo(a));

    return copied;
  }
}
