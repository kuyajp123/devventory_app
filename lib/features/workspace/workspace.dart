class Workspace {
  const Workspace({required this.id, required this.publisherId});
  final String? id;
  final String? publisherId;
  bool get hasPublisher => id != null && publisherId != null;

  factory Workspace.fromJson(Object? value) {
    if (value is! Map ||
        value['protocolVersion'] != 1 ||
        !value.containsKey('workspaceId') ||
        !value.containsKey('deviceId')) {
      throw const FormatException('Unsupported workspace response');
    }
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final id = value['workspaceId'];
    final publisher = value['deviceId'];
    if ((id != null && (id is! String || !uuid.hasMatch(id))) ||
        (publisher != null &&
            (publisher is! String || !uuid.hasMatch(publisher))) ||
        (id == null && publisher != null)) {
      throw const FormatException('Invalid workspace identity');
    }
    return Workspace(id: id as String?, publisherId: publisher as String?);
  }
}
