# P9c 배포 전 보안 설정 검토

이 문서는 제안서다. 원격 배포·WAF 변경·실제 토큰 사용은 수행하지 않았다.

## Worker 예산

|범위|기본값|
|---|---:|
|IPv4 하나 또는 IPv6 /64 요청|60회/분|
|IPv6 /48 보조 요청|240회/분|
|code + IP PIN 연산 입장|20회/분, PBKDF2 전에 원자 차감|
|PIN 인증 성공 계정 동작|20회/분, 읽기·쓰기 포함|
|공개 읽기|code + IP 60회/분, IP 요청 예산도 적용|
|기존 저장 PUT 바이트|IP별 256KiB/분 + 계정별 256KiB/분|
|신규 계정 저장 바이트|IP별 별도 256KiB/분|
|신규 가입|IP별 5회/분 + UTC 일자별 20회/일|
|IPv6 /48 신규 가입|20회/분 + UTC 일자별 200회/일|
|기존 PUT 비상 바이트 차단|128MiB/분|
|신규 저장 비상 바이트 차단|별도 64MiB/분|
|신규 가입 비상 개수 차단|6,000회/분|

전역 요청 1,200회 제한은 제거했다. 기존 PUT과 가입은 바이트 예산을 공유하지 않는다. 기본 IP·계정 예산은 각각 해당 전역 바이트 예산의 1/512 및 1/256이다. `wrangler.toml`과 소스의 기본값을 함께 바꾸며, 사용자별 예산을 전역의 1/8 이하로 유지해야 한다.

실제 이용량 자료는 없다. 용량 설계용 가정인 동시 100개 IP가 각각 분당 256KiB 저장(25MiB)에 대해 기존 저장 비상값은 5.12배다. 가입 100개 IP가 각각 분당 5개 발급받는 가정(500개)에 대해서는 발급 비상값이 12배다. 정상 최대를 실측한 값이나 D1 처리량 보장은 아니다. 기존 PUT 비상값을 소진하려면 512개의 IP·계정 예산이, 신규 저장 비상값에는 최소 256개의 IP 예산이 필요하다. 분 경계의 연속 버스트는 고정 창 특성상 가능하다.

일일 키는 UTC 일자와 정규화 IP의 HMAC이며 분별 키와 별개다. cron은 당일 일일 카운터를 보존하고 지난 일자만 지운다. IP를 계속 바꾸는 분산 공격을 일일 IP 제한으로 완전히 막지는 못한다. `fill.mjs`의 분당 저장량을 24시간에 곱한 예전 추산은 새 일일 한도를 반영하지 않으므로 운영 성장률로 쓰지 않는다. D1 사용량·발급량·429·비상 차단을 관측하고 비용 예산에 맞춰 조정한다.

## 앞단 Cloudflare WAF 속도 제한 제안

운영자가 관리하는 Cloudflare 프록시 호스트에 다음 규칙을 검토한다. 숫자는 초기 제안값이다. 이용자 NAT 공유와 실제 트래픽을 확인한 뒤 조정한다. WAF 카운터만으로 Worker의 D1 한도를 대체하지 않는다.

|대상 식|IP당 제안 상한|동작|
|---|---:|---|
|`starts_with(http.request.uri.path, "/v1/")`|120회/60초|60초 Block, 가능하면 JSON 429|
|`http.request.method eq "POST" and http.request.uri.path eq "/v1/account"`|10회/60초|60초 Block|
|`http.request.method eq "POST" and http.request.uri.path in {"/v1/account/connect" "/v1/save/read" "/v1/rank"}`|30회/60초|60초 Block|

호스트 조건도 운영 도메인으로 한정한다. API에서 characteristics는 `cf.colo.id`, `ip.src`를 사용하며 카운터는 colo별이라는 점을 고려한다. 가능한 period·timeout·규칙 수는 요금제에 따라 검토한다. 선택할 수 없는 60초 값을 그대로 배포하지 않는다. API 클라이언트에 HTML challenge를 반환하면 Godot JSON 흐름이 끊길 수 있어 이 제안은 Block과 JSON 429를 우선한다. 가입 인증은 별도 Turnstile 위젯을 이용한다.

근거: [Cloudflare 속도 제한 매개변수](https://developers.cloudflare.com/waf/rate-limiting-rules/parameters/), [요청 카운터 범위](https://developers.cloudflare.com/waf/rate-limiting-rules/request-rate/), [규칙 작성 절차](https://developers.cloudflare.com/waf/rate-limiting-rules/create-zone-dashboard/). 현재 프로젝트의 `workers.dev` 설정에 위 규칙이 설치되었다는 뜻은 아니다.

## 인증·보관·이관

- `TURNSTILE_ENABLED=true`이면 계정 발급에 토큰이 필수다. 저장 검증과 예산 입장이 성공한 뒤 Siteverify를 호출한다. 따라서 422/429에는 일회용 토큰을 소비하지 않는다. 실패한 Siteverify 시도는 입장 예산을 소비한다. 허용 hostname과 `action=account` 검사도 유지한다.
- PIN 소유자의 다운로드·이력은 `POST /v1/save/read`의 JSON 본문으로 인증한다. PIN을 URL이나 헤더에 싣지 않는다. 코드만의 GET은 code+IP 제한을 쓴다.
- 180일 미사용 계정의 마지막 저장을 추가 30일 보관하는 정책을 유지한다. PIN이 맞는 보관 계정의 PUT·읽기·연결·순위는 410 `archived`다. DELETE는 PIN 확인 후 보관본을 실제 삭제하고 410 `{error:"archived",deleted:true}`를 반환한다. 잘못된 PIN은 403이다. 게임은 410을 보관 상태로 안내하며 `deleted:true`일 때 기기의 자격만 지운다. 로컬 모험은 유지한다.
- 순위 진척 허용 경과는 모든 기준에서 24시간으로 제한한다. 0002의 `rank_at=created`는 유지해 옛 계정·저장·PIN 해시를 보존하며, 이 기준에도 같은 24시간 상한을 적용한다. 이미 적용한 0002를 재작성하거나 재적용할 필요는 없다.
- 필수 secret `IP_HASH_PEPPER`, 개발 기본값과 분리된 운영 secret, 정확한 HTTPS CORS·Turnstile hostname은 기존 절차대로 설정한다. 원격 migration과 배포 전에는 운영자가 기존 DB 백업 및 정책을 확인한다.
