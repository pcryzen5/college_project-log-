// login_page.dart
import 'package:flutter/material.dart';
import 'mongo_helper.dart';
import 'welcome_page.dart';

class LoginPage extends StatefulWidget
{
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
{
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _login() async
  {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty)
    {
      setState(()
      {
        _errorMessage = 'Please enter both username and password.';
      });
      return;
    }

    try
    {
      final user = await MongoHelper.authenticate(username, password);
      if (user != null)
      {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomePage(username: user['username']),),
        );
      }
      else
      {
        setState(() {
          _errorMessage = 'Invalid username or password.';});
      }
    }
    catch (e)
    {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),),
              ),
          ],
        ),
      ),
    );
  }
}

