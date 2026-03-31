# MacTama Starter

이 폴더는 `Phase 0` 기준 Xcode 초기 소스 뼈대다.

사용 방법:

1. Xcode에서 새 `macOS App` 프로젝트를 만든다
2. 프로젝트 이름을 `MacTama`로 맞춘다
3. 이 폴더 안의 파일들을 프로젝트에 추가한다
4. 메뉴바 앱처럼 동작하게 하려면 `Info.plist`에 `Application is agent (UIElement)`를 추가한다

이 구조는 아래 범위까지를 목표로 한다.

- 메뉴바 아이콘 표시
- 팝오버 열기/닫기
- 충전 상태 감지
- sleep/wake 감지
- 최소 상태 저장/복원

아직 포함하지 않는 것:

- 수치 시스템
- 성향 분기
- 픽셀아트
- 진화 연출
