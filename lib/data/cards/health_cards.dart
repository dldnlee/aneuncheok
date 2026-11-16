import '../../models/knowledge_item.dart';

/// 건강 (health)
const List<KnowledgeItem> healthCards = [
  KnowledgeItem(
    id: 'he1',
    categoryId: 'health',
    emoji: '💧',
    title: '하루 물 섭취량',
    content:
        '성인 기준 하루 약 2L(8잔)의 물을 마시는 것이 권장됩니다. 다만 커피, 차, 음식 속 수분도 포함됩니다. 갈증을 느끼면 이미 탈수가 시작된 것입니다.',
  ),
  KnowledgeItem(
    id: 'he2',
    categoryId: 'health',
    emoji: '🧼',
    title: '올바른 손 씻기',
    content:
        '비누로 최소 20초 이상 씻어야 세균이 제거됩니다. 손가락 사이, 손톱 밑, 손목까지 꼼꼼히 씻어야 합니다. 20초는 "생일 축하합니다" 노래를 두 번 부르는 시간입니다.',
  ),
  KnowledgeItem(
    id: 'he3',
    categoryId: 'health',
    emoji: '☕',
    title: '카페인 하루 섭취 한도',
    content:
        '카페인은 성인 하루 400mg 이하지만, 청소년은 몸무게 1kg당 2.5mg 이하(50kg이면 125mg)예요. 큰 사이즈 커피 한 잔만으로도 넘을 수 있으니 주의하세요.',
  ),
  KnowledgeItem(
    id: 'he4',
    categoryId: 'health',
    emoji: '👃',
    title: '코피가 날 때',
    content:
        '코피가 나면 고개를 뒤로 젖히지 말고 앞으로 숙이세요. 콧방울(코의 말랑한 부분)을 10~15분간 꾹 잡아 주세요. 20분이 지나도 멈추지 않으면 병원에 가세요.',
  ),
  KnowledgeItem(
    id: 'he5',
    categoryId: 'health',
    emoji: '😴',
    title: '수면 시간',
    content:
        '성인은 하루 7~9시간의 수면이 권장됩니다. 6시간 이하 수면이 지속되면 인지 능력이 이틀 밤을 새운 것과 비슷한 수준으로 떨어집니다.',
  ),
  KnowledgeItem(
    id: 'he6',
    categoryId: 'health',
    emoji: '🍊',
    title: '약 먹을 때 자몽 주의',
    content:
        '자몽(자몽 주스 포함)은 많은 약물의 대사를 방해합니다. 혈압약, 콜레스테롤약 등과 함께 먹으면 약 효과가 과도하게 강해질 수 있으니 주의하세요.',
  ),
  KnowledgeItem(
    id: 'he7',
    categoryId: 'health',
    emoji: '🪥',
    title: '칫솔 교체 주기',
    content: '칫솔은 약 3개월마다 바꾸는 것이 좋습니다. 칫솔모가 벌어지면 세정력이 떨어지므로 그 전에 교체하세요.',
  ),
  KnowledgeItem(
    id: 'he8',
    categoryId: 'health',
    emoji: '👟',
    title: '만 보를 꼭 걸어야 할까',
    content:
        '하루 만 보가 꼭 필요한 것은 아닙니다. 연구에 따르면 하루 7,000~8,000보만 걸어도 건강에 큰 도움이 됩니다.',
  ),
  KnowledgeItem(
    id: 'he9',
    categoryId: 'health',
    emoji: '☀️',
    title: '실내에서도 자외선',
    content:
        '자외선 A(UVA)는 유리창을 통과해 피부 노화를 일으킵니다. 창가에 오래 있거나 차를 오래 탄다면 실내에서도 자외선 차단제가 도움이 됩니다.',
  ),
  KnowledgeItem(
    id: 'he10',
    categoryId: 'health',
    emoji: '👀',
    title: '20-20-20 눈 휴식법',
    content:
        '화면을 20분 본 뒤에는 20피트(약 6m) 떨어진 곳을 20초 동안 바라보세요. 눈의 피로와 건조함을 줄이는 간단한 방법입니다.',
  ),
  KnowledgeItem(
    id: 'he11',
    categoryId: 'health',
    emoji: '💊',
    title: '해열제 복용 간격',
    content:
        '아세트아미노펜(타이레놀)은 일반 제품은 4~6시간, 8시간용 서방정은 8시간 간격으로 먹어요. 감기약에도 같은 성분이 들어 있을 수 있으니 겹치지 않게 설명서를 꼭 확인하세요.',
  ),
  KnowledgeItem(
    id: 'he12',
    categoryId: 'health',
    emoji: '🛌',
    title: '청소년의 권장 수면',
    content:
        '청소년(13~18세)은 하루 8~10시간 자는 것이 권장됩니다. 잠이 부족하면 집중력과 기분, 성장에 영향을 줄 수 있어요.',
  ),
  KnowledgeItem(
    id: 'he13',
    categoryId: 'health',
    emoji: '📱',
    title: '자기 전 스마트폰',
    content:
        '잠들기 전 스마트폰의 밝은 빛은 졸음을 부르는 호르몬 분비를 방해해 잠들기 어렵게 만들 수 있어요. 자기 전 한 시간은 화면을 줄여 보세요.',
  ),
  KnowledgeItem(
    id: 'he14',
    categoryId: 'health',
    emoji: '🎧',
    title: '이어폰 60-60 규칙',
    content:
        '이어폰은 최대 볼륨의 60% 이하로, 한 번에 60분 이내로 듣는 것이 귀 건강에 좋아요. 큰 소리로 오래 들으면 청력이 손상될 수 있습니다.',
  ),
  KnowledgeItem(
    id: 'he15',
    categoryId: 'health',
    emoji: '🤧',
    title: '감기에 항생제?',
    content:
        '감기는 바이러스 때문에 생기는 병이라 세균을 죽이는 항생제가 듣지 않아요. 항생제를 함부로 먹으면 내성이 생길 수 있어요.',
  ),
  KnowledgeItem(
    id: 'he16',
    categoryId: 'health',
    emoji: '🧴',
    title: '손소독제보다 비누',
    content:
        '손소독제는 편리하지만 눈에 보이는 흙이나 기름때는 잘 없애지 못해요. 손이 더러울 땐 비누로 씻는 것이 가장 좋습니다.',
  ),
  KnowledgeItem(
    id: 'he17',
    categoryId: 'health',
    emoji: '🪥',
    title: '칫솔질은 부드럽게',
    content: '이를 세게 문지르면 잇몸과 이가 상할 수 있어요. 부드러운 칫솔로 잇몸 경계까지 구석구석 약하게 닦아 주세요.',
  ),
  KnowledgeItem(
    id: 'he18',
    categoryId: 'health',
    emoji: '🧵',
    title: '치실이 필요한 이유',
    content: '칫솔이 닿지 않는 이 사이는 치실로 닦아야 해요. 이 사이에 낀 음식물이 충치와 잇몸병의 원인이 될 수 있습니다.',
  ),
  KnowledgeItem(
    id: 'he19',
    categoryId: 'health',
    emoji: '🌡️',
    title: '정상 체온',
    content:
        '사람의 평균 체온은 약 36.5℃이고, 정상 범위는 대략 36~37.5℃예요. 체온은 시간, 활동, 측정 부위에 따라 조금씩 달라집니다.',
  ),
  KnowledgeItem(
    id: 'he20',
    categoryId: 'health',
    emoji: '🌤️',
    title: '햇빛과 비타민 D',
    content:
        '피부가 햇빛을 받으면 몸에서 비타민 D가 만들어져 뼈를 튼튼하게 해줘요. 다만 너무 오래 쬐면 화상과 피부 손상이 생기니 적당히 쬐세요.',
  ),
  KnowledgeItem(
    id: 'he21',
    categoryId: 'health',
    emoji: '👀',
    title: '야외 활동과 시력',
    content:
        '밖에서 햇빛을 받으며 노는 시간이 길수록 어린이와 청소년의 근시가 덜 진행된다는 연구들이 있어요. 가까운 화면만 오래 보는 건 피하세요.',
  ),
  KnowledgeItem(
    id: 'he22',
    categoryId: 'health',
    emoji: '🧍',
    title: '거북목 주의',
    content:
        '스마트폰을 볼 때 고개를 숙일수록 목이 지탱해야 하는 무게가 크게 늘어나요. 화면을 눈높이로 올려서 보면 목 부담을 줄일 수 있어요.',
  ),
  KnowledgeItem(
    id: 'he23',
    categoryId: 'health',
    emoji: '🥶',
    title: '추우면 떨리는 이유',
    content:
        '근육이 빠르게 떨리면 열이 나서 체온을 지키는 데 도움이 돼요. 몸이 떨리는 건 체온을 유지하려는 자연스러운 반응입니다.',
  ),
  KnowledgeItem(
    id: 'he24',
    categoryId: 'health',
    emoji: '🦟',
    title: '모기에 물렸을 때',
    content: '모기에 물리면 긁지 말고 찬물이나 얼음 찜질로 가려움을 가라앉히세요. 긁으면 상처가 나서 염증이 생길 수 있어요.',
  ),
  KnowledgeItem(
    id: 'he25',
    categoryId: 'health',
    emoji: '🥜',
    title: '심한 알레르기 반응',
    content:
        '심한 알레르기는 몇 분 만에 두드러기, 입술·목 부음, 숨쉬기 힘듦, 어지러움이 나타나요. 처방받은 에피네프린 주사가 있으면 바로 쓰고, 지체 없이 119에 신고하세요.',
  ),
  KnowledgeItem(
    id: 'he26',
    categoryId: 'health',
    emoji: '🏃',
    title: '운동 전 준비운동',
    content:
        '운동 전에 몸을 가볍게 풀어 주면 근육이 따뜻해지고 부상 위험이 줄어들어요. 운동이 끝난 뒤에는 정리운동으로 천천히 마무리하세요.',
  ),
  KnowledgeItem(
    id: 'he27',
    categoryId: 'health',
    emoji: '🥤',
    title: '단 음료와 충치',
    content:
        '단 음료를 마시면 입안 세균이 당을 먹고 산을 만들어 이를 상하게 해요. 마신 뒤에는 물로 입을 헹구는 습관이 도움이 됩니다.',
  ),
  KnowledgeItem(
    id: 'he28',
    categoryId: 'health',
    emoji: '😮‍💨',
    title: '심호흡으로 긴장 풀기',
    content: '긴장될 때 숨을 천천히 깊게 들이쉬고 길게 내쉬면 몸이 편안해지는 데 도움이 돼요. 시험이나 발표 전에 해 보세요.',
  ),
];
