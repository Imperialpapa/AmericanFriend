/// 대화 주제 카테고리
enum TopicCategory {
  daily('Daily Life', 'Everyday conversations'),
  travel('Travel', 'Traveling and sightseeing'),
  food('Food & Dining', 'Restaurants, cooking, ordering'),
  work('Work & Business', 'Office, meetings, interviews'),
  shopping('Shopping', 'Buying things, prices, returns'),
  health('Health', 'Doctor visits, pharmacy, wellness'),
  social('Social', 'Making friends, parties, small talk'),
  entertainment('Entertainment', 'Movies, music, hobbies');

  final String displayName;
  final String description;
  const TopicCategory(this.displayName, this.description);
}

/// 개별 주제
class Topic {
  final String id;
  final TopicCategory category;
  final String title;
  final String situation;
  final String aiRole;

  const Topic({
    required this.id,
    required this.category,
    required this.title,
    required this.situation,
    required this.aiRole,
  });
}

/// 기본 제공 주제 목록
class TopicCatalog {
  static const List<Topic> all = [
    // Daily Life
    Topic(
      id: 'daily_greetings',
      category: TopicCategory.daily,
      title: 'Morning Greetings',
      situation: 'You meet your neighbor in the morning.',
      aiRole: 'a friendly neighbor',
    ),
    Topic(
      id: 'daily_weather',
      category: TopicCategory.daily,
      title: 'Weather Talk',
      situation: 'You\'re chatting about today\'s weather.',
      aiRole: 'a coworker at the office',
    ),
    Topic(
      id: 'daily_weekend',
      category: TopicCategory.daily,
      title: 'Weekend Plans',
      situation: 'Discussing plans for the weekend.',
      aiRole: 'a close friend',
    ),

    // Travel
    Topic(
      id: 'travel_hotel',
      category: TopicCategory.travel,
      title: 'Hotel Check-in',
      situation: 'You\'re checking into a hotel.',
      aiRole: 'a hotel receptionist',
    ),
    Topic(
      id: 'travel_directions',
      category: TopicCategory.travel,
      title: 'Asking for Directions',
      situation: 'You\'re lost and need to find a place.',
      aiRole: 'a local person on the street',
    ),
    Topic(
      id: 'travel_airport',
      category: TopicCategory.travel,
      title: 'At the Airport',
      situation: 'You\'re at the airport checking in for a flight.',
      aiRole: 'an airline check-in agent',
    ),

    // Food & Dining
    Topic(
      id: 'food_restaurant',
      category: TopicCategory.food,
      title: 'Ordering at a Restaurant',
      situation: 'You\'re at a restaurant ready to order.',
      aiRole: 'a friendly waiter',
    ),
    Topic(
      id: 'food_cafe',
      category: TopicCategory.food,
      title: 'Coffee Shop Order',
      situation: 'You\'re at a coffee shop.',
      aiRole: 'a barista',
    ),
    Topic(
      id: 'food_recipe',
      category: TopicCategory.food,
      title: 'Sharing Recipes',
      situation: 'You\'re talking about your favorite dishes.',
      aiRole: 'a friend who loves cooking',
    ),

    // Work & Business
    Topic(
      id: 'work_interview',
      category: TopicCategory.work,
      title: 'Job Interview',
      situation: 'You\'re in a job interview.',
      aiRole: 'a hiring manager',
    ),
    Topic(
      id: 'work_meeting',
      category: TopicCategory.work,
      title: 'Team Meeting',
      situation: 'You\'re presenting an idea in a meeting.',
      aiRole: 'a team lead',
    ),
    Topic(
      id: 'work_phone',
      category: TopicCategory.work,
      title: 'Business Phone Call',
      situation: 'You\'re making a business phone call.',
      aiRole: 'a client',
    ),

    // Shopping
    Topic(
      id: 'shop_clothes',
      category: TopicCategory.shopping,
      title: 'Buying Clothes',
      situation: 'You\'re shopping for clothes.',
      aiRole: 'a sales assistant',
    ),
    Topic(
      id: 'shop_return',
      category: TopicCategory.shopping,
      title: 'Returning an Item',
      situation: 'You need to return a defective product.',
      aiRole: 'a customer service representative',
    ),
    Topic(
      id: 'shop_grocery',
      category: TopicCategory.shopping,
      title: 'Grocery Shopping',
      situation: 'You\'re at a grocery store looking for something.',
      aiRole: 'a store employee',
    ),

    // Health
    Topic(
      id: 'health_doctor',
      category: TopicCategory.health,
      title: 'Doctor\'s Visit',
      situation: 'You\'re visiting a doctor about symptoms.',
      aiRole: 'a doctor',
    ),
    Topic(
      id: 'health_pharmacy',
      category: TopicCategory.health,
      title: 'At the Pharmacy',
      situation: 'You need to buy medicine.',
      aiRole: 'a pharmacist',
    ),

    // Social
    Topic(
      id: 'social_party',
      category: TopicCategory.social,
      title: 'At a Party',
      situation: 'You\'re meeting new people at a party.',
      aiRole: 'someone you just met at a party',
    ),
    Topic(
      id: 'social_invite',
      category: TopicCategory.social,
      title: 'Making Plans with Friends',
      situation: 'You\'re inviting a friend to hang out.',
      aiRole: 'a good friend',
    ),

    // Entertainment
    Topic(
      id: 'ent_movies',
      category: TopicCategory.entertainment,
      title: 'Movie Discussion',
      situation: 'You just watched a movie and want to talk about it.',
      aiRole: 'a friend who also saw the movie',
    ),
    Topic(
      id: 'ent_hobbies',
      category: TopicCategory.entertainment,
      title: 'Talking About Hobbies',
      situation: 'You\'re sharing your hobbies with someone new.',
      aiRole: 'a new acquaintance',
    ),
  ];

  static List<Topic> byCategory(TopicCategory category) =>
      all.where((t) => t.category == category).toList();
}
