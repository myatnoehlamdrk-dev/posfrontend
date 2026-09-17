import 'package:flutter/material.dart';
import 'package:posfrontend/features/auth/data/models/login_response.dart';

class AuthScope extends StatefulWidget {
  final Widget child;
  const AuthScope({super.key, required this.child});

  @override
  State<AuthScope> createState() => AuthScopeState();

  static LoginResponse? userOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AuthScopeData>()?.user;
  }

  static void updateUserOf(BuildContext context, LoginResponse? user) {
    context.dependOnInheritedWidgetOfExactType<_AuthScopeData>()?.updateUser(user);
  }
}

class AuthScopeState extends State<AuthScope> {
  LoginResponse? _user;
  LoginResponse? get user => _user;

  void updateUser(LoginResponse? user) {
    if (_user != user) {
      setState(() => _user = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScopeData(
      user: _user,
      updateUser: updateUser,
      child: widget.child,
    );
  }
}

class _AuthScopeData extends InheritedWidget {
  final LoginResponse? user;
  final void Function(LoginResponse?) updateUser;

  const _AuthScopeData({
    required this.user,
    required this.updateUser,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AuthScopeData oldWidget) {
    return user != oldWidget.user;
  }
}
