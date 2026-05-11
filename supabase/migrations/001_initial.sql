-- ============================================================
-- Kopi User POS — Supabase Schema
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── Employees (profil karyawan, linked ke auth.users) ────────
CREATE TABLE public.employees (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  employee_id TEXT UNIQUE NOT NULL,
  name        TEXT NOT NULL,
  role        TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('admin', 'staff')),
  active      BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sync auth.users → employees saat user baru dibuat
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Hanya buat record jika metadata employee_id tersedia
  IF (NEW.raw_user_meta_data->>'employee_id') IS NOT NULL THEN
    INSERT INTO public.employees (id, employee_id, name, role)
    VALUES (
      NEW.id,
      UPPER(NEW.raw_user_meta_data->>'employee_id'),
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'employee_id'),
      COALESCE(NEW.raw_user_meta_data->>'role', 'staff')
    )
    ON CONFLICT (employee_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── Transactions ────────────────────────────────────────────
CREATE SEQUENCE public.tx_seq START 1;

CREATE TABLE public.transactions (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  tx_id       TEXT        UNIQUE NOT NULL
                          DEFAULT '#USR-' || (98400 + NEXTVAL('public.tx_seq')),
  type        TEXT        NOT NULL CHECK (type IN ('income', 'expense')),
  amount      BIGINT      NOT NULL CHECK (amount > 0),
  category    TEXT        NOT NULL,
  method      TEXT        NOT NULL CHECK (method IN ('QRIS', 'Tunai', 'Transfer')),
  notes       TEXT        NOT NULL DEFAULT '',
  bukti_url   TEXT,
  employee_id TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON public.transactions (created_at DESC);
CREATE INDEX ON public.transactions (type);

-- ── Row Level Security ───────────────────────────────────────
ALTER TABLE public.employees    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Karyawan aktif bisa lihat semua profil karyawan
CREATE POLICY "employees: authenticated read"
  ON public.employees FOR SELECT TO authenticated USING (true);

-- Transaksi: semua karyawan authenticated bisa CRUD
CREATE POLICY "transactions: select"
  ON public.transactions FOR SELECT TO authenticated USING (true);

CREATE POLICY "transactions: insert"
  ON public.transactions FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "transactions: update"
  ON public.transactions FOR UPDATE TO authenticated
  USING (true) WITH CHECK (true);

CREATE POLICY "transactions: delete"
  ON public.transactions FOR DELETE TO authenticated USING (true);

-- ── Storage Bucket "bukti" ───────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('bukti', 'bukti', true)
ON CONFLICT DO NOTHING;

CREATE POLICY "bukti: authenticated upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'bukti');

CREATE POLICY "bukti: public read"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'bukti');

CREATE POLICY "bukti: authenticated delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'bukti');
