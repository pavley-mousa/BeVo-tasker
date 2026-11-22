-- Harden BeVo role scopes and require database-side authorization for scoped admin actions.
-- Group admins manage A-D only. Section admins manage a1-d6 only; parent rights are not inherited.

BEGIN;

-- Keep one-time bootstrap credentials away from all API roles.
ALTER TABLE private.bootstrap_secrets ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.bootstrap_secrets FROM PUBLIC, anon, authenticated;

-- Only canonical codes can be assigned. Legacy/unrecognized codes receive no admin scope.
CREATE OR REPLACE FUNCTION private.group_scope_role_applies(p_role text, p_code text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN lower(btrim(COALESCE(p_code, ''))) ~ '^[a-d]$'
      THEN p_role = 'group_admin'
    WHEN lower(btrim(COALESCE(p_code, ''))) ~ '^[a-d][1-6]$'
      THEN p_role = 'section_admin'
    ELSE false
  END;
$function$;

-- A role row must describe exactly one well-formed scope.
ALTER TABLE public.role_assignments
  DROP CONSTRAINT IF EXISTS role_assignments_check;

ALTER TABLE public.role_assignments
  ADD CONSTRAINT role_assignments_scope_shape_check
  CHECK (
    (role = 'super_admin'
      AND college_id IS NULL AND academic_year_id IS NULL
      AND study_level_id IS NULL AND course_group_id IS NULL)
    OR
    (role = 'college_admin'
      AND college_id IS NOT NULL AND academic_year_id IS NULL
      AND study_level_id IS NULL AND course_group_id IS NULL)
    OR
    (role = 'year_admin'
      AND college_id IS NOT NULL AND academic_year_id IS NOT NULL
      AND study_level_id IS NOT NULL AND course_group_id IS NULL)
    OR
    (role IN ('group_admin', 'section_admin')
      AND college_id IS NOT NULL AND academic_year_id IS NOT NULL
      AND study_level_id IS NOT NULL AND course_group_id IS NOT NULL)
    OR
    (role = 'instructor'
      AND college_id IS NOT NULL AND academic_year_id IS NULL
      AND study_level_id IS NULL AND course_group_id IS NULL)
  );

CREATE OR REPLACE FUNCTION private.enforce_role_assignment_scope()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_scope record;
BEGIN
  -- Inactive history rows cannot grant permissions; validate whenever a row is activated.
  IF NEW.is_active IS DISTINCT FROM true THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT'
     AND NEW.role <> 'super_admin'
     AND (SELECT auth.uid()) IS NOT NULL
     AND NEW.assigned_by IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'assigned_by must match the signed-in administrator'
      USING ERRCODE = '42501';
  END IF;

  IF TG_OP = 'UPDATE'
     AND NEW.assigned_by IS DISTINCT FROM OLD.assigned_by
     AND (SELECT auth.uid()) IS NOT NULL
     AND NEW.assigned_by IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'assigned_by must match the signed-in administrator'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.role = 'super_admin' THEN
    IF NEW.college_id IS NOT NULL OR NEW.academic_year_id IS NOT NULL
       OR NEW.study_level_id IS NOT NULL OR NEW.course_group_id IS NOT NULL THEN
      RAISE EXCEPTION 'Super Admin cannot be attached to an academic scope'
        USING ERRCODE = '23514';
    END IF;

  ELSIF NEW.role = 'college_admin' THEN
    IF NEW.academic_year_id IS NOT NULL OR NEW.study_level_id IS NOT NULL
       OR NEW.course_group_id IS NOT NULL
       OR NOT EXISTS (
         SELECT 1 FROM public.colleges c
         WHERE c.id = NEW.college_id AND c.is_active
       ) THEN
      RAISE EXCEPTION 'College Admin must be assigned to one active college only'
        USING ERRCODE = '23514';
    END IF;

  ELSIF NEW.role = 'year_admin' THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.academic_years ay
      JOIN public.study_levels sl
        ON sl.id = NEW.study_level_id
       AND sl.college_id = NEW.college_id
       AND sl.is_active
      WHERE ay.id = NEW.academic_year_id
        AND ay.college_id = NEW.college_id
        AND ay.is_active
    ) OR NEW.course_group_id IS NOT NULL THEN
      RAISE EXCEPTION 'Batch Admin must match one active college, academic year, and study level'
        USING ERRCODE = '23514';
    END IF;

  ELSIF NEW.role IN ('group_admin', 'section_admin') THEN
    SELECT g.code, o.college_id, o.academic_year_id, o.study_level_id
      INTO v_scope
    FROM public.course_groups g
    JOIN public.course_offerings o ON o.id = g.offering_id
    WHERE g.id = NEW.course_group_id
      AND g.is_active
      AND o.is_active;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'The selected group or section is not active'
        USING ERRCODE = '23503';
    END IF;

    IF NEW.college_id IS DISTINCT FROM v_scope.college_id
       OR NEW.academic_year_id IS DISTINCT FROM v_scope.academic_year_id
       OR NEW.study_level_id IS DISTINCT FROM v_scope.study_level_id
       OR NOT private.group_scope_role_applies(NEW.role, v_scope.code) THEN
      RAISE EXCEPTION 'Group/section role does not match the selected academic scope and code'
        USING ERRCODE = '23514';
    END IF;

  ELSIF NEW.role = 'instructor' THEN
    IF NEW.academic_year_id IS NOT NULL OR NEW.study_level_id IS NOT NULL
       OR NEW.course_group_id IS NOT NULL
       OR NOT EXISTS (
         SELECT 1 FROM public.colleges c
         WHERE c.id = NEW.college_id AND c.is_active
       ) THEN
      RAISE EXCEPTION 'Instructor assignment must belong to one active college'
        USING ERRCODE = '23514';
    END IF;

  ELSE
    RAISE EXCEPTION 'Unsupported role: %', NEW.role
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS enforce_role_assignment_scope ON public.role_assignments;
CREATE TRIGGER enforce_role_assignment_scope
BEFORE INSERT OR UPDATE ON public.role_assignments
FOR EACH ROW
EXECUTE FUNCTION private.enforce_role_assignment_scope();

-- Validate shared/default group-role assignments as strictly as direct assignments.
CREATE OR REPLACE FUNCTION private.enforce_group_role_default_scope()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.is_active IS DISTINCT FROM true THEN
    RETURN NEW;
  END IF;

  IF NOT private.group_scope_role_applies(NEW.role, NEW.group_code) THEN
    RAISE EXCEPTION 'Group Admin must use A-D; Section Admin must use a1-d6'
      USING ERRCODE = '23514';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.course_groups g
    JOIN public.course_offerings o ON o.id = g.offering_id
    WHERE o.college_id = NEW.college_id
      AND o.academic_year_id = NEW.academic_year_id
      AND o.study_level_id = NEW.study_level_id
      AND lower(btrim(g.code)) = lower(btrim(NEW.group_code))
      AND g.is_active
      AND o.is_active
      AND private.group_scope_role_applies(NEW.role, g.code)
  ) THEN
    RAISE EXCEPTION 'No active group or section exists for this exact college, year, level, and code'
      USING ERRCODE = '23503';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = NEW.user_id
      AND (p.college_id IS NULL OR p.college_id = NEW.college_id)
  ) THEN
    RAISE EXCEPTION 'The assigned user is outside this college'
      USING ERRCODE = '23514';
  END IF;

  IF TG_OP = 'INSERT'
     AND (SELECT auth.uid()) IS NOT NULL
     AND NEW.assigned_by IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'assigned_by must match the signed-in administrator'
      USING ERRCODE = '42501';
  END IF;

  IF TG_OP = 'UPDATE'
     AND NEW.assigned_by IS DISTINCT FROM OLD.assigned_by
     AND (SELECT auth.uid()) IS NOT NULL
     AND NEW.assigned_by IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'assigned_by must match the signed-in administrator'
      USING ERRCODE = '42501';
  END IF;

  NEW.group_code := lower(btrim(NEW.group_code));
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS enforce_group_role_default_scope ON public.group_role_defaults;
CREATE TRIGGER enforce_group_role_default_scope
BEFORE INSERT OR UPDATE ON public.group_role_defaults
FOR EACH ROW
EXECUTE FUNCTION private.enforce_group_role_default_scope();

-- College Admins assign group/section roles through the checked RPC, not direct table writes.
DROP POLICY IF EXISTS "college admins assign group and section admins" ON public.role_assignments;
DROP POLICY IF EXISTS "college admins manage group role defaults" ON public.group_role_defaults;

-- Scoped admins edit schedule fields through section_admin_update_group only.
-- Whole-row writes stay with admins who manage the parent offering.
DROP POLICY IF EXISTS "admins manage groups" ON public.course_groups;
CREATE POLICY "college and offering admins manage groups"
ON public.course_groups
FOR ALL
TO authenticated
USING (private.can_manage_offering(offering_id))
WITH CHECK (private.can_manage_offering(offering_id));

-- Student selection changes and request reviews must pass the validation RPCs.
DROP POLICY IF EXISTS "admins update change request status" ON public.course_change_requests;
DROP POLICY IF EXISTS "admins update selections" ON public.student_course_selections;
DROP POLICY IF EXISTS "admins delete selections" ON public.student_course_selections;

-- Resolve Year Admin permissions from the student's actual selected offerings,
-- not just whichever academic year happens to be marked current.
CREATE OR REPLACE FUNCTION private.can_manage_student(p_student_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT private.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      JOIN public.role_assignments ra
        ON ra.user_id = (SELECT auth.uid())
       AND ra.is_active
      WHERE p.id = p_student_id
        AND (
          (ra.role = 'college_admin' AND ra.college_id = p.college_id)
          OR (
            ra.role = 'year_admin'
            AND ra.college_id = p.college_id
            AND ra.study_level_id = p.study_level_id
            AND EXISTS (
              SELECT 1
              FROM public.student_course_selections s
              JOIN public.course_offerings o ON o.id = s.offering_id
              JOIN public.academic_years ay
                ON ay.id = o.academic_year_id
               AND ay.college_id = o.college_id
              WHERE s.student_id = p.id
                AND o.is_active
                AND ay.is_active
                AND o.college_id = ra.college_id
                AND o.academic_year_id = ra.academic_year_id
                AND o.study_level_id = ra.study_level_id
            )
          )
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.student_course_selections s
      JOIN public.course_groups g
        ON g.id = s.course_group_id
       AND g.offering_id = s.offering_id
      JOIN public.course_offerings o
        ON o.id = s.offering_id
       AND o.is_active
      WHERE s.student_id = p_student_id
        AND g.is_active
        AND private.is_group_or_section_scope_admin_for_group(g.id)
    );
$function$;

-- Validate direct assignments against the exact group and academic scope.
-- A parent Group Admin does not inherit access to its child sections.
CREATE OR REPLACE FUNCTION private.is_group_or_section_scope_admin_for_group(p_group_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.course_groups g
    JOIN public.course_offerings o ON o.id = g.offering_id
    WHERE g.id = p_group_id
      AND (
        EXISTS (
          SELECT 1
          FROM public.role_assignments ra
          WHERE ra.user_id = (SELECT auth.uid())
            AND ra.is_active
            AND ra.course_group_id = g.id
            AND ra.college_id = o.college_id
            AND ra.academic_year_id = o.academic_year_id
            AND ra.study_level_id = o.study_level_id
            AND private.group_scope_role_applies(ra.role, g.code)
        )
        OR EXISTS (
          SELECT 1
          FROM public.group_role_defaults d
          WHERE d.user_id = (SELECT auth.uid())
            AND d.is_active
            AND d.college_id = o.college_id
            AND d.academic_year_id = o.academic_year_id
            AND d.study_level_id = o.study_level_id
            AND lower(btrim(d.group_code)) = lower(btrim(g.code))
            AND private.group_scope_role_applies(d.role, g.code)
            AND NOT EXISTS (
              SELECT 1
              FROM public.role_assignments override_ra
              WHERE override_ra.is_active
                AND override_ra.role = d.role
                AND override_ra.course_group_id = g.id
                AND override_ra.college_id = o.college_id
                AND override_ra.academic_year_id = o.academic_year_id
                AND override_ra.study_level_id = o.study_level_id
            )
        )
      )
  );
$function$;

CREATE OR REPLACE FUNCTION private.is_group_admin_for_group(p_group_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.course_groups g
    WHERE g.id = p_group_id
      AND private.group_scope_role_applies('group_admin', g.code)
      AND private.is_group_or_section_scope_admin_for_group(g.id)
  );
$function$;

CREATE OR REPLACE FUNCTION private.is_section_admin_for_group(p_group_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.course_groups g
    WHERE g.id = p_group_id
      AND private.group_scope_role_applies('section_admin', g.code)
      AND private.is_group_or_section_scope_admin_for_group(g.id)
  );
$function$;

-- Shared/default assignment: only an active canonical group can seed the scope.
CREATE OR REPLACE FUNCTION public.set_group_role_default(p_group_id uuid, p_role text, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_college_id uuid;
  v_year_id uuid;
  v_level_id uuid;
  v_group_code text;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'يجب تسجيل الدخول' USING ERRCODE = '28000';
  END IF;

  SELECT o.college_id, o.academic_year_id, o.study_level_id, g.code
    INTO v_college_id, v_year_id, v_level_id, v_group_code
  FROM public.course_groups g
  JOIN public.course_offerings o ON o.id = g.offering_id
  WHERE g.id = p_group_id
    AND g.is_active
    AND o.is_active;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الجروب أو السكشن غير موجود أو غير مفعّل' USING ERRCODE = '23503';
  END IF;

  IF p_role NOT IN ('group_admin', 'section_admin')
     OR NOT private.group_scope_role_applies(p_role, v_group_code) THEN
    RAISE EXCEPTION 'الدور لا يطابق كود الجروب أو السكشن' USING ERRCODE = '22023';
  END IF;

  IF NOT private.can_manage_college(v_college_id) THEN
    RAISE EXCEPTION 'لا تملك صلاحية إدارة هذه الكلية' USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_user_id
      AND (p.college_id IS NULL OR p.college_id = v_college_id)
  ) THEN
    RAISE EXCEPTION 'المستخدم غير موجود أو تابع لكلية أخرى' USING ERRCODE = '23503';
  END IF;

  INSERT INTO public.group_role_defaults
    (college_id, academic_year_id, study_level_id, group_code, role, user_id, is_active, assigned_by)
  VALUES
    (v_college_id, v_year_id, v_level_id, lower(btrim(v_group_code)), p_role, p_user_id, true, (SELECT auth.uid()))
  ON CONFLICT (college_id, academic_year_id, study_level_id, group_code, role)
  DO UPDATE SET
    user_id = EXCLUDED.user_id,
    is_active = true,
    assigned_by = (SELECT auth.uid()),
    updated_at = now();

  UPDATE public.role_assignments
  SET is_active = false
  WHERE course_group_id = p_group_id
    AND role = p_role
    AND is_active;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_group_role_override(p_group_id uuid, p_role text, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_college_id uuid;
  v_year_id uuid;
  v_level_id uuid;
  v_group_code text;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'يجب تسجيل الدخول' USING ERRCODE = '28000';
  END IF;

  IF p_role NOT IN ('group_admin', 'section_admin') THEN
    RAISE EXCEPTION 'نوع الدور غير مسموح' USING ERRCODE = '22023';
  END IF;

  SELECT o.college_id, o.academic_year_id, o.study_level_id, g.code
    INTO v_college_id, v_year_id, v_level_id, v_group_code
  FROM public.course_groups g
  JOIN public.course_offerings o ON o.id = g.offering_id
  WHERE g.id = p_group_id
    AND g.is_active
    AND o.is_active;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الجروب أو السكشن غير موجود أو غير مفعّل' USING ERRCODE = '23503';
  END IF;

  IF NOT private.group_scope_role_applies(p_role, v_group_code) THEN
    RAISE EXCEPTION 'الدور لا يطابق كود الجروب أو السكشن' USING ERRCODE = '22023';
  END IF;

  IF NOT private.can_manage_college(v_college_id) THEN
    RAISE EXCEPTION 'لا تملك صلاحية إدارة هذه الكلية' USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_user_id
      AND (p.college_id IS NULL OR p.college_id = v_college_id)
  ) THEN
    RAISE EXCEPTION 'المستخدم غير موجود أو تابع لكلية أخرى' USING ERRCODE = '23503';
  END IF;

  UPDATE public.role_assignments
  SET is_active = false
  WHERE course_group_id = p_group_id
    AND role = p_role
    AND is_active;

  INSERT INTO public.role_assignments
    (user_id, role, college_id, academic_year_id, study_level_id, course_group_id, is_active, assigned_by)
  VALUES
    (p_user_id, p_role, v_college_id, v_year_id, v_level_id, p_group_id, true, (SELECT auth.uid()));
END;
$function$;

CREATE OR REPLACE FUNCTION public.clear_group_role_override(p_group_id uuid, p_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_college_id uuid;
  v_group_code text;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'يجب تسجيل الدخول' USING ERRCODE = '28000';
  END IF;

  IF p_role NOT IN ('group_admin', 'section_admin') THEN
    RAISE EXCEPTION 'نوع الدور غير مسموح' USING ERRCODE = '22023';
  END IF;

  SELECT o.college_id, g.code
    INTO v_college_id, v_group_code
  FROM public.course_groups g
  JOIN public.course_offerings o ON o.id = g.offering_id
  WHERE g.id = p_group_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الجروب غير موجود' USING ERRCODE = '23503';
  END IF;

  IF NOT private.group_scope_role_applies(p_role, v_group_code) THEN
    RAISE EXCEPTION 'الدور لا يطابق كود الجروب أو السكشن' USING ERRCODE = '22023';
  END IF;

  IF NOT private.can_manage_college(v_college_id) THEN
    RAISE EXCEPTION 'لا تملك صلاحية إدارة هذه الكلية' USING ERRCODE = '42501';
  END IF;

  UPDATE public.role_assignments
  SET is_active = false
  WHERE course_group_id = p_group_id
    AND role = p_role
    AND is_active;
END;
$function$;

-- These are authenticated administrative RPCs, not anonymous/public endpoints.
REVOKE EXECUTE ON FUNCTION public.create_academic_year_atomic(uuid, text, date, date, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_academic_year_atomic(uuid, text, date, date, boolean) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.year_admin_create_offering(uuid, uuid, uuid, uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.year_admin_create_offering(uuid, uuid, uuid, uuid, boolean) TO authenticated, service_role;

COMMIT;
