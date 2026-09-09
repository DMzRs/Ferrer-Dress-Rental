import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/router/app_router.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:ferrer_rental_shop/features/home/presentation/widgets/item_card.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final greetingName = user?.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .firstWhere((word) => word.isNotEmpty, orElse: () => 'there') ??
        'there';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.creamGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good day, $greetingName',
                                  style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 3),
                              Text(
                                '${vm.availableCount} exquisite pieces ready for you today',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _UserAvatar(user: user),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SearchBar(controller: _searchController, onChanged: vm.search),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryPillsSection(vm: vm),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            if (vm.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child:
                    Center(child: CircularProgressIndicator(color: AppColors.rose)),
              )
            else if (vm.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No gowns match your search yet.\nTry another keyword or category.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.inkSoft, fontSize: 14, height: 1.5),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                sliver: SliverToBoxAdapter(
                  // Column count comes from the screen width rather than a
                  // SliverLayoutBuilder: layout-callback widgets inside the
                  // IndexedStack trip a Flutter 3.44 layout assertion when
                  // the auth gate swaps screens.
                  child: Builder(builder: (context) {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final crossAxisCount = screenWidth > 600 ? 4 : 2;
                    final columns = List.generate(
                        crossAxisCount, (_) => <(CatalogItem, int)>[]);
                    for (var i = 0; i < vm.items.length; i++) {
                      columns[i % crossAxisCount].add((vm.items[i], i));
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var c = 0; c < columns.length; c++) ...[
                          if (c > 0) const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                for (final (item, index) in columns[c])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: ItemCard(
                                      item: item,
                                      index: index,
                                      onTap: () => context.pushNamed(
                                          AppRoutes.itemDetails,
                                          arguments: item),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CategoryPillsSection extends StatelessWidget {
  final HomeViewModel vm;

  const CategoryPillsSection({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return CategoryPills(
      categories: HomeViewModel.categories,
      selected: vm.selectedCategory,
      onSelect: vm.selectCategory,
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.goldSoft.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .22),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
        decoration: const InputDecoration(
          hintText: 'Search dresses & kiddie costumes...',
          hintStyle: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.rose),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final AppUser? user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .45),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        user?.initials ?? '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
