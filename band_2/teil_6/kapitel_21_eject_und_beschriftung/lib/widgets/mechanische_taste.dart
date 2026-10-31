import 'package:flutter/material.dart';

class MechanischeTaste extends StatelessWidget {
  final String beschriftung;
  final IconData? icon;
  final bool istGedrueckt;
  final Color? akzentFarbe;
  final VoidCallback onGedrueckt;

  const MechanischeTaste({
    super.key,
    required this.beschriftung,
    this.icon,
    required this.istGedrueckt,
    this.akzentFarbe,
    required this.onGedrueckt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGedrueckt,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 72,
        height: 64,
        margin: EdgeInsets.only(top: istGedrueckt ? 4.0 : 0.0),
        decoration: BoxDecoration(
          color: istGedrueckt
              ? const Color(0xFF181B20)
              : const Color(0xFF2B303C),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            top: BorderSide(
              color: istGedrueckt
                  ? const Color(0xFF0F1115)
                  : const Color(0xFF5A6376),
              width: 2.0,
            ),
            bottom: BorderSide(
              color: istGedrueckt
                  ? const Color(0xFF475569)
                  : const Color(0xFF0F1115),
              width: istGedrueckt ? 1.0 : 4.0,
            ),
            left: BorderSide(
              color: istGedrueckt
                  ? const Color(0xFF1E222A)
                  : const Color(0xFF3E4656),
              width: 1.5,
            ),
            right: BorderSide(
              color: istGedrueckt
                  ? const Color(0xFF1E222A)
                  : const Color(0xFF1E222A),
              width: 1.5,
            ),
          ),
          boxShadow: istGedrueckt
              ? null
              : [
                  const BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 18,
                color: istGedrueckt
                    ? (akzentFarbe ?? const Color(0xFF38BDF8))
                    : const Color(0xFFCBD5E1),
              ),
            const SizedBox(height: 4),
            Text(
              beschriftung,
              style: TextStyle(
                color: istGedrueckt
                    ? (akzentFarbe ?? const Color(0xFF38BDF8))
                    : const Color(0xFFE2E8F0),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
