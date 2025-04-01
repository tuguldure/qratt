import 'dart:io';
import 'dart:js';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_att/model/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color.fromRGBO(108, 53, 222, 1);
  String birth = "Date of birth";

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  void pickUploadProfilePic() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxHeight: 512,
      maxWidth: 512,
      imageQuality: 90,
    );

    Reference ref = FirebaseStorage.instance
        .ref()
        .child("${User.studentID.toLowerCase()}_profilepic.jpg");

    await ref.putFile(File(image!.path));
    ref.getDownloadURL().then((value) async {
      setState(() {
        User.profilePicLink = value;
      });

      await FirebaseFirestore.instance
          .collection("student")
          .doc(User.id)
          .update({
        'profilePic': value,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 80, bottom: 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                pickUploadProfilePic();
              },
              child: Container(
                height: 120,
                width: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: primary,
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: User.profilePicLink == " "
                        ? Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 80,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(User.profilePicLink),
                          ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Student ${User.studentID}",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(
              height: 24,
            ),
            User.canEdit
                ? textField("First Name", "First name", firstNameController)
                : field("First Name", User.firstName),
            User.canEdit
                ? textField("Last Name", "Last name", lastNameController)
                : field("Last Name", User.lastName),
            User.canEdit
                ? GestureDetector(
                    onTap: () {
                      showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primary,
                                    secondary: primary,
                                    onSecondary: Colors.white,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: primary,
                                    ),
                                  ),
                                  textTheme: const TextTheme(
                                      headlineMedium: TextStyle(
                                        fontFamily: "NexaBold",
                                      ),
                                      labelSmall: TextStyle(
                                        fontFamily: "NexaBold",
                                      ),
                                      labelLarge: TextStyle(
                                        fontFamily: "NexaBold",
                                      ))),
                              child: child!,
                            );
                          }).then((value) {
                        setState(() {
                          birth = DateFormat("MM/dd/yyyy").format(value!);
                        });
                      });
                    },
                    child: field("Date of birth", birth),
                  )
                : field("Date of birth", User.birthDate),
            User.canEdit
                ? textField("Address", "Address", addressController)
                : field("Address", User.address),
            User.canEdit
                ? GestureDetector(
                    onTap: () async {
                      String firstName = firstNameController.text;
                      String lastName = lastNameController.text;
                      String birthDate = birth;
                      String address = addressController.text;

                      if (User.canEdit) {
                        if (firstName.isEmpty) {
                          showSnackBar("Please enter your first name!");
                        } else if (lastName.isEmpty) {
                          showSnackBar("Please enter your last name!");
                        } else if (birthDate.isEmpty) {
                          showSnackBar("Please enter your birth name!");
                        } else if (address.isEmpty) {
                          showSnackBar("Please enter your address!");
                        } else {
                          await FirebaseFirestore.instance
                              .collection("student")
                              .doc(User.id)
                              .update({
                            'firstName': firstName,
                            'lastName': lastName,
                            'birthDate': birthDate,
                            'address': address,
                            'canEdit': false,
                          }).then((value) {
                            setState(() {
                              User.canEdit = false;
                              User.firstName = firstName;
                              User.lastName = lastName;
                              User.birthDate = birthDate;
                              User.address = address;
                            });
                          });
                        }
                      } else {
                        showSnackBar(
                            "You can't edit anymore, please contact support team.");
                      }
                    },
                    child: Container(
                      height: kToolbarHeight,
                      width: screenWidth,
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: primary,
                      ),
                      child: Center(
                        child: Text(
                          "SAVE",
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}

Widget field(String title, String text) {
  return Column(
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "NexaBold",
            color: Colors.black54,
          ),
        ),
      ),
      Container(
        height: kToolbarHeight,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.only(left: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.black54,
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget textField(String title, String hint, TextEditingController controller) {
  return Column(
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "NexaBold",
            color: Colors.black54,
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          cursorColor: Colors.black54,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black54,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.black54,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

void showSnackBar(String text) {
  ScaffoldMessenger.of(context as BuildContext).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        text,
      ),
    ),
  );
}
