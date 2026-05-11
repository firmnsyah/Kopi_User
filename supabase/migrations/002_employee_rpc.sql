-- ============================================================
-- Kopi User POS — Employee Management RPC Functions
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── Buat karyawan baru (admin only) ─────────────────────────
CREATE OR REPLACE FUNCTION public.admin_create_employee(
  p_employee_id TEXT,
  p_name        TEXT,
  p_role        TEXT,
  p_pin         TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_new_id      UUID;
BEGIN
  SELECT role INTO v_caller_role
  FROM public.employees
  WHERE id = auth.uid();

  IF v_caller_role IS DISTINCT FROM 'admin' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Hanya admin yang dapat menambah karyawan.');
  END IF;

  IF EXISTS (SELECT 1 FROM public.employees WHERE employee_id = upper(p_employee_id)) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Employee ID sudah digunakan.');
  END IF;

  v_new_id := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_new_id,
    'authenticated', 'authenticated',
    lower(p_employee_id) || '@kopi.local',
    crypt(p_pin, gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'employee_id', upper(p_employee_id),
      'name', p_name,
      'role', p_role
    ),
    NOW(), NOW(),
    '', '', '', ''
  );

  RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ── Update nama/role karyawan, opsional reset PIN (admin only) ─
CREATE OR REPLACE FUNCTION public.admin_update_employee(
  p_employee_id TEXT,
  p_name        TEXT,
  p_role        TEXT,
  p_new_pin     TEXT DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_user_id     UUID;
BEGIN
  SELECT role INTO v_caller_role
  FROM public.employees
  WHERE id = auth.uid();

  IF v_caller_role IS DISTINCT FROM 'admin' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Hanya admin yang dapat mengedit karyawan.');
  END IF;

  SELECT id INTO v_user_id
  FROM public.employees
  WHERE employee_id = upper(p_employee_id);

  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Karyawan tidak ditemukan.');
  END IF;

  UPDATE public.employees
  SET name = p_name, role = p_role
  WHERE employee_id = upper(p_employee_id);

  UPDATE auth.users
  SET raw_user_meta_data = jsonb_build_object(
    'employee_id', upper(p_employee_id),
    'name', p_name,
    'role', p_role
  )
  WHERE id = v_user_id;

  IF p_new_pin IS NOT NULL AND length(trim(p_new_pin)) = 4 THEN
    UPDATE auth.users
    SET encrypted_password = crypt(p_new_pin, gen_salt('bf'))
    WHERE id = v_user_id;
  END IF;

  RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ── Toggle active/nonaktif karyawan (admin only) ─────────────
CREATE OR REPLACE FUNCTION public.admin_toggle_employee(
  p_employee_id TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_current     BOOLEAN;
BEGIN
  SELECT role INTO v_caller_role
  FROM public.employees
  WHERE id = auth.uid();

  IF v_caller_role IS DISTINCT FROM 'admin' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Hanya admin yang dapat mengubah status karyawan.');
  END IF;

  SELECT active INTO v_current
  FROM public.employees
  WHERE employee_id = upper(p_employee_id);

  IF v_current IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Karyawan tidak ditemukan.');
  END IF;

  UPDATE public.employees
  SET active = NOT v_current
  WHERE employee_id = upper(p_employee_id);

  RETURN jsonb_build_object('success', true, 'active', NOT v_current);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Pastikan role authenticated bisa memanggil semua fungsi ini
GRANT EXECUTE ON FUNCTION public.admin_create_employee(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_employee(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_toggle_employee(TEXT) TO authenticated;
