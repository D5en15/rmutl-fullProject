import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------- AUTH ----------
import 'ui/auth/login_page.dart';
import 'ui/auth/register_page.dart';
import 'ui/auth/forgot_password_page.dart';

// ---------- COMMON ----------
import 'ui/common/profile_page.dart';
import 'ui/common/notification_page.dart';
import 'ui/common/settings_page.dart';
import 'ui/common/role_shell.dart';
import 'ui/common/messages_page.dart';
import 'ui/common/chat_page.dart';

// ---------- shared pages -----
import 'ui/common/edit_profile_page.dart';

// ---------- STUDENT ----------
import 'ui/student/home_page.dart' as s;
import 'ui/student/grades_page.dart';
import 'ui/student/edit_grade_page.dart';
import 'ui/student/career_page.dart';
import 'ui/student/subjects_page.dart';
import 'ui/student/add_subject_page.dart';
import 'ui/student/edit_subject_page.dart';

// ---------- TEACHER ----------
import 'ui/teacher/teacher_home_page.dart' as t;
import 'ui/teacher/student_list_page.dart';
import 'ui/teacher/student_detail_page.dart';
import 'ui/teacher/feedback_page.dart';

// ---------- ADMIN ----------
import 'ui/admin/admin_home_page.dart' as a;
import 'ui/admin/user_manage_page.dart';
import 'ui/admin/user_edit_form_page.dart';
import 'ui/admin/user_add_page.dart';
import 'ui/admin/role_permission_page.dart';
import 'ui/admin/moderation_page.dart';

// ---------- ADMIN CONFIG ----------
import 'ui/admin/dashboard_config_page.dart';
import 'ui/admin/subjects_manage_page.dart';
import 'ui/admin/subject_add_page.dart';
import 'ui/admin/subject_edit_page.dart';
// SubPLO
import 'ui/admin/subplo_manage_page.dart';
import 'ui/admin/subplo_add_page.dart';
import 'ui/admin/subplo_edit_page.dart';
// PLO
import 'ui/admin/plo_manage_page.dart';
import 'ui/admin/plo_add_page.dart';
import 'ui/admin/plo_edit_page.dart';
// Careers
import 'ui/admin/career_manage_page.dart';
import 'ui/admin/career_add_page.dart';
import 'ui/admin/career_edit_page.dart';
// Mapping ✅
import 'ui/admin/subject_subplo_mapping_page.dart';
import 'ui/admin/plo_subplo_mapping_page.dart';
import 'ui/admin/career_mapping_page.dart';

// ---------- FORUM (shared) ----------
import 'ui/forum/forum_list_page.dart';
import 'ui/forum/post_detail_page.dart';
import 'ui/forum/create_post_page.dart';
import 'ui/forum/edit_post_page.dart';


class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();
  static final _studentShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'studentShell');
  static final _teacherShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'teacherShell');
  static final _adminShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'adminShell');

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: Center(child: Text('404 • Page not found: ${state.uri}')),
    ),
    routes: [
      // ---------- AUTH ----------
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordPage()),

      // ---------- COMMON ----------
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationPage()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, s) => EditProfilePage(
          role: (s.extra as Map?)?['role'] as String? ?? 'student',
          initial: (s.extra as Map?)?['initial'] as EditProfileInitial?,
        ),
      ),

      // Messages & Chat
      GoRoute(path: '/student/messages', builder: (_, __) => const MessagesPage()),
      GoRoute(path: '/teacher/messages', builder: (_, __) => const MessagesPage()),
      GoRoute(path: '/admin/messages', builder: (_, __) => const MessagesPage()),
      GoRoute(
        path: '/chat/:id',
        builder: (_, s) => ChatPage(threadId: s.pathParameters['id']!),
      ),

      // ================= STUDENT =================
      ShellRoute(
        navigatorKey: _studentShellKey,
        builder: (context, state, child) =>
            RoleShell(role: 'student', child: child),
        routes: [
          GoRoute(
            path: '/student',
            builder: (_, __) => const s.StudentHomePage(),
            routes: [
              GoRoute(path: 'grades', builder: (_, __) => const GradesPage()),
              GoRoute(path: 'grades/edit', builder: (_, __) => const EditGradePage()),
              GoRoute(path: 'career', builder: (_, __) => const CareerPage()),
            ],
          ),
          GoRoute(
            path: '/student/subjects',
            builder: (_, __) => const SubjectsPage(),
            routes: [
              GoRoute(path: 'add', builder: (_, __) => const AddSubjectPage()),
              GoRoute(
                path: ':id/edit',
                builder: (_, s) =>
                    EditSubjectPage(enrollmentId: s.pathParameters['id']!), // ✅ fixed
              ),
            ],
          ),
          GoRoute(
            path: '/student/forum',
            builder: (_, __) => const ForumListPage(),
            routes: [
              GoRoute(path: 'create', builder: (_, __) => const CreatePostPage()),
              GoRoute(
                path: ':postId',
                builder: (_, s) =>
                    PostDetailPage(postId: s.pathParameters['postId']!),
              ),
              GoRoute(
                path: ':postId/edit',
                builder: (_, s) =>
                    EditPostPage(postId: s.pathParameters['postId']!),
              ),
            ],
          ),
          GoRoute(path: '/student/settings', builder: (_, __) => const SettingsPage()),
          GoRoute(path: '/student/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(
              path: '/student/notifications',
              builder: (_, __) => const NotificationPage()),
        ],
      ),

      // ================= TEACHER =================
      ShellRoute(
        navigatorKey: _teacherShellKey,
        builder: (context, state, child) =>
            RoleShell(role: 'teacher', child: child),
        routes: [
          GoRoute(
            path: '/teacher',
            builder: (_, __) => const t.TeacherHomePage(),
            routes: [
              GoRoute(path: 'students', builder: (_, __) => const StudentListPage()),
              GoRoute(
                path: 'students/:id',
                builder: (_, s) =>
                    StudentDetailPage(studentId: s.pathParameters['id']!),
              ),
              GoRoute(path: 'feedback', builder: (_, __) => const FeedbackPage()),
            ],
          ),
          GoRoute(
            path: '/teacher/forum',
            builder: (_, __) => const ForumListPage(),
            routes: [
              GoRoute(path: 'create', builder: (_, __) => const CreatePostPage()),
              GoRoute(
                path: ':postId',
                builder: (_, s) =>
                    PostDetailPage(postId: s.pathParameters['postId']!),
              ),
              GoRoute(
                path: ':postId/edit',
                builder: (_, s) =>
                    EditPostPage(postId: s.pathParameters['postId']!),
              ),
            ],
          ),
          GoRoute(path: '/teacher/settings', builder: (_, __) => const SettingsPage()),
          GoRoute(path: '/teacher/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(
              path: '/teacher/notifications',
              builder: (_, __) => const NotificationPage()),
        ],
      ),

      // ================= ADMIN =================
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) =>
            RoleShell(role: 'admin', child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const a.AdminHomePage(),
            routes: [
              GoRoute(path: 'users', builder: (_, __) => const UserManagePage()),
              GoRoute(path: 'users/add', builder: (_, __) => const UserAddPage()),
              GoRoute(
                path: 'users/:id',
                builder: (_, s) => UserEditFormPage(
                  userId: s.pathParameters['id']!,
                  email: s.uri.queryParameters['email'] ??
                      s.pathParameters['id']!,
                ),
              ),
              GoRoute(path: 'roles', builder: (_, __) => const RolePermissionPage()),
              GoRoute(path: 'moderation', builder: (_, __) => const ModerationPage()),

              // CONFIG dashboard
              GoRoute(path: 'career-config', builder: (_, __) => const DashboardConfigPage()),
              GoRoute(path: 'config', builder: (_, __) => const DashboardConfigPage()),

              // SUBJECTS management
              GoRoute(
                  path: 'config/subjects',
                  builder: (_, __) => const SubjectsManagePage()),
              GoRoute(
                  path: 'config/subjects/add',
                  builder: (_, __) => const SubjectAddPage()),
              GoRoute(
                path: 'config/subjects/:id/edit',
                builder: (_, s) =>
                    SubjectEditPage(subjectId: s.pathParameters['id']!),
              ),

              // SUBPLO management
              GoRoute(
                  path: 'config/subplo',
                  builder: (_, __) => const SubPLOManagePage()),
              GoRoute(
                  path: 'config/subplo/add',
                  builder: (_, __) => const SubPLOAddPage()),
              GoRoute(
                path: 'config/subplo/:id/edit',
                builder: (_, s) =>
                    SubPLOEditPage(subploId: s.pathParameters['id']!),
              ),

              // PLO management
              GoRoute(
                  path: 'config/plo',
                  builder: (_, __) => const PLOManagePage()),
              GoRoute(
                  path: 'config/plo/add',
                  builder: (_, __) => const PLOAddPage()),
              GoRoute(
                path: 'config/plo/:id/edit',
                builder: (_, s) =>
                    PLOEditPage(ploId: s.pathParameters['id']!),
              ),

              // CAREERS management
              GoRoute(
                  path: 'config/careers',
                  builder: (_, __) => const CareerManagePage()),
              GoRoute(
                  path: 'config/careers/add',
                  builder: (_, __) => const CareerAddPage()),
              GoRoute(
                path: 'config/careers/:id/edit',
                builder: (_, s) =>
                    CareerEditPage(careerId: s.pathParameters['id']!),
              ),

              // ✅ Mapping pages
              GoRoute(
                  path: 'config/subject-subplo-mapping',
                  builder: (_, __) => const SubjectSubPLOMappingPage()),
              GoRoute(
                  path: 'config/plo-subplo-mapping',
                  builder: (_, __) => const PLOSubPLOMappingPage()),
              GoRoute(
                  path: 'config/mappings',
                  builder: (_, __) => const CareerMappingPage()),

              // ✅ Admin forum
              GoRoute(
                path: 'forum',
                builder: (_, __) => const ForumListPage(),
                routes: [
                  GoRoute(path: 'create', builder: (_, __) => const CreatePostPage()),
                  GoRoute(
                    path: ':postId',
                    builder: (_, s) =>
                        PostDetailPage(postId: s.pathParameters['postId']!),
                  ),
                  GoRoute(
                    path: ':postId/edit',
                    builder: (_, s) =>
                        EditPostPage(postId: s.pathParameters['postId']!),
                  ),
                ],
              ),

              // ✅ Admin settings
              GoRoute(
                path: 'settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),

      // ---------- Global forum ----------
      GoRoute(
        path: '/forum',
        builder: (_, __) => const ForumListPage(),
        routes: [
          GoRoute(path: 'create', builder: (_, __) => const CreatePostPage()),
          GoRoute(
            path: ':postId',
            builder: (_, s) =>
                PostDetailPage(postId: s.pathParameters['postId']!),
          ),
          GoRoute(
            path: ':postId/edit',
            builder: (_, s) =>
                EditPostPage(postId: s.pathParameters['postId']!),
          ),
        ],
      ),
    ],
  );
}