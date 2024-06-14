/*Assuming payload of push notification has this structure:
                     {
                        "pushName":"<Push name>",
                        "pushDate":"<Push date>"
                      }*/
class Payload {
  final String pushName;
  final String pushDate;

  Payload({required this.pushName, required this.pushDate});

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      pushName: json['pushName'],
      pushDate: json['pushDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushName': pushName,
      'pushDate': pushDate,
    };
  }
}