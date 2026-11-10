import 'package:flutter/material.dart';
import 'package:myapp/tarsi/models/plan_section.dart';
import 'package:myapp/tarsi/widgets/simulated_notification_banner.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final _notificationKey = GlobalKey<SimulatedNotificationBannerState>();
  var _nextNotification = 0;

  static const _sections = [
    PlanSection(
      title: 'Category budgets',
      summary: 'Set limits for everyday spending',
      description: 'Create monthly limits for categories like food, transport, and shopping.',
      icon: Icons.donut_large_rounded,
    ),
    PlanSection(
      title: 'Personal Goals',
      summary: 'Save for something meaningful',
      description: 'Create a savings target, add contributions, and track your progress.',
      icon: Icons.flag_outlined,
    ),
    PlanSection(
      title: 'Debt',
      summary: 'Keep repayments in view',
      description:
          'Track balances and due dates for money you need to pay back.',
      icon: Icons.credit_card_outlined,
    ),
    PlanSection(
      title: 'Money owed to you',
      summary: 'Track what you are waiting for',
      description: 'Keep a simple record of people who owe you and expected repayment dates.',
      icon: Icons.call_received_rounded,
    ),
    PlanSection(
      title: 'Planned payments',
      summary: 'Prepare for upcoming bills',
      description: 'Keep recurring and one-time payments together so nothing catches you off guard.',
      icon: Icons.event_note_rounded,
    ),
    PlanSection(
      title: 'Installments',
      summary: 'Stay on top of payment plans',
      description: 'Review your remaining installment balance and upcoming payment dates.',
      icon: Icons.calendar_month_outlined,
    ),
  ];

  static const _notifications = [
    (
      title: 'Payment reminder',
      message: 'Your phone bill is due tomorrow.',
      icon: Icons.event_available_rounded,
    ),
    (
      title: 'Money received',
      message: 'You logged a ₱500 repayment from Alex.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      title: 'Budget check-in',
      message: 'You have used 70% of your Food budget.',
      icon: Icons.pie_chart_outline_rounded,
    ),
  ];

  void _showNotification() {
    final notification = _notifications[_nextNotification];
    _notificationKey.currentState?.show(
      title: notification.title,
      message: notification.message,
      icon: notification.icon,
    );
    setState(() {
      _nextNotification = (_nextNotification + 1) % _notifications.length;
    });
  }

  void _showSectionDetails(PlanSection section) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(section.description),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF39745A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildTopBar(),
                          const SizedBox(height: 30),
                          _buildHeading(context),
                          const SizedBox(height: 24),
                          _buildSnapshotCard(),
                          const SizedBox(height: 32),
                          Text(
                            'Your plan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          for (final section in _sections) ...[
                            _PlanSectionCard(
                              section: section,
                              onTap: () => _showSectionDetails(section),
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 12),
                          const Text(
                            'A little planning today can make tomorrow feel lighter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF858C86),
                              fontSize: 12,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: SimulatedNotificationBanner(key: _notificationKey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EFE8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.spa_outlined,
            size: 21,
            color: Color(0xFF39745A),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'tarsi',
          style: TextStyle(
            color: Color(0xFF202521),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _showNotification,
          tooltip: 'Show a sample notification',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF434A44),
            side: const BorderSide(color: Color(0xFFE8EBE7)),
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildHeading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plan', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text(
          'Manage your budget, goals and more.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSnapshotCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF39745A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MONTHLY OVERVIEW',
                  style: TextStyle(
                    color: Color(0xFFD8E7DD),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 17),
          const Text(
            '₱18,450',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'planned across your budgets',
            style: TextStyle(color: Color(0xFFD8E7DD), fontSize: 12),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const LinearProgressIndicator(
              value: 0.62,
              minHeight: 6,
              backgroundColor: Color(0x557FA58F),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE4F0E7)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '62% of your monthly plan',
            style: TextStyle(color: Color(0xFFD8E7DD), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PlanSectionCard extends StatelessWidget {
  const _PlanSectionCard({required this.section, required this.onTap});

  final PlanSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9ECE8)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  section.icon,
                  color: const Color(0xFF39745A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        color: Color(0xFF252A26),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      section.summary,
                      style: const TextStyle(
                        color: Color(0xFF7C837D),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF979D98),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
