class SMS {
  final int? id;
  final String sender;
  final String message;

  SMS({this.id, required this.sender, required this.message});

  // Convert a SMS object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
    };
  }

  // Extract a SMS object from a Map object
  factory SMS.fromMap(Map<String, dynamic> map) {
    return SMS(
      id: map['id'],
      sender: map['sender'],
      message: map['message'],
    );
  }

  @override
  String toString() {
    return 'SMS{id: $id, sender: $sender, message: $message}';
  }
}
