import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/brand_mark.dart';
import '../../app/widgets/primary_button.dart';

class _OnboardingPageData {
  const _OnboardingPageData({required this.asset, required this.title, required this.subtitle});

  final String asset;
  final String title;
  final String subtitle;
}

const _informationalPages = [
  _OnboardingPageData(
    asset: 'assets/brand/Onboarding1.png',
    title: 'Organize everything in one place.',
    subtitle: 'Manage people, events, attendance, communication, and follow-ups from one beautifully organized platform.',
  ),
  _OnboardingPageData(
    asset: 'assets/brand/onboading2.png',
    title: 'Build stronger relationships.',
    subtitle: 'Track every interaction, follow-up, and journey so no person is ever forgotten.',
  ),
  _OnboardingPageData(
    asset: 'assets/brand/Onboarding3.png',
    title: 'Built for every organization.',
    subtitle:
        "Whether you're managing a church, business, school, NGO, association, or community, Relvio adapts to the way your team works.",
  ),
];

/// Total panel count in design/ui-reference/3.png's frozen composite: the 3
/// informational panels above plus the 4th "Let's get started." action panel
/// (Product Task 077A).
const _pageCount = 4;
const _finalPageIndex = _pageCount - 1;

/// Matches design/ui-reference/3.png's full 4-panel onboarding carousel
/// exactly (Product Task 077A corrects Task 077, which had wrongly treated
/// the standalone Welcome screen as a substitute for panel 4). Panels 1-3
/// are the informational panels with Skip/Continue and page dots; panel 4
/// is the frozen "Let's get started." action panel — no Skip, no dots, and
/// its own real entry-action buttons — reached either by "Get Started" on
/// panel 3 or by tapping Skip on any of panels 1-3. There is no persisted
/// "has seen onboarding" flag (no invented persistence authority), so this
/// carousel is shown at the start of every unauthenticated session. The
/// standalone WelcomeScreen (design/ui-reference/2.png) is untouched and
/// remains a separate, still-routable screen — it is not reused here.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _skipToFinalPanel() {
    // A direct jump (not animateToPage): the final panel's layout differs
    // from the informational panels (no Skip row, no dots/button footer),
    // and animating across that layout change mid-flight is unreliable.
    _pageController.jumpToPage(_finalPageIndex);
  }

  void _continue() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final onFinalPanel = _currentPage == _finalPageIndex;

    // The Skip row and dots/button footer occupy a fixed-height SizedBox on
    // every page — with a real child on pages 1-3, and no child at all
    // (genuinely absent, not just invisible) on the final panel — so the
    // Expanded PageView's viewport dimension never changes as pages advance.
    // Removing them outright via `if` caused the PageView's scroll position
    // to be recalculated mid-transition and land back on the wrong page.
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: onFinalPanel
                  ? null
                  : Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextButton(onPressed: _skipToFinalPanel, child: const Text('Skip')),
                      ),
                    ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => index == _finalPageIndex
                    ? const _GetStartedPage()
                    : _OnboardingPage(data: _informationalPages[index]),
              ),
            ),
            SizedBox(
              height: 140,
              child: onFinalPanel
                  ? null
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _informationalPages.length,
                              (index) => _PageDot(active: index == _currentPage),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _continue,
                              child: Text(
                                _currentPage == _informationalPages.length - 1 ? 'Get Started' : 'Continue',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Image.asset(data.asset, height: 260),
          const SizedBox(height: 32),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The frozen 4th panel: "Let's get started." (design/ui-reference/3.png,
/// bottom-right). Its real actions mirror WelcomeScreen's — "Create an
/// Organization" begins the real Register journey (org creation itself
/// requires an authenticated, org-less account) and "Already a member? Sign
/// In" routes to the real Sign In screen. "Join Your Organization" is
/// omitted: no Invitation/join-workflow backend authority is approved v1
/// (Product Task 071), so there is nothing real to wire it to.
class _GetStartedPage extends StatelessWidget {
  const _GetStartedPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(child: BrandMark(size: 88)),
          const SizedBox(height: 32),
          const Text(
            "Let's get started.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            "Choose how you'd like to begin using Relvio.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          PrimaryButton(label: 'Create an Organization', onPressed: () => context.go(createAccountPath)),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go(signInPath),
              child: const Text('Already a member? Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.brandPrimary : AppColors.borderSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
