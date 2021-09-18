import 'dart:typed_data';

import 'package:animation_maker/test.dart';
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

  Widget build(BuildContext context, int index) {
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
              color: Colors.green,
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
  List<Point> points = [];
  late AnimationController animation;
  StateSetter? mySetState;
  MyAnimation myAnimation = MyAnimation();
  Uint8List? bgImage;

  _MyHomePageState() {
    initPoints();
  }

  void callBack() {
    setState(() {});
  }

  void initPoints() {
    points = [
      Point(Offset(0, 0.5), callback: callBack),
      Point(Offset(1, 0.5), callback: callBack),
    ];
  }

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
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
              myAnimation.points = points.map((e) => e.pos).toList();
              return Positioned(
                  right: 40,
                  bottom: myAnimation.transform(animation.value) * 80,
                  child: Icon(
                    Icons.circle,
                    color: Colors.blue,
                    size: 20,
                  ));
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
                      points.remove(item);
                      sort();
                    });
                  });
                  points.add(p);
                  sort();
                });
              },
            ),
          ),
          ...buildPoint(),
          Positioned(
              bottom: 30,
              left: 30,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          initPoints();
                        });
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 20,),
                  SizedBox(
                    width: 40,
                    height: 40,
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
                      child: Text(
                        'Image',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 20,),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      onPressed: () {
                        String code = MyAnimation.genCode(points.map((e) => e.pos).toList());
                        Clipboard.setData(ClipboardData(text: code));
                      },
                      child: Text(
                        'Code',
                        style: TextStyle(fontSize: 12),
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
      ret.add(points[i].build(context, i));
    }
    return ret;
  }

  Widget buildLine() {
    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: CustomPaint(
          painter: MyCustomPainter(points),
          child: SizedBox.expand(),
        ),
      ),
    );
  }

  void sort() {
    points.sort((o1, o2) {
      if (o1.pos.dx > o2.pos.dx) {
        return 1;
      } else if (o1.pos.dx < o2.pos.dx) {
        return -1;
      } else {
        return 0;
      }
    });
  }
}

class MyCustomPainter extends CustomPainter {
  final List<Point> points;

  MyCustomPainter(this.points);

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
      ..color = Colors.deepOrange
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
