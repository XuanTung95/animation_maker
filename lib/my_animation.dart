import 'dart:ui';
import 'package:flutter/animation.dart';

class CustomAnimation extends Animatable<double> {
  List<Offset> points;
  int _lastIdx = 0;

  CustomAnimation({this.points = const []});

  @override
  transform(double t) {
    // find the start and end point in the time line
    Offset? start;
    Offset end = points.last;
    int startIndex = 0;
    if (_lastIdx < points.length - 1 && t > points[_lastIdx].dx) {
      startIndex = _lastIdx + 1;
    }
    for (int i = startIndex; i < points.length; i++) {
      if (t <= points[i].dx) {
        end = points[i];
        _lastIdx = i;
        if (i > 0) {
          start = points[i - 1];
        }
        break;
      }
    }
    if (start == null) {
      // no start point
      return end.dy;
    } else {
      // calculate the output between start-end
      double tx = end.dx - start.dx;
      if (tx > 0) {
        return start.dy + (t - start.dx) * (end.dy - start.dy) / tx;
      }
    }
    return end.dy;
  }

  static String genCode(List<List<Offset>> list, {bool onlyArray = false}) {
    String code = '''
    import 'dart:ui';
    import 'package:flutter/animation.dart';
    
    POINTS_GO_HERE
    
    class CustomAnimation extends Animatable<double> {
      List<Offset> points;
      int _lastIdx = 0;
    
      CustomAnimation({this.points = const []});
    
      @override
      transform(double t) {
        Offset? start;
        Offset end = points.last;
        int startIndex = 0;
        if (_lastIdx < points.length - 1 && t > points[_lastIdx].dx) {
          startIndex = _lastIdx + 1;
        }
        for (int i = startIndex; i < points.length; i++) {
          if (t <= points[i].dx) {
            end = points[i];
            _lastIdx = i;
            if (i > 0) {
              start = points[i - 1];
            }
            break;
          }
        }
        if (start == null) {
          return end.dy;
        } else {
          double tx = end.dx - start.dx;
          if (tx > 0) {
            return start.dy + (t - start.dx) * (end.dy - start.dy) / tx;
          }
        }
        return end.dy;
      }
    }
    ''';
    String str = '';
    for(int i=0; i<list.length; i++){
      var points = list[i];
      str += 'var ANIMATION_$i = [';
      points.forEach((e) {
        str += 'Offset(${e.dx},${e.dy}), ';
      });
      str += '];\n';
    }
    if (onlyArray) {
      return str;
    } else {
      code = code.replaceFirst('POINTS_GO_HERE', str);
      return code;
    }
  }
}
