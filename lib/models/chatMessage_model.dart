class chatMessageModel{
  final String text;
  final String userId;
  final String userName;
  final DateTime createdAt;

  chatMessageModel({
    required this.text,
    required this.userId,
    required this.userName,
    required this.createdAt,


});
  factory chatMessageModel.fromJson(Map<String, dynamic> json){
    return chatMessageModel(text: json["text"], userId: json["userId"], userName: json["userName"], createdAt: DateTime.parse(json["createdAt"]),);
  }
}