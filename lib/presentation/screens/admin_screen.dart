import 'package:appwrite/appwrite.dart';
import 'package:belanja_praktis/config/appwrite_db.dart';
import 'package:belanja_praktis/data/models/user_model.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();

  bool _isAdmin = false;
  bool _isLoading = true;

  List<UserModel> _users = [];
  int _totalUsers = 0;
  int _premiumUsers = 0;
  int _freeUsers = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = await _authRepository.getCurrentUser();
    if (currentUser != null && await _authRepository.isAdmin(currentUser.uid)) {
      setState(() {
        _isAdmin = true;
      });
      await _loadAdminData();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAdminData() async {
    try {
      // Get all users from the repository
      final users = await _authRepository.getAllUsers();

      // Calculate statistics
      final totalUsers = users.length;
      final premiumUsers = users.where((user) => user.isPremium).length;
      final freeUsers = totalUsers - premiumUsers;

      setState(() {
        _users = users;
        _totalUsers = totalUsers;
        _premiumUsers = premiumUsers;
        _freeUsers = freeUsers;
      });
    } catch (e) {
      print('Error loading admin data: $e');
      _showSnackBar('❌ Failed to load user data: ${e.toString()}');
      setState(() {
        _users = [];
        _totalUsers = 0;
        _premiumUsers = 0;
        _freeUsers = 0;
      });
    }
  }

  Future<void> _togglePremiumStatus(UserModel user) async {
    final newStatus = !user.isPremium;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('${newStatus ? "Grant" : "Revoke"} Premium?'),
          content: Text(
            'Are you sure you want to ${newStatus ? "grant" : "revoke"} premium access for "${user.username}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(newStatus ? 'Grant' : 'Revoke'),
              onPressed: () async {
                try {
                  // Find the user document by uid
                  final databases = GetIt.I<Databases>();
                  final response = await databases.listDocuments(
                    databaseId: AppwriteDB.databaseId,
                    collectionId: AppwriteDB.usersCollectionId,
                    queries: [Query.equal('uid', user.uid)],
                  );

                  if (response.documents.isEmpty) {
                    throw Exception('User document not found.');
                  }

                  final docId = response.documents.first.$id;

                  // Update the premium status
                  await databases.updateDocument(
                    databaseId: AppwriteDB.databaseId,
                    collectionId: AppwriteDB.usersCollectionId,
                    documentId: docId,
                    data: {'isPremium': newStatus},
                  );

                  // ignore: use_build_context_synchronously
                  Navigator.of(dialogContext).pop();
                  await _loadAdminData();
                  _showSnackBar(
                    '✅ Premium status for "${user.username}" updated.',
                  );
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(dialogContext).pop();
                  _showSnackBar(
                    '❌ Failed to update premium status: ${e.toString()}',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userUid, String userName) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete User?'),
          content: Text(
            'Are you sure you want to delete "$userName"? This will also delete all their lists and items!',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await _authRepository.deleteUser(userUid);
                // ignore: use_build_context_synchronously
                Navigator.of(dialogContext).pop();
                _loadAdminData();
                _showSnackBar('✅ User "$userName" deleted successfully');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllUsers() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Users?'),
          content: const Text(
            'This will delete all users except admin. This action cannot be undone!',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Clear All'),
              onPressed: () async {
                await _authRepository.clearAllUsersExceptAdmin();
                // ignore: use_build_context_synchronously
                Navigator.of(dialogContext).pop();
                _loadAdminData();
                _showSnackBar('✅ All non-admin users deleted!');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _adminLogout() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout Admin?'),
          content: const Text('You will be returned to the login screen'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                await _authRepository.logout();
                // ignore: use_build_context_synchronously
                Navigator.of(dialogContext).pop();
                // ignore: use_build_context_synchronously
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _isAdmin ? _buildAdminDashboard() : _buildAccessDenied(),
    );
  }

  Widget _buildAccessDenied() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3a3a3a), Color(0xFF2a2a2a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gpp_bad_outlined,
                size: 90,
                color: Color(0xFFF44336),
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You do not have the necessary permissions to view this page. Please contact the administrator if you believe this is an error.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF667EEA),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _adminLogout,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Total Users',
                    _totalUsers.toString(),
                    Colors.white,
                    Colors.white70,
                  ),
                  _buildStatCard(
                    'Premium Users',
                    _premiumUsers.toString(),
                    Colors.amber,
                    Colors.amber.shade100,
                  ),
                  _buildStatCard(
                    'Free Users',
                    _freeUsers.toString(),
                    Colors.lightBlueAccent,
                    Colors.lightBlueAccent.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'User List',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white.withOpacity(0.9),
                    child: ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey.shade100,
                            child: Icon(
                              user.isPremium ? Icons.star : Icons.person,
                              color: user.isPremium
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                          ),
                          title: Text(user.username),
                          subtitle: Text(user.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Toggle Premium Status',
                                icon: Icon(
                                  Icons.workspace_premium,
                                  color: user.isPremium
                                      ? Colors.amber.shade700
                                      : Colors.grey,
                                ),
                                onPressed: () => _togglePremiumStatus(user),
                              ),
                              IconButton(
                                tooltip: 'Delete User',
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _deleteUser(user.uid, user.username),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _clearAllUsers,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red.shade700,
                    shadowColor: Colors.red.shade900.withOpacity(0.5),
                    elevation: 8,
                  ),
                  child: const Text(
                    'CLEAR ALL NON-ADMIN USERS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color gradientStart,
    Color gradientEnd,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
