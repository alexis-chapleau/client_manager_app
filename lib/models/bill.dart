class Bill {
  int? id;
  int clientId;
  double amount;
  String time;
  String actName;
  String date;

  Bill({
    this.id,
    required this.clientId,
    required this.amount,
    required this.time,
    required this.actName,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'clientId': clientId,
      'amount': amount,
      'time': time,
      'actName': actName,
      'date': date,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      clientId: map['clientId'],
      amount: map['amount'],
      time: map['time'],
      actName: map['actName'],
      date: map['date'],
    );
  }
}
