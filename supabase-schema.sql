-- L D MODERN EDUCATION ACADEMY - Ultimate Free Cloud ERP
-- Run the full script in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 email text,
 full_name text,
 role text not null default 'viewer',
 status text not null default 'active',
 created_at timestamptz default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
declare total_users integer;
begin
 select count(*) into total_users from public.profiles;
 insert into public.profiles(id,email,full_name,role,status)
 values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name',new.email),
        case when total_users=0 then 'super_admin' else 'viewer' end,'active');
 return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.my_role() returns text language sql stable security definer set search_path=public as $$
 select role from public.profiles where id=auth.uid() and status='active'
$$;
create or replace function public.role_in(roles text[]) returns boolean language sql stable security definer set search_path=public as $$
 select coalesce(public.my_role()=any(roles),false)
$$;

create table if not exists admissions(
 id uuid primary key default gen_random_uuid(), admission_no text not null, admission_date date, academic_session text,
 student_name text not null, class_name text, section text, roll_no text, dob date, gender text, blood_group text,
 aadhaar_last4 text, pen_no text, apaar_id text, udise_student_id text,
 father_name text, father_occupation text, mother_name text, mother_occupation text, guardian_name text, relation text,
 primary_phone text, alternate_phone text, email text, parent_email text,
 category text, religion text, nationality text, mother_tongue text, minority text, bpl text, disability text, disability_type text,
 address text, permanent_address text, village text, post text, police_station text, district text, state text, pincode text,
 previous_school text, previous_class text, last_result text, tc_no text, tc_date date,
 transport_required text, route_name text, hostel_required text, medical_note text, emergency_contact text,
 admission_status text default 'Admitted', created_at timestamptz default now()
);

create table if not exists students(
 id uuid primary key default gen_random_uuid(), student_name text not null, roll_no text, class_name text, section text,
 admission_no text, dob date, gender text, father_name text, mother_name text, phone text, student_email text, parent_email text,
 pen_no text, apaar_id text, udise_student_id text, address text, status text default 'Active', created_at timestamptz default now()
);
create table if not exists attendance(id uuid primary key default gen_random_uuid(),date date,student_name text,class_name text,roll_no text,status text,remark text,created_at timestamptz default now());
create table if not exists fees(id uuid primary key default gen_random_uuid(),date date,receipt_no text,student_name text,class_name text,fee_type text,total_fee numeric default 0,discount numeric default 0,paid_amount numeric default 0,due_amount numeric default 0,payment_mode text,transaction_id text,due_date date,note text,created_at timestamptz default now());
create table if not exists staff(id uuid primary key default gen_random_uuid(),employee_id text,staff_name text not null,role_name text,subject text,qualification text,phone text,email text,aadhaar_last4 text,joining_date date,salary numeric default 0,bank_name text,account_last4 text,ifsc text,address text,status text default 'Active',created_at timestamptz default now());
create table if not exists exams(id uuid primary key default gen_random_uuid(),exam_name text,exam_date date,student_name text,class_name text,roll_no text,subject text,max_marks numeric default 0,marks_obtained numeric default 0,percentage numeric default 0,grade text,remark text,created_at timestamptz default now());
create table if not exists timetable(id uuid primary key default gen_random_uuid(),class_name text,section text,day_name text,period_no integer,start_time time,end_time time,subject text,teacher_name text,created_at timestamptz default now());
create table if not exists homework(id uuid primary key default gen_random_uuid(),date date,class_name text,section text,subject text,title text,description text,due_date date,teacher_name text,created_at timestamptz default now());
create table if not exists transport(id uuid primary key default gen_random_uuid(),route_name text,vehicle_no text,driver_name text,driver_phone text,student_name text,class_name text,pickup_point text,monthly_fee numeric default 0,status text default 'Active',created_at timestamptz default now());
create table if not exists library(id uuid primary key default gen_random_uuid(),book_code text,book_title text,author text,category text,student_name text,issue_date date,due_date date,return_date date,status text default 'Available',created_at timestamptz default now());
create table if not exists income(id uuid primary key default gen_random_uuid(),date date,source text,amount numeric default 0,payment_mode text,reference_no text,note text,created_at timestamptz default now());
create table if not exists expenses(id uuid primary key default gen_random_uuid(),date date,category text,vendor text,amount numeric default 0,payment_mode text,reference_no text,note text,created_at timestamptz default now());
create table if not exists notices(id uuid primary key default gen_random_uuid(),date date,title text,audience text,message text,created_at timestamptz default now());
create table if not exists certificates(id uuid primary key default gen_random_uuid(),date date,certificate_type text,student_name text,class_name text,certificate_no text,purpose text,remark text,created_at timestamptz default now());
create table if not exists documents(id uuid primary key default gen_random_uuid(),student_name text,class_name text,document_type text,document_no text,verified text,remark text,created_at timestamptz default now());

alter table profiles enable row level security;
do $$ declare t text; begin
 foreach t in array array['admissions','students','attendance','fees','staff','exams','timetable','homework','transport','library','income','expenses','notices','certificates','documents']
 loop execute format('alter table %I enable row level security',t); end loop;
end $$;

drop policy if exists "profile self read" on profiles;
create policy "profile self read" on profiles for select to authenticated using(id=auth.uid() or public.role_in(array['super_admin','admin','principal']));
drop policy if exists "profile admin update" on profiles;
create policy "profile admin update" on profiles for update to authenticated using(public.role_in(array['super_admin','admin'])) with check(public.role_in(array['super_admin','admin']));

-- Read policies
do $$ declare t text; begin
 foreach t in array array['admissions','students','attendance','fees','staff','exams','timetable','homework','transport','library','income','expenses','notices','certificates','documents']
 loop
  execute format('drop policy if exists "read authorized" on %I',t);
  execute format('create policy "read authorized" on %I for select to authenticated using (public.my_role() is not null)',t);
 end loop;
end $$;

-- Role-specific write policies
create policy "admissions write" on admissions for all to authenticated using(public.role_in(array['super_admin','admin','principal','admission'])) with check(public.role_in(array['super_admin','admin','principal','admission']));
create policy "students write" on students for all to authenticated using(public.role_in(array['super_admin','admin','principal','admission'])) with check(public.role_in(array['super_admin','admin','principal','admission']));
create policy "attendance write" on attendance for all to authenticated using(public.role_in(array['super_admin','admin','principal','teacher'])) with check(public.role_in(array['super_admin','admin','principal','teacher']));
create policy "fees write" on fees for all to authenticated using(public.role_in(array['super_admin','admin','principal','accountant'])) with check(public.role_in(array['super_admin','admin','principal','accountant']));
create policy "staff write" on staff for all to authenticated using(public.role_in(array['super_admin','admin','principal'])) with check(public.role_in(array['super_admin','admin','principal']));
create policy "exams write" on exams for all to authenticated using(public.role_in(array['super_admin','admin','principal','teacher'])) with check(public.role_in(array['super_admin','admin','principal','teacher']));
create policy "timetable write" on timetable for all to authenticated using(public.role_in(array['super_admin','admin','principal','teacher'])) with check(public.role_in(array['super_admin','admin','principal','teacher']));
create policy "homework write" on homework for all to authenticated using(public.role_in(array['super_admin','admin','principal','teacher'])) with check(public.role_in(array['super_admin','admin','principal','teacher']));
create policy "transport write" on transport for all to authenticated using(public.role_in(array['super_admin','admin','principal','transport'])) with check(public.role_in(array['super_admin','admin','principal','transport']));
create policy "library write" on library for all to authenticated using(public.role_in(array['super_admin','admin','principal','librarian'])) with check(public.role_in(array['super_admin','admin','principal','librarian']));
create policy "income write" on income for all to authenticated using(public.role_in(array['super_admin','admin','principal','accountant'])) with check(public.role_in(array['super_admin','admin','principal','accountant']));
create policy "expenses write" on expenses for all to authenticated using(public.role_in(array['super_admin','admin','principal','accountant'])) with check(public.role_in(array['super_admin','admin','principal','accountant']));
create policy "notices write" on notices for all to authenticated using(public.role_in(array['super_admin','admin','principal','teacher'])) with check(public.role_in(array['super_admin','admin','principal','teacher']));
create policy "certificates write" on certificates for all to authenticated using(public.role_in(array['super_admin','admin','principal','admission'])) with check(public.role_in(array['super_admin','admin','principal','admission']));
create policy "documents write" on documents for all to authenticated using(public.role_in(array['super_admin','admin','principal','admission'])) with check(public.role_in(array['super_admin','admin','principal','admission']));

-- NOTE:
-- This is a single-school ERP. "Student" and "Parent" roles are read-only in the UI.
-- For strict row-by-row parent/student privacy, link each auth account to one student record in a future phase.
