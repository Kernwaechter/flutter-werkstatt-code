import 'package:flutter/material.dart';

class Bandzaehlwerk extends StatelessWidget {
  final int zaehlerstand;
  final bool memoAktiv;
  final VoidCallback onReset;
  final ValueChanged<bool> onMemoChanged;

  const Bandzaehlwerk({
    super.key,
    required this.zaehlerstand,
    this.memoAktiv = false,
    required this.onReset,
    required this.onMemoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = zaehlerstand.clamp(0, 999).toString().padLeft(3, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TAPE',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF475569)),
            ),
            child: Row(
              children: [
                _ZiffernWalze(ziffer: text[0]),
                const SizedBox(width: 4),
                _ZiffernWalze(ziffer: text[1]),
                const SizedBox(width: 4),
                _ZiffernWalze(ziffer: text[2]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onReset,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF64748B)),
              ),
              child: const Text(
                'RESET',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // MEMO Schalter (Memory-Stop)
          InkWell(
            onTap: () => onMemoChanged(!memoAktiv),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: memoAktiv
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: memoAktiv
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF475569),
                ),
              ),
              child: Text(
                'MEMO',
                style: TextStyle(
                  color: memoAktiv ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZiffernWalze extends StatelessWidget {
  final String ziffer;

  const _ZiffernWalze({required this.ziffer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF181B20),
      ),
      child: Text(
        ziffer,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
