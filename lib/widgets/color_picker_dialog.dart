import 'package:flutter/material.dart';
import '../services/state.dart';
import '../services/database/app_database.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialPrimary;
  final Color initialSecondary;
  final Color? initialTextColor;

  const ColorPickerDialog({
    super.key,
    required this.initialPrimary,
    required this.initialSecondary,
    this.initialTextColor,
  });

  static Future<void> show(BuildContext context) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => ColorPickerDialog(
        initialPrimary: AppState.customPrimaryColorNotifier.value,
        initialSecondary: AppState.customSecondaryColorNotifier.value,
        initialTextColor: AppState.customTextColorNotifier.value ?? theme.colorScheme.onSurface,
      ),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _primary;
  late Color _secondary;
  late Color _textColor;
  int _editTarget = 0; // 0: Primary, 1: Accent, 2: Text

  late double _hue;
  late double _saturation;
  late double _value;
  final TextEditingController _hexController = TextEditingController();

  final List<Map<String, dynamic>> _quickPalettes = [
    {
      'name': 'Tally Ledger',
      'primary': const Color(0xFFE4572E),
      'secondary': const Color(0xFFF6F0E1),
      'text': const Color(0xFFF6F0E1),
    },
    {
      'name': 'Tally Ink',
      'primary': const Color(0xFFE8A13C),
      'secondary': const Color(0xFFE4572E),
      'text': const Color(0xFFE8A13C),
    },
    {
      'name': 'Tally Paper',
      'primary': const Color(0xFFE4572E),
      'secondary': const Color(0xFF17493B),
      'text': const Color(0xFF17493B),
    },
    {
      'name': 'Violet Neon',
      'primary': const Color(0xFF8B5CF6),
      'secondary': const Color(0xFF10B981),
      'text': Colors.white,
    },
    {
      'name': 'Ocean Cyan',
      'primary': const Color(0xFF3B82F6),
      'secondary': const Color(0xFF06B6D4),
      'text': Colors.white,
    },
    {
      'name': 'Emerald Matrix',
      'primary': const Color(0xFF10B981),
      'secondary': const Color(0xFFA78BFA),
      'text': Colors.white,
    },
    {
      'name': 'Solar Amber',
      'primary': const Color(0xFFF59E0B),
      'secondary': const Color(0xFFEF4444),
      'text': Colors.white,
    },
    {
      'name': 'Rose Velvet',
      'primary': const Color(0xFFF43F5E),
      'secondary': const Color(0xFF8B5CF6),
      'text': Colors.white,
    },
    {
      'name': 'Cyberpunk Teal',
      'primary': const Color(0xFF14B8A6),
      'secondary': const Color(0xFFE879F9),
      'text': Colors.white,
    },
    {
      'name': 'Midnight Gold',
      'primary': const Color(0xFFD97706),
      'secondary': const Color(0xFF3B82F6),
      'text': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    _primary = widget.initialPrimary;
    _secondary = widget.initialSecondary;
    _textColor = widget.initialTextColor ?? const Color(0xFFF6F0E1);
    _syncHsvFromColor(_primary);
  }

  Color get _activeColor {
    if (_editTarget == 0) return _primary;
    if (_editTarget == 1) return _secondary;
    return _textColor;
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
      if (_editTarget == 0) {
        _primary = newColor;
      } else if (_editTarget == 1) {
        _secondary = newColor;
      } else {
        _textColor = newColor;
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
          if (_editTarget == 0) {
            _primary = newColor;
          } else if (_editTarget == 1) {
            _secondary = newColor;
          } else {
            _textColor = newColor;
          }
          _syncHsvFromColor(newColor);
        });
      }
    }
  }

  Future<void> _applyTheme() async {
    AppState.customPrimaryColorNotifier.value = _primary;
    AppState.customSecondaryColorNotifier.value = _secondary;
    AppState.customTextColorNotifier.value = _textColor;
    AppState.avatarColorNotifier.value = _primary;

    if (AppState.currentUser != null) {
      final username = AppState.currentUser!;
      final profile = await AppDatabase.instance.loadProfile(username);
      await AppState.saveProfile(profile.copyWith(
        primaryColor: _primary,
        secondaryColor: _secondary,
        textColor: _textColor,
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final activeColor = _activeColor;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: onSurface.withValues(alpha: 0.1)),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: onSurface),
              const SizedBox(width: 8),
              Text(
                'Theme Studio',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: onSurface,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, color: onSurface.withValues(alpha: 0.54), size: 20),
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
              // Target Selector: Primary vs Accent vs Text
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _tabButton(0, 'Primary', _primary),
                    _tabButton(1, 'Accent', _secondary),
                    _tabButton(2, 'Text Tone', _textColor),
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
                child: Column(
                  children: [
                    Row(
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
                                _editTarget == 0
                                    ? 'Primary: ${_hexController.text}'
                                    : (_editTarget == 1
                                        ? 'Accent: ${_hexController.text}'
                                        : 'Text Color: ${_hexController.text}'),
                                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Live components reflect these colors.',
                                style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sample Text Preview: Tally Personal Finance',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Graphic Sliders (Hue, Saturation, Lightness)
              Text(
                'HUE (COLOR SPECTRUM)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withValues(alpha: 0.54),
                  letterSpacing: 1,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: activeColor,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: onSurface.withValues(alpha: 0.12),
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

              Text(
                'SATURATION (VIBRANCY)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withValues(alpha: 0.54),
                  letterSpacing: 1,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: activeColor,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: onSurface.withValues(alpha: 0.12),
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

              Text(
                'BRIGHTNESS (LIGHTNESS)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withValues(alpha: 0.54),
                  letterSpacing: 1,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: activeColor,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: onSurface.withValues(alpha: 0.12),
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
                  Text(
                    'HEX: ',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _hexController,
                        style: TextStyle(color: onSurface, fontSize: 13, fontFamily: 'monospace'),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onSubmitted: _onHexSubmitted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Curated Palettes
              Text(
                'CURATED PALETTES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withValues(alpha: 0.54),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPalettes.map((p) {
                  final pri = p['primary'] as Color;
                  final sec = p['secondary'] as Color;
                  final txt = p['text'] as Color? ?? Colors.white;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _primary = pri;
                        _secondary = sec;
                        _textColor = txt;
                        if (_editTarget == 0) {
                          _syncHsvFromColor(pri);
                        } else if (_editTarget == 1) {
                          _syncHsvFromColor(sec);
                        } else {
                          _syncHsvFromColor(txt);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: pri, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: sec, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: txt, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(p['name'] as String, style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 11)),
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
          child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.54))),
        ),
        ElevatedButton(
          onPressed: _applyTheme,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Apply Theme',
            style: TextStyle(
              color: _primary.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, Color color) {
    final isSelected = _editTarget == index;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _editTarget = index;
            _syncHsvFromColor(_activeColor);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected
                  ? (color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                  : onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
