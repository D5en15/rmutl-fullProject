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
import 'ui/admin/user_add_page.dart'; // ✅ เพิ่มเข้ามา
import 'ui/admin/role_permission_page.dart';
import 'ui/admin/moderation_page.dart';

// ---------- ADMIN CONFIG ----------
import 'ui/admin/dashboard_config_page.dart';
import 'ui/admin/subjects_manage_page.dart';
import 'ui/admin/subject_add_page.dart';
import 'ui/admin/subject_edit_page.dart';
// Skills
import 'ui/admin/skills_manage_page.dart';
import 'ui/admin/skill_add_page.dart';
import 'ui/admin/skill_edit_page.dart';
// Careers
import 'ui/admin/career_manage_page.dart';
import 'ui/admin/career_add_page.dart';
import 'ui/admin/career_edit_page.dart';

// ---------- FORUM (shared) ----------
import 'ui/forum/forum_list_page.dart';
import 'ui/forum/post_detail_page.dart';
import 'ui/forum/create_post_page.dart';
import 'ui/forum/edit_post_page.dart'; // ✅ เพิ่มใหม่

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

      // Messages & Chat (นอก shell)
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
                    EditSubjectPage(subjectId: s.pathParameters['id']!),
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
                    EditPostPage(postId: s.pathParameters['postId']!), // ✅
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
                    EditPostPage(postId: s.pathParameters['postId']!), // ✅
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
              GoRoute(
                  path: 'users/add',
                  builder: (_, __) => const UserAddPage()), // ✅ เพิ่ม
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

              // CONFIG dashboard (alias)
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

              // SKILLS management
              GoRoute(
                  path: 'config/skills',
                  builder: (_, __) => const SkillsManagePage()),
              GoRoute(
                  path: 'config/skills/add',
                  builder: (_, __) => const SkillAddPage()),
              GoRoute(
                path: 'config/skills/:id/edit',
                builder: (_, s) =>
                    SkillEditPage(skillId: s.pathParameters['id']!),
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
            ],
          ),

          // aliases นอกซับรูต
          GoRoute(path: '/admin/users', builder: (_, __) => const UserManagePage()),
          GoRoute(
              path: '/admin/users/add', builder: (_, __) => const UserAddPage()), // ✅ alias
          GoRoute(
            path: '/admin/users/:id',
            builder: (_, s) => UserEditFormPage(
              userId: s.pathParameters['id']!,
              email: s.uri.queryParameters['email'] ?? s.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/admin/moderation', builder: (_, __) => const ModerationPage()),
          GoRoute(path: '/admin/settings', builder: (_, __) => const SettingsPage()),
          GoRoute(path: '/admin/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(
              path: '/admin/notifications',
              builder: (_, __) => const NotificationPage()),

          GoRoute(
            path: '/admin/forum',
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
                    EditPostPage(postId: s.pathParameters['postId']!), // ✅
              ),
            ],
          ),

          // Absolute aliases
          GoRoute(
              path: '/admin/config/careers',
              builder: (_, __) => const CareerManagePage()),
          GoRoute(
              path: '/admin/config/careers/add',
              builder: (_, __) => const CareerAddPage()),
          GoRoute(
            path: '/admin/config/careers/:id/edit',
            builder: (_, s) =>
                CareerEditPage(careerId: s.pathParameters['id']!),
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
                EditPostPage(postId: s.pathParameters['postId']!), // ✅
          ),
        ],
      ),
    ],
  );
}