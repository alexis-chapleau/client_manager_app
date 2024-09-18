class Client {
  int? id;
  String name;
  String patientId;
  String dateOfBirth;

  Client({
    this.id,
    required this.name,
    required this.patientId,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'name': name,
      'patientId': patientId,
      'dateOfBirth': dateOfBirth,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      patientId: map['patientId'],
      dateOfBirth: map['dateOfBirth'],
    );
  }
}
