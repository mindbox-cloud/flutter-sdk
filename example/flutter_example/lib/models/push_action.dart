class PushAction {

  PushAction({
    required this.uniqueKey,
    required this.text,
    required this.url,
  });

  factory PushAction.fromJson(Map<String, dynamic> json) {
    return PushAction(
      uniqueKey: json['uniqueKey'],
      text: json['text'],
      url: json['url'],
    );
  }
  final String uniqueKey;
  final String text;
  final String url;

  Map<String, dynamic> toJson() {
    return {
      'uniqueKey': uniqueKey,
      'text': text,
      'url': url,
    };
  }
}