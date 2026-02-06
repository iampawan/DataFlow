// actions.dart - All actions for the complex real-world example
import 'package:dataflow/dataflow.dart';

import 'store.dart';

// ============ AUTH ACTIONS ============

class LoginAction extends DataAction<AppStore> with Retryable<AppStore> {
  final String email;
  final String password;

  LoginAction({required this.email, required this.password});

  @override
  DataAction<AppStore> retry() => LoginAction(email: email, password: password);

  @override
  Future<void> execute() async {
    store.isAuthenticating = true;
    store.authError = null;
    DataFlow.notify(this);

    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    // Simulate validation
    if (email.isEmpty || password.isEmpty) {
      store.authError = 'Email and password required';
      store.isAuthenticating = false;
      throw Exception(store.authError);
    }

    if (password.length < 6) {
      store.authError = 'Password must be at least 6 characters';
      store.isAuthenticating = false;
      throw Exception(store.authError);
    }

    // Success
    store.currentUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      email: email,
      settings: UserSettings(),
    );
    store.isAuthenticating = false;
  }
}

class LogoutAction extends DataAction<AppStore> {
  @override
  Future<void> execute() async {
    await Future.delayed(const Duration(milliseconds: 500));
    store.currentUser = null;
    store.posts = [];
    store.notifications = [];
    store.selectedPost = null;
    store.currentPage = 0;
    store.hasMorePosts = true;
  }
}

class UpdateSettingsAction extends DataAction<AppStore> {
  final bool? darkMode;
  final bool? notifications;
  final String? language;

  UpdateSettingsAction({this.darkMode, this.notifications, this.language});

  // @override
  // DataAction<AppStore> retry() => UpdateSettingsAction(
  //       darkMode: !darkMode!,
  //       notifications: notifications,
  //       language: language,
  //     );

  @override
  Future<void> execute() async {
    if (store.currentUser == null) return;

    await Future.delayed(const Duration(milliseconds: 300));

    store.currentUser = User(
      id: store.currentUser!.id,
      name: store.currentUser!.name,
      email: store.currentUser!.email,
      avatarUrl: store.currentUser!.avatarUrl,
      settings: store.currentUser!.settings.copyWith(
        darkMode: darkMode,
        notifications: notifications,
        language: language,
      ),
    );
  }
}

// ============ FEED ACTIONS ============

class LoadPostsAction extends DataAction<AppStore> with Retryable<AppStore> {
  final bool refresh;

  LoadPostsAction({this.refresh = false});

  @override
  DataAction<AppStore> retry() => LoadPostsAction(refresh: refresh);

  @override
  Future<void> execute() async {
    if (refresh) {
      store.currentPage = 0;
      store.hasMorePosts = true;
    }

    if (!store.hasMorePosts && !refresh) return;

    store.isLoadingPosts = true;
    store.feedError = null;
    DataFlow.notify(this);

    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    // Simulate random error (10% chance)
    if (DateTime.now().millisecond % 10 == 0) {
      store.isLoadingPosts = false;
      store.feedError = 'Network error. Please try again.';
      throw Exception(store.feedError);
    }

    // Generate fake posts
    final newPosts = List.generate(5, (i) {
      final index = store.currentPage * 5 + i;
      return Post(
        id: 'post_$index',
        authorId: 'author_${index % 3}',
        title: 'Post #$index: ${_sampleTitles[index % _sampleTitles.length]}',
        content: 'This is the content for post $index. It contains interesting information.',
        createdAt: DateTime.now().subtract(Duration(hours: index * 2)),
        likes: (index * 7) % 100,
        comments: [],
      );
    });

    if (refresh) {
      store.posts = newPosts;
    } else {
      store.posts = [...store.posts, ...newPosts];
    }

    store.currentPage++;
    store.hasMorePosts = store.currentPage < 5; // Max 5 pages
    store.isLoadingPosts = false;
  }

  static const _sampleTitles = [
    'Getting Started with Flutter',
    'State Management Best Practices',
    'Building Responsive UIs',
    'Performance Optimization Tips',
    'Testing Your Flutter Apps',
    'CI/CD for Mobile Apps',
    'Design Patterns in Dart',
  ];
}

class LikePostAction extends DataAction<AppStore> {
  final String postId;

  LikePostAction({required this.postId});

  @override
  Future<void> execute() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = store.posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      store.posts[index] = store.posts[index].copyWith(
        likes: store.posts[index].likes + 1,
      );
      store.posts = List.from(store.posts); // Trigger rebuild
    }
  }
}

class SelectPostAction extends DataAction<AppStore> {
  final Post post;

  SelectPostAction({required this.post});

  @override
  Future<void> execute() async {
    store.selectedPost = post;
    store.isLoadingComments = true;
    DataFlow.notify(this);

    await Future.delayed(const Duration(milliseconds: 800));

    // Load comments
    final comments = List.generate(
        3,
        (i) => Comment(
              id: 'comment_${post.id}_$i',
              postId: post.id,
              authorName: 'User ${i + 1}',
              text: 'This is comment #$i on this post. Great content!',
              createdAt: DateTime.now().subtract(Duration(minutes: i * 30)),
            ));

    store.selectedPost = post.copyWith(comments: comments);
    store.isLoadingComments = false;
  }
}

class AddCommentAction extends DataAction<AppStore> {
  final String text;

  AddCommentAction({required this.text});

  @override
  Future<void> execute() async {
    if (store.selectedPost == null || store.currentUser == null) return;

    await Future.delayed(const Duration(milliseconds: 500));

    final newComment = Comment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: store.selectedPost!.id,
      authorName: store.currentUser!.name,
      text: text,
      createdAt: DateTime.now(),
    );

    store.selectedPost = store.selectedPost!.copyWith(
      comments: [...store.selectedPost!.comments, newComment],
    );
  }
}

// ============ NOTIFICATION ACTIONS ============

class LoadNotificationsAction extends DataAction<AppStore> with Retryable<AppStore> {
  @override
  DataAction<AppStore> retry() => LoadNotificationsAction();

  @override
  Future<void> execute() async {
    await Future.delayed(const Duration(milliseconds: 600));

    store.notifications = List.generate(
        5,
        (i) => Notification(
              id: 'notif_$i',
              title: i == 0 ? 'Welcome!' : 'New activity',
              message: i == 0 ? 'Thanks for joining!' : 'Someone liked your post #$i',
              isRead: i > 2,
              timestamp: DateTime.now().subtract(Duration(hours: i)),
            ));

    store.unreadCount = store.notifications.where((n) => !n.isRead).length;
  }
}

class MarkNotificationReadAction extends DataAction<AppStore> {
  final String notificationId;

  MarkNotificationReadAction({required this.notificationId});

  @override
  Future<void> execute() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = store.notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notif = store.notifications[index];
      store.notifications[index] = Notification(
        id: notif.id,
        title: notif.title,
        message: notif.message,
        isRead: true,
        timestamp: notif.timestamp,
      );
      store.notifications = List.from(store.notifications);
      store.unreadCount = store.notifications.where((n) => !n.isRead).length;
    }
  }
}

// ============ SEARCH ACTIONS ============

class SearchPostsAction extends DataAction<AppStore> {
  final String query;

  SearchPostsAction({required this.query});

  @override
  Future<void> execute() async {
    store.searchQuery = query;

    if (query.isEmpty) {
      store.searchResults = [];
      store.isSearching = false;
      return;
    }

    store.isSearching = true;
    DataFlow.notify(this);

    await Future.delayed(const Duration(milliseconds: 500));

    store.searchResults =
        store.posts.where((p) => p.title.toLowerCase().contains(query.toLowerCase())).toList();
    store.isSearching = false;
  }
}

// ============ UI ACTIONS ============

class ChangeTabAction extends DataAction<AppStore> {
  final int index;

  ChangeTabAction({required this.index});

  @override
  Future<void> execute() async {
    store.selectedTabIndex = index;
  }
}

// ============ DEBUG/TEST ACTIONS ============

/// Rapid fire action for testing "Rapid Action Calls" insight
class RapidIncrementAction extends DataAction<AppStore> {
  @override
  Future<void> execute() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

/// Slow action for testing "Slow Action" insight
class SlowNetworkAction extends DataAction<AppStore> {
  @override
  Future<void> execute() async {
    await Future.delayed(const Duration(seconds: 6));
  }
}
