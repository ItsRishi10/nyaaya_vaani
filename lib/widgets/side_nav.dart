import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SideNav extends StatelessWidget {
  const SideNav({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Container(
      width: 56,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          const SizedBox(height: 8),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open',
          ),
          const Spacer(),
          if (auth.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Tooltip(
                message: auth.currentUser?['username'] ?? '',
                child: CircleAvatar(child: Text((auth.currentUser?['username'] ?? 'U').toString()[0].toUpperCase())),
              ),
            ),
        ],
      ),
    );
  }
}
