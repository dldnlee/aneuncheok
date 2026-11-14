import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/knowledge_item.dart';

final List<Category> categories = [
  const Category(
    id: 'daily',
    name: '생활',
    icon: Icons.home,
    color: Color(0xFFE57373),
  ),
  const Category(
    id: 'health',
    name: '건강',
    icon: Icons.favorite,
    color: Color(0xFF64B5F6),
  ),
  const Category(
    id: 'food',
    name: '음식',
    icon: Icons.restaurant,
    color: Color(0xFFFFB74D),
  ),
  const Category(
    id: 'money',
    name: '돈',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF81C784),
  ),
  const Category(
    id: 'safety',
    name: '안전',
    icon: Icons.shield,
    color: Color(0xFFBA68C8),
  ),
  const Category(
    id: 'body',
    name: '인체',
    icon: Icons.accessibility_new,
    color: Color(0xFF4DB6AC),
  ),
];

final List<KnowledgeItem> knowledgeItems = [
  // 생활 (Daily Life)
  const KnowledgeItem(
    id: 'd1',
    categoryId: 'daily',
    title: '유통기한 ≠ 못 먹는 날',
    content: '유통기한은 판매 가능한 기한이지, 먹으면 안 되는 날짜가 아닙니다. 2023년부터는 "소비기한" 표시로 바뀌고 있으며, 소비기한은 실제로 먹어도 되는 마지막 날짜입니다.',
  ),
  const KnowledgeItem(
    id: 'd2',
    categoryId: 'daily',
    title: '전자레인지에 금속',
    content: '전자레인지에 금속을 넣으면 전자파가 반사되어 불꽃이 튀고 화재가 날 수 있습니다. 알루미늄 호일, 스테인리스 그릇, 금테 접시 등은 절대 넣지 마세요.',
  ),
  const KnowledgeItem(
    id: 'd3',
    categoryId: 'daily',
    title: '건전지 보관법',
    content: '건전지를 냉장고에 보관하면 결로(물방울)가 생겨 오히려 수명이 줄어듭니다. 상온의 건조한 곳에 보관하는 것이 가장 좋습니다.',
  ),
  const KnowledgeItem(
    id: 'd4',
    categoryId: 'daily',
    title: '핸드폰 충전',
    content: '리튬이온 배터리는 0%까지 방전하면 수명이 줄어듭니다. 20~80% 사이를 유지하는 것이 배터리 수명에 가장 좋습니다. 밤새 충전해도 과충전은 되지 않습니다.',
  ),
  const KnowledgeItem(
    id: 'd5',
    categoryId: 'daily',
    title: '세탁 표시 삼각형',
    content: '옷 태그의 삼각형 표시는 표백 가능 여부입니다. 빈 삼각형은 표백 가능, X 친 삼각형은 표백 불가, 빗금 삼각형은 산소계 표백만 가능합니다.',
  ),
  const KnowledgeItem(
    id: 'd6',
    categoryId: 'daily',
    title: '화장실 환풍기',
    content: '샤워 후 환풍기는 최소 15~20분 이상 돌려야 습기가 제대로 빠집니다. 습기를 방치하면 곰팡이가 생기고, 곰팡이 포자는 호흡기 질환을 유발할 수 있습니다.',
  ),
  const KnowledgeItem(
    id: 'd7',
    categoryId: 'daily',
    title: '수도꼭지 방향',
    content: '대부분의 수도꼭지는 왼쪽이 온수, 오른쪽이 냉수입니다. 이는 국제 표준으로, 오른손잡이가 냉수를 쉽게 틀 수 있도록 설계된 것입니다.',
  ),

  const KnowledgeItem(
    id: 'd8',
    categoryId: 'daily',
    title: '재활용품은 헹궈서',
    content: '음식물이 묻은 용기는 재활용이 되지 않고 일반쓰레기가 됩니다. 내용물을 비우고 물로 헹군 뒤, 라벨 등 다른 재질은 떼어서 배출하세요.',
  ),
  const KnowledgeItem(
    id: 'd9',
    categoryId: 'daily',
    title: '119, 112, 120',
    content: '화재·구급은 119, 범죄 신고는 112입니다. 120은 지자체의 민원·생활 불편 상담 번호(서울은 다산콜센터)로, 긴급 상황에는 쓰지 않습니다.',
  ),
  const KnowledgeItem(
    id: 'd10',
    categoryId: 'daily',
    title: '멀티탭 문어발',
    content: '멀티탭에는 정격 용량(보통 15~16A, 약 3,300~3,500W)이 있습니다. 전기히터, 전기밥솥 같은 고출력 제품을 한 곳에 여러 개 꽂으면 과열되어 화재가 날 수 있습니다.',
  ),
  const KnowledgeItem(
    id: 'd11',
    categoryId: 'daily',
    title: '침구 세탁 주기',
    content: '이불과 베개 커버는 1~2주에 한 번 세탁하는 것이 좋습니다. 땀과 각질이 쌓이면 집먼지진드기가 번식하기 쉽습니다.',
  ),
  const KnowledgeItem(
    id: 'd12',
    categoryId: 'daily',
    title: '냉장고는 70%만',
    content: '냉장실은 70% 정도만 채워야 냉기가 잘 순환합니다. 반대로 냉동실은 가득 채워야 서로 냉기를 유지해 효율이 좋습니다.',
  ),

  // 건강 (Health)
  const KnowledgeItem(
    id: 'he1',
    categoryId: 'health',
    title: '하루 물 섭취량',
    content: '성인 기준 하루 약 2L(8잔)의 물을 마시는 것이 권장됩니다. 다만 커피, 차, 음식 속 수분도 포함됩니다. 갈증을 느끼면 이미 탈수가 시작된 것입니다.',
  ),
  const KnowledgeItem(
    id: 'he2',
    categoryId: 'health',
    title: '올바른 손 씻기',
    content: '비누로 최소 20초 이상 씻어야 세균이 제거됩니다. 손가락 사이, 손톱 밑, 손목까지 꼼꼼히 씻어야 합니다. 20초는 "생일 축하합니다" 노래를 두 번 부르는 시간입니다.',
  ),
  const KnowledgeItem(
    id: 'he3',
    categoryId: 'health',
    title: '카페인 하루 권장량',
    content: '성인 기준 카페인은 하루 400mg 이하가 권장됩니다. 아메리카노 한 잔이 약 100~150mg이므로, 하루 3잔 정도가 적당합니다.',
  ),
  const KnowledgeItem(
    id: 'he4',
    categoryId: 'health',
    title: '코피가 날 때',
    content: '코피가 나면 고개를 뒤로 젖히면 안 됩니다. 피가 목으로 넘어가 구역질을 유발할 수 있습니다. 고개를 앞으로 숙이고 콧방울을 5~10분 꽉 잡아주세요.',
  ),
  const KnowledgeItem(
    id: 'he5',
    categoryId: 'health',
    title: '수면 시간',
    content: '성인은 하루 7~9시간의 수면이 권장됩니다. 6시간 이하 수면이 지속되면 인지 능력이 이틀 밤을 새운 것과 비슷한 수준으로 떨어집니다.',
  ),
  const KnowledgeItem(
    id: 'he6',
    categoryId: 'health',
    title: '약 먹을 때 자몽 주의',
    content: '자몽(자몽 주스 포함)은 많은 약물의 대사를 방해합니다. 혈압약, 콜레스테롤약 등과 함께 먹으면 약 효과가 과도하게 강해질 수 있으니 주의하세요.',
  ),

  const KnowledgeItem(
    id: 'he7',
    categoryId: 'health',
    title: '칫솔 교체 주기',
    content: '칫솔은 약 3개월마다 바꾸는 것이 좋습니다. 칫솔모가 벌어지면 세정력이 떨어지므로 그 전에 교체하세요.',
  ),
  const KnowledgeItem(
    id: 'he8',
    categoryId: 'health',
    title: '만 보를 꼭 걸어야 할까',
    content: '하루 만 보가 꼭 필요한 것은 아닙니다. 연구에 따르면 하루 7,000~8,000보만 걸어도 건강에 큰 도움이 됩니다.',
  ),
  const KnowledgeItem(
    id: 'he9',
    categoryId: 'health',
    title: '실내에서도 자외선',
    content: '자외선 A(UVA)는 유리창을 통과해 피부 노화를 일으킵니다. 창가에 오래 있거나 차를 오래 탄다면 실내에서도 자외선 차단제가 도움이 됩니다.',
  ),
  const KnowledgeItem(
    id: 'he10',
    categoryId: 'health',
    title: '20-20-20 눈 휴식법',
    content: '화면을 20분 본 뒤에는 20피트(약 6m) 떨어진 곳을 20초 동안 바라보세요. 눈의 피로와 건조함을 줄이는 간단한 방법입니다.',
  ),
  const KnowledgeItem(
    id: 'he11',
    categoryId: 'health',
    title: '해열제 복용 간격',
    content: '아세트아미노펜(타이레놀)은 보통 4~6시간 이상 간격을 두고 먹어야 합니다. 하루 최대 용량을 넘기면 간 손상 위험이 있으니 설명서를 꼭 확인하세요.',
  ),

  // 음식 (Food)
  const KnowledgeItem(
    id: 'f1',
    categoryId: 'food',
    title: '계란 신선도 확인',
    content: '물에 계란을 넣었을 때 가라앉으면 신선한 것, 옆으로 기울면 먹을 수 있는 수준, 물 위에 뜨면 상한 것입니다. 오래될수록 내부에 공기가 많아져 뜹니다.',
  ),
  const KnowledgeItem(
    id: 'f2',
    categoryId: 'food',
    title: '밥 한 공기 칼로리',
    content: '밥 한 공기(약 210g)는 약 300kcal입니다. 이는 성인 하루 권장 칼로리(2,000~2,500kcal)의 약 12~15%에 해당합니다.',
  ),
  const KnowledgeItem(
    id: 'f3',
    categoryId: 'food',
    title: '소금 하루 권장량',
    content: '세계보건기구(WHO)가 권장하는 하루 소금 섭취량은 5g(나트륨 2,000mg)입니다. 라면 한 개에 약 1,800mg의 나트륨이 들어 있어 거의 하루치에 가깝습니다.',
  ),
  const KnowledgeItem(
    id: 'f4',
    categoryId: 'food',
    title: '꿀은 절대 안 상한다',
    content: '꿀은 수분 함량이 낮고 산성이 강해 세균이 살 수 없습니다. 이집트 피라미드에서 3,000년 된 꿀이 발견되었는데, 여전히 먹을 수 있는 상태였습니다.',
  ),
  const KnowledgeItem(
    id: 'f5',
    categoryId: 'food',
    title: '바나나 보관법',
    content: '바나나는 냉장 보관하면 껍질이 까맣게 변하지만 과육은 오래 보존됩니다. 꼭지를 랩으로 감싸면 에틸렌 가스 방출을 줄여 숙성을 늦출 수 있습니다.',
  ),
  const KnowledgeItem(
    id: 'f6',
    categoryId: 'food',
    title: '냉동 고기 해동법',
    content: '실온 해동은 세균 번식 위험이 있습니다. 냉장실에서 천천히 해동하거나, 밀봉 후 찬물에 담그는 것이 안전합니다. 전자레인지 해동 후에는 바로 조리하세요.',
  ),

  const KnowledgeItem(
    id: 'f7',
    categoryId: 'food',
    title: '싹 난 감자',
    content: '감자의 싹과 초록빛 껍질에는 솔라닌이라는 독소가 있어 복통과 구토를 일으킬 수 있습니다. 싹이 많이 났거나 초록색이 넓다면 버리는 것이 안전합니다.',
  ),
  const KnowledgeItem(
    id: 'f8',
    categoryId: 'food',
    title: '남은 밥 보관법',
    content: '밥을 실온에 오래 두면 바실러스 세레우스균이 번식해 식중독을 일으킬 수 있습니다. 남은 밥은 식혀서 바로 소분해 냉동 보관하세요.',
  ),
  const KnowledgeItem(
    id: 'f9',
    categoryId: 'food',
    title: '토마토는 익혀서',
    content: '토마토의 라이코펜은 열을 가하고 기름과 함께 먹을 때 몸에 더 잘 흡수됩니다. 생으로 먹는 것보다 올리브유에 볶아 먹는 것이 유리합니다.',
  ),
  const KnowledgeItem(
    id: 'f10',
    categoryId: 'food',
    title: '달걀 보관 방향',
    content: '달걀은 둥근 쪽(공기주머니)이 위로 가게 두면 신선도가 더 오래 유지됩니다. 껍질을 씻지 말고 냉장 보관하세요.',
  ),
  const KnowledgeItem(
    id: 'f11',
    categoryId: 'food',
    title: '세균이 번식하는 온도',
    content: '음식은 5~60℃ 사이에서 세균이 빠르게 번식합니다. 조리한 음식은 2시간 이내에 냉장하고, 다시 먹을 때는 속까지 충분히 데우세요.',
  ),

  // 돈 (Money)
  const KnowledgeItem(
    id: 'm1',
    categoryId: 'money',
    title: '복리의 힘',
    content: '연 7% 복리로 투자하면 약 10년 만에 원금이 2배가 됩니다. "72의 법칙"으로 계산할 수 있는데, 72를 수익률로 나누면 원금 2배까지 걸리는 햇수입니다.',
  ),
  const KnowledgeItem(
    id: 'm2',
    categoryId: 'money',
    title: '신용등급과 신용점수',
    content: '신용등급(1~10등급)은 2021년부터 신용점수(1~1,000점)로 바뀌었습니다. 점수가 높을수록 대출 금리가 낮아지고, 카드 발급이 쉬워집니다.',
  ),
  const KnowledgeItem(
    id: 'm3',
    categoryId: 'money',
    title: '연말정산 뜻',
    content: '연말정산은 1년간 낸 세금과 실제 내야 할 세금을 비교해서 더 냈으면 돌려받고, 덜 냈으면 더 내는 정산 과정입니다. 매년 1~2월에 진행됩니다.',
  ),
  const KnowledgeItem(
    id: 'm4',
    categoryId: 'money',
    title: '비상금 권장 규모',
    content: '예상치 못한 상황에 대비해 최소 월 생활비의 3~6개월분은 비상금으로 준비해두는 것이 좋습니다. 이 돈은 입출금이 자유로운 계좌에 보관하세요.',
  ),
  const KnowledgeItem(
    id: 'm5',
    categoryId: 'money',
    title: '4대 보험',
    content: '직장인이 가입하는 4대 보험은 국민연금, 건강보험, 고용보험, 산재보험입니다. 급여에서 자동으로 공제되며, 회사와 근로자가 나누어 부담합니다.',
  ),

  const KnowledgeItem(
    id: 'm6',
    categoryId: 'money',
    title: '체크카드 vs 신용카드',
    content: '신용카드는 먼저 쓰고 나중에 갚는 후불 결제이고, 체크카드는 계좌 잔액에서 바로 빠져나갑니다. 연말정산 소득공제율은 신용카드 15%, 체크카드 30%입니다.',
  ),
  const KnowledgeItem(
    id: 'm7',
    categoryId: 'money',
    title: '인플레이션',
    content: '인플레이션은 물가가 계속 오르는 현상입니다. 같은 돈으로 살 수 있는 물건이 줄어들기 때문에, 예금 금리가 물가상승률보다 낮으면 실질 가치는 줄어듭니다.',
  ),
  const KnowledgeItem(
    id: 'm8',
    categoryId: 'money',
    title: 'ETF란?',
    content: 'ETF(상장지수펀드)는 주가지수 등을 따라가도록 만든 펀드를 주식처럼 사고팔 수 있게 한 상품입니다. 한 번에 여러 종목에 분산 투자하는 효과가 있습니다.',
  ),
  const KnowledgeItem(
    id: 'm9',
    categoryId: 'money',
    title: '리볼빙의 함정',
    content: '리볼빙은 카드 결제 금액의 일부만 내고 나머지를 다음 달로 넘기는 서비스입니다. 연 15~20% 안팎의 높은 수수료가 붙어 빚이 빠르게 불어날 수 있습니다.',
  ),
  const KnowledgeItem(
    id: 'm10',
    categoryId: 'money',
    title: '전입신고와 확정일자',
    content: '전세나 월세로 이사하면 전입신고를 하고 확정일자를 받아두세요. 전입신고는 대항력을, 확정일자는 보증금을 우선 돌려받을 권리(우선변제권)를 갖게 해줍니다.',
  ),

  // 안전 (Safety)
  const KnowledgeItem(
    id: 'sa1',
    categoryId: 'safety',
    title: '지진 발생 시',
    content: '지진이 나면 테이블 아래로 들어가 머리를 보호하세요. 엘리베이터는 절대 타지 말고 계단을 이용하세요. 건물 밖에서는 건물에서 떨어져 넓은 공간으로 이동하세요.',
  ),
  const KnowledgeItem(
    id: 'sa2',
    categoryId: 'safety',
    title: '소화기 사용법',
    content: '소화기 사용법은 "당·비·빗·쏴"입니다. 안전핀을 당기고, 노즐을 빼고, 바람을 등지고 빗자루 쓸 듯이 쏴주면 됩니다. 화점에서 1.5~3m 거리를 유지하세요.',
  ),
  const KnowledgeItem(
    id: 'sa3',
    categoryId: 'safety',
    title: '벌에 쏘였을 때',
    content: '벌에 쏘이면 신용카드 등으로 밀어서 벌침을 빼세요. 핀셋으로 집으면 독이 더 들어갑니다. 쏘인 부위를 차갑게 해주고, 호흡곤란이 오면 즉시 119에 신고하세요.',
  ),
  const KnowledgeItem(
    id: 'sa4',
    categoryId: 'safety',
    title: '심폐소생술 (CPR)',
    content: '의식이 없고 호흡이 없는 사람을 발견하면 119에 신고 후 즉시 심폐소생술을 시작하세요. 가슴 중앙을 분당 100~120회 속도로, 약 5cm 깊이로 압박합니다.',
  ),
  const KnowledgeItem(
    id: 'sa5',
    categoryId: 'safety',
    title: '화상 응급처치',
    content: '화상을 입으면 즉시 흐르는 찬물로 10~20분간 식혀주세요. 얼음을 직접 대거나, 된장·치약·알로에를 바르면 오히려 감염 위험이 높아집니다.',
  ),

  const KnowledgeItem(
    id: 'sa6',
    categoryId: 'safety',
    title: '하임리히법',
    content: '음식물이 목에 걸려 말을 못 하면 119에 신고하고 하임리히법을 하세요. 뒤에서 허리를 감싸 안고 주먹을 명치 아래에 대고 위로 힘껏 밀어 올립니다. 영아와 임산부는 방법이 다릅니다.',
  ),
  const KnowledgeItem(
    id: 'sa7',
    categoryId: 'safety',
    title: '화재 시 대피 요령',
    content: '화재가 나면 젖은 수건으로 코와 입을 막고 낮은 자세로 대피하세요. 연기는 위로 모입니다. 엘리베이터는 타지 말고 계단을 이용하세요.',
  ),
  const KnowledgeItem(
    id: 'sa8',
    categoryId: 'safety',
    title: '가스 냄새가 날 때',
    content: '가스 냄새가 나면 먼저 밸브를 잠그고 창문을 열어 환기하세요. 전등이나 환풍기 스위치를 켜면 불꽃이 튈 수 있으니 만지지 말고, 밖으로 나가 신고하세요.',
  ),
  const KnowledgeItem(
    id: 'sa9',
    categoryId: 'safety',
    title: '전동킥보드 헬멧',
    content: '전동킥보드 같은 개인형 이동장치는 헬멧 착용이 의무이며, 어기면 범칙금 2만 원이 부과됩니다. 운전면허도 필요하고 인도 주행은 금지입니다.',
  ),
  const KnowledgeItem(
    id: 'sa10',
    categoryId: 'safety',
    title: '보이스피싱 대처',
    content: '수사기관이나 금융기관은 전화로 돈을 보내라거나 앱을 설치하라고 하지 않습니다. 의심되면 바로 끊고 112 또는 금융감독원(1332)에 확인하세요.',
  ),

  // 인체 (Body)
  const KnowledgeItem(
    id: 'b1',
    categoryId: 'body',
    title: '혈액형과 성격',
    content: '혈액형으로 성격을 판단하는 것은 과학적 근거가 없습니다. 혈액형은 적혈구 표면의 항원 종류를 나타내는 것일 뿐, 성격과는 아무 관련이 없습니다.',
  ),
  const KnowledgeItem(
    id: 'b2',
    categoryId: 'body',
    title: '뼈 개수',
    content: '성인의 뼈는 약 206개입니다. 아기는 약 270개의 뼈를 갖고 태어나지만, 자라면서 여러 뼈가 합쳐져 줄어듭니다.',
  ),
  const KnowledgeItem(
    id: 'b3',
    categoryId: 'body',
    title: '관절 꺾을 때 소리',
    content: '손가락 관절을 꺾을 때 나는 "뚝" 소리는 관절액 속 기포가 터지는 소리입니다. 관절을 꺾는 것이 관절염을 유발한다는 것은 과학적으로 입증되지 않았습니다.',
  ),
  const KnowledgeItem(
    id: 'b4',
    categoryId: 'body',
    title: '혀의 미각 지도는 거짓',
    content: '혀의 특정 부위에서만 특정 맛을 느낀다는 "미각 지도"는 잘못된 상식입니다. 실제로 혀 전체에서 모든 맛(단맛, 짠맛, 신맛, 쓴맛, 감칠맛)을 느낄 수 있습니다.',
  ),
  const KnowledgeItem(
    id: 'b5',
    categoryId: 'body',
    title: '하품은 왜 전염될까',
    content: '하품이 전염되는 것은 "거울 뉴런" 때문입니다. 다른 사람의 행동을 보면 뇌가 자동으로 따라하려는 반응이며, 공감 능력과 관련이 있다고 알려져 있습니다.',
  ),
  const KnowledgeItem(
    id: 'b6',
    categoryId: 'body',
    title: '눈 깜빡임',
    content: '사람은 1분에 평균 15~20번 눈을 깜빡입니다. 하루에 약 2만 번이며, 컴퓨터나 스마트폰을 볼 때는 깜빡임 횟수가 절반으로 줄어 눈이 건조해집니다.',
  ),
  const KnowledgeItem(
    id: 'b7',
    categoryId: 'body',
    title: '몸의 60%는 물',
    content: '성인 몸무게의 약 60%는 물입니다. 신생아는 이보다 높고, 나이가 들수록 수분 비율이 줄어듭니다.',
  ),
  const KnowledgeItem(
    id: 'b8',
    categoryId: 'body',
    title: '쉬지 않는 심장',
    content: '성인의 심장은 안정 시 1분에 60~100번 뜁니다. 하루에 약 10만 번 뛰면서 온몸으로 피를 보냅니다.',
  ),
  const KnowledgeItem(
    id: 'b9',
    categoryId: 'body',
    title: '가장 큰 장기, 피부',
    content: '피부는 몸에서 가장 큰 장기로, 성인 기준 면적이 약 1.5~2㎡입니다. 겉의 표피는 약 4주마다 새것으로 바뀝니다.',
  ),
  const KnowledgeItem(
    id: 'b10',
    categoryId: 'body',
    title: '뇌는 10%만 쓴다?',
    content: '사람이 뇌의 10%만 쓴다는 말은 사실이 아닙니다. 뇌는 하루 종일 대부분의 영역이 활동하며, 몸무게의 2%지만 에너지는 약 20%를 씁니다.',
  ),
  const KnowledgeItem(
    id: 'b11',
    categoryId: 'body',
    title: '딸꾹질의 정체',
    content: '딸꾹질은 가로막(횡격막)이 갑자기 수축하고 성대 사이가 닫히면서 나는 소리입니다. 대부분 몇 분 안에 멈추지만, 48시간 넘게 이어지면 병원에 가세요.',
  ),
];

List<KnowledgeItem> getItemsByCategory(String categoryId) {
  return knowledgeItems.where((item) => item.categoryId == categoryId).toList();
}
