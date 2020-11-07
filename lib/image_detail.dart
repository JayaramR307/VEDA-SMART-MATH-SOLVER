import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:http/http.dart' as http;



class DetailScreen extends StatefulWidget {
  final String imagePath;
  DetailScreen(this.imagePath);

  @override
  _DetailScreenState createState() => new _DetailScreenState(imagePath);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this.path);

  final String path;
  String text = "";
  Size _imageSize;
  List data;
  List<TextElement> _elements = [];
  String recognizedText = "Loading ...";
  bool isLoaded = false;
  bool match=false;

  void _initializeVision() async {
    final File imageFile = File(path);

    if (imageFile != null) {
      await _getImageSize(imageFile);
    }

    final FirebaseVisionImage visionImage =
    FirebaseVisionImage.fromFile(imageFile);

    final TextRecognizer textRecognizer =
    FirebaseVision.instance.textRecognizer();

    final VisionText visionText =
    await textRecognizer.processImage(visionImage);

    String pattern = r"^([a-zA-Z0-9().*-+]+={1}[a-zA-Z0-9().*-+]+)+$";
    RegExp regEx = RegExp(pattern);


    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        if (regEx.hasMatch(line.text)) {
          match=true;
          text += line.text;
          for (TextElement element in line.elements) {
            _elements.add(element);
          }
        }
        else{
          text += line.text;
          for (TextElement element in line.elements) {
            _elements.add(element);
          }
        }
      }
    }
    if(match)
    {
      String api = 'https://math-solver-veda.herokuapp.com/solveEquation/';
      String url = api+text.replaceAll('\n', '');
      var response = await http.get(url);
      setState(() {
        data = jsonDecode(response.body);
        isLoaded = true;
        text='Recognized Expression: '+text+'\n'+data.join("\n");
        //print("*********************|${data}|*****************************");
      });
    }
    else{
      text= text +"\n\nWrong Expression!!! Please scan again!!!";
    }
    if (this.mounted) {
      setState(() {
        //recognizedText = mailAddress.replaceAll('\n', '');
        recognizedText = text;
      });
    }
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }
  @override
  void initState() {
    _initializeVision();
    //fetchData();
    super.initState();
    /*
    print('------------------------Recognized Text=${recognizedText}');
    print('------------------------JSON=${data}');
    print('------------------------'+api+recognizedText);*/
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("VEDA - Math Solver"),
      ),
      body: _imageSize != null
          ? Stack(
        children: <Widget>[
          Center(
            child: Container(
              width: double.maxFinite,
              color: Colors.black,
              child: CustomPaint(
                foregroundPainter:
                TextDetectorPainter(_imageSize, _elements),
                child: AspectRatio(
                  aspectRatio: _imageSize.aspectRatio,
                  child: Image.file(
                    File(path),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Scrollbar(
              child: Card(
                elevation: 3,
                color: Colors.white.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Solution",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        height: 200,
                        child: SingleChildScrollView(
                          child: Text(
                            recognizedText,
                            style: TextStyle(
                            fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      )
          : Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.elements);

  final Size absoluteImageSize;
  final List<TextElement> elements;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(TextContainer container) {
      return Rect.fromLTRB(
        container.boundingBox.left * scaleX,
        container.boundingBox.top * scaleY,
        container.boundingBox.right * scaleX,
        container.boundingBox.bottom * scaleY,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 5.0;

    for (TextElement element in elements) {
      canvas.drawRect(scaleRect(element), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return true;
  }
}





