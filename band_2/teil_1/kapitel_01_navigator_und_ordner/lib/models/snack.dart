import 'package:flutter/material.dart';

class Snack {
  final String id;
  final String name;
  final String kategorie;
  final String beschreibung;
  final double grundpreis;
  final IconData symbol;
  final Color akzentFarbe;

  const Snack({
    required this.id,
    required this.name,
    required this.kategorie,
    required this.beschreibung,
    required this.grundpreis,
    required this.symbol,
    required this.akzentFarbe,
  });
}

const List<Snack> kioskSpeisekarte = [
  Snack(
    id: 'baguette_caprese',
    name: 'Ofen-Baguette Caprese',
    kategorie: 'Herzhaft',
    beschreibung:
        'Knuspriges Steinofen-Baguette mit Mozzarella, '
        'Strauchtomaten und frischem Basilikum-Pesto.',
    grundpreis: 3.80,
    symbol: Icons.bakery_dining,
    akzentFarbe: Color(0xFFD97706),
  ),
  Snack(
    id: 'wrap_falafel',
    name: 'Knusper-Falafel Wrap',
    kategorie: 'Vegan',
    beschreibung:
        'Warmer Weizen-Wrap mit Kichererbsen-Falafel, '
        'Rotkohl, Hummus und Minz-Joghurt-Dip.',
    grundpreis: 4.20,
    symbol: Icons.lunch_dining,
    akzentFarbe: Color(0xFF059669),
  ),
  Snack(
    id: 'bowl_beeren',
    name: 'Power-Beeren Joghurt',
    kategorie: 'Frisch',
    beschreibung:
        'Cremiger Naturjoghurt mit geröstetem Hafer-Crunch, '
        'Blaubeeren und einem Löffel Waldhonig.',
    grundpreis: 2.90,
    symbol: Icons.icecream,
    akzentFarbe: Color(0xFF7C3AED),
  ),
  Snack(
    id: 'smoothie_mango',
    name: 'Mango-Maracuja Smoothie',
    kategorie: 'Getränk',
    beschreibung:
        'Eiskalt gemixt aus reifer Mango, Maracuja '
        'und frisch gepresstem Orangensaft.',
    grundpreis: 3.10,
    symbol: Icons.local_cafe,
    akzentFarbe: Color(0xFF0284C7),
  ),
];
