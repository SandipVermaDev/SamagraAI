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
      id: 'gemini-2.5-flash-lite',
      name: 'Gemini 2.5 Flash-Lite',
      description: 'Fastest and most cost-effective model',
    ),
    AIModel(
      id: 'gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      description: 'Fast and efficient for most conversations',
    ),
    AIModel(
      id: 'gemini-2.5-pro',
      name: 'Gemini 2.5 Pro',
      description: 'Most capable model for complex tasks',
    ),
    AIModel(
      id: 'gemini-2.0-flash-lite',
      name: 'Gemini 2.0 Flash-Lite',
      description: 'Lightweight and quick responses',
    ),
    AIModel(
      id: 'gemini-2.0-flash',
      name: 'Gemini 2.0 Flash',
      description: 'Balanced performance and speed',
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
