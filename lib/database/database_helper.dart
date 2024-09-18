import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/bill.dart';

class DatabaseHelper {
  static DatabaseHelper? _databaseHelper;
  static Database? _database;

  String clientTable = 'clientTable';
  String billTable = 'billTable';

  String colId = 'id';
  String colName = 'name';
  String colPatientId = 'patientId';
  String colDateOfBirth = 'dateOfBirth';

  String colBillId = 'id';
  String colClientId = 'clientId';
  String colAmount = 'amount';
  String colTime = 'time';
  String colActName = 'actName';
  String colDate = 'date';

  DatabaseHelper._createInstance();

  factory DatabaseHelper() {
    _databaseHelper ??= DatabaseHelper._createInstance();
    return _databaseHelper!;
  }

  Future<Database> get database async {
    _database ??= await initializeDatabase();
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'clients.db');

    var clientsDatabase = await openDatabase(
      path,
      version: 4,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return clientsDatabase;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $clientTable(
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colName TEXT,
        $colPatientId TEXT,
        $colDateOfBirth TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $billTable(
        $colBillId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colClientId INTEGER,
        $colAmount REAL,
        $colTime TEXT,
        $colActName TEXT,
        $colDate TEXT,
        FOREIGN KEY ($colClientId) REFERENCES $clientTable($colId) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS $billTable');
    await db.execute('DROP TABLE IF EXISTS $clientTable');
    await _createDb(db, newVersion);
  }

  Future<Client> insertClient(Client client) async {
    Database db = await this.database;
    client.id = await db.insert(clientTable, client.toMap());
    return client;
  }

  Future<int> updateClient(Client client) async {
    Database db = await this.database;
    var result = await db.update(
      clientTable,
      client.toMap(),
      where: '$colId = ?',
      whereArgs: [client.id],
    );
    return result;
  }

  Future<int> deleteClient(int id) async {
    Database db = await this.database;
    var result = await db.delete(
      clientTable,
      where: '$colId = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<List<Client>> getClients() async {
    Database db = await this.database;
    var result = await db.query(
      clientTable,
      orderBy: '$colName ASC',
    );
    List<Client> clients = result.isNotEmpty
        ? result.map((c) => Client.fromMap(c)).toList()
        : [];
    return clients;
  }

  Future<Bill> insertBill(Bill bill) async {
    Database db = await this.database;
    bill.id = await db.insert(billTable, bill.toMap());
    return bill;
  }

  Future<int> updateBill(Bill bill) async {
    Database db = await this.database;
    var result = await db.update(
      billTable,
      bill.toMap(),
      where: '$colBillId = ?',
      whereArgs: [bill.id],
    );
    return result;
  }

  Future<int> deleteBill(int id) async {
    Database db = await this.database;
    var result = await db.delete(
      billTable,
      where: '$colBillId = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<List<Bill>> getBillsByClientId(int clientId) async {
    Database db = await this.database;
    var result = await db.query(
      billTable,
      where: '$colClientId = ?',
      whereArgs: [clientId],
      orderBy: '$colDate DESC',
    );
    List<Bill> bills = result.isNotEmpty
        ? result.map((b) => Bill.fromMap(b)).toList()
        : [];
    return bills;
  }
}
