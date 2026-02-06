// main.dart - Complex real-world example
import 'package:dataflow/dataflow.dart';
import 'package:flutter/material.dart';
import 'store.dart';
import 'actions.dart';

void main() {
  final store = AppStore();
  DataFlow.init(store);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DataFlowInspector(
      child: MaterialApp(
        title: 'DataFlow Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Auth wrapper to handle login state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {LoginAction, LogoutAction},
      builder: (context, store, status) {
        if (store.currentUser != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ============ LOGIN SCREEN ============

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'demo@example.com');
  final _passwordController = TextEditingController(text: 'password123');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DataSync<AppStore>(
            actions: const {LoginAction},
            builder: (context, store, status) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.bolt, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'DataFlow Demo',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complex real-world example',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  if (store.authError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      store.authError!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: store.isAuthenticating
                        ? null
                        : () {
                            LoginAction(
                              email: _emailController.text,
                              password: _passwordController.text,
                            );
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: store.isAuthenticating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Test buttons for insights
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Trigger rapid actions to test insights
                            for (int i = 0; i < 6; i++) {
                              Future.delayed(Duration(milliseconds: i * 100), () {
                                RapidIncrementAction();
                              });
                            }
                          },
                          child: const Text('Test Rapid'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => SlowNetworkAction(),
                          child: const Text('Test Slow'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============ HOME SCREEN ============

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    LoadPostsAction(refresh: true);
    LoadNotificationsAction();
  }

  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {ChangeTabAction, LoadNotificationsAction},
      builder: (context, store, status) {
        return Scaffold(
          body: IndexedStack(
            index: store.selectedTabIndex,
            children: const [
              FeedTab(),
              SearchTab(),
              NotificationsTab(),
              ProfileTab(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: store.selectedTabIndex,
            onDestinationSelected: (i) => ChangeTabAction(index: i),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
              const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Badge(
                  label: Text('${store.unreadCount}'),
                  isLabelVisible: store.unreadCount > 0,
                  child: const Icon(Icons.notifications),
                ),
                label: 'Alerts',
              ),
              const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

// ============ FEED TAB ============

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {LoadPostsAction, LikePostAction},
      builder: (context, store, status) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Feed'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => LoadPostsAction(refresh: true),
              ),
            ],
          ),
          body: _buildBody(context, store),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppStore store) {
    if (store.isLoadingPosts && store.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.feedError != null && store.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(store.feedError!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => LoadPostsAction(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        LoadPostsAction(refresh: true);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        itemCount: store.posts.length + (store.hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= store.posts.length) {
            // Load more trigger
            if (!store.isLoadingPosts) {
              LoadPostsAction();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = store.posts[index];
          return PostCard(post: post);
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          SelectPostAction(post: post);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () => LikePostAction(postId: post.id),
                  ),
                  Text('${post.likes}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined, size: 20),
                  const SizedBox(width: 4),
                  Text('${post.comments.length}'),
                  const Spacer(),
                  Text(
                    _formatTime(post.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ============ POST DETAIL SCREEN ============

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {SelectPostAction, AddCommentAction},
      builder: (context, store, status) {
        final post = store.selectedPost;

        return Scaffold(
          appBar: AppBar(title: Text(post?.title ?? 'Post')),
          body: post == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(post.content),
                      const Divider(height: 32),
                      Text(
                        'Comments (${post.comments.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      if (store.isLoadingComments)
                        const Center(child: CircularProgressIndicator())
                      else
                        ...post.comments.map((c) => ListTile(
                              leading: CircleAvatar(child: Text(c.authorName[0])),
                              title: Text(c.authorName),
                              subtitle: Text(c.text),
                            )),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              AddCommentAction(text: 'Great post!');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ============ SEARCH TAB ============

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {SearchPostsAction},
      builder: (context, store, status) {
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search posts...',
                border: InputBorder.none,
              ),
              onChanged: (q) => SearchPostsAction(query: q),
            ),
          ),
          body: _buildBody(store),
        );
      },
    );
  }

  Widget _buildBody(AppStore store) {
    if (store.searchQuery.isEmpty) {
      return const Center(
        child: Text('Search for posts by title'),
      );
    }

    if (store.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.searchResults.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      itemCount: store.searchResults.length,
      itemBuilder: (context, index) {
        return PostCard(post: store.searchResults[index]);
      },
    );
  }
}

// ============ NOTIFICATIONS TAB ============

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {LoadNotificationsAction, MarkNotificationReadAction},
      builder: (context, store, status) {
        return Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: store.notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: store.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = store.notifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notif.isRead ? Colors.grey : Colors.blue,
                        child: Icon(
                          notif.isRead ? Icons.check : Icons.notifications,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notif.message),
                      onTap: () {
                        if (!notif.isRead) {
                          MarkNotificationReadAction(notificationId: notif.id);
                        }
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

// ============ PROFILE TAB ============

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DataSync<AppStore>(
      actions: const {UpdateSettingsAction, LogoutAction},
      builder: (context, store, status) {
        final user = store.currentUser;
        if (user == null) return const SizedBox.shrink();

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ListView(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 50,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                user.email,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: user.settings.darkMode,
                onChanged: (v) => UpdateSettingsAction(darkMode: v),
              ),
              SwitchListTile(
                title: const Text('Notifications'),
                value: user.settings.notifications,
                onChanged: (v) => UpdateSettingsAction(notifications: v),
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(user.settings.language.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final newLang = user.settings.language == 'en' ? 'es' : 'en';
                  UpdateSettingsAction(language: newLang);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => LogoutAction(),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Debug Actions', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Rapid Actions'),
                      onPressed: () {
                        for (int i = 0; i < 6; i++) {
                          Future.delayed(Duration(milliseconds: i * 100), () {
                            RapidIncrementAction();
                          });
                        }
                      },
                    ),
                    ActionChip(
                      label: const Text('Slow Action'),
                      onPressed: () => SlowNetworkAction(),
                    ),
                    ActionChip(
                      label: const Text('Reload Feed'),
                      onPressed: () => LoadPostsAction(refresh: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
