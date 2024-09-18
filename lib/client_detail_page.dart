import 'package:flutter/material.dart';
import 'models/client.dart';
import 'models/bill.dart';
import 'database/database_helper.dart';
import 'bill_detail_page.dart';

class ClientDetailPage extends StatefulWidget {
  final Client client;

  ClientDetailPage({required this.client});

  @override
  _ClientDetailPageState createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  late String name;
  late String patientId;
  late String dateOfBirth;

  List<Bill> bills = [];
  List<Bill> filteredBills = [];
  TextEditingController searchController = TextEditingController();

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    name = widget.client.name;
    patientId = widget.client.patientId;
    dateOfBirth = widget.client.dateOfBirth;
    isEditing = false;
    fetchBills();
    searchController.addListener(() {
      filterBills();
    });
  }

  Future<void> fetchBills() async {
    List<Bill> clientBills =
        await dbHelper.getBillsByClientId(widget.client.id!);
    setState(() {
      bills = clientBills;
      filteredBills = clientBills;
    });
  }

  void filterBills() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredBills = bills
          .where((bill) =>
              bill.actName.toLowerCase().contains(query) ||
              bill.date.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> saveClient() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Client updatedClient = Client(
        id: widget.client.id,
        name: name,
        patientId: patientId,
        dateOfBirth: dateOfBirth,
      );

      await dbHelper.updateClient(updatedClient);

      setState(() {
        isEditing = false;
      });
    }
  }

  void navigateToBillDetail(Bill? bill, {bool resend = false}) async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillDetailPage(
          client: widget.client,
          bill: bill,
          resend: resend,
        ),
      ),
    );

    if (result == true) {
      fetchBills();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Details'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                saveClient();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: isEditing
          ? Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name Field
                    TextFormField(
                      initialValue: name,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                      onSaved: (value) => name = value!,
                    ),
                    // Patient ID Field
                    TextFormField(
                      initialValue: patientId,
                      decoration: InputDecoration(labelText: 'Patient ID'),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter a patient ID'
                          : null,
                      onSaved: (value) => patientId = value!,
                    ),
                    // Date of Birth Field
                    TextFormField(
                      initialValue: dateOfBirth,
                      decoration: InputDecoration(labelText: 'Date of Birth'),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter date of birth'
                          : null,
                      onSaved: (value) => dateOfBirth = value!,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                ListTile(
                  title: Text('Name'),
                  subtitle: Text(name),
                ),
                ListTile(
                  title: Text('Patient ID'),
                  subtitle: Text(patientId),
                ),
                ListTile(
                  title: Text('Date of Birth'),
                  subtitle: Text(dateOfBirth),
                ),
                Divider(),
                ListTile(
                  title: Text('Bills'),
                  trailing: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      navigateToBillDetail(null);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search bills...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredBills.length,
                    itemBuilder: (context, index) {
                      Bill bill = filteredBills[index];
                      return GestureDetector(
                        onLongPress: () {
                          navigateToBillDetail(bill, resend: true);
                        },
                        child: ListTile(
                          title: Text(bill.actName),
                          subtitle: Text(
                              'Amount: \$${bill.amount.toStringAsFixed(2)} | Date: ${bill.date}'),
                          onTap: () {
                            navigateToBillDetail(bill);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
