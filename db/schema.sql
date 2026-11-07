-- 데모 채팅 앱 스키마. 앱이 시작할 때 적용한다 (store.go의 Migrate).
-- 여러 번 실행해도 안전해야 한다: 이미 있으면 아무것도 바꾸지 않는다.
CREATE TABLE IF NOT EXISTS chat_messages (
  id            bigserial PRIMARY KEY,
  -- 클라이언트가 만든 ID. 재전송해도 한 번만 저장되고, 유실 검증의 기준이 된다
  client_msg_id text NOT NULL UNIQUE CHECK (length(client_msg_id) BETWEEN 8 AND 64),
  author        text NOT NULL,
  body          text NOT NULL,
  -- 이 메시지를 처리한 앱의 환경 (env-a, env-b)
  app_env       text NOT NULL,
  -- 이 메시지가 처음 저장된 DB. 기본값은 쓰기를 받은 서버에서 계산되고,
  -- 논리 복제는 값 자체를 옮기므로 복제된 행에서도 원래 값이 유지된다.
  -- app.node_name은 DB 운영 쪽에서 서버마다 설정한다 (없으면 unknown)
  db_node       text NOT NULL DEFAULT coalesce(current_setting('app.node_name', true), 'unknown'),
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- 일본어 번역 (에이전트가 함께 보낸다. 사람이 보낸 메시지는 비어 있다).
-- 컬럼이 이미 있으면 아무것도 바꾸지 않는다
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS translation text;

-- ─────────────────────────────────────────────────────────────────────────────
-- 원본 EKS(chat-source/chat-db, DB chat)에 화면용 샘플 데이터와 함께 들어간 표들.
-- 데이터는 이전 플랫폼의 복제가 옮기므로 여기서는 정의만 원본과 똑같이 만든다
-- (기준: 원본 pg_dump --schema-only, PostgreSQL 16.15, 2026-11-07).
-- 원본에는 기본 키 말고 외래 키·인덱스·시퀀스가 없다. 그래서 id도 자동 증가가 아니다.
-- cmp_switchover_marker는 이전 플랫폼이 만드는 표라 여기에 두지 않는다.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_seed_info (
  id         integer PRIMARY KEY,
  note       text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
  id         integer PRIMARY KEY,
  email      text NOT NULL,
  name       text NOT NULL,
  status     text NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS addresses (
  id         integer PRIMARY KEY,
  user_id    integer NOT NULL,
  city       text NOT NULL,
  postcode   text NOT NULL,
  is_default boolean NOT NULL
);

CREATE TABLE IF NOT EXISTS categories (
  id        integer PRIMARY KEY,
  name      text NOT NULL,
  parent_id integer
);

CREATE TABLE IF NOT EXISTS products (
  id          integer PRIMARY KEY,
  category_id integer NOT NULL,
  sku         text NOT NULL,
  name        text NOT NULL,
  price_cents integer NOT NULL,
  stock       integer NOT NULL,
  created_at  timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id          integer PRIMARY KEY,
  user_id     integer NOT NULL,
  status      text NOT NULL,
  total_cents integer NOT NULL,
  created_at  timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
  id               integer PRIMARY KEY,
  order_id         integer NOT NULL,
  product_id       integer NOT NULL,
  qty              integer NOT NULL,
  unit_price_cents integer NOT NULL
);

CREATE TABLE IF NOT EXISTS payments (
  id           integer PRIMARY KEY,
  order_id     integer NOT NULL,
  method       text NOT NULL,
  amount_cents integer NOT NULL,
  status       text NOT NULL,
  paid_at      timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS reviews (
  id         integer PRIMARY KEY,
  user_id    integer NOT NULL,
  product_id integer NOT NULL,
  rating     integer NOT NULL,
  body       text NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS events (
  id         bigint PRIMARY KEY,
  user_id    integer NOT NULL,
  kind       text NOT NULL,
  payload    jsonb NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id         bigint PRIMARY KEY,
  actor      text NOT NULL,
  action     text NOT NULL,
  target     text NOT NULL,
  created_at timestamptz NOT NULL
);
