import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_root.dart';
import '../features/customer/home_feed.dart';
import '../features/customer/more_screen.dart';

/// Customer bottom-nav shell: Home, Orders, Cart (Gebeta), More.
/// Orders & Cart open as full-screen routes; Home & More live in the stack.
class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeFeed(), Placeholder(), Placeholder(), MoreScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 1) {
            context.go('/orders');
            return;
          }
          if (i == 2) {
            context.go('/cart');
            return;
          }
          setState(() => _index = i);
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: const Icon(Icons.history), label: s.orders),
          const NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Gebeta'),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: s.more),
        ],
      ),
    );
  }
}