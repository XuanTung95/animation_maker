import 'dart:ui';
import 'package:flutter/animation.dart';

class MyAnimation extends Animatable<double> {
  List<Offset> points;
  int idx = 0;

  MyAnimation({this.points = const []});

  @override
  transform(double t) {
    Offset? start;
    Offset end = points.last;
    int si = 0;
    if (idx < points.length - 1 && t > points[idx].dx) {
      si = idx + 1;
    }
    for (int i = si; i < points.length; i++) {
      if (t <= points[i].dx) {
        end = points[i];
        idx = i;
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

  static String genCode(List<List<Offset>> list, {bool onlyArray = false}) {
    String code = '''
    import 'dart:ui';
    import 'package:flutter/animation.dart';
    
    POINTS_GO_HERE
    
    class MyAnimation extends Animatable<double> {
      List<Offset> points = [];
      int idx = 0;
    
      MyAnimation({this.points = const []});
    
      @override
      transform(double t) {
        Offset? start;
        Offset end = points.last;
        int si = 0;
        if (idx < points.length - 1 && t > points[idx].dx) {
          si = idx + 1;
        }
        for (int i = si; i < points.length; i++) {
          if (t <= points[i].dx) {
            end = points[i];
            idx = i;
            if (i>0) {
              start = points[i-1];
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
