class AIModel {
  final String id;
  final String name;
  final String description;
  final bool isAvailable;

  const AIModel({
    required this.id,
    required this.name,
    required this.description,
    this.isAvailable = true,
  });

  static const List<AIModel> availableModels = [
    AIModel(
      id: 'gpt-3.5-turbo',
      name: 'GPT-3.5 Turbo',
      description: 'Fast and efficient for most conversations',
    ),
    AIModel(
      id: 'gpt-4',
      name: 'GPT-4',
      description: 'Most capable model for complex tasks',
    ),
    AIModel(
      id: 'claude-3-sonnet',
      name: 'Claude 3 Sonnet',
      description: 'Balanced performance and speed',
    ),
    AIModel(
      id: 'claude-3-opus',
      name: 'Claude 3 Opus',
      description: 'Most powerful model for complex reasoning',
    ),
  ];

  static AIModel getDefault() => availableModels.first;

  static AIModel? getById(String id) {
    try {
      return availableModels.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
