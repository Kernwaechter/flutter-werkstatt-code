import 'package:flutter/material.dart';
import '../energie_tacho.dart';
import '../models/messwert.dart';
import '../verlaufs_diagramm.dart';

class CockpitScreen extends StatefulWidget {
  const CockpitScreen({super.key});

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  int _navIndex = 0;

  static const List<Messwert> _daten = [
    Messwert(zeitpunkt: '06:00', watt: 0),
    Messwert(zeitpunkt: '08:00', watt: 620),
    Messwert(zeitpunkt: '10:00', watt: 2100),
    Messwert(zeitpunkt: '12:00', watt: 4100),
    Messwert(zeitpunkt: '14:00', watt: 3850),
    Messwert(zeitpunkt: '16:00', watt: 2400),
    Messwert(zeitpunkt: '18:00', watt: 800),
    Messwert(zeitpunkt: '20:00', watt: 80),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breite = constraints.maxWidth;
        final istHandy = breite < 600;
        final istDesktop = breite >= 1000;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(
              istHandy
                  ? 'Cockpit'
                  : 'Wetter- & Energie-Cockpit (${breite.toInt()} px)',
            ),
          ),
          bottomNavigationBar: istHandy
              ? NavigationBar(
                  selectedIndex: _navIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _navIndex = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard),
                      label: 'Cockpit',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.show_chart),
                      label: 'Verlauf',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings),
                      label: 'Optionen',
                    ),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (!istHandy)
                NavigationRail(
                  selectedIndex: _navIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _navIndex = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: const Color(0xFF1E293B),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Cockpit'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.show_chart),
                      label: Text('Verlauf'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Optionen'),
                    ),
                  ],
                ),
              Expanded(
                child: istDesktop
                    ? _baueDesktopLayout()
                    : istHandy
                        ? _baueHandyLayout()
                        : _baueTabletLayout(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _baueHandyLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _baueKachel(
          titel: 'SOLAR-LEISTUNG (LIVE)',
          kind: const SizedBox(
            height: 260,
            child: EnergieTacho(wertInWatt: 3840),
          ),
        ),
        const SizedBox(height: 16),
        _baueKachel(
          titel: 'TAGESVERLAUF',
          kind: const SizedBox(
            height: 220,
            child: VerlaufsDiagramm(datenpunkte: _daten),
          ),
        ),
      ],
    );
  }

  Widget _baueTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: _baueKachel(
                    titel: 'SOLAR-LEISTUNG',
                    kind: const EnergieTacho(wertInWatt: 3840),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _baueKachel(
                    titel: 'AKKU-SPEICHER',
                    kind: const Center(
                      child: Text(
                        '84 % GELADEN\n(4,2 kWh)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: _baueKachel(
              titel: 'TAGESVERLAUF',
              kind: const VerlaufsDiagramm(datenpunkte: _daten),
            ),
          ),
        ],
      ),
    );
  }

  Widget _baueDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _baueKachel(
              titel: 'SOLARLEISTUNG LIVE',
              kind: const EnergieTacho(wertInWatt: 3840),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _baueKachel(
                    titel: 'TAGES-ERTRAGSKURVE (24h)',
                    kind: const VerlaufsDiagramm(datenpunkte: _daten),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _baueStatusChip(
                          'Netzeinspeisung',
                          '2.150 W',
                          const Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _baueStatusChip(
                          'Eigenverbrauch',
                          '1.690 W',
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _baueStatusChip(
                          'Batterieladung',
                          '84 %',
                          const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _baueKachel({required String titel, required Widget kind}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: kind),
        ],
      ),
    );
  }

  Widget _baueStatusChip(String titel, String wert, Color farbe) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            wert,
            style: TextStyle(
              color: farbe,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titel,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
