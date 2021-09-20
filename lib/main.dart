import 'dart:typed_data';

import 'package:animation_maker/my_animation.dart';
import 'package:animation_maker/parse_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Point {
  late Offset pos;
  Offset posStart = Offset(0, 0);
  Offset posBefore = Offset(0, 0);
  VoidCallback? callback;
  void Function(Point)? remove;

  Point(this.pos, {this.callback, this.remove});

  Offset getPos(Size size) {
    return Offset(
      pos.dx * size.width,
      pos.dy * size.height,
    );
  }

  bool panDown = false;

  Widget build(BuildContext context, int index, Color color) {
    var size = MediaQuery.of(context).size;
    var _pos = getPos(size);
    return Positioned(
        bottom: _pos.dy - 15 / 2,
        left: _pos.dx - 15 / 2,
        width: 15,
        height: 15,
        child: GestureDetector(
          onPanDown: (details) {
            panDown = true;
            posStart = details.globalPosition;
            posBefore = pos;
          },
          onPanUpdate: (details) {
            if (panDown) {
              var d = details.globalPosition - posStart;
              pos = posBefore + Offset(d.dx / size.width, -d.dy / size.height);
              callback?.call();
            }
          },
          onPanCancel: () {
            panDown = false;
          },
          onPanEnd: (details) {
            panDown = false;
          },
          onDoubleTap: () {
            remove?.call(this);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
                child: Text(
              '$index',
              style: TextStyle(fontSize: 10, color: Colors.white),
            )),
          ),
        ));
  }
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<List<Point>> points = [];
  int currIndex = 0;
  late AnimationController animation;
  StateSetter? mySetState;
  MyAnimation myAnimation = MyAnimation();
  Uint8List? bgImage;

  _MyHomePageState() {
    points.add([]);
    initPoints();
  }

  void callBack() {
    setState(() {});
  }

  void initPoints() {
    List<Point> lst = points[currIndex];
    lst.clear();
    lst.addAll([
      Point(Offset(0, 0.5), callback: callBack),
      Point(Offset(1, 0.5), callback: callBack),
    ]);
  }

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    animation.addListener(updateAnimation);
    animation.repeat();
  }

  void updateAnimation() {
    mySetState?.call(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (bgImage != null)
            SizedBox.expand(
                child: Image.memory(
              bgImage!,
              fit: BoxFit.fill,
            )),
          SizedBox.expand(child: buildLine()),
          StatefulBuilder(
            builder: (context, setState) {
              mySetState = setState;
              return SizedBox.expand(
                child: Stack(
                  children: buildAnimation(),
                ),
              );
            },
          ),
          SizedBox.expand(
            child: GestureDetector(
              onPanDown: (detail) {
                print(detail);
              },
              onTapUp: (detail) {
                print(detail);
                var size = MediaQuery.of(context).size;
                setState(() {
                  Point p = Point(
                      Offset(detail.globalPosition.dx / size.width,
                          1 - detail.globalPosition.dy / size.height),
                      callback: callBack, remove: (item) {
                    setState(() {
                      points[currIndex].remove(item);
                      sort();
                    });
                  });
                  points[currIndex].add(p);
                  sort();
                });
              },
            ),
          ),
          ...buildPoint(),
          Positioned(
            bottom: 20,
            left: 30,
            child: Container(
              width: 50,
              height: 5,
              color: getColorIndex(currIndex),
            ),
          ),
          Positioned(
              bottom: 30,
              left: 30,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () {
                          if (points.length == 1) return;
                          currIndex = (currIndex + 1) % points.length;
                          setState(() {});
                        },
                        child: FittedBox(
                          child: Text(
                            'Chg Idx',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            initPoints();
                          });
                        },
                        child: FittedBox(
                          child: Text(
                            'Reset',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () async {
                          final ImagePicker _picker = ImagePicker();
                          // Pick an image
                          final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            bgImage = await image.readAsBytes();
                            setState(() {});
                          }
                        },
                        child: FittedBox(
                          child: Text(
                            'Image',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () {
                          String code = MyAnimation.genCode(points
                              .map((e) => e.map((l) => l.pos).toList())
                              .toList());
                          Clipboard.setData(ClipboardData(text: code));
                        },
                        child: FittedBox(
                          child: Text(
                            'Code',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () {
                          String code = MyAnimation.genCode(
                              points
                                  .map((e) => e.map((l) => l.pos).toList())
                                  .toList(),
                              onlyArray: true);
                          Clipboard.setData(ClipboardData(text: code));
                        },
                        child: FittedBox(
                          child: Text(
                            'Point',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () {
                          points.add([]);
                          currIndex = points.length - 1;
                          initPoints();
                          setState(() {});
                        },
                        child: FittedBox(
                          child: Text(
                            'Add',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () {
                          if (points.length > 1) {
                            points.removeAt(currIndex);
                            if (currIndex > points.length - 1) {
                              currIndex = points.length - 1;
                            }
                            setState(() {});
                          }
                        },
                        child: FittedBox(
                          child: Text(
                            'Del',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FloatingActionButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController txtController =
                                  TextEditingController();
                              return Dialog(
                                child: SizedBox(
                                  width: 50,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Code: '),
                                          Expanded(
                                            child: TextField(
                                              controller: txtController,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  var listAnimationString =
                                                      ParseString.parse(
                                                          txtController.text,
                                                          '[',
                                                          ']');
                                                  if (listAnimationString
                                                      .isEmpty) return;
                                                  List<List<Point>> newPoint =
                                                      [];
                                                  listAnimationString.forEach(
                                                      (animationString) {
                                                    List<Offset> lstOffset = [];
                                                    var offsets =
                                                        ParseString.parse(
                                                            animationString,
                                                            '(',
                                                            ')');
                                                    offsets.forEach((dx_dy) {
                                                      var number =
                                                          dx_dy.split(',');
                                                      if (number.length == 2) {
                                                        lstOffset.add(Offset(
                                                            double.parse(
                                                                number[0]
                                                                    .trim()),
                                                            double.parse(
                                                                number[1]
                                                                    .trim())));
                                                      }
                                                    });
                                                    if (lstOffset.isNotEmpty) {
                                                      int index =
                                                          newPoint.length;
                                                      newPoint.add(
                                                          lstOffset.map((pos) {
                                                        return Point(pos,
                                                            callback: callBack,
                                                            remove: (item) {
                                                          setState(() {
                                                            points[index]
                                                                .remove(item);
                                                            sort();
                                                          });
                                                        });
                                                      }).toList());
                                                    }
                                                  });
                                                  if (newPoint.isNotEmpty) {
                                                    points = newPoint;
                                                    sort();
                                                    setState(() {});
                                                  }
                                                },
                                                child: Text('OK')),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: FittedBox(
                          child: Text(
                            'In',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ))
        ],
      ),
    );
  }

  List<Widget> buildPoint() {
    List<Widget> ret = [];
    for (int i = 0; i < points.length; i++) {
      var curr = points[i];
      var color = getColorIndex(i);
      for (int j = 0; j < curr.length; j++) {
        ret.add(curr[j].build(context, j, color));
      }
    }
    return ret;
  }

  Widget buildLine() {
    List<Widget> children = [];
    for (int i = 0; i < points.length; i++) {
      var item = points[i];
      children.add(CustomPaint(
        painter: MyCustomPainter(item, getColorIndex(i)),
        child: SizedBox.expand(),
      ));
    }
    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: children,
        ),
      ),
    );
  }

  void sort() {
    points.forEach((e) {
      e.sort((o1, o2) {
        if (o1.pos.dx > o2.pos.dx) {
          return 1;
        } else if (o1.pos.dx < o2.pos.dx) {
          return -1;
        } else {
          return 0;
        }
      });
    });
  }

  Color getColorIndex(int i) {
    List<Color> colors = [
      Colors.orangeAccent,
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.blueGrey,
      Colors.cyanAccent,
      Colors.pink,
      Colors.deepOrange,
    ];
    return colors[i % colors.length];
  }

  List<Widget> buildAnimation() {
    List<Widget> ret = [];
    for (int i = 0; i < points.length; i++) {
      var color = getColorIndex(i);
      var lst = points[i];
      myAnimation.points = lst.map((e) => e.pos).toList();
      ret.addAll([
        Positioned(
            right: 40,
            bottom: myAnimation.transform(animation.value) * 80,
            child: Icon(
              Icons.circle,
              color: color,
              size: 20,
            )),
        Positioned(
            bottom: 40,
            right: 100 + myAnimation.transform(animation.value) * 80,
            child: Icon(
              Icons.circle,
              color: color,
              size: 20,
            )),
      ]);
    }
    return ret;
  }
}

class MyCustomPainter extends CustomPainter {
  final List<Point> points;
  final Color color;

  MyCustomPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    for (int i = 0; i < points.length; i++) {
      var pos = points[i].getPos(size);
      pos = Offset(pos.dx, size.height - pos.dy);
      if (i == 0) {
        path.moveTo(pos.dx, pos.dy);
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
