import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsScreen extends StatefulWidget {
  static String id = "Settings_Screen";
  const SettingsScreen({super.key});
  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late Color pickerColor;
  double fontSize = 12;
  @override
  void initState() {
    _loadColorPreference().then((colorValue) {
      setState(() {
        pickerColor = colorValue ?? AppTheme.grey;
      });
    });
    _loadSizePreference().then((size) {
      setState(() {
        fontSize = size;
      });
    });
    super.initState();
  }

  Future<void> _saveColorPreference(Color color) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', color.value);
    Provider.of<ThemeProvider>(context, listen: false)
        .updatePrimaryColor(color);
  }

  Future<void> _saveSizePreference(double size) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
    Provider.of<ThemeProvider>(context, listen: false).updateFontSize(size);
  }

  Future<Color?> _loadColorPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('theme_color');
    return colorValue != null ? Color(colorValue) : null;
  }

  Future<double> _loadSizePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? size = prefs.getDouble('font_size');
    return size ?? 16;
  }

  Future<void> _resetSettings() async {
    setState(() {
      fontSize = 16;
      pickerColor = AppTheme.grey;
    });

    await _saveColorPreference(pickerColor);
    await _saveSizePreference(fontSize);
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
    _saveColorPreference(color);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: null,
        title: const Text('Settings'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select a color'),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: pickerColor,
                          onColorChanged: changeColor,
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Done'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: ListTile(
                title: Text(
                  'Theme Color',
                  style: themeProvider.title.copyWith(color: Colors.black),
                ),
                trailing: CircleAvatar(
                  backgroundColor: pickerColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Font Size',
                    style: themeProvider.title.copyWith(color: Colors.black),
                  ),
                  SizedBox(
                    width: 150,
                    child: Slider(
                        value: fontSize,
                        onChanged: (newSize) {
                          _saveSizePreference(newSize);
                          setState(() => fontSize = newSize);
                        },
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: "Font Size: $fontSize"),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: ElevatedButton(
              onPressed: _resetSettings,
              child: Text(
                'Reset Settings',
                style: themeProvider.title.copyWith(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
