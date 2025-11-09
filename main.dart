import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const SeguroApp());
}

// ============= SINGLETON =============
class InsuranceManager {
  static final InsuranceManager _instance = InsuranceManager._internal();
  factory InsuranceManager() => _instance;
  InsuranceManager._internal();

  List<InsurancePolicy> policies = [];
  Map<String, dynamic> userProfile = {};

  void addPolicy(InsurancePolicy policy) => policies.add(policy);
  void removePolicy(String id) => policies.removeWhere((p) => p.id == id);
  bool get hasAcceptedTerms => userProfile['acceptedTerms'] == true;
  void acceptTerms() => userProfile['acceptedTerms'] = true;
}

// ============= MODELOS =============
class InsurancePolicy {
  final String id;
  final String insurer;
  final String category;
  final String type;
  final int premium;
  final int coverage;
  final int deductible;
  final String description;
  final bool isParametric;
  final int populalityScore;

  InsurancePolicy({
    required this.id,
    required this.insurer,
    required this.category,
    required this.type,
    required this.premium,
    required this.coverage,
    required this.deductible,
    required this.description,
    required this.isParametric,
    this.populalityScore = 80,
  });
}

class PortfolioData {
  final double totalCoverage;
  final double monthlyCost;
  final Map<String, double> coverageByCategory;
  final Map<String, double> riskDistribution;

  PortfolioData({
    required this.totalCoverage,
    required this.monthlyCost,
    required this.coverageByCategory,
    required this.riskDistribution,
  });
}

// ============= TRANSICIONES =============
class SlideTransitionPage extends PageRouteBuilder {
  final Widget child;

  SlideTransitionPage({required this.child})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

class FadeTransitionPage extends PageRouteBuilder {
  final Widget child;

  FadeTransitionPage({required this.child})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

// ============= APP PRINCIPAL =============
class SeguroApp extends StatefulWidget {
  const SeguroApp({super.key});

  @override
  State<SeguroApp> createState() => _SeguroAppState();
}

class _SeguroAppState extends State<SeguroApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiskQuantum Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: InitialScreen(onToggleTheme: _toggleTheme),
    );
  }
}

// ============= PANTALLA INICIAL =============
class InitialScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const InitialScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    if (InsuranceManager().hasAcceptedTerms && InsuranceManager().userProfile.isNotEmpty) {
      return HomeScreen(onToggleTheme: onToggleTheme);
    }
    return OnboardingSurvey(onToggleTheme: onToggleTheme);
  }
}

// ============= ONBOARDING CENTRADO =============
class OnboardingSurvey extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const OnboardingSurvey({super.key, required this.onToggleTheme});

  @override
  State<OnboardingSurvey> createState() => _OnboardingSurveyState();
}

class _OnboardingSurveyState extends State<OnboardingSurvey> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _disasterExperience = '';
  String _location = '';
  final List<String> _selectedInsuranceTypes = [];
  String _incomeRange = '';

  final Map<String, Map<String, dynamic>> _riskMap = {
    'jalisco': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'guadalajara': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'guerrero': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'oaxaca': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'veracruz': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'tabasco': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'chiapas': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'tamaulipas': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'yucatan': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'quintana roo': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'ciudad de mexico': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'cdmx': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'monterrey': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'puebla': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'morelos': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'baja california': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'sonora': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'chihuahua': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'coahuila': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'nuevo leon': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
  };

  void _nextPage() {
    if (_currentPage == 3) {
      _saveProfile();
      Navigator.pushReplacement(
        context,
        FadeTransitionPage(child: TermsAndConditionsScreen(onToggleTheme: widget.onToggleTheme)),
      );
      return;
    }

    if (_currentPage < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _saveProfile() {
    final profileData = {
      'experience': _disasterExperience,
      'location': _location,
      'types': List<String>.from(_selectedInsuranceTypes),
      'income': _incomeRange,
    };

    InsuranceManager().userProfile = profileData;
  }

  Widget _buildGlassCard({required Widget child, int index = 0}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'RiskQuantum Pro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Protección inteligente para tu futuro',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  bool isCurrent = _currentPage == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF3B82F6)
                          : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildGlassCard(
                      index: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildQuestionTitle('¿Has vivido un desastre natural?'),
                            const SizedBox(height: 24),
                            ...[
                              {'value': 'prevent', 'text': 'Nunca, pero quiero prevenirme'},
                              {'value': 'affected', 'text': 'Sí, y perdí mi hogar/negocio'},
                              {'value': 'minor', 'text': 'Sí, pero solo daños menores'},
                            ].map((option) => _buildSelectableOption(
                              context: context,
                              text: option['text']!,
                              isSelected: _disasterExperience == option['value'],
                              onTap: () => setState(() => _disasterExperience = option['value']!),
                            )).toList(),
                          ],
                        ),
                      ),
                    ),
                    _buildGlassCard(
                      index: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildQuestionTitle('¿Dónde vives?'),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                onChanged: (value) => setState(() => _location = value.toLowerCase()),
                                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  hintText: 'Ej: Jalisco, CDMX, Veracruz...',
                                  hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                                  filled: true,
                                  fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[400]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_location.isNotEmpty && _riskMap.containsKey(_location))
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _riskMap[_location]!['color']!.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _riskMap[_location]!['color']!.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_riskMap[_location]!['icon']!, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Riesgo detectado: ${_riskMap[_location]!['level']}',
                                      style: TextStyle(
                                        color: _riskMap[_location]!['color'],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _buildGlassCard(
                      index: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildQuestionTitle('¿Qué quieres asegurar?'),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: ['Casa', 'Coche', 'Vida', 'Salud', 'Negocio', 'Agrícola'].map((type) =>
                                  FilterChip(
                                    label: Text(
                                      type,
                                      style: TextStyle(
                                        color: _selectedInsuranceTypes.contains(type)
                                            ? Colors.white
                                            : (isDark ? Colors.grey[300]! : Colors.grey[700]!),
                                        fontSize: 14,
                                        fontWeight: _selectedInsuranceTypes.contains(type)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    selected: _selectedInsuranceTypes.contains(type),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedInsuranceTypes.add(type);
                                        } else {
                                          _selectedInsuranceTypes.remove(type);
                                        }
                                      });
                                    },
                                    backgroundColor: isDark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.grey[100],
                                    selectedColor: const Color(0xFF3B82F6),
                                    checkmarkColor: Colors.white,
                                    showCheckmark: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                      ),
                                    ),
                                  )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildGlassCard(
                      index: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildQuestionTitle('¿Cuál es tu rango de ingresos?'),
                            const SizedBox(height: 24),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        {'value': '<10k', 'text': '< \$10k'},
                                        {'value': '10k-25k', 'text': '\$10k - \$25k'},
                                        {'value': '25k-50k', 'text': '\$25k - \$50k'},
                                        {'value': '50k-100k', 'text': '\$50k - \$100k'},
                                        {'value': '>100k', 'text': '> \$100k'},
                                      ].map((option) => _buildSelectableOption(
                                        context: context,
                                        text: option['text']!,
                                        isSelected: _incomeRange == option['value'],
                                        onTap: () => setState(() => _incomeRange = option['value']!),
                                      )).toList(),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Esta información ayuda a personalizar recomendaciones',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(_currentPage == 3 ? 'CONTINUAR' : 'SIGUIENTE'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );
  }

  Widget _buildSelectableOption({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.15)
              : (isDark ? Colors.black.withOpacity(0.2) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 18),
          ],
        ),
      ),
    );
  }
}

// ============= TÉRMINOS Y CONDICIONES =============
class TermsAndConditionsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const TermsAndConditionsScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        '1. Aceptación de Términos',
                        'Al utilizar RiskQuantum Pro, aceptas estos términos y condiciones en su totalidad.',
                      ),
                      const SizedBox(height: 20),
                      _buildTermsSection(
                        '2. Servicios Ofrecidos',
                        'RiskQuantum Pro proporciona un marketplace de seguros paramétricos para protección contra desastres naturales.',
                      ),
                      const SizedBox(height: 20),
                      _buildTermsSection(
                        '3. Proceso de Contratación',
                        'La contratación se realiza mediante blockchain con pago en USDC. Activación inmediata.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF3B82F6),
                  ),
                  Expanded(
                    child: Text(
                      'He leído y acepto los términos y condiciones',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecked
                      ? () {
                    InsuranceManager().acceptTerms();
                    Navigator.pushReplacement(
                      context,
                      FadeTransitionPage(child: HomeScreen(onToggleTheme: widget.onToggleTheme)),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    disabledForegroundColor: Colors.white,
                  ),
                  child: const Text(
                    'ACEPTAR Y CONTINUAR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

// ============= HOME SCREEN =============
class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _riskLevel = 'Ingresa tu ubicación';
  String _riskIcon = '📍';
  String _userLocation = '';
  final TextEditingController _locationController = TextEditingController();
  List<InsurancePolicy> _policies = [];
  List<InsurancePolicy> _filteredPolicies = [];
  String _sortBy = 'popularidad';
  List<String> _selectedCategories = [];

  final Map<String, Map<String, dynamic>> _riskMap = {
    'jalisco': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'guadalajara': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'guerrero': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'oaxaca': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'veracruz': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'tabasco': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'chiapas': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'tamaulipas': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'yucatan': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'quintana roo': {'level': 'Riesgo Alto', 'icon': '⚡', 'color': Colors.redAccent},
    'ciudad de mexico': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'cdmx': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'monterrey': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'puebla': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'morelos': {'level': 'Riesgo Medio', 'icon': '⚠️', 'color': Colors.orangeAccent},
    'baja california': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'sonora': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'chihuahua': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'coahuila': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
    'nuevo leon': {'level': 'Riesgo Bajo', 'icon': '✓', 'color': Colors.greenAccent},
  };

  @override
  void initState() {
    super.initState();
    _userLocation = InsuranceManager().userProfile['location'] ?? '';
    _selectedCategories = List<String>.from(InsuranceManager().userProfile['types'] ?? []);
    _locationController.text = _userLocation;

    if (_userLocation.isNotEmpty) {
      final risk = _riskMap[_userLocation] ?? {'level': 'Riesgo NO Mapeado', 'icon': '❓', 'color': Colors.grey};
      _riskLevel = risk['level']!;
      _riskIcon = risk['icon']!;
    }

    _loadPolicies();
  }

  void _updateLocation() {
    setState(() => _isLoading = true);
    final location = _locationController.text.toLowerCase().trim();

    setState(() {
      _userLocation = location;
      final risk = _riskMap[location] ?? {'level': 'Riesgo NO Mapeado', 'icon': '❓', 'color': Colors.grey};
      _riskLevel = risk['level']!;
      _riskIcon = risk['icon']!;
      _isLoading = false;
    });

    InsuranceManager().userProfile['location'] = location;
  }

  void _loadPolicies() {
    final allPolicies = [
      InsurancePolicy(id: 'MX_CASA_HUR', insurer: 'GNP Seguros', category: 'Casa', type: 'Huracán', premium: 3, coverage: 250, deductible: 0, description: 'Activación automática por viento >80km/h', isParametric: true, populalityScore: 95),
      InsurancePolicy(id: 'MX_CASA_INU', insurer: 'AXA México', category: 'Casa', type: 'Inundación', premium: 4, coverage: 300, deductible: 0, description: 'Pago inmediato por lluvia >150mm/24h', isParametric: true, populalityScore: 88),
      InsurancePolicy(id: 'MX_COCHE_GRA', insurer: 'Qualitas', category: 'Coche', type: 'Granizo', premium: 2, coverage: 150, deductible: 0, description: 'Cobertura por granizo >2cm de diámetro', isParametric: true, populalityScore: 85),
      InsurancePolicy(id: 'MX_COCHE_COL', insurer: 'Mapfre', category: 'Coche', type: 'Colisión', premium: 5, coverage: 500, deductible: 100, description: 'Cobertura tradicional para accidentes', isParametric: false, populalityScore: 90),
      InsurancePolicy(id: 'MX_VIDA_ACC', insurer: 'MetLife', category: 'Vida', type: 'Accidental', premium: 3, coverage: 1000, deductible: 0, description: 'Protección por desastre natural', isParametric: true, populalityScore: 94),
      InsurancePolicy(id: 'MX_SALUD_URG', insurer: 'SURA', category: 'Salud', type: 'Urgencias', premium: 4, coverage: 300, deductible: 0, description: 'Atención médica inmediata en desastres', isParametric: true, populalityScore: 87),
      InsurancePolicy(id: 'MX_NEG_INT', insurer: 'AIG', category: 'Negocio', type: 'Interrupción', premium: 8, coverage: 800, deductible: 0, description: 'Compensación por pérdida de ingresos', isParametric: true, populalityScore: 73),
      InsurancePolicy(id: 'MX_AGR_SEQ', insurer: 'Agroasemex', category: 'Agrícola', type: 'Sequía', premium: 2, coverage: 200, deductible: 0, description: 'Activación por déficit de lluvia >30 días', isParametric: true, populalityScore: 68),
    ];

    setState(() {
      _policies = allPolicies;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      List<InsurancePolicy> tempPolicies = _selectedCategories.isEmpty
          ? List.from(_policies)
          : _policies.where((p) => _selectedCategories.contains(p.category)).toList();

      if (_sortBy == 'precio_menor') {
        tempPolicies.sort((a, b) => a.premium.compareTo(b.premium));
      } else if (_sortBy == 'precio_mayor') {
        tempPolicies.sort((a, b) => b.premium.compareTo(a.premium));
      } else {
        tempPolicies.sort((a, b) => b.populalityScore.compareTo(a.populalityScore));
      }

      _filteredPolicies = tempPolicies;
    });
  }

  void _buyPolicy(InsurancePolicy policy) {
    final manager = InsuranceManager();
    final bool isAlreadyPurchased = manager.policies.any((p) => p.id == policy.id);

    if (isAlreadyPurchased) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Póliza Ya Comprada'),
          content: Text(
            'Ya tienes la póliza "${policy.category} - ${policy.type}" de ${policy.insurer} activa.',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: Color(0xFF3B82F6))),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 40,
                height: 4,
                child: Divider(thickness: 4, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield, color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar Compra',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      Text(
                        policy.category,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPolicyDetailRow('Aseguradora', policy.insurer),
            _buildPolicyDetailRow('Tipo', policy.type),
            _buildPolicyDetailRow('Prima Mensual', '\$${policy.premium} USDC'),
            _buildPolicyDetailRow('Cobertura', '\$${policy.coverage}'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Cerrar el bottom sheet primero
                Navigator.pop(bottomSheetContext);

                // Agregar la póliza
                InsuranceManager().addPolicy(policy);

                // Mostrar diálogo de redireccionamiento
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => const RedirectingDialog(),
                );

                await Future.delayed(const Duration(seconds: 2));

                // Cerrar diálogo de redireccionamiento
                Navigator.pop(context);

                // Mostrar diálogo de éxito
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (successContext) => const SuccessDialog(message: 'Póliza contratada exitosamente'),
                );
              },
              icon: const Icon(Icons.security),
              label: const Text('Comprar Póliza'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(bool isDark, IconData icon, String label, String sortKey) {
    final isSelected = _sortBy == sortKey;
    return InkWell(
      onTap: () {
        setState(() => _sortBy = sortKey);
        _applyFilters();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(InsurancePolicy policy, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          policy.insurer,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${policy.category} • ${policy.type}',
                          style: TextStyle(
                            color: const Color(0xFF3B82F6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: policy.isParametric ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        policy.isParametric ? 'PARAMÉTRICO' : 'TRADICIONAL',
                        style: TextStyle(
                          color: policy.isParametric ? const Color(0xFF10B981) : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  policy.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${policy.premium}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        Text(
                          'por mes',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _buyPolicy(policy),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Contratar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RiskQuantum Pro',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Cambiar tema',
            onPressed: widget.onToggleTheme,
            color: isDark ? Colors.yellow : const Color(0xFF3B82F6),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Mis Pólizas Activas',
            onPressed: () => Navigator.push(context, SlideTransitionPage(child: const MisPolizasScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard',
            onPressed: () => Navigator.push(context, FadeTransitionPage(child: const DashboardScreen())),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Casa', 'Coche', 'Vida', 'Salud', 'Negocio', 'Agrícola'].map((cat) => FilterChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      selected: _selectedCategories.contains(cat),
                      onSelected: (selected) {
                        setState(() {
                          selected ? _selectedCategories.add(cat) : _selectedCategories.remove(cat);
                        });
                        _applyFilters();
                      },
                      backgroundColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
                      selectedColor: const Color(0xFF3B82F6),
                      checkmarkColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSortButton(isDark, Icons.trending_up, 'Popularidad', 'popularidad'),
                      _buildSortButton(isDark, Icons.arrow_downward, 'Precio ↓', 'precio_menor'),
                      _buildSortButton(isDark, Icons.arrow_upward, 'Precio ↑', 'precio_mayor'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'UBICACIÓN DE RIESGO',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Ej: CDMX, Jalisco, Veracruz...',
                            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
                            filled: true,
                            fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _updateLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('ACTUALIZAR'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_userLocation.isNotEmpty && _riskMap.containsKey(_userLocation))
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideTransitionPage(child: RiskDetailScreen(location: _userLocation)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _riskMap[_userLocation]!['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _riskMap[_userLocation]!['color'].withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Text(_riskMap[_userLocation]!['icon']!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _riskLevel.toUpperCase(),
                                    style: TextStyle(
                                      color: _riskMap[_userLocation]!['color'],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ver análisis detallado →',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredPolicies.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay pólizas con estos filtros',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories.clear();
                          _applyFilters();
                        });
                      },
                      child: const Text('Restablecer filtros'),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredPolicies.length,
                itemBuilder: (context, index) => _buildPolicyCard(_filteredPolicies[index], index),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, SlideTransitionPage(child: const ChatbotScreen())),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.support_agent),
        label: const Text('Asistente'),
      ),
    );
  }
}

// ============= DASHBOARD =============
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  PortfolioData _calculatePortfolioData() {
    final policies = InsuranceManager().policies;
    double totalCoverage = 0;
    double monthlyCost = 0;
    Map<String, double> coverageByCategory = {};
    Map<String, double> riskDistribution = {'ALTO': 0, 'MEDIO': 0, 'BAJO': 0};

    for (var policy in policies) {
      totalCoverage += policy.coverage;
      monthlyCost += policy.premium;
      coverageByCategory[policy.category] = (coverageByCategory[policy.category] ?? 0) + policy.coverage;
    }

    if (policies.isNotEmpty) {
      final location = InsuranceManager().userProfile['location'] ?? '';
      final riskLevel = _getRiskLevelForLocation(location);
      riskDistribution[riskLevel] = totalCoverage;
    }

    return PortfolioData(
      totalCoverage: totalCoverage,
      monthlyCost: monthlyCost,
      coverageByCategory: coverageByCategory,
      riskDistribution: riskDistribution,
    );
  }

  String _getRiskLevelForLocation(String location) {
    final highRisk = ['jalisco', 'veracruz', 'guerrero', 'oaxaca'];
    final mediumRisk = ['cdmx', 'monterrey', 'puebla'];
    if (highRisk.contains(location)) return 'ALTO';
    if (mediumRisk.contains(location)) return 'MEDIO';
    return 'BAJO';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _calculatePortfolioData();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio Analytics')),
      body: data.coverageByCategory.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text('No tienes pólizas activas', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add),
              label: const Text('Explorar pólizas'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildKpiCard(
                  icon: Icons.shield,
                  label: 'Cobertura Total',
                  value: currencyFormat.format(data.totalCoverage),
                  color: const Color(0xFF3B82F6),
                  delay: 0,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  icon: Icons.payments,
                  label: 'Costo Mensual',
                  value: currencyFormat.format(data.monthlyCost),
                  color: const Color(0xFF8B5CF6),
                  delay: 100,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildChartSection(
              title: 'Cobertura por Categoría',
              child: Container(
                height: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(data.coverageByCategory, isDark),
                    centerSpaceRadius: 60,
                    sectionsSpace: 3,
                  ),
                ),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildPieLegend(data.coverageByCategory, isDark),
            const SizedBox(height: 32),
            _buildChartSection(
              title: 'Distribución por Nivel de Riesgo',
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: data.riskDistribution.values.reduce((a, b) => a > b ? a : b) + 50,
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const titles = ['ALTO', 'MEDIO', 'BAJO'];
                            return Text(
                              titles[value.toInt()],
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: _buildBarGroups(data.riskDistribution),
                  ),
                ),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildRiskSummary(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection({required String title, required Widget child, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500 + delay),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSummary(bool isDark) {
    final location = InsuranceManager().userProfile['location'] ?? '';
    final riskLevel = _getRiskLevelForLocation(location);
    final riskColor = riskLevel == 'ALTO' ? Colors.redAccent : (riskLevel == 'MEDIO' ? Colors.orangeAccent : Colors.greenAccent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANÁLISIS DE RIESGO',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  riskLevel == 'ALTO' ? Icons.warning : (riskLevel == 'MEDIO' ? Icons.info : Icons.check_circle),
                  color: riskColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel de Riesgo: $riskLevel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: riskColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Basado en tu ubicación en ${location.toUpperCase()}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegend(Map<String, double> data, bool isDark) {
    final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.red, Colors.teal];
    int i = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leyenda de Cobertura',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: data.entries.map((entry) {
              final color = colors[i++ % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 8),
                  Text(entry.key, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data, bool isDark) {
    final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.red, Colors.teal];
    int i = 0;

    return data.entries.map((entry) {
      final value = entry.value;
      final percentage = (value / data.values.reduce((a, b) => a + b) * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: colors[i++ % colors.length],
        value: value,
        title: '$percentage%',
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, double> distribution) {
    final colors = {'ALTO': Colors.red, 'MEDIO': Colors.orange, 'BAJO': Colors.green};
    final entries = distribution.entries.toList();

    return List.generate(entries.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entries[index].value,
            color: colors[entries[index].key],
            width: 40,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }
}

// ============= RISK DETAIL CON HISTORIA Y PREVENCION =============
class RiskDetailScreen extends StatelessWidget {
  final String location;

  const RiskDetailScreen({super.key, required this.location});

  Map<String, dynamic> _getRiskDetails(String loc) {
    final riskDetails = {
      'jalisco': {
        'level': 'Riesgo Alto',
        'icon': '⚡',
        'color': Colors.redAccent,
        'history': 'Histórico de Huracanes: Patricia (2015), Willa (2018)',
        'prevention': 'Prevención: Refuerza techos, instala protecciones en ventanas, mantén suministros de emergencia',
      },
      'guadalajara': {
        'level': 'Riesgo Alto',
        'icon': '⚡',
        'color': Colors.redAccent,
        'history': 'Histórico: Inundaciones recurrentes, granizo severo',
        'prevention': 'Prevención: Sistema de drenaje, techos reforzados, seguro paramétrico',
      },
      'veracruz': {
        'level': 'Riesgo Alto',
        'icon': '⚡',
        'color': Colors.redAccent,
        'history': 'Histórico: Huracanes Karl (2010), Ingrid (2013)',
        'prevention': 'Prevención: Evita zonas bajas, prepara mochila de emergencia, contrata seguros paramétricos',
      },
      'cdmx': {
        'level': 'Riesgo Medio',
        'icon': '⚠️',
        'color': Colors.orangeAccent,
        'history': 'Histórico: Sismo 1985, 2017, inundaciones ocasionales',
        'prevention': 'Prevención: Refuerza estructura, plan de evacuación, seguro de sismo',
      },
      'monterrey': {
        'level': 'Riesgo Medio',
        'icon': '⚠️',
        'color': Colors.orangeAccent,
        'history': 'Histórico: Sequías severas, granizo ocasional',
        'prevention': 'Prevención: Sistemas de captación de agua, protección contra granizo',
      },
    };

    return riskDetails[loc] ?? {
      'level': 'Riesgo NO Mapeado',
      'icon': '❓',
      'color': Colors.grey,
      'history': 'No hay datos históricos disponibles',
      'prevention': 'Consulta con autoridades locales',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final details = _getRiskDetails(location);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Riesgo')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(details['icon'] as String, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 20),
                Text(details['level'] as String, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: details['color'] as Color?)),
                const SizedBox(height: 10),
                Text('Ubicación: ${location.toUpperCase()}', style: TextStyle(fontSize: 20, color: isDark ? Colors.white70 : Colors.grey[700])),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 HISTÓRICO DE DESASTRES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      Text(details['history'] as String, style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🛡️ RECOMENDACIONES DE PREVENCIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      Text(details['prevention'] as String, style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============= CHATBOT =============
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _controller.clear();
      _isLoading = true;
    });

    // Scroll to bottom after adding user message
    _scrollToBottom();

    try {
      final request = await HttpClient().postUrl(Uri.parse('http://127.0.0.1:11434/api/chat'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode({
        'model': 'phi3:mini',
        'messages': [
          for (final msg in _messages)
            {'role': msg['role'], 'content': msg['content']}
        ],
        'stream': true
      })));

      final response = await request.close();

      String assistantMessage = '';
      setState(() {
        _messages.add({'role': 'assistant', 'content': ''});
      });

      await for (final line in response.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          final chunk = data['message']?['content'];
          if (chunk != null) {
            assistantMessage += chunk;
            setState(() {
              _messages[_messages.length - 1]['content'] = assistantMessage;
            });
            _scrollToBottom();
          }
        } catch (e) {
          // Ignora líneas que no sean JSON válidos
        }
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Error de conexión con Ollama: $e'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Virtual (Ollama)'),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.smart_toy,
                      size: 80,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Asistente Local con Ollama',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Conectado a phi3:mini',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF3B82F6)
                            : (isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: isUser
                            ? null
                            : Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['content']!,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.grey[400]! : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pensando...',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                      tooltip: 'Enviar mensaje',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= MIS PÓLIZAS =============
class MisPolizasScreen extends StatefulWidget {
  const MisPolizasScreen({super.key});

  @override
  State<MisPolizasScreen> createState() => _MisPolizasScreenState();
}

class _MisPolizasScreenState extends State<MisPolizasScreen> {
  void _cancelPolicy(InsurancePolicy policy) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Cancelando póliza...'),
    );

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    setState(() {
      InsuranceManager().removePolicy(policy.id);
    });

    showDialog(
      context: context,
      builder: (context) => SuccessDialog(message: 'Póliza de ${policy.insurer} cancelada exitosamente'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final policies = InsuranceManager().policies;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pólizas Activas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              setState(() {
                InsuranceManager().policies.clear();
              });
            },
            tooltip: 'Limpiar todas las pólizas',
          ),
        ],
      ),
      body: policies.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.policy_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text('No tienes pólizas activas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Contrata tu primera póliza desde el inicio', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: policies.length,
        itemBuilder: (context, index) {
          final policy = policies[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: policy.isParametric ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  policy.isParametric ? Icons.auto_awesome : Icons.handyman,
                  color: policy.isParametric ? Colors.green : Colors.grey,
                ),
              ),
              title: Text('${policy.category} - ${policy.type}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(policy.insurer, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    policy.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('\$${policy.premium}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  Text('USDC/mes', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Cancelar Póliza'),
                    content: Text('¿Deseas cancelar la póliza de ${policy.insurer}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _cancelPolicy(policy);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sí, cancelar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============= DIALOGOS DE SISTEMA =============
class RedirectingDialog extends StatelessWidget {
  const RedirectingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text('Redirigiendo a la aseguradora...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Por favor espera', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class SuccessDialog extends StatelessWidget {
  final String message;

  const SuccessDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(width: 12),
          Text('Éxito'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }
}