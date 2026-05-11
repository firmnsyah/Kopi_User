-- ============================================================
-- JALANKAN SQL INI di: Supabase Dashboard → SQL Editor
-- Tujuan: Fix trigger + buat employee pertama
-- ============================================================

-- ── STEP 1: Fix trigger agar tidak error saat user tanpa metadata ──
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
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

-- ── STEP 2: Buat employee admin (ROASTER-01 / PIN: 1234) ──────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated', 'authenticated',
  'owner-01@kopi.local',
  crypt('8458', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"employee_id":"OWNER-01","name":"Farid","role":"admin"}'::jsonb,
  NOW(), NOW(),
  '', '', '', ''
);

INSERT INTO auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated', 'authenticated',
  'barista-01@kopi.local',
  crypt('0011', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"employee_id":"BARISTA-01","name":"Alfian","role":"admin"}'::jsonb,
  NOW(), NOW(),
  '', '', '', ''
);

-- ── Verifikasi ────────────────────────────────────────────────────
SELECT u.email, e.employee_id, e.name, e.role
FROM auth.users u
JOIN public.employees e ON e.id = u.id
ORDER BY e.created_at;
