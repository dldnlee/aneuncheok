import 'dart:math';

/// Anonymous identity. Nicknames are built from fixed word lists so players
/// cannot type free text (no real names, no inappropriate names) - important
/// for an app aimed at young people.
class Identity {
  const Identity({
    required this.adjectiveIndex,
    required this.animalIndex,
    required this.code,
  });

  final int adjectiveIndex;
  final int animalIndex;

  /// Friend code, 6 characters from [codeAlphabet].
  final String code;

  String get adjective => adjectives[adjectiveIndex];
  String get animalName => animals[animalIndex].name;
  String get avatar => animals[animalIndex].emoji;
  String get nickname => '$adjective $animalName';

  Identity copyWith({int? adjectiveIndex, int? animalIndex}) => Identity(
    adjectiveIndex: adjectiveIndex ?? this.adjectiveIndex,
    animalIndex: animalIndex ?? this.animalIndex,
    code: code,
  );

  Map<String, Object> toJson() => {
    'adjective': adjectiveIndex,
    'animal': animalIndex,
    'code': code,
  };

  /// Returns null when [json] is malformed or out of range.
  static Identity? tryFromJson(Map<String, dynamic> json) {
    final adjective = json['adjective'];
    final animal = json['animal'];
    final code = json['code'];
    if (adjective is! int || animal is! int || code is! String) return null;
    if (adjective < 0 || adjective >= adjectives.length) return null;
    if (animal < 0 || animal >= animals.length) return null;
    if (normalizeCode(code) != code) return null;
    return Identity(adjectiveIndex: adjective, animalIndex: animal, code: code);
  }
}

class Animal {
  const Animal(this.name, this.emoji);

  final String name;
  final String emoji;
}

const List<String> adjectives = [
  '용감한',
  '똑똑한',
  '졸린',
  '신나는',
  '엉뚱한',
  '느긋한',
  '재빠른',
  '수줍은',
  '당당한',
  '호기심 많은',
  '배고픈',
  '든든한',
  '반짝이는',
  '씩씩한',
  '꼼꼼한',
  '유쾌한',
];

const List<Animal> animals = [
  Animal('판다', '🐼'),
  Animal('여우', '🦊'),
  Animal('고양이', '🐱'),
  Animal('강아지', '🐶'),
  Animal('토끼', '🐰'),
  Animal('펭귄', '🐧'),
  Animal('곰', '🐻'),
  Animal('호랑이', '🐯'),
  Animal('사자', '🦁'),
  Animal('개구리', '🐸'),
  Animal('햄스터', '🐹'),
  Animal('올빼미', '🦉'),
  Animal('돌고래', '🐬'),
  Animal('코알라', '🐨'),
  Animal('유니콘', '🦄'),
  Animal('공룡', '🦖'),
];

/// No 0/O or 1/I so codes are easy to read aloud and type.
const String codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int codeLength = 6;

String generateFriendCode(Random random) => String.fromCharCodes(
  List.generate(
    codeLength,
    (_) => codeAlphabet.codeUnitAt(random.nextInt(codeAlphabet.length)),
  ),
);

Identity generateIdentity(Random random) => Identity(
  adjectiveIndex: random.nextInt(adjectives.length),
  animalIndex: random.nextInt(animals.length),
  code: generateFriendCode(random),
);

/// Shows a code as `ABC-DEF`.
String formatCode(String code) => code.length == codeLength
    ? '${code.substring(0, 3)}-${code.substring(3)}'
    : code;

/// Cleans user input (any case, spaces, dashes) into a canonical code.
/// Returns null when the result is not a valid friend code.
String? normalizeCode(String input) {
  final cleaned = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  if (cleaned.length != codeLength) return null;
  for (final unit in cleaned.codeUnits) {
    if (!codeAlphabet.codeUnits.contains(unit)) return null;
  }
  return cleaned;
}
