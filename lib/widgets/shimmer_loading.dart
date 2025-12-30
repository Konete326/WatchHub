import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  const ShimmerWidget.rounded({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class BannerShimmer extends StatelessWidget {
  const BannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerWidget.rectangular(height: 200);
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: ShimmerWidget.rounded(height: double.infinity),
        ),
        const SizedBox(height: 8),
        ShimmerWidget.rectangular(
          height: 16,
          width: MediaQuery.of(context).size.width * 0.3,
        ),
        const SizedBox(height: 4),
        ShimmerWidget.rectangular(
          height: 14,
          width: MediaQuery.of(context).size.width * 0.2,
        ),
      ],
    );
  }
}

class ListShimmer extends StatelessWidget {
  final int itemCount;
  const ListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const ShimmerWidget.rounded(
                width: 80,
                height: 80,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerWidget.rectangular(height: 16),
                    const SizedBox(height: 8),
                    ShimmerWidget.rectangular(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductDetailShimmer extends StatelessWidget {
  const ProductDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget.rectangular(height: 300),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget.rectangular(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.3,
                ),
                const SizedBox(height: 12),
                ShimmerWidget.rectangular(
                  height: 28,
                  width: MediaQuery.of(context).size.width * 0.7,
                ),
                const SizedBox(height: 12),
                ShimmerWidget.rectangular(
                  height: 20,
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
                const SizedBox(height: 24),
                const ShimmerWidget.rectangular(height: 32, width: 120),
                const SizedBox(height: 24),
                const ShimmerWidget.rectangular(height: 18, width: 100),
                const SizedBox(height: 12),
                const ShimmerWidget.rectangular(height: 14),
                const SizedBox(height: 8),
                const ShimmerWidget.rectangular(height: 14),
                const SizedBox(height: 8),
                const ShimmerWidget.rectangular(height: 14, width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
