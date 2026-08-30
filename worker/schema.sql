-- Addis Bites Database Schema & Seed Data for Cloudflare D1
-- Mirrors §4 Server-Owned Tables

CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  phone TEXT UNIQUE,
  name TEXT,
  role TEXT CHECK(role IN ('customer', 'merchant', 'driver', 'admin', 'ceo', 'support', 'finance')),
  vehicle TEXT,
  status TEXT DEFAULT 'active',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS merchants (
  id TEXT PRIMARY KEY,
  name_am TEXT,
  name_en TEXT,
  sefer TEXT,
  sub_city TEXT,
  lat REAL,
  lng REAL,
  phone_gsm TEXT,
  prep_min INTEGER DEFAULT 25,
  rating REAL DEFAULT 4.5,
  tsom_certified INTEGER DEFAULT 0,
  halal_certified INTEGER DEFAULT 0,
  thermal INTEGER DEFAULT 0,
  accepts_cash INTEGER DEFAULT 1,
  accepts_chapa INTEGER DEFAULT 1,
  is_restaurant_of_the_day INTEGER DEFAULT 0,
  accent TEXT
);

CREATE TABLE IF NOT EXISTS menu_items (
  id TEXT PRIMARY KEY,
  merchant_id TEXT,
  name_am TEXT,
  name_en TEXT,
  price_etb INTEGER,
  category TEXT,
  is_tsom INTEGER DEFAULT 0,
  is_halal INTEGER DEFAULT 0,
  is_raw_meat INTEGER DEFAULT 0,
  is_available INTEGER DEFAULT 1,
  injera_stepper INTEGER DEFAULT 0,
  spice_levels INTEGER DEFAULT 0,
  source TEXT DEFAULT 'manual'
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  phone TEXT,
  merchant_id TEXT,
  items_json TEXT,
  subtotal INTEGER,
  delivery_fee INTEGER,
  service_fee INTEGER,
  surge INTEGER DEFAULT 0,
  total INTEGER,
  payment_method TEXT,
  payment_status TEXT,
  payment_ref TEXT,
  status TEXT,
  sub_city TEXT,
  sefer TEXT,
  landmark_text TEXT,
  lat REAL,
  lng REAL,
  plus_code TEXT,
  courier_name TEXT,
  courier_phone TEXT,
  courier_vehicle TEXT,
  ack_deadline_at DATETIME,
  sms_fallback_sent INTEGER DEFAULT 0,
  settlement_batch TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_config (
  key TEXT PRIMARY KEY,
  value TEXT
);

CREATE TABLE IF NOT EXISTS sub_cities (
  id TEXT PRIMARY KEY,
  name_en TEXT,
  name_am TEXT
);

CREATE TABLE IF NOT EXISTS fasting_rules (
  id TEXT PRIMARY KEY,
  label_am TEXT,
  label_en TEXT,
  start_date DATE,
  end_date DATE
);

CREATE TABLE IF NOT EXISTS disputes (
  id TEXT PRIMARY KEY,
  order_id TEXT,
  opened_by TEXT,
  reason TEXT,
  status TEXT DEFAULT 'open',
  resolution TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS promotions (
  id TEXT PRIMARY KEY,
  label TEXT,
  discount_pct INTEGER,
  max_uses INTEGER,
  uses INTEGER DEFAULT 0,
  active INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS foot_signups (
  id TEXT PRIMARY KEY,
  phone TEXT UNIQUE,
  mode TEXT,
  source TEXT,
  auth_ok INTEGER DEFAULT 1,
  orientation_ok INTEGER DEFAULT 0,
  radius_km REAL DEFAULT 1.5,
  first_delivery_done INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Seed Sub-cities
INSERT OR REPLACE INTO sub_cities (id, name_en, name_am) VALUES
  ('bole', 'Bole', 'ቦሌ'),
  ('kirkos', 'Kirkos', 'ኪርኮስ'),
  ('yeka', 'Yeka', 'የካ'),
  ('arada', 'Arada', 'አራዳ');

-- Seed Config
INSERT OR REPLACE INTO app_config (key, value) VALUES
  ('serviceFee', '20'),
  ('deliveryFee2km', '80'),
  ('deliveryFee5km', '150'),
  ('deliveryFee8km', '240'),
  ('footFee', '45'),
  ('rainSurge', '40'),
  ('bunaRunFee', '50'),
  ('bunaMaxOrder', '150'),
  ('bunaMaxKm', '1'),
  ('courierSharePct', '80'),
  ('courierTipsPct', '100'),
  ('codFloatCap', '1500'),
  ('codSettlementHours', '24'),
  ('commissionPct', '12'),
  ('restaurantOfTheDayCommissionPct', '0'),
  ('smsProvider', 'afromessage'),
  ('smsCostEtb', '0.45'),
  ('ackTimeoutSeconds', '90'),
  ('rainMode', 'false'),
  ('fastingOverride', 'false'),
  ('vehicleCurfew', 'false'),
  ('restaurantOfTheDayId', 'sheger-kitchen'),
  ('inflationPct', '22'),
  ('feeMultiplier', '1.0');

-- Seed Merchants
INSERT OR REPLACE INTO merchants (id, name_am, name_en, sefer, sub_city, lat, lng, phone_gsm, prep_min, rating, tsom_certified, halal_certified, thermal, accepts_cash, accepts_chapa, is_restaurant_of_the_day, accent) VALUES
  ('sheger-kitchen', 'ሸገር ኩሽና', 'Sheger Kitchen', 'Bole Medhanealem', 'Bole', 8.9888, 38.7872, '+251 911 224 410', 28, 4.7, 1, 0, 1, 1, 1, 1, '#C84B20'),
  ('habesha-coffee', 'ሀበሻ ቡና ቤት', 'Habesha Coffee House', 'Kazanchis', 'Kirkos', 9.0105, 38.7612, '+251 555 882 120', 6, 4.4, 0, 0, 0, 1, 1, 0, '#6E3A1F'),
  ('desta-kitfo', 'ደስታ ክትፎ', 'Desta Kitfo & Siga', 'Piazza', 'Arada', 9.0240, 38.7469, '+251 911 331 220', 14, 4.9, 0, 0, 1, 1, 1, 0, '#A93226'),
  ('vegan-bole', 'የጾም ደስታ', 'Yetsom Delight', 'Edna Mall', 'Bole', 8.9935, 38.7812, '+251 911 778 330', 20, 4.6, 1, 1, 0, 1, 1, 0, '#1E6B3A'),
  ('pizza-mercato', 'መርካቶ ፒዛ', 'Mercato Pizza & Dough', 'Merkato', 'Arada', 9.0420, 38.7512, '+251 911 662 004', 22, 4.2, 0, 1, 0, 1, 1, 0, '#C9B458'),
  ('keto-club', 'ኬቶ ክለብ', 'The Keto Club', 'CMC', 'Yeka', 9.0320, 38.7882, '+251 922 554 771', 18, 4.8, 0, 1, 0, 1, 1, 0, '#7A4B8B');

-- Seed Menu Items
INSERT OR REPLACE INTO menu_items (id, merchant_id, name_am, name_en, price_etb, category, is_tsom, is_halal, is_raw_meat, is_available, injera_stepper, spice_levels, source) VALUES
  ('sk-doro-wot', 'sheger-kitchen', 'ዶሮ ወጥ', 'Doro Wot', 420, 'Meat Wots', 0, 0, 0, 1, 1, 3, 'manual'),
  ('sk-tibs', 'sheger-kitchen', 'ዘልዘል ጥብስ', 'Zilzil Tibs', 380, 'Meat Wots', 0, 0, 0, 1, 1, 3, 'manual'),
  ('sk-shiro', 'sheger-kitchen', 'ሽሮ ወጥ', 'Shiro Wot', 245, 'Vegan / Yetsom', 1, 1, 0, 1, 1, 2, 'manual'),
  ('hc-buna', 'habesha-coffee', 'ቡና', 'Habesha Buna', 85, 'Beverages', 1, 1, 0, 1, 0, 0, 'manual'),
  ('hc-genfo', 'habesha-coffee', 'ገንፎ', 'Genfo with Berbere', 120, 'Breakfast', 1, 1, 0, 1, 0, 1, 'manual'),
  ('dk-kitfo', 'desta-kitfo', 'ክትፎ', 'Kitfo (raw or rare)', 460, 'Raw Meat', 0, 0, 1, 1, 1, 3, 'manual'),
  ('dk-tere', 'desta-kitfo', 'ጥሬ ስጋ', 'Tere Siga', 520, 'Raw Meat', 0, 0, 1, 1, 1, 2, 'manual'),
  ('yd-beyainetu', 'vegan-bole', 'በየአይነቱ', 'Beyainetu Veggie Platter', 300, 'Vegan / Yetsom', 1, 1, 0, 1, 1, 2, 'manual'),
  ('yd-misir', 'vegan-bole', 'ምስር ወጥ', 'Misir Wot', 230, 'Veggie Stews', 1, 1, 0, 1, 1, 2, 'manual'),
  ('kc-caesar', 'keto-club', 'ሳላት', 'Keto Caesar Salad', 310, 'Salads', 0, 1, 0, 1, 0, 0, 'manual'),
  ('kc-bowl', 'keto-club', 'ኦፕቲም', 'High-Protein Bowl', 360, 'Healthy', 0, 1, 0, 1, 0, 0, 'manual');

-- Trust & Safety (support console, tech-spec §3.6): misconduct reports,
-- progressive strike ledger, and refund requests.
CREATE TABLE IF NOT EXISTS misconduct_reports (
  id TEXT PRIMARY KEY,
  order_id TEXT,
  reporter_type TEXT,
  reporter_id TEXT,
  subject_type TEXT,
  subject_id TEXT,
  category TEXT,
  status TEXT DEFAULT 'open',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS strikes (
  id TEXT PRIMARY KEY,
  subject_type TEXT,
  subject_id TEXT,
  validated_count INTEGER,
  level TEXT,
  issued_at TEXT
);

CREATE TABLE IF NOT EXISTS refund_requests (
  id TEXT PRIMARY KEY,
  order_id TEXT,
  amount_etb INTEGER,
  status TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Finance console (tech-spec §3.5): two-person-release payout batches and the
-- double-entry ledger (every txn sums to zero).
CREATE TABLE IF NOT EXISTS payout_batches (
  id TEXT PRIMARY KEY,
  method TEXT,
  status TEXT,
  total_etb INTEGER,
  count INTEGER,
  scheduled_for TEXT
);

CREATE TABLE IF NOT EXISTS ledger_entries (
  id TEXT PRIMARY KEY,
  txn_id TEXT,
  account TEXT,
  debit INTEGER DEFAULT 0,
  credit INTEGER DEFAULT 0,
  order_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_ledger_txn ON ledger_entries(txn_id);

-- Seed demo Support / Finance accounts (profile role CHECK extended above).
INSERT OR REPLACE INTO profiles (id, phone, name, role) VALUES
  ('p-support-demo', '+25192223331', 'Selam Support', 'support'),
  ('p-finance-demo', '+25194445551', 'Finance Lead', 'finance');

-- Seed support console data (DB path mirrors worker/src/index.js in-memory seed)
INSERT OR REPLACE INTO misconduct_reports (id, order_id, reporter_type, reporter_id, subject_type, subject_id, category, status) VALUES
  ('rep-1', 'ord-1', 'customer', 'cust-1', 'courier', 'c-1', 'late_slow', 'open'),
  ('rep-2', 'ord-2', 'courier', 'c-2', 'restaurant', 'r-1', 'nonpayment', 'open');

INSERT OR REPLACE INTO refund_requests (id, order_id, amount_etb, status, created_at) VALUES
  ('rf-1', 'ord-9', 120, 'requested', '2026-08-25T00:00:00.000Z');

-- Seed finance console data: two payout batches + a balanced double-entry ledger.
INSERT OR REPLACE INTO payout_batches (id, method, status, total_etb, count, scheduled_for) VALUES
  ('pb-1', 'telebirr_b2c', 'pending', 18500, 23, '2026-08-26T10:00:00.000Z'),
  ('pb-2', 'bank_transfer', 'sent', 64200, 5, '2026-08-26T13:00:00.000Z');

INSERT OR REPLACE INTO ledger_entries (id, txn_id, account, debit, credit, order_id) VALUES
  ('txn-1-a', 'txn-1', 'platform:fees', 0, 1280, 'ord-1'),
  ('txn-1-b', 'txn-1', 'courier:c-1', 1280, 0, 'ord-1'),
  ('txn-2-a', 'txn-2', 'merchant:sheger-kitchen', 0, 2400, 'ord-2'),
  ('txn-2-b', 'txn-2', 'platform:fees', 2400, 0, 'ord-2');

-- Ratings (three-directional, one per order/direction — matches /api/ratings).
CREATE TABLE IF NOT EXISTS ratings (
  order_id TEXT NOT NULL,
  direction TEXT NOT NULL,
  stars INTEGER,
  tags_json TEXT DEFAULT '[]',
  comment TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id, direction)
);

-- Proof-of-delivery receipts (photo + pin) — matches /api/driver/pod.
CREATE TABLE IF NOT EXISTS pod_receipts (
  order_id TEXT PRIMARY KEY,
  photo_b64 TEXT,
  pin TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
