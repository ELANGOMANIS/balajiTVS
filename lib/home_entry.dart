import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'main.dart';

class HomeEntry extends StatefulWidget {
  const HomeEntry({Key? key}) : super(key: key);
  @override
  State<HomeEntry> createState() => _HomeEntryState();
}
class _HomeEntryState extends State<HomeEntry>{
  Widget build(BuildContext context) {
    return Scaffold(
      // Appbar starts
      appBar: AppBar(centerTitle: true,
        backgroundColor: Colors.purple.shade400,
        //(0xFF01B8A4),
        // Appbar title
        title: Text('Manage Driver'),

      ),
      // Appbar ends
      // Main content starts here
      body: Container(
        // decoration: BoxDecoration(
        //     gradient: LinearGradient(colors:[
        //       //Colors.pinkAccent.shade100,
        //       Colors.cyan.shade100,
        //       // Colors.pink.shade200,
        //        Colors.deepPurple.shade300
        //     ]
        //     )
        // ),
        decoration:  BoxDecoration(
          image:DecorationImage(
              image: const AssetImage('assets/bg22.svg'),
              colorFilter: ColorFilter.mode(
                Colors.white70.withOpacity(0.3),
                BlendMode.dstATop,
              ),
              fit: BoxFit.fill),),
        child: Center(
          child: Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              // color: Colors.purple.shade200,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                child: Card(
                  elevation: 0,
                  color: Colors.purple.withOpacity(0.2),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Flutter UI design',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


