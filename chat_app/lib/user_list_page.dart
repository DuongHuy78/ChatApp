import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'chat.dart';

class UserListPage extends StatefulWidget {
  final String myid;
  const UserListPage({super.key, required this.myid});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> users = [];
  late Dio dio;
  String ip = "chatapp-6ehz.onrender.com";

  @override
  void initState() {
    super.initState();
    dio = Dio(BaseOptions(baseUrl: "https://$ip",
      connectTimeout: const Duration(seconds: 60), 
      receiveTimeout: const Duration(seconds: 60),));
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await dio.get("/users");
      if (response.statusCode == 200) {
        setState(() {
          users = response.data;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn người nhắn tin'),
      ),
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text('UserID: ${user['userid']}'),
                  subtitle: Text('Email: ${user['email']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          myid: widget.myid,
                          receiverid: user['userid'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}