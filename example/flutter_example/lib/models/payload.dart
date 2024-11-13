/*Assuming payload of push notification has this structure:
                     {
                        "pushName":"<Push name>",
                        "pushDate":"<Push date>"
                      }*/
class Payload {

  Payload({required this.pushName, required this.pushDate});

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      pushName: json['pushName'],
      pushDate: json['pushDate'],
    );
  }
  final String pushName;
  final String pushDate;

  Map<String, dynamic> toJson() {
    return {
      'pushName': pushName,
      'pushDate': pushDate,
    };
  }
}