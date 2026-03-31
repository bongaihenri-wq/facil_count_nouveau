import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class InvoiceImageViewer extends StatelessWidget {
  final String? imageUrl;
  final Widget placeholder;

  const InvoiceImageViewer({
    super.key,
    this.imageUrl,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder;
    }

    return PhotoView(
      imageProvider: NetworkImage(imageUrl!),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      initialScale: PhotoViewComputedScale.contained,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => _buildLoading(),
      errorBuilder: (context, error, stackTrace) => _buildError(),
      enableRotation: false,
      filterQuality: FilterQuality.high,
      gestureDetectorBehavior: HitTestBehavior.translucent,
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez votre connexion',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Extension pour galerie si besoin de plusieurs images
class InvoiceImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const InvoiceImageGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoViewGallery.builder(
      itemCount: imageUrls.length,
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(imageUrls[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          initialScale: PhotoViewComputedScale.contained,
        );
      },
      pageController: PageController(initialPage: initialIndex),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}