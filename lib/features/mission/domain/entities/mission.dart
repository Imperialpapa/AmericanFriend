/// 역할극 미션 정의
class Mission {
  final String id;
  final String title;
  final String description;
  final String situation;
  final String aiRole;
  /// 완료 조건: 최소 턴 수
  final int requiredTurns;
  /// 미션에서 사용해야 할 핵심 표현 (선택)
  final List<String> keyPhrases;
  final MissionDifficulty difficulty;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.situation,
    required this.aiRole,
    this.requiredTurns = 5,
    this.keyPhrases = const [],
    this.difficulty = MissionDifficulty.easy,
  });
}

enum MissionDifficulty {
  easy('Easy', 1),
  medium('Medium', 2),
  hard('Hard', 3);

  final String label;
  final int stars;
  const MissionDifficulty(this.label, this.stars);
}

class MissionCatalog {
  static const List<Mission> all = [
    // Easy
    Mission(
      id: 'mission_cafe_order',
      title: 'Coffee Run',
      description: 'Order your favorite drink at a cafe',
      situation: 'You walk into a busy coffee shop.',
      aiRole: 'a barista',
      requiredTurns: 4,
      keyPhrases: ['I\'d like', 'size', 'to go'],
      difficulty: MissionDifficulty.easy,
    ),
    Mission(
      id: 'mission_greet_neighbor',
      title: 'Friendly Neighbor',
      description: 'Have a small talk with your neighbor',
      situation: 'You run into your neighbor in the hallway.',
      aiRole: 'your friendly neighbor',
      requiredTurns: 4,
      keyPhrases: ['How are you', 'weather', 'have a nice day'],
      difficulty: MissionDifficulty.easy,
    ),
    Mission(
      id: 'mission_taxi',
      title: 'Catch a Ride',
      description: 'Take a taxi to your destination',
      situation: 'You just got into a taxi.',
      aiRole: 'a taxi driver',
      requiredTurns: 4,
      keyPhrases: ['take me to', 'how long', 'how much'],
      difficulty: MissionDifficulty.easy,
    ),

    // Medium
    Mission(
      id: 'mission_restaurant',
      title: 'Fine Dining',
      description: 'Order a full meal at a restaurant',
      situation: 'You\'re seated at a nice restaurant.',
      aiRole: 'a waiter at a fine dining restaurant',
      requiredTurns: 6,
      keyPhrases: ['recommend', 'appetizer', 'check please'],
      difficulty: MissionDifficulty.medium,
    ),
    Mission(
      id: 'mission_doctor',
      title: 'Feeling Under the Weather',
      description: 'Describe your symptoms to a doctor',
      situation: 'You\'re at the doctor\'s office feeling sick.',
      aiRole: 'a doctor',
      requiredTurns: 6,
      keyPhrases: ['symptoms', 'how long', 'prescription'],
      difficulty: MissionDifficulty.medium,
    ),
    Mission(
      id: 'mission_hotel_problem',
      title: 'Hotel Complaint',
      description: 'Report a problem with your hotel room',
      situation: 'There\'s a problem with your hotel room.',
      aiRole: 'the hotel front desk manager',
      requiredTurns: 6,
      keyPhrases: ['issue', 'could you', 'appreciate'],
      difficulty: MissionDifficulty.medium,
    ),

    // Hard
    Mission(
      id: 'mission_interview',
      title: 'Dream Job',
      description: 'Ace a job interview',
      situation: 'You\'re interviewing for your dream job.',
      aiRole: 'a hiring manager at a tech company',
      requiredTurns: 8,
      keyPhrases: ['experience', 'strength', 'why should we hire you'],
      difficulty: MissionDifficulty.hard,
    ),
    Mission(
      id: 'mission_negotiate',
      title: 'Deal Maker',
      description: 'Negotiate a better price',
      situation: 'You\'re buying something expensive and want a discount.',
      aiRole: 'a sales representative',
      requiredTurns: 8,
      keyPhrases: ['discount', 'budget', 'deal'],
      difficulty: MissionDifficulty.hard,
    ),
    Mission(
      id: 'mission_debate',
      title: 'Friendly Debate',
      description: 'Have a debate about a trending topic',
      situation: 'You and a friend disagree about whether AI will replace jobs.',
      aiRole: 'a friend with the opposite opinion',
      requiredTurns: 8,
      keyPhrases: ['in my opinion', 'on the other hand', 'I see your point'],
      difficulty: MissionDifficulty.hard,
    ),
  ];
}
