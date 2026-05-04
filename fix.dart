import 'dart:io';
import 'dart:convert';

void main() {
  String badString = 'Trang chĂ¡Â»Â§';
  try {
    // Reverse double mojibake
    // step 1: encode to latin1 (which is close to cp1252 for these chars)
    List<int> bytes1 = latin1.encode(badString);
    String midString = utf8.decode(bytes1);
    
    List<int> bytes2 = latin1.encode(midString);
    String goodString = utf8.decode(bytes2);
    print("FIXED: \$goodString");
  } catch (e) {
    print("Error: \$e");
  }
}
