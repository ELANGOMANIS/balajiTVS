import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart'as http;
import 'main.dart';



class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  final _formKey = GlobalKey<FormState>();
  TextEditingController companyName =TextEditingController();
  TextEditingController address =TextEditingController();
  TextEditingController contact =TextEditingController();
  TextEditingController mailId =TextEditingController();
  TextEditingController gstNo =TextEditingController();
  TextEditingController tinNo =TextEditingController();
  TextEditingController cstNo =TextEditingController();
  TextEditingController bankName =TextEditingController();
  TextEditingController accNo =TextEditingController();
  TextEditingController branch =TextEditingController();
  TextEditingController ifscCode =TextEditingController();
  TextEditingController companySearch =TextEditingController();
  TextEditingController uid =TextEditingController();
  String selectedCompany = '';
  Map<String,dynamic> profileData ={};

  Future<void> insert(Map<String,dynamic> profileData) async{
    const String apiUrl = 'http://localhost:3309/company_profile';
    try{
      final response = await http.post(Uri.parse(apiUrl),
        headers:<String,String>{
          'Content-Type':'application/json; charset=UTF-8',
        },
        body:jsonEncode({'profileData': profileData }),
      );
      if (response.statusCode == 200) {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: const Text('Saved Successfully'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Profile()),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        print('Failed to Table insert data');
        throw Exception('Failed to Table insert data');
      }
    }
    catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
  Future<void> personalDataInsert()async{
    List<Future<void>> insertFutures = [];
    Map<String, dynamic> myData = {
      'companyName':companyName.text,
      'address':address.text,
      'contact':contact.text,
      'mailId':mailId.text,
      'gstNo':gstNo.text,
      'tinNo':tinNo.text,
      'cstNo':cstNo.text,
      'bankName':bankName.text,
      'accNo':accNo.text,
      'branch':branch.text,
      'ifscCode':ifscCode.text,
      'uid':uid.text,
    };
    insertFutures.add(insert(myData));
    await Future.wait(insertFutures);
  }

  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];

  void filterData(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        filteredData = data;
        companyName.clear();
        address.clear();
        contact.clear();
        mailId.clear();
        gstNo.clear();
        tinNo.clear();
        cstNo.clear();
        bankName.clear();
        accNo.clear();
        branch.clear();
        ifscCode.clear();
        uid.clear();
      } else {
        final existingSupplier = data.firstWhere(
              (item) => item['companyName']?.toString() == searchText,
          orElse: () => {},
        );
        if (existingSupplier.isNotEmpty) {
          companyName.text = existingSupplier['companyName']?.toString() ?? '';
          address.text = existingSupplier['address']?.toString() ?? '';
          contact.text = existingSupplier['contact']?.toString() ?? '';
          mailId.text = existingSupplier['mailId']?.toString() ?? '';
          gstNo.text = existingSupplier['gstNo']?.toString() ?? '';
          tinNo.text = existingSupplier['tinNo']?.toString() ?? '';
          cstNo.text = existingSupplier['cstNo']?.toString() ?? '';
          bankName.text = existingSupplier['bankName']?.toString() ?? '';
          accNo.text = existingSupplier['accNo']?.toString() ?? '';
          branch.text = existingSupplier['branch']?.toString() ?? '';
          ifscCode.text = existingSupplier['ifscCode']?.toString() ?? '';
          uid.text = existingSupplier['id']?.toString() ?? '';
        } else {
        }
      }
    });
  }
  String? userid;
  Future<void> fetchData() async {
    try {
      final url = Uri.parse('http://localhost:3309/company_fetch/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itemGroups = responseData;

        setState(() {
          data = itemGroups.cast<Map<String, dynamic>>();
        });
        companySearch.text= data[0]['companyName'].toString();
        print('Data: $data');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }

  Future<bool>checkForDuplicateCompany(String uid) async {
    List<dynamic> sizeData = await fetchUid();
    for (var item in sizeData) {
      if (item['uid'] == uid) {
        return true; // Size already exists, return true
      }
    }
    return false; // Size is unique, return false
  }

  Future<List<Map<String, dynamic>>> fetchUid() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/fetch_company_duplicate'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error loading color entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load color entries: $e');
    }
  }
  Future<void> updateCompany(
      String uid,
      String companyName,
      String address,
      String contact,
      String mailId,
      String gstNo,
      String tinNo,
      String cstNo,
      String bankName,
      String accNo,
      String branch,
      String ifscCode,

      ) async {
    final Uri url = Uri.parse('http://localhost:3309/company_update');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'uid':uid,
        'companyName':companyName,
        'address':address,
        'contact':contact,
        'mailId':mailId,
        'gstNo':gstNo,
        'tinNo':tinNo,
        'cstNo':cstNo,
        'bankName':bankName,
        'accNo':accNo,
        'branch':branch,
        'ifscCode':ifscCode,
      }),
    );

    if (response.statusCode == 200) {
      print("Update Successful");
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Sales"),
            content: const Text(
                "Update Successfully"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const Profile()));
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      print('Failed to update. Status code: ${response.statusCode}');
      throw Exception('Failed to update purchase entry');
    }
  }


  @override
  void initState() {
    super.initState();
    fetchData();
  }
  @override
  Widget build(BuildContext context) {
    companySearch.addListener(() {
      filterData(companySearch.text);
    });
    bool isCompanySearchNotEmpty = companySearch.text.isEmpty;
    return  MyScaffold(
      route: "settings_entry",
      backgroundColor: Colors.white,
      body: Form(
          key: _formKey,
          child: Center(
            child: Column(
              children: [
                /*    Container(
            margin: EdgeInsets.all(8.0),
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company Name: ${data[0]['companyName']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Address: ${data[0]['address']}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),*/
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 500,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey), // Add a border for the box
                      borderRadius: BorderRadius.circular(10.0), // Add border radius for rounded corners
                    ),
                    child: Column(
                        children: [
                          SizedBox(height: 10,),
                          const Text("Company Info", style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),),
                          SizedBox(height: 15,),

                          /* Padding(
                            padding: const EdgeInsets.only(left: 160),
                            child: SizedBox(
                              width: 140,
                              child: TypeAheadFormField<String>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  controller: companySearch, // Use the controller for kvinvoice
                                  style: const TextStyle(fontSize: 13),
                                  onChanged: (value) {
                                    setState(() {
                                    });
                                  },
                                  inputFormatters: [
                                    UpperCaseTextFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    fillColor: Colors.white,
                                    filled: true,
                                    labelText: "Find", // Change the label text for kvinvoice
                                    labelStyle: TextStyle(fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                suggestionsCallback: (pattern) async {
                                  List<String> suggestions;
                                  if (pattern.isNotEmpty) {
                                    suggestions = data
                                        .where((item) =>
                                        (item['companyName']?.toString()?.toLowerCase() ?? '').startsWith(pattern.toLowerCase()))
                                        .map((item) => item['companyName'].toString())
                                        .toSet()
                                        .toList();
                                    suggestions = suggestions.take(5).toList();
                                  } else {
                                    suggestions = [];
                                  }
                                  return suggestions;
                                },
                                itemBuilder: (context, suggestion) {
                                  return ListTile(
                                    title: Text(suggestion),
                                  );
                                },
                                onSuggestionSelected: (suggestion) {
                                  setState(() {
                                    selectedCompany = suggestion;
                                    companySearch.text = suggestion;
                                  });
                                  print('Selected Kvinvoice: $selectedCompany');
                                },
                              ),
                            ),
                          ),*/
                          SizedBox(height: 10,),

                          Column(
                            children: [
                              // SizedBox(
                              //   width: 300,
                              //   child: TextFormField(
                              //     controller: uid,
                              //     enabled: isCompanySearchNotEmpty,
                              //     validator: (value) {
                              //       if (value!.isEmpty) {
                              //         return '* Enter Company id';
                              //       }
                              //       return null;
                              //     },
                              //     style: const TextStyle(fontSize: 12),
                              //     decoration: InputDecoration(
                              //       labelText: "Company Id",
                              //       border: OutlineInputBorder(
                              //         borderRadius: BorderRadius.circular(10),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: companyName,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return '* Enter Company Name';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // Validate the form on every text change
                                    _formKey.currentState?.validate();
                                  },
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    labelText: "Company Name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: address,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return '* Enter Address';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // Validate the form on every text change
                                    _formKey.currentState?.validate();
                                  },
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null, // Allow multiple lines
                                  decoration: InputDecoration(
                                    labelText: "Address",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: contact,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "* Enter Mobile Number";
                                    }  else{
                                      return null;}
                                  },
                                  onChanged: (value) {
                                    // Validate the form on every text change
                                    _formKey.currentState?.validate();
                                  },
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    labelText: "Contact ",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    LengthLimitingTextInputFormatter(50)
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: mailId,
                                  // validator: (value) {
                                  //   if (value == null || value.trim().isEmpty) {
                                  //     return '* Enter your Email Address';
                                  //   }
                                  //   // Check if the entered email has the right format and domain
                                  //   if (!RegExp(r'^[\w-\.]+@(gmail\.com|yahoo\.com)$').hasMatch(value)) {
                                  //     return '* Enter a valid mail Address';
                                  //   }
                                  //   // Return null if the entered email is valid
                                  //   return null;
                                  // },
                                  // onChanged: (value) {
                                  //   // Validate the form on every text change
                                  //   _formKey.currentState?.validate();
                                  // },
                                  style: const TextStyle(fontSize: 12),

                                  decoration: InputDecoration(
                                    labelText: "Mail Id",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: gstNo,
                                  // validator: (value) {
                                  //   if (value!.isEmpty) {
                                  //     return '* Enter GST No';
                                  //   }
                                  //   return null;
                                  // },
                                  // onChanged: (value) {
                                  //   // Validate the form on every text change
                                  //   _formKey.currentState?.validate();
                                  // },
                                  style: const TextStyle(fontSize: 12),

                                  decoration: InputDecoration(
                                    labelText: "GST No",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: tinNo,

                                  style: const TextStyle(fontSize: 12),

                                  decoration: InputDecoration(
                                    labelText: "TIN No",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: cstNo,

                                  style: const TextStyle(fontSize: 12),

                                  decoration: InputDecoration(
                                    labelText: "CST No ",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: bankName,
                                  // validator: (value) {
                                  //   if (value!.isEmpty) {
                                  //     return '* Enter Bank Name';
                                  //   }
                                  //   return null;
                                  // },
                                  style: const TextStyle(fontSize: 12),
                                  // onChanged: (value) {
                                  //   // Validate the form on every text change
                                  //   _formKey.currentState?.validate();
                                  // },
                                  decoration: InputDecoration(
                                    labelText: "Bank Name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: accNo,
                                  // validator: (value) {
                                  //   if (value!.isEmpty) {
                                  //     return '* Enter Account No';
                                  //   }
                                  //   return null;
                                  // },
                                  style: const TextStyle(fontSize: 12),
                                  // onChanged: (value) {
                                  //   // Validate the form on every text change
                                  //   _formKey.currentState?.validate();
                                  // },
                                  decoration: InputDecoration(
                                    labelText: "Account No",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: branch,
                                  // validator: (value) {
                                  //   if (value!.isEmpty) {
                                  //     return '* Enter Branch';
                                  //   }
                                  //   return null;
                                  // },
                                  style: const TextStyle(fontSize: 12),
                                  // onChanged: (value) {
                                  //   // Validate the form on every text change
                                  //   _formKey.currentState?.validate();
                                  // },
                                  decoration: InputDecoration(
                                    labelText: "Branch",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: ifscCode,
                                  // validator: (value) {
                                  //   // Regular expression to validate IFSC code
                                  //   final ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
                                  //   if (!ifscPattern.hasMatch(value!)) {
                                  //     return '* Enter a valid IFSC Code';
                                  //   }
                                  //   return null;
                                  // },
                                  onChanged: (value) {
                                    _formKey.currentState?.validate();
                                  },
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    labelText: "IFSC Code",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10,),
                          Wrap(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MaterialButton(
                                color:Colors.green,onPressed: () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  String enteredUid = uid.text;
                                  bool uidIsDuplicate = await checkForDuplicateCompany(
                                      enteredUid);
                                  if (uidIsDuplicate) {
                                    updateCompany(
                                      uid.text,
                                      companyName.text,
                                      address.text,
                                      contact.text,
                                      mailId.text,
                                      gstNo.text,
                                      tinNo.text,
                                      cstNo.text,
                                      bankName.text,
                                      accNo.text,
                                      branch.text,
                                      ifscCode.text,
                                    );
                                  }
                                  else {
                                    personalDataInsert();
                                  }
                                }
                              },child: Text("Submit",style: TextStyle(color: Colors.white),),),
                              SizedBox(width: 15,),

                              MaterialButton(
                                color: Colors.red.shade600,
                                onPressed: (){
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) =>Profile()));
                                },child: Text("Cancel",style: TextStyle(color: Colors.white),),)
                            ],
                          ),
                          SizedBox(height: 15,),
                        ]),
                  ),
                ),
              ],
            ),
          )
      ),
    );
  }
}
///
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text?.toUpperCase() ?? '', // Convert to uppercase
      selection: newValue.selection,
    );
  }
}
