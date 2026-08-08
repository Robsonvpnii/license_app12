import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

void main() {
  runApp(const LicenseActivatorApp());
}

class LicenseActivatorApp extends StatelessWidget {
  const LicenseActivatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'License Activator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blue,
        focusColor: Colors.blueAccent,
      ),
      home: const LicenseChecker(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LicenseChecker extends StatefulWidget {
  const LicenseChecker({super.key});

  @override
  State<LicenseChecker> createState() => _LicenseCheckerState();
}

class _LicenseCheckerState extends State<LicenseChecker> {
  bool _isLoading = true;
  bool _hasConfig = false;

  @override
  void initState() {
    super.initState();
    _checkConfigFile();
  }

  Future<void> _checkConfigFile() async {
    setState(() => _isLoading = true);
    
    try {
      final configPath = '/storage/emulated/0/Android/.config';
      final file = File(configPath);
      
      if (await file.exists()) {
        _hasConfig = true;
      } else {
        _hasConfig = false;
      }
    } catch (e) {
      _hasConfig = false;
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      );
    }

    return _hasConfig ? const DashboardScreen() : const LicenseScreen();
  }
}

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final TextEditingController _licenseController = TextEditingController();
  final FocusNode _licenseFocus = FocusNode();
  final FocusNode _activateFocus = FocusNode();
  bool _isLoading = false;
  String _message = '';
  Color _messageColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    _licenseFocus.addListener(() {
      setState(() {});
    });
    _activateFocus.addListener(() {
      setState(() {});
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _licenseFocus.dispose();
    _activateFocus.dispose();
    super.dispose();
  }

  Future<void> _activateLicense() async {
    final license = _licenseController.text.trim();
    
    if (license.isEmpty) {
      setState(() {
        _message = 'Por favor, insira uma licenÃ§a vÃ¡lida';
        _messageColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://fluffernutter-joy-factory.lovable.app/endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'license': license}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' || data['valid'] == true) {
          await _saveConfigFile();
          setState(() {
            _message = 'âœ… LicenÃ§a ativada com sucesso!';
            _messageColor = Colors.green;
          });
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          setState(() {
            _message = 'âŒ LicenÃ§a invÃ¡lida. Tente novamente.';
            _messageColor = Colors.red;
          });
        }
      } else {
        setState(() {
          _message = 'âŒ Erro no servidor. Tente novamente.';
          _messageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'âŒ Erro de conexÃ£o. Verifique sua internet.';
        _messageColor = Colors.red;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfigFile() async {
    try {
      final configPath = '/storage/emulated/0/Android/.config';
      final file = File(configPath);
      
      final licenseData = {
        'license': _licenseController.text.trim(),
        'activated_at': DateTime.now().toIso8601String(),
        'status': 'active'
      };
      
      await file.writeAsString(jsonEncode(licenseData));
    } catch (e) {
      setState(() {
        _message = 'âŒ Erro ao salvar arquivo de configuraÃ§Ã£o';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 120,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Ativador de LicenÃ§a',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Insira sua chave de ativaÃ§Ã£o',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Focus(
                      onKey: (node, event) {
                        if (event is RawKeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.select ||
                              event.logicalKey == LogicalKeyboardKey.enter) {
                            if (_licenseFocus.hasFocus) {
                              _activateLicense();
                            }
                          }
                        }
                        return KeyEventResult.handled;
                      },
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _licenseFocus.hasFocus
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: _licenseController,
                              focusNode: _licenseFocus,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Digite sua licenÃ§a...',
                                hintStyle: TextStyle(
                                  fontSize: 24,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                prefixIcon: Icon(
                                  Icons.vpn_key_rounded,
                                  color: Colors.blueAccent,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: Focus(
                              onKey: (node, event) {
                                if (event is RawKeyDownEvent) {
                                  if (event.logicalKey == LogicalKeyboardKey.select ||
                                      event.logicalKey == LogicalKeyboardKey.enter) {
                                    _activateLicense();
                                  }
                                }
                                return KeyEventResult.handled;
                              },
                              child: ElevatedButton(
                                focusNode: _activateFocus,
                                onPressed: _isLoading ? null : _activateLicense,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  minimumSize: const Size(double.infinity, 80),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 32,
                                        width: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('ATIVAR'),
                              ),
                            ),
                          ),
                          if (_message.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _message,
                                style: TextStyle(
                                  fontSize: 22,
                                  color: _messageColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FocusNode _deleteFocus = FocusNode();
  final FocusNode _exitFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _deleteFocus.addListener(() => setState(() {}));
    _exitFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _deleteFocus.dispose();
    _exitFocus.dispose();
    super.dispose();
  }

  Future<void> _deleteConfig() async {
    try {
      final configPath = '/storage/emulated/0/Android/.config';
      final file = File(configPath);
      
      if (await file.exists()) {
        await file.delete();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LicenseChecker()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir arquivo de configuraÃ§Ã£o'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dashboard_rounded,
                    size: 120,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Painel de Controle',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sistema ativado com sucesso',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        Focus(
                          onKey: (node, event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.select ||
                                  event.logicalKey == LogicalKeyboardKey.enter) {
                                _deleteConfig();
                              }
                            }
                            return KeyEventResult.handled;
                          },
                          child: ElevatedButton(
                            focusNode: _deleteFocus,
                            onPressed: _deleteConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              minimumSize: const Size(double.infinity, 80),
                            ),
                            child: const Text('APAGAR CONFIG'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Focus(
                          onKey: (node, event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.select ||
                                  event.logicalKey == LogicalKeyboardKey.enter) {
                                SystemNavigator.pop();
                              }
                            }
                            return KeyEventResult.handled;
                          },
                          child: ElevatedButton(
                            focusNode: _exitFocus,
                            onPressed: () {
                              SystemNavigator.pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              minimumSize: const Size(double.infinity, 80),
                            ),
                            child: const Text('SAIR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
