import '../../models/knowledge_item.dart';

/// 디지털 (digital life and online safety)
const List<KnowledgeItem> digitalCards = [
  KnowledgeItem(
    id: 'dig1',
    categoryId: 'digital',
    emoji: '🔑',
    title: '비밀번호는 길게',
    content: '비밀번호는 짧고 복잡한 것보다 길고 나만 아는 것이 안전해요. 생일이나 1234처럼 쉽게 추측되는 번호는 피하세요.',
  ),
  KnowledgeItem(
    id: 'dig2',
    categoryId: 'digital',
    emoji: '🔁',
    title: '같은 비밀번호 돌려쓰기 금지',
    content:
        '여러 사이트에 같은 비밀번호를 쓰면 한 곳이 털릴 때 다른 계정도 위험해져요. 중요한 계정은 서로 다른 비밀번호를 쓰세요.',
  ),
  KnowledgeItem(
    id: 'dig3',
    categoryId: 'digital',
    emoji: '🛡️',
    title: '2단계 인증',
    content: '2단계 인증을 켜면 비밀번호가 털려도 문자나 앱으로 한 번 더 확인하기 때문에 계정을 지킬 수 있어요.',
  ),
  KnowledgeItem(
    id: 'dig4',
    categoryId: 'digital',
    emoji: '📍',
    title: '사진 속 위치 정보',
    content:
        '스마트폰으로 찍은 사진에는 촬영 위치와 시간이 숨어 있을 수 있어요. SNS에 올릴 때는 집이나 학교가 드러나지 않게 주의하세요.',
  ),
  KnowledgeItem(
    id: 'dig5',
    categoryId: 'digital',
    emoji: '📶',
    title: '공용 와이파이 조심',
    content:
        '카페나 공항의 공용 와이파이는 보안이 약할 수 있어요. 로그인이나 결제처럼 중요한 일은 모바일 데이터로 하는 것이 안전해요.',
  ),
  KnowledgeItem(
    id: 'dig6',
    categoryId: 'digital',
    emoji: '🔍',
    title: '가짜뉴스 구별법',
    content:
        '뉴스를 공유하기 전에 누가 언제 쓴 글인지, 믿을 만한 다른 곳에도 같은 내용이 있는지 확인해 보세요. 자극적인 제목일수록 더 의심해 보세요.',
  ),
  KnowledgeItem(
    id: 'dig7',
    categoryId: 'digital',
    emoji: '🖼️',
    title: '이미지에도 저작권이 있어요',
    content:
        '인터넷에서 찾은 사진이나 그림은 대부분 만든 사람의 저작물이에요. 마음대로 쓰면 안 되고, 사용해도 되는지 확인해야 해요.',
  ),
  KnowledgeItem(
    id: 'dig8',
    categoryId: 'digital',
    emoji: '💬',
    title: '악플은 범죄가 될 수 있어요',
    content:
        '온라인에서 남을 모욕하거나 깎아내리면 모욕죄나 명예훼손으로 처벌받을 수 있어요. 사실인 내용이라도 명예훼손이 될 수 있고, 익명이어도 추적될 수 있어요.',
  ),
  KnowledgeItem(
    id: 'dig9',
    categoryId: 'digital',
    emoji: '🔒',
    title: '자물쇠 아이콘의 진실',
    content:
        '주소창의 자물쇠는 통신이 암호화되었다는 뜻이지, 그 사이트가 믿을 만하다는 보증은 아니에요. 가짜 사이트에도 자물쇠가 있을 수 있어요.',
  ),
  KnowledgeItem(
    id: 'dig10',
    categoryId: 'digital',
    emoji: '📲',
    title: '앱은 공식 스토어에서',
    content: '앱은 공식 앱 스토어에서만 설치하세요. 출처를 모르는 파일이나 링크로 설치하면 악성 앱일 수 있어요.',
  ),
  KnowledgeItem(
    id: 'dig11',
    categoryId: 'digital',
    emoji: '🔄',
    title: '업데이트는 보안이에요',
    content:
        '스마트폰과 앱 업데이트에는 새로 발견된 보안 구멍을 막는 내용이 들어 있어요. 귀찮아도 업데이트하면 해킹 위험이 줄어요.',
  ),
  KnowledgeItem(
    id: 'dig12',
    categoryId: 'digital',
    emoji: '🕶️',
    title: '시크릿 모드의 한계',
    content:
        '시크릿(비공개) 모드는 내 기기에 방문 기록을 남기지 않을 뿐이에요. 학교나 회사, 인터넷 업체에는 접속 기록이 남을 수 있어요.',
  ),
  KnowledgeItem(
    id: 'dig13',
    categoryId: 'digital',
    emoji: '🔢',
    title: '비트와 바이트',
    content:
        '컴퓨터 정보의 가장 작은 단위는 비트(bit)이고, 8비트가 1바이트예요. 인터넷 속도의 Mbps를 8로 나누면 MB/s가 돼요.',
  ),
  KnowledgeItem(
    id: 'dig14',
    categoryId: 'digital',
    emoji: '🫧',
    title: '필터 버블',
    content:
        '추천 알고리즘은 내가 본 것과 비슷한 영상과 글을 계속 보여 줘요. 한쪽 생각만 접하게 될 수 있으니 일부러 다양한 정보를 찾아보세요.',
  ),
  KnowledgeItem(
    id: 'dig15',
    categoryId: 'digital',
    emoji: '📷',
    title: 'QR코드도 조심해요',
    content:
        '출처를 모르는 QR코드를 찍으면 가짜 사이트로 연결될 수 있어요. 찍은 뒤 나온 주소를 꼭 확인하고, 이상하면 열지 마세요.',
  ),
  KnowledgeItem(
    id: 'dig16',
    categoryId: 'digital',
    emoji: '🚨',
    title: '온라인 피해를 당했다면',
    content:
        '온라인 사기, 해킹, 협박을 당했다면 혼자 해결하려 하지 말고 보호자에게 알리고 경찰(112)에 신고하세요. 증거 화면은 지우지 말고 저장해 두세요.',
  ),
];
