import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'register2.dart';

class HomePage extends StatelessWidget {
	const HomePage({super.key});

	@override
	Widget build(BuildContext context) {
		final primary = Theme.of(context).colorScheme.primary;
		return Scaffold(
			backgroundColor: const Color(0xFFFAF2EC),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
					child: Column(
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										const SizedBox(height: 12),
										// top illustration placeholder
										Center(
											child: Container(
												height: 260,
												width: double.infinity,
												decoration: BoxDecoration(
													color: Colors.white,
													borderRadius: BorderRadius.circular(24),
												),
												child: const Center(
													child: Icon(Icons.person_search, size: 120, color: Colors.orangeAccent),
												),
											),
										),
										const SizedBox(height: 24),
										const Text(
											'Discover Your\nDream Job here',
											style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
										),
										const SizedBox(height: 12),
										const Text(
											'Explore all the existing job roles based on your interest and study major',
											style: TextStyle(fontSize: 14, color: Colors.black54),
										),
									],
								),
							),

							// Bottom action row: prominent Login button and Register links
							Container(
								padding: const EdgeInsets.symmetric(vertical: 12),
								child: Row(
									children: [
										Expanded(
											flex: 2,
											child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													backgroundColor: primary,
													foregroundColor: Colors.white,
													padding: const EdgeInsets.symmetric(vertical: 14),
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													elevation: 6,
												),
												onPressed: () {
													Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
												},
												child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
											),
										),
										const SizedBox(width: 12),
										Expanded(
											flex: 3,
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													TextButton(
														onPressed: () {
															Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
														},
														child: const Text('Register as a User', style: TextStyle(fontSize: 16, color: Colors.black87)),
													),
													TextButton(
														onPressed: () {
															Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterAdvocatePage()));
														},
														child: const Text('Register as an Advocate', style: TextStyle(fontSize: 16, color: Colors.black87)),
													),
												],
											),
										),
									],
								),
							),
						],
					),
				),
			),
		);
	}
}

