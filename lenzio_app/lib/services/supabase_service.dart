import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_model.dart';

/// Supabase Service for managing Authentication (Email/Password)
/// and CRUD operations on the `todos` table.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// Table name constant
  static const String todosTable = 'todos';

  /// Get direct SupabaseClient instance
  SupabaseClient get client => Supabase.instance.client;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Initialize Supabase Flutter SDK
  /// Call this in `main()` before `runApp()`.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    // Sanitize url in case user enters rest/v1 or trailing slash
    final cleanUrl = url.replaceAll(RegExp(r'/rest/v1/?$'), '').replaceAll(RegExp(r'/+$'), '');

    await Supabase.initialize(
      url: cleanUrl,
      publishableKey: anonKey,
    );
  }

  // ===========================================================================
  // AUTHENTICATION (Email & Password)
  // ===========================================================================

  /// Stream of AuthState changes (signed in, signed out, token refreshed, etc.)
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Current signed-in User (null if guest)
  User? get currentUser => client.auth.currentUser;

  /// Current User ID
  String? get currentUserId => client.auth.currentUser?.id;

  /// Current Auth Session
  Session? get currentSession => client.auth.currentSession;

  /// Check if user is currently signed in
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Register new user with Email and Password
  ///
  /// Optionally supply additional user profile [data] (e.g. `{'full_name': 'Somchai'}`).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: data,
    );
  }

  /// Sign in with Email and Password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Send password reset link to user's email
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  // ===========================================================================
  // CRUD FOR 'todos' TABLE
  // ===========================================================================

  /// Fetch all todos for the authenticated user
  ///
  /// Can optionally filter by [isComplete], and sort by [orderBy] (default 'created_at').
  Future<List<Todo>> getTodos({
    bool? isComplete,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    var query = client.from(todosTable).select();

    if (isComplete != null) {
      query = query.eq('is_complete', isComplete);
    }

    final response = await query.order(orderBy, ascending: ascending);
    return (response as List).map((item) => Todo.fromJson(item)).toList();
  }

  /// Fetch a single Todo by [id]
  Future<Todo?> getTodoById(int id) async {
    final response = await client
        .from(todosTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Todo.fromJson(response);
  }

  /// Create a new Todo record in Supabase
  ///
  /// Auto-assigns [userId] from `client.auth.currentUser?.id` if not already provided.
  Future<Todo> createTodo(Todo todo) async {
    final data = todo.toJson(forInsert: true);

    // If userId not set, auto-inject current user's id
    if (!data.containsKey('user_id') && currentUserId != null) {
      data['user_id'] = currentUserId;
    }

    final response = await client
        .from(todosTable)
        .insert(data)
        .select()
        .single();

    return Todo.fromJson(response);
  }

  /// Update an existing Todo record
  Future<Todo> updateTodo(Todo todo) async {
    if (todo.id == null) {
      throw ArgumentError('Cannot update Todo without an id.');
    }

    final data = todo.toJson();
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await client
        .from(todosTable)
        .update(data)
        .eq('id', todo.id!)
        .select()
        .single();

    return Todo.fromJson(response);
  }

  /// Toggle or update completion status of a Todo by [id]
  Future<void> toggleTodoStatus({
    required int id,
    required bool isComplete,
  }) async {
    await client.from(todosTable).update({
      'is_complete': isComplete,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Delete a Todo record by [id]
  Future<void> deleteTodo(int id) async {
    await client.from(todosTable).delete().eq('id', id);
  }

  /// Realtime Stream of Todos (Live updates automatically when data changes)
  Stream<List<Todo>> streamTodos({
    String orderBy = 'created_at',
    bool ascending = false,
  }) {
    return client
        .from(todosTable)
        .stream(primaryKey: ['id'])
        .order(orderBy, ascending: ascending)
        .map((records) => records.map((e) => Todo.fromJson(e)).toList());
  }
}
