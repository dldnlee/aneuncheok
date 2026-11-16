import '../../models/knowledge_item.dart';

/// 생활 (daily life)
const List<KnowledgeItem> dailyCards = [
  KnowledgeItem(
    id: 'd1',
    categoryId: 'daily',
    emoji: '📅',
    title: '유통기한 ≠ 못 먹는 날',
    content:
        '유통기한은 판매할 수 있는 기한이에요. 2023년에 소비기한 표시제가 시작되어 2024년부터 본격 적용돼요. 소비기한은 보관 방법을 지켰을 때 먹어도 안전한 마지막 날짜이니 보관법도 꼭 확인하세요.',
  ),
  KnowledgeItem(
    id: 'd2',
    categoryId: 'daily',
    emoji: '⚡',
    title: '전자레인지에 금속',
    content:
        '전자레인지에 금속을 넣으면 전자파가 반사되어 불꽃이 튀고 화재가 날 수 있습니다. 알루미늄 호일, 스테인리스 그릇, 금테 접시 등은 절대 넣지 마세요.',
  ),
  KnowledgeItem(
    id: 'd3',
    categoryId: 'daily',
    emoji: '🔋',
    title: '건전지 보관법',
    content:
        '건전지를 냉장고에 보관하면 결로(물방울)가 생겨 오히려 수명이 줄어듭니다. 상온의 건조한 곳에 보관하는 것이 가장 좋습니다.',
  ),
  KnowledgeItem(
    id: 'd4',
    categoryId: 'daily',
    emoji: '📱',
    title: '핸드폰 충전',
    content:
        '리튬이온 배터리는 0%까지 방전하면 수명이 줄어듭니다. 20~80% 사이를 유지하는 것이 배터리 수명에 가장 좋습니다. 밤새 충전해도 과충전은 되지 않습니다.',
  ),
  KnowledgeItem(
    id: 'd5',
    categoryId: 'daily',
    emoji: '👕',
    title: '세탁 표시 삼각형',
    content:
        '옷 태그의 삼각형 표시는 표백 가능 여부입니다. 빈 삼각형은 표백 가능, X 친 삼각형은 표백 불가, 빗금 삼각형은 산소계 표백만 가능합니다.',
  ),
  KnowledgeItem(
    id: 'd6',
    categoryId: 'daily',
    emoji: '🚿',
    title: '화장실 환풍기',
    content:
        '샤워 후 환풍기는 최소 15~20분 이상 돌려야 습기가 제대로 빠집니다. 습기를 방치하면 곰팡이가 생기고, 곰팡이 포자는 호흡기 질환을 유발할 수 있습니다.',
  ),
  KnowledgeItem(
    id: 'd7',
    categoryId: 'daily',
    emoji: '🚰',
    title: '수도꼭지 방향',
    content:
        '대부분의 수도꼭지는 왼쪽이 온수, 오른쪽이 냉수예요. 여러 나라에서 굳어진 관례로, 헷갈려서 뜨거운 물에 데지 않도록 위치를 통일한 거예요.',
  ),
  KnowledgeItem(
    id: 'd8',
    categoryId: 'daily',
    emoji: '♻️',
    title: '재활용품은 헹궈서',
    content:
        '음식물이 묻은 용기는 재활용이 되지 않고 일반쓰레기가 됩니다. 내용물을 비우고 물로 헹군 뒤, 라벨 등 다른 재질은 떼어서 배출하세요.',
  ),
  KnowledgeItem(
    id: 'd9',
    categoryId: 'daily',
    emoji: '📞',
    title: '119, 112, 120',
    content:
        '화재·구급은 119, 범죄 신고는 112입니다. 120은 지자체의 민원·생활 불편 상담 번호(서울은 다산콜센터)로, 긴급 상황에는 쓰지 않습니다.',
  ),
  KnowledgeItem(
    id: 'd10',
    categoryId: 'daily',
    emoji: '🔌',
    title: '멀티탭 문어발',
    content:
        '멀티탭에는 정격 용량이 적혀 있어요(예: 16A는 4,000W까지). 전기히터, 전기밥솥 같은 고출력 제품을 여러 개 꽂아 표시 용량을 넘기면 과열되어 불이 날 수 있어요.',
  ),
  KnowledgeItem(
    id: 'd11',
    categoryId: 'daily',
    emoji: '🛏️',
    title: '침구 세탁 주기',
    content: '이불과 베개 커버는 1~2주에 한 번 세탁하는 것이 좋습니다. 땀과 각질이 쌓이면 집먼지진드기가 번식하기 쉽습니다.',
  ),
  KnowledgeItem(
    id: 'd12',
    categoryId: 'daily',
    emoji: '🧊',
    title: '냉장고는 70%만',
    content:
        '냉장실은 70% 정도만 채워야 냉기가 잘 순환합니다. 반대로 냉동실은 가득 채워야 서로 냉기를 유지해 효율이 좋습니다.',
  ),
  KnowledgeItem(
    id: 'd13',
    categoryId: 'daily',
    emoji: '🧴',
    title: '락스와 식초는 섞지 마세요',
    content:
        '락스(염소계 세제)를 식초나 산성 세제와 섞으면 독성 가스가 나와 위험합니다. 세제는 절대 섞어 쓰지 말고, 쓸 때는 환기하세요.',
  ),
  KnowledgeItem(
    id: 'd14',
    categoryId: 'daily',
    emoji: '🔌',
    title: '플러그만 꽂아도 전기를 써요',
    content:
        '전원을 꺼도 플러그가 꽂혀 있으면 소량의 전기(대기전력)가 계속 쓰입니다. 안 쓰는 충전기와 가전은 플러그를 뽑으면 전기를 아낄 수 있어요.',
  ),
  KnowledgeItem(
    id: 'd15',
    categoryId: 'daily',
    emoji: '🧺',
    title: '수건과 섬유유연제',
    content:
        '수건에 섬유유연제를 쓰면 섬유 표면이 코팅되어 물을 잘 빨아들이지 못하게 됩니다. 수건은 섬유유연제 없이 빠는 것이 좋아요.',
  ),
  KnowledgeItem(
    id: 'd16',
    categoryId: 'daily',
    emoji: '✈️',
    title: '보조배터리는 기내에만',
    content:
        '보조배터리는 화재 위험 때문에 위탁수하물에 넣을 수 없어요. 기내에서는 선반에 두지 말고 몸에 지니며, 사용과 충전도 제한되니 항공사 규정을 꼭 확인하세요.',
  ),
  KnowledgeItem(
    id: 'd17',
    categoryId: 'daily',
    emoji: '💧',
    title: '쾌적한 실내 습도',
    content: '실내 습도는 40~60%가 쾌적합니다. 너무 건조하면 목과 피부가 힘들고, 너무 습하면 곰팡이와 진드기가 늘어나요.',
  ),
  KnowledgeItem(
    id: 'd18',
    categoryId: 'daily',
    emoji: '🧊',
    title: '냉장고 적정 온도',
    content:
        '냉장실은 0~5℃, 냉동실은 -18℃ 이하로 유지하는 것이 좋습니다. 문을 자주 오래 열면 온도가 올라가 음식이 빨리 상해요.',
  ),
  KnowledgeItem(
    id: 'd19',
    categoryId: 'daily',
    emoji: '📅',
    title: '윤년은 왜 있을까',
    content: '지구가 태양을 한 바퀴 도는 데 약 365.24일이 걸려서, 4년에 한 번 2월 29일을 넣어 달력을 맞춥니다.',
  ),
  KnowledgeItem(
    id: 'd20',
    categoryId: 'daily',
    emoji: '📏',
    title: '1평은 몇 ㎡일까',
    content: '집 크기를 말할 때 쓰는 1평은 약 3.3㎡입니다. 평수에 3.3을 곱하면 대략의 ㎡를 알 수 있어요.',
  ),
  KnowledgeItem(
    id: 'd21',
    categoryId: 'daily',
    emoji: '📶',
    title: 'IP68, 방수의 뜻',
    content:
        'IP68 같은 등급에서 앞자리는 먼지, 뒷자리는 물에 대한 보호 정도예요. 방수폰도 바닷물이나 뜨거운 물에서는 성능이 보장되지 않는 경우가 많아요.',
  ),
  KnowledgeItem(
    id: 'd22',
    categoryId: 'daily',
    emoji: '🏷️',
    title: '세탁 표시의 숫자',
    content:
        '세탁 표시의 대야 그림 속 숫자는 물의 최고 온도예요. 40이라고 적혀 있으면 40℃ 이하의 물로 빨아야 옷이 줄거나 상하지 않아요.',
  ),
  KnowledgeItem(
    id: 'd23',
    categoryId: 'daily',
    emoji: '🧹',
    title: '청소는 위에서 아래로',
    content: '먼지는 아래로 떨어지기 때문에, 청소는 선반이나 조명 같은 높은 곳부터 시작해 바닥으로 내려오는 것이 효율적이에요.',
  ),
  KnowledgeItem(
    id: 'd24',
    categoryId: 'daily',
    emoji: '🔋',
    title: '배터리가 부풀면 위험해요',
    content:
        '스마트폰이나 보조배터리가 부풀어 오르면 배터리 안에 가스가 찬 것이라 위험합니다. 사용을 멈추고 서비스센터에 가져가세요.',
  ),
  KnowledgeItem(
    id: 'd25',
    categoryId: 'daily',
    emoji: '🧼',
    title: '수건은 자주 빨아요',
    content: '젖은 수건은 세균이 번식하기 쉬워요. 쓰고 나서 잘 말리고, 보통 3~4번 쓴 뒤에는 세탁하는 것이 좋습니다.',
  ),
  KnowledgeItem(
    id: 'd26',
    categoryId: 'daily',
    emoji: '🪟',
    title: '맞통풍 환기',
    content: '하루 몇 번, 10분 이상 창문을 열어 바람이 지나가게 하면 실내 오염 물질이 빠르게 줄어듭니다.',
  ),
  KnowledgeItem(
    id: 'd27',
    categoryId: 'daily',
    emoji: '💡',
    title: 'LED가 전기를 아껴요',
    content:
        'LED 전구는 백열전구보다 훨씬 적은 전기로 같은 밝기를 내고 수명도 깁니다. 집의 전구를 LED로 바꾸면 전기요금을 아낄 수 있어요.',
  ),
  KnowledgeItem(
    id: 'd28',
    categoryId: 'daily',
    emoji: '☂️',
    title: '우산은 펴서 말려요',
    content: '젖은 우산을 접어 두면 곰팡이와 냄새가 생기기 쉬워요. 펼쳐서 그늘에서 완전히 말린 뒤 접어 보관하세요.',
  ),
  KnowledgeItem(
    id: 'd29',
    categoryId: 'daily',
    emoji: '📦',
    title: '택배 송장 정보',
    content: '택배 송장에는 이름, 주소, 전화번호가 적혀 있어요. 버릴 때는 송장을 떼거나 지워서 개인정보가 새지 않게 하세요.',
  ),
  KnowledgeItem(
    id: 'd30',
    categoryId: 'daily',
    emoji: '🌀',
    title: '선풍기와 에어컨을 함께',
    content: '에어컨과 선풍기를 같이 쓰면 찬 공기가 방 안을 순환해 더 빨리 시원해지고 냉방 효율도 좋아집니다.',
  ),
];
