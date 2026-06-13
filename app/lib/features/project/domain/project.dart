/// Projeto: agrupador de medições por área/talhão (melhoria sobre o desktop).
class Project {
  const Project({
    this.id,
    this.remoteId,
    required this.name,
    this.description,
    this.owner,
    this.createdAt,
    this.updatedAt,
    this.archived = false,
  });

  final int? id;
  final String? remoteId;
  final String name;
  final String? description;
  final String? owner;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool archived;

  Project copyWith({
    int? id,
    String? remoteId,
    String? name,
    String? description,
    String? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return Project(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}
