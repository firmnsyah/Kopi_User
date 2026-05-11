-- ============================================================
-- Kopi User POS — Role-Based Transaction Access
-- Staff hanya bisa melihat transaksi miliknya sendiri.
-- Admin bisa melihat semua transaksi.
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- Helper: baca role langsung dari tabel (selalu sinkron, tidak dari JWT)
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT role FROM public.employees WHERE id = auth.uid();
$$;

-- Helper: baca employee_id dari tabel
CREATE OR REPLACE FUNCTION public.current_employee_id()
RETURNS TEXT LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT employee_id FROM public.employees WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.current_user_role()    TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_employee_id()  TO authenticated;

-- ── Perbarui semua policy transaksi ──────────────────────────

DROP POLICY IF EXISTS "transactions: select" ON public.transactions;
DROP POLICY IF EXISTS "transactions: insert" ON public.transactions;
DROP POLICY IF EXISTS "transactions: update" ON public.transactions;
DROP POLICY IF EXISTS "transactions: delete" ON public.transactions;

-- SELECT: admin lihat semua, staff hanya miliknya
CREATE POLICY "transactions: select"
  ON public.transactions FOR SELECT TO authenticated
  USING (
    public.current_user_role() = 'admin'
    OR employee_id = public.current_employee_id()
  );

-- INSERT: employee_id wajib sesuai akun yang login
CREATE POLICY "transactions: insert"
  ON public.transactions FOR INSERT TO authenticated
  WITH CHECK (
    employee_id = public.current_employee_id()
  );

-- UPDATE: admin bisa semua, staff hanya miliknya
CREATE POLICY "transactions: update"
  ON public.transactions FOR UPDATE TO authenticated
  USING (
    public.current_user_role() = 'admin'
    OR employee_id = public.current_employee_id()
  )
  WITH CHECK (
    public.current_user_role() = 'admin'
    OR employee_id = public.current_employee_id()
  );

-- DELETE: admin bisa semua, staff hanya miliknya
CREATE POLICY "transactions: delete"
  ON public.transactions FOR DELETE TO authenticated
  USING (
    public.current_user_role() = 'admin'
    OR employee_id = public.current_employee_id()
  );
