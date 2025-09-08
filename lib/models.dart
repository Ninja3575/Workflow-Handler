class RequestItem {
  final String name;
  final String status; // pending | confirmed | not_available
  RequestItem({required this.name, required this.status});
  factory RequestItem.fromJson(Map<String, dynamic> j) =>
      RequestItem(name: j['name'], status: j['status']);
  Map<String, dynamic> toJson() => { 'name': name, 'status': status };
}

class RequestModel {
  final String id;
  final String userId;
  final String receiverId;
  final List<RequestItem> items;
  final String status; // Pending | Confirmed | Partially Fulfilled
  final String createdAt;
  final String updatedAt;

  RequestModel({
    required this.id,
    required this.userId,
    required this.receiverId,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> j) => RequestModel(
    id: j['id'].toString(),
    userId: j['userId'],
    receiverId: j['receiverId'],
    items: (j['items'] as List).map((e) => RequestItem.fromJson(e)).toList(),
    status: j['status'],
    createdAt: j['createdAt'],
    updatedAt: j['updatedAt'],
  );
}
