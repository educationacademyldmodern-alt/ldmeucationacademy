# L D MODERN EDUCATION ACADEMY — Ultimate Free Cloud ERP

## Main features
- Supabase Cloud Database + Supabase Auth
- Multiple devices
- Multi-login + role-based permissions
- First registered user automatically becomes SUPER ADMIN
- Super Admin/Admin can assign roles
- Official responsive dashboard
- Nursery to Class 10
- Comprehensive admission/student profile
- Admissions, Students, Attendance, Fees
- Staff, Exams & Marks
- Timetable, Homework
- Transport, Library
- Income, Expenses, Balance Sheet
- Notices, Certificates, Documents
- Users & Roles
- Reports, Print, Cloud backup
- Search + Add New + Edit + Delete where permitted

## Roles
- super_admin: everything
- admin: almost everything
- principal: school operations and reports
- admission: admissions/students/documents/certificates
- accountant: fees/income/expenses/balance
- teacher: students/attendance/exams/timetable/homework/notices
- librarian: library + student reference
- transport: transport + student reference
- student: read-oriented portal
- parent: read-oriented portal
- viewer: dashboard/notices

## Setup
1. Create a free Supabase project.
2. Open SQL Editor.
3. Paste and RUN the whole `supabase-schema.sql`.
4. Copy Project URL + Publishable/Anon key.
5. Deploy these files to Vercel / Netlify / GitHub Pages.
6. Open the website and enter Project URL + key.
7. Create the FIRST user. It becomes Super Admin automatically.
8. Create other user accounts from the public Create Account screen.
9. Super Admin -> Users & Roles -> assign each user's role.

## Important security note
Supabase free tier and free static hosting can be used within their free limits. Free plans can change limits/conditions over time.

The current SQL uses database Row Level Security and role-specific write permissions. Student/Parent UI is read-oriented. For strict privacy where each parent sees ONLY their own child and each student sees ONLY their own record, a second identity-linking layer should be added before using those portals with real sensitive student data.

Do not put a Supabase service_role/secret key in the website. Only use the Publishable/Anon key.
