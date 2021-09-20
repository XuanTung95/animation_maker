
class ParseString {

  static List<String> parse(String input, String start, String end){
    List<String> ret = [];
    String curr = '';
    bool check = false;
    for (int i=0; i< input.length; i++ ) {
      if (input[i] == start) {
        check = true;
        continue;
      }
      if (input[i] == end) {
        check = false;
        ret.add(curr);
        curr = '';
        continue;
      }
      if (check) {
        curr += input[i];
      }
    }
    return ret;
  }
}