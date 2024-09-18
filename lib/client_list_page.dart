import 'package:flutter/material.dart';
import 'models/client.dart';
import 'database/database_helper.dart';
import 'client_detail_page.dart';
import 'client_create_page.dart';

class ClientListPage extends StatefulWidget {
  @override
  _ClientListPageState createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Client> clients = [];
  List<Client> filteredClients = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    refreshClientList();
    searchController.addListener(() {
      filterClients();
    });
  }

  Future<void> refreshClientList() async {
    List<Client> x = await dbHelper.getClients();
    setState(() {
      clients = x;
      filteredClients = x;
    });
  }

  void filterClients() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredClients = clients
          .where((client) =>
              client.name.toLowerCase().contains(query) ||
              client.patientId.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> deleteClient(int id) async {
    await dbHelper.deleteClient(id);
    refreshClientList();
  }

  void navigateToDetail(Client client) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClientDetailPage(client: client)),
    );
    refreshClientList();
  }

  void navigateToCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClientCreatePage()),
    );
    refreshClientList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text('Clients'), backgroundColor: Colors.blueAccent),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredClients.length,
                itemBuilder: (context, index) {
                  Client client = filteredClients[index];
                  return Dismissible(
                    key: Key(client.id.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      deleteClient(client.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${client.name} deleted')),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      title: Text(client.name),
                      subtitle: Text(client.patientId),
                      onTap: () {
                        navigateToDetail(client);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            navigateToCreate();
          },
          child: Icon(Icons.add),
        ));
  }
}
