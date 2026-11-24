import '../../models/knowledge_item.dart';

/// 음식 (food)
const List<KnowledgeItem> foodCards = [
  KnowledgeItem(
    id: 'f1',
    categoryId: 'food',
    emoji: '🥚',
    title: '계란 신선도 확인',
    content:
        '물에 넣었을 때 바닥에 눕듯 가라앉으면 신선하고, 비스듬히 서면 조금 오래된 것, 물 위에 뜨면 아주 오래된 거예요. 오래될수록 속 공기주머니가 커져서 떠요. 깨서 냄새가 나면 버리세요.',
  ),
  KnowledgeItem(
    id: 'f2',
    categoryId: 'food',
    emoji: '🍚',
    title: '밥 한 공기 칼로리',
    content:
        '밥 한 공기(약 210g)는 약 300kcal입니다. 이는 성인 하루 권장 칼로리(2,000~2,500kcal)의 약 12~15%에 해당합니다.',
  ),
  KnowledgeItem(
    id: 'f3',
    categoryId: 'food',
    emoji: '🧂',
    title: '소금 하루 권장량',
    content:
        '세계보건기구(WHO)가 권장하는 하루 소금 섭취량은 5g(나트륨 2,000mg)입니다. 라면 한 개에 약 1,800mg의 나트륨이 들어 있어 거의 하루치에 가깝습니다.',
  ),
  KnowledgeItem(
    id: 'f4',
    categoryId: 'food',
    emoji: '🍯',
    title: '꿀은 잘 안 상한다',
    content:
        '꿀은 수분이 적고 산성이라 세균이 자라기 어려워 아주 오래 보관할 수 있어요. 하지만 습기가 들어가면 발효될 수 있고, 1살 미만 아기에게는 보툴리누스균 위험 때문에 먹이면 안 돼요.',
  ),
  KnowledgeItem(
    id: 'f5',
    categoryId: 'food',
    emoji: '🍌',
    title: '바나나 보관법',
    content:
        '바나나는 냉장 보관하면 껍질이 까맣게 변하지만 과육은 오래 보존됩니다. 꼭지를 랩으로 감싸면 에틸렌 가스 방출을 줄여 숙성을 늦출 수 있습니다.',
  ),
  KnowledgeItem(
    id: 'f6',
    categoryId: 'food',
    emoji: '🥩',
    title: '냉동 고기 해동법',
    content:
        '실온 해동은 세균 번식 위험이 있습니다. 냉장실에서 천천히 해동하거나, 밀봉 후 찬물에 담그는 것이 안전합니다. 전자레인지 해동 후에는 바로 조리하세요.',
  ),
  KnowledgeItem(
    id: 'f7',
    categoryId: 'food',
    emoji: '🥔',
    title: '싹 난 감자',
    content:
        '감자의 싹과 초록빛 껍질에는 솔라닌이라는 독소가 있어 복통과 구토를 일으킬 수 있습니다. 싹이 많이 났거나 초록색이 넓다면 버리는 것이 안전합니다.',
  ),
  KnowledgeItem(
    id: 'f8',
    categoryId: 'food',
    emoji: '🍱',
    title: '남은 밥 보관법',
    content:
        '밥을 실온에 오래 두면 바실러스 세레우스균이 번식해 식중독을 일으킬 수 있습니다. 남은 밥은 식혀서 바로 소분해 냉동 보관하세요.',
  ),
  KnowledgeItem(
    id: 'f9',
    categoryId: 'food',
    emoji: '🍅',
    title: '토마토는 익혀서',
    content:
        '토마토의 라이코펜은 열을 가하고 기름과 함께 먹을 때 몸에 더 잘 흡수됩니다. 생으로 먹는 것보다 올리브유에 볶아 먹는 것이 유리합니다.',
  ),
  KnowledgeItem(
    id: 'f10',
    categoryId: 'food',
    emoji: '🐣',
    title: '달걀 보관 방향',
    content: '달걀은 둥근 쪽(공기주머니)이 위로 가게 두면 신선도가 더 오래 유지됩니다. 껍질을 씻지 말고 냉장 보관하세요.',
  ),
  KnowledgeItem(
    id: 'f11',
    categoryId: 'food',
    emoji: '🌡️',
    title: '세균이 번식하는 온도',
    content:
        '음식은 5~60℃ 사이에서 세균이 빠르게 번식합니다. 조리한 음식은 2시간 이내에 냉장하고, 다시 먹을 때는 속까지 충분히 데우세요.',
  ),
  KnowledgeItem(
    id: 'f12',
    categoryId: 'food',
    emoji: '🍳',
    title: '계란 삶는 시간',
    content:
        '끓는 물에서 계란을 6~7분 삶으면 반숙, 10~12분 삶으면 완숙이 돼요. 크기와 처음 온도에 따라 조금씩 달라집니다.',
  ),
  KnowledgeItem(
    id: 'f13',
    categoryId: 'food',
    emoji: '🍗',
    title: '생닭은 씻지 마세요',
    content:
        '생닭을 물로 씻으면 세균이 주변으로 튀어 오히려 퍼질 수 있어요. 씻지 말고 속까지 충분히 익혀 먹는 것이 안전합니다.',
  ),
  KnowledgeItem(
    id: 'f14',
    categoryId: 'food',
    emoji: '🔪',
    title: '도마는 나눠 쓰기',
    content: '날고기와 생선용 도마, 채소와 과일용 도마를 나눠 쓰면 세균이 옮겨 가는 것을 막을 수 있어요.',
  ),
  KnowledgeItem(
    id: 'f15',
    categoryId: 'food',
    emoji: '❄️',
    title: '재냉동은 피하세요',
    content:
        '한 번 해동한 음식을 다시 얼리면 맛과 품질이 떨어지고 세균이 늘어날 수 있어요. 한 번 먹을 만큼씩 나눠서 얼리세요.',
  ),
  KnowledgeItem(
    id: 'f16',
    categoryId: 'food',
    emoji: '🍬',
    title: '설탕은 얼마나?',
    content:
        '세계보건기구(WHO)는 첨가당을 하루 섭취 열량의 10% 미만으로 줄이라고 권고해요. 5% 아래로 줄이면 더 좋다고 합니다.',
  ),
  KnowledgeItem(
    id: 'f17',
    categoryId: 'food',
    emoji: '🥤',
    title: '콜라 한 캔의 설탕',
    content: '콜라 한 캔(355mL 기준)에는 설탕이 약 35~40g 들어 있어요. 각설탕으로 치면 10개 안팎이에요.',
  ),
  KnowledgeItem(
    id: 'f18',
    categoryId: 'food',
    emoji: '⚡',
    title: '에너지 음료와 카페인',
    content:
        '에너지 음료에는 카페인이 많이 들어 있어요. 어린이와 청소년은 카페인의 영향을 더 크게 받아 가슴 두근거림과 불면이 생기기 쉬우니 피하는 게 좋아요.',
  ),
  KnowledgeItem(
    id: 'f19',
    categoryId: 'food',
    emoji: '🍎',
    title: '사과는 이웃을 익혀요',
    content:
        '사과는 에틸렌 가스를 내뿜어 근처 과일을 빨리 익게 만들어요. 덜 익은 과일을 사과와 함께 봉지에 넣으면 더 빨리 익습니다.',
  ),
  KnowledgeItem(
    id: 'f20',
    categoryId: 'food',
    emoji: '🍠',
    title: '고구마는 냉장 금지',
    content: '고구마는 추운 곳에 두면 속이 딱딱해지고 맛이 변하는 냉해를 입어요. 서늘한 실온에서 보관하는 것이 좋습니다.',
  ),
  KnowledgeItem(
    id: 'f21',
    categoryId: 'food',
    emoji: '🍞',
    title: '곰팡이 핀 빵',
    content:
        '빵에 곰팡이가 보이면 눈에 안 보이는 균사가 속까지 퍼져 있을 수 있어요. 핀 부분만 떼고 먹지 말고 통째로 버리세요.',
  ),
  KnowledgeItem(
    id: 'f22',
    categoryId: 'food',
    emoji: '🥫',
    title: '부푼 통조림',
    content: '통조림이 부풀었거나 새고, 열었을 때 이상한 냄새가 나면 세균이 자란 것일 수 있어요. 먹지 말고 버리세요.',
  ),
  KnowledgeItem(
    id: 'f23',
    categoryId: 'food',
    emoji: '🧂',
    title: '알레르기 표시 확인',
    content:
        '식품 포장에는 알레르기를 일으킬 수 있는 재료가 표시되어 있어요. 우유, 달걀, 땅콩, 새우 같은 재료는 꼭 확인하세요.',
  ),
  KnowledgeItem(
    id: 'f24',
    categoryId: 'food',
    emoji: '🥛',
    title: '우유를 마시면 배가 아파요',
    content:
        '우유를 마시면 배가 아프고 설사를 하는 건 우유 속 당(유당)을 분해하는 힘이 약해서예요. 알레르기와는 다른, 흔한 체질입니다.',
  ),
  KnowledgeItem(
    id: 'f25',
    categoryId: 'food',
    emoji: '🍚',
    title: '쌀의 첫 물은 버려요',
    content: '쌀을 씻을 때 처음 헹군 물은 쌀겨 냄새를 빨리 흡수해요. 첫 물은 재빨리 따라 버리는 것이 좋습니다.',
  ),
  KnowledgeItem(
    id: 'f26',
    categoryId: 'food',
    emoji: '🥬',
    title: '채소와 과일 씻기',
    content: '흙 묻은 채소는 흐르는 물에 여러 번 씻고, 껍질째 먹는 과일도 흐르는 물에 문질러 씻어 먹는 것이 좋습니다.',
  ),
  KnowledgeItem(
    id: 'f27',
    categoryId: 'food',
    emoji: '🥗',
    title: '식이섬유의 힘',
    content: '채소, 과일, 현미 속 식이섬유는 장을 건강하게 하고 포만감을 줘요. 여러 색깔의 채소를 골고루 먹으면 좋습니다.',
  ),
  KnowledgeItem(
    id: 'f28',
    categoryId: 'food',
    emoji: '🌶️',
    title: '매운맛은 맛이 아니라 통증',
    content: '매운맛은 혀의 맛이 아니라 입안의 통증과 온도 감각이 느끼는 자극이에요. 그래서 먹으면 화끈거리고 땀이 납니다.',
  ),
  KnowledgeItem(
    id: 'f29',
    categoryId: 'food',
    emoji: '🧅',
    title: '양파를 썰면 눈물이 나요',
    content: '양파를 자르면 자극적인 성분이 공기 중으로 퍼져 눈을 자극해서 눈물이 나요. 양파를 차갑게 해서 썰면 덜 매워요.',
  ),
];
