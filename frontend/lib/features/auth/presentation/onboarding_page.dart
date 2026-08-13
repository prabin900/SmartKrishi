import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Direct Sourcing',
      'description': 'Buy fresh produce directly from local Nepalese farmers. No middleman markups, fair pricing, and transparency.',
      'icon': 'agriculture'
    },
    {
      'title': 'Quality Checked',
      'description': 'Every crop and farm partner is certified organic and thoroughly checked to ensure premium quality.',
      'icon': 'verified'
    },
    {
      'title': 'Fast Logistics',
      'description': 'A robust local delivery network ensures harvest-fresh greens arrive at your doorstep in record time.',
      'icon': 'local_shipping'
    }
  ];

  IconData _getIcon(String name) {
    switch (name) {
      case 'agriculture':
        return Icons.agriculture;
      case 'verified':
        return Icons.verified_user_outlined;
      case 'local_shipping':
        return Icons.local_shipping_outlined;
      default:
        return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final slide = _slides[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                          child: Icon(_getIcon(slide['icon']!), size: 80, color: const Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title']!,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide['description']!,
                          style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _slides.length - 1) {
                      context.go('/login');
                    } else {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_currentPage == _slides.length - 1 ? 'Get Started' : 'Next', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
