// store.dart - Models and Store for the complex real-world example
import 'package:dataflow/dataflow.dart';

// ============ MODELS ============

class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserSettings settings;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.settings,
  });

  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, settings: $settings)';
}

class UserSettings {
  final bool darkMode;
  final bool notifications;
  final String language;

  UserSettings({
    this.darkMode = false,
    this.notifications = true,
    this.language = 'en',
  });

  UserSettings copyWith({bool? darkMode, bool? notifications, String? language}) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
    );
  }

  @override
  String toString() =>
      'Settings(darkMode: $darkMode, notifications: $notifications, lang: $language)';
}

class Post {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final int likes;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.comments = const [],
  });

  Post copyWith({int? likes, List<Comment>? comments}) {
    return Post(
      id: id,
      authorId: authorId,
      title: title,
      content: content,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }

  @override
  String toString() =>
      'Post(id: $id, title: "$title", likes: $likes, comments: ${comments.length})';
}

class Comment {
  final String id;
  final String postId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  @override
  String toString() {
    final truncatedText = text.length > 20 ? text.substring(0, 20) : text;
    return 'Comment(by: $authorName, text: "$truncatedText...")';
  }
}

class Notification {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime timestamp;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.timestamp,
  });

  @override
  String toString() => 'Notification(title: "$title", read: $isRead)';
}

// ============ STORE ============

class AppStore extends DataStore {
  // Auth State
  User? currentUser;
  bool isAuthenticating = false;
  String? authError;

  // Feed State
  List<Post> posts = [];
  bool isLoadingPosts = false;
  bool hasMorePosts = true;
  int currentPage = 0;
  String? feedError;

  // Selected Post State
  Post? selectedPost;
  bool isLoadingComments = false;

  // Notifications State
  List<Notification> notifications = [];
  int unreadCount = 0;

  // Search State
  String searchQuery = '';
  List<Post> searchResults = [];
  bool isSearching = false;

  // UI State
  int selectedTabIndex = 0;

  @override
  String toString() {
    return '''
AppStore {
  === AUTH ===
  currentUser: ${currentUser?.name ?? 'null'},
  isAuthenticating: $isAuthenticating,
  authError: $authError,

  === FEED ===
  posts: ${posts.length} items,
  isLoadingPosts: $isLoadingPosts,
  hasMorePosts: $hasMorePosts,
  currentPage: $currentPage,
  feedError: $feedError,

  === SELECTED POST ===
  selectedPost: ${selectedPost?.title ?? 'null'},
  isLoadingComments: $isLoadingComments,

  === NOTIFICATIONS ===
  notifications: ${notifications.length} items,
  unreadCount: $unreadCount,

  === SEARCH ===
  searchQuery: "$searchQuery",
  searchResults: ${searchResults.length} items,
  isSearching: $isSearching,

  === UI ===
  selectedTabIndex: $selectedTabIndex
}''';
  }
}
