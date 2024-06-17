import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../home.dart';
import '../main.dart';
class CheckItemGroupPage extends StatefulWidget {
  const CheckItemGroupPage({Key? key}) : super(key: key);
  @override
  State<CheckItemGroupPage> createState() => _CheckItemGroupPageState();
}
class _CheckItemGroupPageState extends State<CheckItemGroupPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MyScaffold(
        route: "/check_itempages",backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              children:  [
                Align(
                  alignment: Alignment.center,
                  child: const TabBar(
                    //  controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.black,
                      tabs:[
                        Tab(text:("Item Group"),),
                        Tab(text: ('Item Name'),),
                      ]),
                ),
                const SizedBox(height: 30,),
                Container(
                    height:1100,
                    child: TabBarView(children: [
                      ItemGroups(),
                      ItemCreation(),
                    ])
                )
              ],
            ),
          ),
        ),

      ),
    );
  }
}
class ItemGroups extends StatefulWidget {
  const ItemGroups({Key? key}) : super(key: key);
  @override
  State<ItemGroups> createState() => _ItemGroupsState();
}
class _ItemGroupsState extends State<ItemGroups> {
  GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredData = [];
  bool showInitialData = true;
  String selectedSuggestion = '';

  String? itemGroupValue = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }


  TextEditingController itemGroup = TextEditingController();
  Map<String, dynamic> dataToInsert = {};

  Future<void> insertData(Map<String, dynamic> dataToInsert) async {
    final String apiUrl = 'http://localhost:3309/post_itemgroup'; // Replace with your server details

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'dataToInsert': dataToInsert}),
      );

      if (response.statusCode == 200) {
        print('Data inserted successfully');
      } else {
        print('Failed to insert data');
        throw Exception('Failed to insert data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
  bool fieldExists = false;
  int serialNumber = 1;
  Future<List<Map<String, dynamic>>> fetchUnitEntries() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/getall_item_groups'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error loading unit entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load unit entries: $e');
    }
  }
  Future<List<dynamic>> fetchSizeData() async {
    const String apiUrl = 'http://localhost:3309/getall_item_groups/'; // Replace with your server details
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> sizeData = jsonDecode(response.body);
        return sizeData;
      } else {
        print('Failed to fetch data');
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
  Future<bool> checkForDuplicate(String size) async {
    List<dynamic> sizeData = await fetchSizeData();
    for (var item in sizeData) {
      if (item['itemGroup'] == size) {
        return true; // Size already exists, return true
      }
    }
    return false; // Size is unique, return false
  }
  Future<void> updateData(int id, Map<String, dynamic> updatedData) async {
    final String apiUrl = 'http://localhost:3309/updateitem/$id';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'updatedData': updatedData}),
      );

      if (response.statusCode == 200) {
        print('Data updated successfully');
      } else {
        print('Failed to update data');
        throw Exception('Failed to update data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }
  Future<void> updateItemGroup(BuildContext context, Map<String, dynamic> unitEntry) async {
    TextEditingController itemGroupController = TextEditingController(text: unitEntry['itemGroup']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item Group'),
          content: TextField(
            controller: itemGroupController,
            decoration: InputDecoration(labelText: 'Item Group'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String updatedItemGroup = itemGroupController.text;

                try {
                  final response = await http.put(
                    Uri.parse('http://localhost:3309/item_group_update/${unitEntry['id']}'),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({'itemGroup': updatedItemGroup}),
                  );

                  if (response.statusCode == 200) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckItemGroupPage(),
                      ),
                    );
                  } else {
                    throw Exception('Error updating Item Group: ${response.statusCode}');
                  }
                } catch (e) {
                  throw Exception('Failed to update Item Group: $e');
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
  Future<void> deleteItem(BuildContext context, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3309/item_group_delete/$id'),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CheckItemGroupPage(),
          ),
        );
      } else {
        throw Exception('Error deleting Item Group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete Item Group: $e');
    }
  }
  Future<void> confirmDelete(BuildContext context, int id) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this Item Group?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteItem(context, id);
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    serialNumber++; // Add this line to increment the serial number
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Icon(Icons.save_alt, size:30),
                                  const Padding(
                                    padding: EdgeInsets.only(right:0),
                                    child: Text(" Item Group Creation",style: TextStyle(fontSize:20,fontWeight: FontWeight.bold),),
                                  ),
                                ]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 7,),
                                      SizedBox(
                                        width: 300, height: 70,
                                        child: TextFormField(
                                          controller: itemGroup,
                                          style: TextStyle(fontSize: 13),
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return '* Enter Item Group';
                                            }
                                            return null;
                                          },
                                          onChanged: (query) {
                                            String capitalizedValue = capitalizeFirstLetter(query);
                                            itemGroup.value = itemGroup.value.copyWith(
                                              text: capitalizedValue,
                                              selection: TextSelection.collapsed(offset: capitalizedValue.length),
                                            );
                                          },
                                          decoration: InputDecoration(
                                            labelText: "Item Group",
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10)
                                            ),
                                          ),
                                        ),
                                      ), // Add spacing
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: MaterialButton(
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      color: Colors.green.shade600,
                                      onPressed: () async {
                                        if(_formkey.currentState!.validate()){
                                          String enteredSize = itemGroup.text;
                                          bool isDuplicate = await checkForDuplicate(enteredSize);
                                          if(isDuplicate){
                                            setState(() {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Already Exists")));}
                                            );}
                                          else{
                                            dataToInsert = {
                                              'itemGroup':itemGroup.text,
                                            };
                                            await insertData(dataToInsert);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Group created successfully")));
                                          }
                                        }
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=>CheckItemGroupPage()));

                                      },
                                      child: const Text("SAVE",style: TextStyle(color: Colors.white),)
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                MaterialButton(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    color: Colors.blue.shade600,
                                    onPressed: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>CheckItemGroupPage()));
                                    },
                                    child: const Text("RESET",style: TextStyle(color: Colors.white),)
                                ),
                                SizedBox(width: 10,),
                                MaterialButton(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    color: Colors.red.shade600,
                                    onPressed: (){
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) => Home())
                                      );
                                    },
                                    child: const Text("CANCEL",style: TextStyle(color: Colors.white),)
                                ),
                              ],
                            ),
                          ]
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0,right: 8.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SingleChildScrollView(
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: fetchUnitEntries(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              } else {
                                return Container(
                                  color: Colors.white,
                                  child: DataTable(
                                    border: TableBorder.all(),
                                    headingTextStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                    columnSpacing: 180,
                                    columns: [
                                      DataColumn(label: Text('S.No')),
                                      DataColumn(label: Text('Item Group')),
                                      DataColumn(label: Text('Action')),
                                    ],
                                    rows: snapshot.data!.map((ItemGroupAction) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text((snapshot.data!.indexOf(ItemGroupAction) + 1).toString())),
                                          DataCell(Text(ItemGroupAction['itemGroup'])),
                                          DataCell(Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () {
                                                  updateItemGroup(context, ItemGroupAction);
                                                },),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text('Delete'),
                                                        content: Text('Are you sure? you want to delete the Item Group'),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            child: Text('Cancel'),
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                          ),TextButton(
                                                            child: Text('Delete'),
                                                            onPressed: () {
                                                              deleteItem(context, ItemGroupAction['id']);
                                                              Navigator.of(context).pop();
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          ),
                                        ],

                                      );

                                    }).toList(),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }
}
class ItemCreation extends StatefulWidget {
  const ItemCreation({Key? key}) : super(key: key);
  @override
  State<ItemCreation> createState() => _ItemCreationState();
}
class _ItemCreationState extends State<ItemCreation> {

  List<String> itemGroupValues = [];
  late FocusNode _itemNameFocusNode;
  late FocusNode _hsnCodeFocusNode;
  late FocusNode _sizeFocusNode;
  late FocusNode _unitFocusNode;
  late FocusNode _colorFocusNode;
  late FocusNode _gstFocusNode;
  late FocusNode _saleRateFocusNode;
  Future<List<dynamic>> fetchSizeData() async {
    const String apiUrl = 'http://localhost:3309/getallitemName/'; // Replace with your server details
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> sizeData = jsonDecode(response.body);
        return sizeData;
      } else {
        print('Failed to fetch data');
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }

  Future<bool> checkForDuplicate(String size) async {
    List<dynamic> sizeData = await fetchSizeData();
    for (var item in sizeData) {
      if (item['itemName'] == size) {
        return true; // Size already exists, return true
      }
    }
    return false; // Size is unique, return false
  }


  @override
  void initState() {
    _itemNameFocusNode = FocusNode();
    _hsnCodeFocusNode = FocusNode();
    _sizeFocusNode = FocusNode();
    _unitFocusNode = FocusNode();
    _colorFocusNode = FocusNode();
    _gstFocusNode = FocusNode();
    _saleRateFocusNode = FocusNode();
    fetchData();
    getsize();
    getunit();
    getcolor();
    getgst();
    itemGroupfetch();
    getitemGroup();
    itemGroup = itemGroupValues.isNotEmpty ? itemGroupValues[0] : null;
  }

  @override
  void dispose() {
    _itemNameFocusNode.dispose();
    _hsnCodeFocusNode.dispose();
    _sizeFocusNode.dispose();
    _unitFocusNode.dispose();
    _colorFocusNode.dispose();
    _gstFocusNode.dispose();
    _saleRateFocusNode.dispose();

  }



  GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController itemName=TextEditingController();
  TextEditingController han_sac_code=TextEditingController();
  TextEditingController saleRate=TextEditingController();
  bool itemGroupExists = false;
  String? itemGroup;
  Map<String, dynamic> dataToInsert = {};
  Future<void> insertData(List<String> itemGroups, Map<String, dynamic> dataToInsert) async {
    const String apiUrl = 'http://localhost:3309/itemcreation/';
    try {
      for (String itemGroup in itemGroups) {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'dataToInsert': {
              ...dataToInsert,
              'itemGroup': itemGroup,
            },
          }),
        );

        if (response.statusCode == 200) {
          print('Data inserted successfully for item group $itemGroup');
        } else {
          print('Failed to insert data for item group $itemGroup');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Map<String, dynamic> dataToInsertitem = {};
  void insertDataitemName(Map<String, dynamic> dataToInsertitem) async {
    const String apiUrl = 'http://localhost:3309/item_Name_entry/';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'dataToInsertitem': dataToInsertitem}),
      );
      if (response.statusCode == 200) {
        print('Data inserted successfully');
      } else {
        print('Failed to insert data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Map<String, bool> selectedValues = {};
  List<String> selectedItem = [];
  List<String> getSelectedItems() {
    List<String> selectedItems = [];
    for (String value in selectedValues.keys) {
      if (selectedValues[value] == true) {
        selectedItems.add(value);
      }
    }

    return selectedItems;
  }
  Future<void> fetchData() async {
    try {
      final url = Uri.parse('http://localhost:3309/getall/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itemGroups = responseData;

        itemGroupValues = itemGroups.map((item) => item['itemGroup'] as String).toList();

        setState(() {
          // Print itemGroupValues to check if it's populated correctly.
          print('Item Groups: $itemGroupValues');
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }
  List<String> size = [];
  String? selectedSize;
  Future<void> getsize() async {
    try {
      final url = Uri.parse('http://localhost:3309/size_entry/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> sizes = responseData;

        size = sizes.map((item) => item['size'] as String).toList();

        setState(() {
          // Print itemGroupValues to check if it's populated correctly.
          print('Sizes: $size');
        });


      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }
  List<String> itG = [];
  List<String> itGList = [];
  String? selecteditG;
  Future<void> itemGroupfetch() async {
    try {
      final url = Uri.parse('http://localhost:3309/getall/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itGroup = responseData;
        itG = itGroup.map((item) => item['itemGroup'] as String).toList();
        setState(() {
          itGList= itG;
          print('itemGroup: $itG');
        });


      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }
  List<String> unit = [];
  String? selectedunit;
  Future<void> getunit() async {
    try {
      final url = Uri.parse('http://localhost:3309/unit_entry/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> units = responseData;

        unit = units.map((item) => item['unit'] as String).toList();

        setState(() {
          // Print itemGroupValues to check if it's populated correctly.
          print('Item Groups: $unit');
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }
  List<String> itemGroups = [];
  String? selectitemG;
  Future<void> getitemGroup() async {
    try {
      final url = Uri.parse('http://localhost:3309/item_group_get/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> itGr = responseData;

        itemGroups = itGr.map((item) => item['itemGroup'] as String).toList();

        setState(() {
          // Print itemGroupValues to check if it's populated correctly.
          print('Item Groups: $itemGroups');
        });

      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }
  List<String> color = [];
  String? selectedcolor;
  Future<void> getcolor() async {
    try {
      final url = Uri.parse('http://localhost:3309/color_entry/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> colors = responseData;

        color = colors.map((item) => item['color'] as String).toList();

        setState(() {
          // Print itemGroupValues to check if it's populated correctly.
          print('Item Groups: $color');
        });

      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }
  List<String> gst = [];
  String? selectedgst;
  Future<void> getgst() async {
    try {
      final url = Uri.parse('http://localhost:3309/gst_entry/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> gsts = responseData;


        setState(() {
          gst = gsts.map((item) => item['gst'] as String).toList();
          print('Item Groups: $gst');
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any other errors, e.g., network issues
      print('Error: $error');
    }
  }

  // void _showListViewDialog(BuildContext context) {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return Container(
  //             height:300, // Set the height as needed
  //             width:300,  // Set the width as needed
  //             child: ListView.builder(
  //               itemCount: itemGroupValues.length,
  //               itemBuilder: (BuildContext context, int index) {
  //                 final String value = itemGroupValues[index];
  //                 return SizedBox(
  //                   width: 50,
  //                   child: CheckboxListTile(
  //                     title: Text(
  //                       value,
  //                       style: TextStyle(fontSize: 16),
  //                     ),
  //                     value: selectedValues[value] ?? false,
  //                     onChanged: (bool? newValue) {
  //                       setState(() {
  //                         selectedValues[value] = newValue!;
  //                         if (newValue == true) {
  //                           if (!selectedItem.contains(value)) {
  //                             selectedItem.add(value); // Add to selectedItems when selected
  //                           }
  //                         } else {
  //                           selectedItem.remove(value); // Remove from selectedItems when deselected
  //                         }
  //                       });
  //                     },
  //                   ),
  //                 );
  //               },
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
//for Table
  Future<List<Map<String, dynamic>>> fetchUnitEntries() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3309/getallitem'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error loading unit entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load unit entries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Form(
        key: _formkey,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                // Text(itGList.toString()),
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                          children: [
                            // Text(itemGroups.toString()),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Icon(Icons.save_alt, size:30),
                                  const Padding(
                                    padding: EdgeInsets.only(right:0),
                                    child: Text(" Item Name creation",style: TextStyle(fontSize:20,fontWeight: FontWeight.bold),),
                                  ),
                                  // for (var data in customerData)

                                ]),
                            SizedBox(height: 10,),

                            Wrap(
                                children: [
                                  //item  group
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 200,
                                          height: 35,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.black12),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButtonFormField<String>(
                                                hint:const Text("Item Group"),
                                                value: selectitemG, // Use selectedSize to store the selected value
                                                items: itG.map((String value) {
                                                  return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(fontSize: 15),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    selectitemG = newValue; // Update selectedSize when a value is selected
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10,),
                                  // item Name
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 200,height: 70,
                                          child: TextFormField(style: const TextStyle(fontSize: 13),
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return '* Enter Item Name';
                                              }
                                              return null;
                                            },
                                            controller: itemName,
                                            decoration: InputDecoration(
                                              labelText: "Item Name",
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),

                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10,),
                                  //unit
                                  Padding(padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 200,
                                          height: 35,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(5),),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButtonFormField<String>(
                                                value: selectedunit, // Use selectedSize to store the selected value
                                                items: unit.map((String value) {
                                                  return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: const TextStyle(fontSize: 15),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    selectedunit = newValue; // Update selectedSize when a value is selected
                                                  });
                                                },
                                                hint:const Text("Unit"),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10,),
                                  //size
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 200,
                                          height: 35,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButtonFormField<String>(
                                                hint: const Text("Size"),
                                                value: selectedSize, // Use selectedSize to store the selected value
                                                items: size.map((String value) {
                                                  return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: const TextStyle(fontSize: 15),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    selectedSize = newValue; // Update selectedSize when a value is selected
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],),
                                  ),
                                ]),
                            Wrap(
                              children: [
                                //color
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 200,
                                        height: 35,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.black12),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButtonFormField<String>(
                                              hint:const Text("Color"),
                                              value: selectedcolor, // Use selectedSize to store the selected value
                                              items: color.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(
                                                    value,
                                                    style: TextStyle(fontSize: 15),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedcolor = newValue; // Update selectedSize when a value is selected
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                //rate
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left:0),
                                    child: SizedBox(
                                      width: 200,height: 70,
                                      child: TextFormField(style: TextStyle(fontSize: 13),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return '* Enter Rate per Unit';
                                          }
                                          return null;
                                        },
                                        controller: saleRate,
                                        decoration: InputDecoration(
                                          labelText: "Rate per Unit",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                //GST
                                Padding (
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 200,
                                        height: 35,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(5),),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButtonFormField<String>(
                                              hint:const Text("GST(%)"),
                                              value:selectedgst , // Use selectedSize to store the selected value
                                              items: gst.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(
                                                    value,
                                                    style: TextStyle(fontSize: 15),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedgst = newValue; // Update selectedSize when a value is selected
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                //hscn code
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 200,height: 70,
                                        child: TextFormField(style: const TextStyle(fontSize: 13),
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return '* Enter HSN/SAC Code';
                                            }
                                            return null;
                                          },
                                          controller: han_sac_code,
                                          decoration: InputDecoration(
                                            labelText: "HSN/SAC Code",
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),

                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // const SizedBox(width: 10,),

                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: MaterialButton(
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      color: Colors.green.shade600,
                                      onPressed: () async {
                                        if (_formkey.currentState!.validate()) {
                                          final dataToInsert = {
                                            'itemName': itemName.text,
                                            'code': han_sac_code.text,
                                            'size': selectedSize,
                                            'unit': selectedunit,
                                            'color': selectedcolor,
                                            'gst': selectedgst,
                                            'rate': saleRate.text,
                                          };

                                          await insertData(itGList, dataToInsert);

                                          String enteredSize = itemName.text;
                                          bool isDuplicate = await checkForDuplicate(enteredSize);
                                          if (!isDuplicate == true) {
                                            final dataToInsertitem = {
                                              'itemName': itemName.text,
                                            };
                                            insertDataitemName(dataToInsertitem);
                                          }


                                          itemName.clear();
                                          han_sac_code.clear();
                                          saleRate.clear();
                                          selectedItem.clear();
                                          setState(() {
                                            selectedSize = null;
                                            selectedunit = null;
                                            selectedcolor = null;
                                            selectedgst = null;
                                            selectitemG = null;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item Name Creation successfully")));
                                          print("Successful");
                                        }
                                      }, child: const Text("SAVE",style: TextStyle(color: Colors.white),)),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: MaterialButton(
                                    color: Colors.blue.shade600,
                                    onPressed:(){
                                      itemName.clear();
                                      han_sac_code.clear();
                                      saleRate.clear();
                                      selectedItem.clear();
                                      setState(() {
                                        selectedSize = null;
                                        selectedunit = null;
                                        selectedcolor = null;
                                        selectedgst = null;
                                        selectitemG = null;
                                      });

                                    },
                                    child: const Text("RESET", style: TextStyle(color: Colors.white)),),
                                ),
                                const SizedBox(width: 10,),
                                MaterialButton(
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    color: Colors.red.shade600,
                                    onPressed: (){

                                      Navigator.push(context,

                                          MaterialPageRoute(builder: (context) =>Home()));
                                    }, child: const Text("CANCEL",style: TextStyle(color: Colors.white),)),
                              ],
                            ),
                          ]
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0,right: 8.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SingleChildScrollView(
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: fetchUnitEntries(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              } else {
                                List<Map<String, dynamic>> sortedData = List.from(snapshot.data!);
                                sortedData.sort((a, b) {
                                  int groupComparison = b['itemGroup'].compareTo(a['itemGroup']);
                                  if (groupComparison != 0) return groupComparison;
                                  return b['itemName'].compareTo(a['itemName']);
                                });
                                return Container(
                                  color: Colors.white,
                                  child: Table(
                                    border: TableBorder.all(),
                                    columnWidths: {
                                      0: FlexColumnWidth(1),
                                      1: FlexColumnWidth(2),
                                      2: FlexColumnWidth(2),
                                      3: FlexColumnWidth(1),
                                      4: FlexColumnWidth(1),
                                      5: FlexColumnWidth(1),
                                      6: FlexColumnWidth(2),
                                      7: FlexColumnWidth(2),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          TableCell(child: Center(child: Text('S.No'))),
                                          TableCell(child: Center(child: Text('Item Group'))),
                                          TableCell(child: Center(child: Text('Item Name'))),
                                          TableCell(child: Center(child: Text('Unit'))),
                                          TableCell(child: Center(child: Text('Size'))),
                                          TableCell(child: Center(child: Text('Color'))),
                                          TableCell(child: Center(child: Text('Rate per Unit'))),
                                          TableCell(child: Center(child: Text('Action'))),
                                        ],
                                      ),
                                      for (var ItemGroupAction in snapshot.data!)
                                        TableRow(
                                          children: [
                                            TableCell(child: Center(child: Text((snapshot.data!.indexOf(ItemGroupAction) + 1).toString()))),
                                            TableCell(child: Center(child: Text(ItemGroupAction['itemGroup']))),
                                            TableCell(child: Center(child: Text(ItemGroupAction['itemName']))),
                                            TableCell(child: Center(child: Text(ItemGroupAction['unit'].toString()))),
                                            TableCell(child: Center(child: Text(ItemGroupAction['size'].toString()))),
                                            TableCell(child: Center(child: Text(ItemGroupAction['color'].toString()))),
                                            TableCell(child: Center(child: Text(ItemGroupAction['rate'].toString()))),
                                            TableCell(
                                              child: Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.edit, color: Colors.blue),
                                                      onPressed: () {
//  updateItemGroup(context, ItemGroupAction);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return AlertDialog(
                                                              title: Text('Delete'),
                                                              content: Text('Are you sure? you want to delete the Item Group'),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  child: Text('Cancel'),
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                ),
                                                                TextButton(
                                                                  child: Text('Delete'),
                                                                  onPressed: () {
//  deleteItem(context, ItemGroupAction['id']);
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                  ),
                ),






              ],
            ),
          ),
        ),
      ),
    );
  }
}
