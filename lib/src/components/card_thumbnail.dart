import 'package:flutter/material.dart';

import '../models/card_master.dart';

class CardThumbnail extends StatefulWidget {
  final CardMaster? cardMaster;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  const CardThumbnail({
    super.key,
    required this.cardMaster,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 12,
    this.iconSize = 24,
  });

  @override
  State<CardThumbnail> createState() => _CardThumbnailState();
}

class _CardThumbnailState extends State<CardThumbnail> {
  late List<_CardImageSource> _sources;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _sources = _buildSources(widget.cardMaster?.cardImageUrl ?? '');
  }

  @override
  void didUpdateWidget(covariant CardThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrl = oldWidget.cardMaster?.cardImageUrl ?? '';
    final newUrl = widget.cardMaster?.cardImageUrl ?? '';
    if (oldUrl != newUrl) {
      _sources = _buildSources(newUrl);
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _parseColor(widget.cardMaster?.imageColor ?? '#7C83FD');

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: cardColor.withValues(alpha: 0.15),
        child: _buildImage(cardColor),
      ),
    );
  }

  Widget _buildImage(Color cardColor) {
    if (_currentIndex >= _sources.length) {
      return _buildFallback(cardColor);
    }

    final source = _sources[_currentIndex];
    if (source.type == _CardImageType.network) {
      return Image.network(
        source.value,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          _moveToNextSource();
          return _buildFallback(cardColor);
        },
      );
    }

    return Image.asset(
      source.value,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        _moveToNextSource();
        return _buildFallback(cardColor);
      },
    );
  }

  Widget _buildFallback(Color cardColor) {
    return Icon(
      Icons.credit_card_rounded,
      color: cardColor,
      size: widget.iconSize,
    );
  }

  void _moveToNextSource() {
    if (_currentIndex >= _sources.length - 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _currentIndex += 1);
    });
  }

  List<_CardImageSource> _buildSources(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return const [];

    if (value.startsWith('asset:')) {
      final assetPath = value.substring('asset:'.length).trim();
      if (assetPath.isEmpty) return const [];
      return [_CardImageSource(_CardImageType.asset, assetPath)];
    }

    if (value.startsWith('assets/')) {
      return [_CardImageSource(_CardImageType.asset, value)];
    }

    final uri = Uri.tryParse(value);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return [_CardImageSource(_CardImageType.network, value)];
    }

    return [_CardImageSource(_CardImageType.asset, value)];
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

enum _CardImageType { network, asset }

class _CardImageSource {
  final _CardImageType type;
  final String value;

  const _CardImageSource(this.type, this.value);
}
