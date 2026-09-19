import 'package:flutter/material.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialPrimary;
  final Color initialSecondary;

  const ColorPickerDialog({
    super.key,
    required this.initialPrimary,
    required this.initialSecondary,
  });

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => ColorPickerDialog(
        initialPrimary: AppState.customPrimaryColorNotifier.value,
        initialSecondary: AppState.customSecondaryColorNotifier.value,
      ),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _primary;
  late Color _secondary;
  bool _isEditingPrimary = true;

  late double _hue;
  late double _saturation;
  late double _value;
  final TextEditingController _hexController = TextEditingController();

  final List<Map<String, dynamic>> _quickPalettes = [
    {
      'name': 'Violet Neon',
      'primary': const Color(0xFF8B5CF6),
      'secondary': const Color(0xFF10B981),
    },
    {
      'name': 'Ocean Cyan',
      'primary': const Color(0xFF3B82F6),
      'secondary': const Color(0xFF06B6D4),
    },
    {
      'name': 'Emerald Matrix',
      'primary': const Color(0xFF10B981),
      'secondary': const Color(0xFFA78BFA),
    },
    {
      'name': 'Solar Amber',
      'primary': const Color(0xFFF59E0B),
      'secondary': const Color(0xFFEF4444),
    },
    {
      'name': 'Rose Velvet',
      'primary': const Color(0xFFF43F5E),
      'secondary': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Cyberpunk Teal',
      'primary': const Color(0xFF14B8A6),
      'secondary': const Color(0xFFE879F9),
    },
    {
      'name': 'Midnight Gold',
      'primary': const Color(0xFFD97706),
      'secondary': const Color(0xFF3B82F6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _primary = widget.initialPrimary;
    _secondary = widget.initialSecondary;
    _syncHsvFromColor(_primary);
  }

  void _syncHsvFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _hexController.text = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  void _updateActiveColor() {
    final newColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    setState(() {
      if (_isEditingPrimary) {
        _primary = newColor;
      } else {
        _secondary = newColor;
      }
      _hexController.text = '#${newColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    });
  }

  void _onHexSubmitted(String hex) {
    String cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      final intVal = int.tryParse('FF$cleanHex', radix: 16);
      if (intVal != null) {
        final newColor = Color(intVal);
        setState(() {
          if (_isEditingPrimary) {
            _primary = newColor;
          } else {
            _secondary = newColor;
          }
          _syncHsvFromColor(newColor);
        });
      }
    }
  }

  Future<void> _applyTheme() async {
    AppState.customPrimaryColorNotifier.value = _primary;
    AppState.customSecondaryColorNotifier.value = _secondary;
    AppState.avatarColorNotifier.value = _primary;

    if (AppState.currentUser != null) {
      final username = AppState.currentUser!;
      final profile = await AppDatabase.instance.loadProfile(username);
      await AppState.saveProfile(profile.copyWith(
        primaryColor: _primary,
        secondaryColor: _secondary,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isEditingPrimary ? _primary : _secondary;

    return AlertDialog(
      backgroundColor: const Color(0xFF151A22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text('Theme Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Selector: Primary vs Secondary
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0E14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditingPrimary = true;
                            _syncHsvFromColor(_primary);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isEditingPrimary ? _primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Primary Tone',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isEditingPrimary ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditingPrimary = false;
                            _syncHsvFromColor(_secondary);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isEditingPrimary ? _secondary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Accent Tone',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !_isEditingPrimary ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Live Preview Strip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primary.withValues(alpha: 0.25),
                      _secondary.withValues(alpha: 0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _primary,
                      radius: 18,
                      child: Icon(Icons.flash_on, color: _secondary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditingPrimary ? 'Primary: ${_hexController.text}' : 'Accent: ${_hexController.text}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          const Text('Live components will reflect these colors.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Graphic Sliders (Hue, Saturation, Lightness)
              const Text('HUE (COLOR SPECTRUM)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: activeColor,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: Colors.white12,
                ),
                child: Slider(
                  value: _hue,
                  min: 0,
                  max: 360,
                  onChanged: (v) {
                    _hue = v;
                    _updateActiveColor();
                  },
                ),
              ),

              const Text('SATURATION (VIBRANCY)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: activeColor,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: Colors.white12,
                ),
                child: Slider(
                  value: _saturation,
                  min: 0,
                  max: 1.0,
                  onChanged: (v) {
                    _saturation = v;
                    _updateActiveColor();
                  },
                ),
              ),

              const Text('BRIGHTNESS (LIGHTNESS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: activeColor,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: Colors.white12,
                ),
                child: Slider(
                  value: _value,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) {
                    _value = v;
                    _updateActiveColor();
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Hex Input
              Row(
                children: [
                  const Text('HEX: ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0E14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _hexController,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onSubmitted: _onHexSubmitted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Curated Palettes
              const Text('CURATED PALETTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPalettes.map((p) {
                  final pri = p['primary'] as Color;
                  final sec = p['secondary'] as Color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _primary = pri;
                        _secondary = sec;
                        _syncHsvFromColor(_isEditingPrimary ? pri : sec);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0E14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: pri, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: sec, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(p['name'] as String, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _applyTheme,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Apply Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
