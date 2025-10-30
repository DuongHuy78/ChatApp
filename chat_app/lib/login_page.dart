import 'package:chat_app/user_list_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String ip ="192.168.1.118" ;
  late Dio dio;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    dio = Dio(BaseOptions(baseUrl: "http://$ip:8000"));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _login() async{
    try {
      final email = _emailController.text.toString();
      final password = _passwordController.text.toString();

      final response = await dio.post("/login", data: {
        "email": email,
        "password": password, 
      });
      if (response.statusCode == 200) {
        // final data = response.data;
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('userid', data['userid']);
        // await prefs.setString('token', data['token']);
        String myid = response.data['userid'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserListPage(myid: myid,)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng thử lại email và mật khẩu')),
        );
      }
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại: $e')),
      );
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty ||
        _confirmPasswordController.text != _passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra thông tin')),
      );
      return;
    }
    try {
      final response = await dio.post("/register", data: {
        "email": _emailController.text,
        "password": _passwordController.text,
      });
      if (response.statusCode == 201) {
        final data = response.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng ký thành công! UserID: ${data['userid']}')),
        );
        _tabController.animateTo(0);  // Chuyển về tab Login
      }
    } catch (e) {
      print('Register error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đăng nhập'),
            Tab(text: 'Đăng ký'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Đăng nhập'),
                ),
              ],
            ),
          ),
          // Tab Đăng ký
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Đăng ký'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}