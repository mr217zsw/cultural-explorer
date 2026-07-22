class Question {
  final String id;
  final String question;
  final List<String> options;
  final int difficulty;
  final String category;

  Question({
    required this.id,
    required this.question,
    required this.options,
    this.difficulty = 1,
    this.category = 'history',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      category: json['category'] as String? ?? 'history',
    );
  }
}
