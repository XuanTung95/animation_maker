import 'dart:ui';
import 'package:flutter/animation.dart';

class MyAnimation extends Animatable<double> {
  List<Offset> points = [];
  int idx = 0;

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

  static String genCode(List<Offset> points) {
    String code = '''
    import 'dart:ui';
    import 'package:flutter/animation.dart';
    
    class MyAnimation extends Animatable<double> {
      List<Offset> points = [POINTS_GO_HERE];
      int idx = 0;
    
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
    points.forEach((e) {
      str += 'Offset(${e.dx},${e.dy}),';
    });
    code = code.replaceFirst('POINTS_GO_HERE', str);
    return code;
  }
}
