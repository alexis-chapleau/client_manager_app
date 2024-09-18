import 'package:flutter/material.dart';
import 'models/client.dart';
import 'models/bill.dart';
import 'database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class BillDetailPage extends StatefulWidget {
  final Client client;
  final Bill? bill;
  final bool resend;

  BillDetailPage({required this.client, this.bill, this.resend = false});

  @override
  _BillDetailPageState createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  late double amount;
  late String time;
  late String actName;
  late String date;

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      amount = widget.bill!.amount;
      time = widget.bill!.time;
      actName = widget.bill!.actName;
      date = widget.bill!.date;
      isEditing = false;
      if (widget.resend) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          sendBill();
        });
      }
    } else {
      amount = 0.0;
      time = '';
      actName = '';
      date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      isEditing = true;
    }
  }

  Future<void> saveBill({bool sendEmail = false}) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Bill bill = Bill(
        id: widget.bill?.id,
        clientId: widget.client.id!,
        amount: amount,
        time: time,
        actName: actName,
        date: date,
      );

      if (widget.bill == null) {
        await dbHelper.insertBill(bill);
      } else {
        await dbHelper.updateBill(bill);
      }

      if (sendEmail) {
        await sendBill();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Email sent')));
      }

      Navigator.pop(context, true);
    }
  }

  Future<void> sendBill() async {
    var uuid = Uuid();
    String invoiceNumber = uuid.v4();

    String subject = '${widget.client.name} - Invoice $invoiceNumber';

    String body = '''
Invoice Number: $invoiceNumber

Client Information:
Name: ${widget.client.name}
Patient ID: ${widget.client.patientId}
Date of Birth: ${widget.client.dateOfBirth}

Bill Details:
Act Name: $actName
Amount Charged: \$${amount.toStringAsFixed(2)}
Time of Consult: $time
Date: $date
''';

    String mailtoLink =
        'mailto:your_email@example.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    final Uri emailUri = Uri.parse(mailtoLink);

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the email app')),
      );
      print('Could not launch mailto link.');
    }
  }

  Future<void> pickDate() async {
    DateTime initialDate = DateTime.parse(date);
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        date = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill Details'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                saveBill();
              },
            ),
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                sendBill();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Email sent')));
              },
            ),
        ],
      ),
      body: isEditing
          ? Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue:
                          amount != 0.0 ? amount.toStringAsFixed(2) : '',
                      decoration:
                          InputDecoration(labelText: 'Amount Charged (\$)'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an amount' : null,
                      onSaved: (value) => amount = double.parse(value!),
                    ),
                    TextFormField(
                      initialValue: time,
                      decoration:
                          InputDecoration(labelText: 'Time of Consult (HH:MM)'),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter the time of consult'
                          : null,
                      onSaved: (value) => time = value!,
                    ),
                    TextFormField(
                      initialValue: actName,
                      decoration: InputDecoration(labelText: 'Name of the Act'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter the act name' : null,
                      onSaved: (value) => actName = value!,
                    ),
                    ListTile(
                      title: Text('Date'),
                      subtitle: Text(date),
                      trailing: Icon(Icons.calendar_today),
                      onTap: pickDate,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        saveBill(sendEmail: true);
                      },
                      child: Text('Save & Send'),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  ListTile(
                    title: Text('Amount Charged'),
                    subtitle: Text('\$${amount.toStringAsFixed(2)}'),
                  ),
                  ListTile(
                    title: Text('Time of Consult'),
                    subtitle: Text(time),
                  ),
                  ListTile(
                    title: Text('Name of the Act'),
                    subtitle: Text(actName),
                  ),
                  ListTile(
                    title: Text('Date'),
                    subtitle: Text(date),
                  ),
                ],
              ),
            ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
              child: Icon(Icons.edit),
            ),
    );
  }
}
