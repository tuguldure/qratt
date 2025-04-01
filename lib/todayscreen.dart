import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:qr_att/model/user.dart';
import 'package:permission_handler/permission_handler.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late double screenHeight;
  late double screenWidth;

  String checkIn = "--/--";
  String scanResult = " ";
  String lectureCode = " ";
  Timer? timer;
  // Location
  String locationMessage = '';
  late String lat;
  late String long;
  // University location
  final double minUniversityLatitude = 47.926200;
  final double maxUniversityLatitude = 47.926668;
  final double minUniversityLongitude = 106.883102;
  final double maxUniversityLongitude = 106.885400;

  Color primary = const Color.fromRGBO(108, 53, 222, 1);

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _getRecord();
    startTimer();
    _getCurrentLocation();
  }

  // Request location permission
  void _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isDenied || status.isRestricted) {
      // Handle denied or restricted permissions
    }
  }

  // Location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<bool> _isLocationWithinBoundary(Position currentPosition) async {
    double latitude = currentPosition.latitude;
    double longitude = currentPosition.longitude;

    // Check if latitude is within the defined range
    bool isLatitudeWithinRange = (latitude >= minUniversityLatitude &&
        latitude <= maxUniversityLatitude);
    print('Is latitude within range? $isLatitudeWithinRange');

    // Check if longitude is within the defined range
    bool isLongitudeWithinRange = (longitude >= minUniversityLongitude &&
        longitude <= maxUniversityLongitude);
    print('Is longitude within range? $isLongitudeWithinRange');

    // Return true if both latitude and longitude are within the defined range
    return isLatitudeWithinRange && isLongitudeWithinRange;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // QR section
  Future<void> scanQRandCheck() async {
    String result = " ";
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied || locationStatus.isRestricted) {
      return;
    }

    try {
      result = await FlutterBarcodeScanner.scanBarcode(
          "#FFFFFF", "Cancel", false, ScanMode.QR);
    } catch (e) {
      print("error");
    }
    setState(() {
      scanResult = result;
    });

    if (scanResult == lectureCode) {
      print("working");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atleast they are equal'),
        ),
      );
      Position currentPosition = await _getCurrentLocation();
      bool isWithinUniversity =
          await _isLocationWithinBoundary(currentPosition);
      if (isWithinUniversity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('location checking correctly'),
          ),
        );
        print('location check');

        QuerySnapshot snap = await FirebaseFirestore.instance
            .collection("student")
            .where('id', isEqualTo: User.studentID)
            .get();
        print('student get');
        DocumentSnapshot snap2 = await FirebaseFirestore.instance
            .collection("student")
            .doc(snap.docs[0].id)
            .collection("Record")
            .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
            .get();

        try {
          String checkIn = snap2['checkIn'];
          await FirebaseFirestore.instance
              .collection("student")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
              .update({
            'date': Timestamp.now(),
            'checkIn': checkIn,
            'location':
                GeoPoint(currentPosition.latitude, currentPosition.longitude),
          });
        } catch (e) {
          setState(() {
            checkIn = DateFormat('hh:mm').format(DateTime.now());
          });
          await FirebaseFirestore.instance
              .collection("student")
              .doc(snap.docs[0].id)
              .collection("Record")
              .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
              .set({
            'date': Timestamp.now(),
            'checkIn': DateFormat('hh:mm').format(DateTime.now()),
            'location':
                GeoPoint(currentPosition.latitude, currentPosition.longitude),
          });
        }
      } else {
        print("hud2");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check in at your school.'),
          ),
        );
      }
    } else {
      print("bolku bna");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong QR code'),
        ),
      );
    }
  }

  // Code generation
  void _getLectureCode() async {
    DocumentSnapshot snap = await FirebaseFirestore.instance
        .collection("lectures")
        .doc('Mobile Programming')
        .get();

    setState(() {
      lectureCode = snap['code'];
      print("lecture code:$lectureCode");
    });
  }

  // Key generation
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      print("timer check");
      // Generating random key
      final key = generateRandomKey(6);

      FirebaseFirestore.instance
          .collection("lectures")
          .doc("Mobile Programming")
          .update({"code": key}).then((_) {
        _getLectureCode();
      });
    });
  }

  String generateRandomKey(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _getRecord() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("student")
          .where('id', isEqualTo: User.studentID)
          .get();

      DocumentSnapshot snap2 = await FirebaseFirestore.instance
          .collection("student")
          .doc(snap.docs[0].id)
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .get();

      if (mounted) {
        setState(() {
          checkIn = snap2['checkIn'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          checkIn = "--/--";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 20,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Text(
                "Student ${User.studentID}",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Today's status",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Check In",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkIn,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Lecture Name",
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 20,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: DateTime.now().day.toString(),
                      style: TextStyle(
                        color: primary,
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 18,
                      ),
                    ),
                    TextSpan(
                      text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaBold",
                        fontSize: screenWidth / 20,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('hh:mm:ss a').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 20,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }),
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: Builder(
                builder: (context) {
                  return GestureDetector(
                    onTap: scanQRandCheck,
                    child: Center(
                      child: Container(
                        height: screenWidth / 2,
                        width: screenWidth / 2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.expand,
                                    size: 70,
                                    color: primary,
                                  ),
                                  Icon(
                                    FontAwesomeIcons.camera,
                                    size: 25,
                                    color: primary,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: Text(
                                  "Scan to check in",
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontFamily: "NexaRegular",
                                      fontSize: screenWidth / 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
