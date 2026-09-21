import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';

class StudentListShimmer extends StatelessWidget {
  const StudentListShimmer({super.key, this.count = 12});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (_, __) => const StudentShimmerTile(),
    );
  }
}

/// Shimmer rows as a sliver — safe inside [CustomScrollView].
class StudentListShimmerSliver extends StatelessWidget {
  const StudentListShimmerSliver({super.key, this.count = 12});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
      sliver: SliverList.separated(
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 5),
        itemBuilder: (_, __) => const StudentShimmerTile(),
      ),
    );
  }
}

class StudentShimmerTile extends StatelessWidget {
  const StudentShimmerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
