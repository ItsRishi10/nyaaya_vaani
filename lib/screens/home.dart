import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'login.dart';
import 'register.dart';
import 'register2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatelessWidget {
	const HomePage({super.key});

	@override
	Widget build(BuildContext context) {
		final loc = context.watch<AppLocalizations>();
		return Scaffold(
			backgroundColor: const Color(0xFFFAF2EC),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
					child: Column(
						children: [
							// top row: language toggle on the right
							Row(
								children: [
									const Spacer(),
									IconButton(
										icon: loc.isTranslating
											  ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
											  : FaIcon(FontAwesomeIcons.globe),
										onPressed: loc.isTranslating ? null : () => context.read<AppLocalizations>().toggleLanguage(),
									),
								],
							),
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
													//child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 120, color: Colors.orangeAccent),
												),
											),
										),
										const SizedBox(height: 24),
										Text(
											loc.getText('app_title'),
											style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
										),
										const SizedBox(height: 12),
										Text(
											loc.getText('Subtitle'),
											style: const TextStyle(fontSize: 14, color: Colors.black54),
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
													backgroundColor: Colors.orangeAccent,
													foregroundColor: Colors.white,
													padding: const EdgeInsets.symmetric(vertical: 14),
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													elevation: 6,
												),
												onPressed: () {
													Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
												},
												child: Text(loc.getText('login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
											),
										),
										const SizedBox(width: 12),
										Expanded(
											flex: 3,
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													ElevatedButton(
														style: ElevatedButton.styleFrom(
															backgroundColor: Colors.orangeAccent,
															foregroundColor: Colors.white,
															padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
															shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
														),
														onPressed: () {
															Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
														},
														child: Text(loc.getText('register_as_user'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
													),
													const SizedBox(height: 8),
													ElevatedButton(
														style: ElevatedButton.styleFrom(
															backgroundColor: Colors.orangeAccent,
															foregroundColor: Colors.white,
															padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
															shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
														),
														onPressed: () {
															Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterAdvocatePage()));
														},
														child: Text(loc.getText('register_as_advocate'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

