

class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final String type;
  bool lu;
  final String dateHumaine;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.lu,
    required this.dateHumaine,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      titre: json['titre'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      lu: json['lu'] ?? false,
      dateHumaine: json['date_humaine'] ?? '',
    );
  }
}