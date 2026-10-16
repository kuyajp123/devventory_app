enum ProjectType { web, desktop, mobile, backend, library, monorepo, other }

/// The complete allowlisted project record, including its publication anchor.
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.projectType,
    required this.createdAt,
    required this.updatedAt,
    required this.snapshotId,
    required this.observedAt,
    required this.receivedAt,
  });

  final String id, name, snapshotId;
  final String? description;
  final ProjectType projectType;
  final DateTime createdAt, updatedAt, observedAt, receivedAt;

  factory Project.fromJson(Object? value) {
    if (value is! Map || value['kind'] != 'project' || value['data'] is! Map) {
      throw const FormatException('Invalid project record');
    }
    final data = value['data'] as Map;
    final id = _uuid(data['id']);
    final name = data['name'];
    final description = data['description'];
    final type = ProjectType.values
        .where((type) => type.name == data['projectType'])
        .firstOrNull;
    if (value['id'] != id ||
        name is! String ||
        name.isEmpty ||
        name.length > 255 ||
        !data.containsKey('description') ||
        (description != null &&
            (description is! String || description.length > 2000)) ||
        type == null) {
      throw const FormatException('Invalid project data');
    }
    return Project(
      id: id,
      name: name,
      description: description as String?,
      projectType: type,
      createdAt: projectTime(data['createdAt']),
      updatedAt: projectTime(data['updatedAt']),
      snapshotId: _uuid(value['snapshotId']),
      observedAt: projectTime(value['observedAt']),
      receivedAt: projectTime(value['receivedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': 'project',
    'id': id,
    'data': {
      'id': id,
      'name': name,
      'description': description,
      'projectType': projectType.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    },
    'snapshotId': snapshotId,
    'observedAt': observedAt.toUtc().toIso8601String(),
    'receivedAt': receivedAt.toUtc().toIso8601String(),
  };
}

String _uuid(Object? value) {
  if (value is! String ||
      !RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value)) {
    throw const FormatException('Invalid project identity');
  }
  return value;
}

DateTime projectTime(Object? value) {
  final match = value is String
      ? RegExp(
          r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-](\d{2}):(\d{2}))$',
        ).firstMatch(value)
      : null;
  if (match == null) {
    throw const FormatException('Invalid metadata time');
  }
  int part(int group) => int.parse(match.group(group)!);
  final year = part(1), month = part(2), day = part(3);
  final calendar = DateTime.utc(year, month, day);
  // DateTime.parse normalizes invalid dates/times instead of rejecting them.
  if (calendar.year != year ||
      calendar.month != month ||
      calendar.day != day ||
      part(4) > 23 ||
      part(5) > 59 ||
      part(6) > 59 ||
      (match.group(9) != null && (part(9) > 23 || part(10) > 59))) {
    throw const FormatException('Invalid metadata time');
  }
  final parsed = DateTime.tryParse(value as String);
  if (parsed == null) throw const FormatException('Invalid metadata time');
  return parsed.toUtc();
}
