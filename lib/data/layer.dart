import 'package:flutter/material.dart';
import 'package:image_editor_plus/data/image_item.dart';
import 'package:nb_utils/nb_utils.dart';

/// Layer class with some common properties
class BaseLayerData {
  late Offset offset;
  late double rotation, scale, opacity;

  BaseLayerData({
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) {
    this.offset = offset ?? const Offset(64, 64);
    this.opacity = opacity ?? 1;
    this.rotation = rotation ?? 0;
    this.scale = scale ?? 1;
  }
}

/// Attributes used by [BackgroundLayer]
class BackgroundLayerData extends BaseLayerData {
  ImageItem file;

  BackgroundLayerData({
    required this.file,
  });
}

/// Attributes used by [EmojiLayer]
class EmojiLayerData extends BaseLayerData {
  String text;
  double size;

  EmojiLayerData({
    Key? key,
    this.text = '',
    this.size = 64,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) : super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
        );
}

/// Attributes used by [ImageLayer]
class ImageLayerData extends BaseLayerData {
  ImageItem image;
  double size;

  ImageLayerData({
    Key? key,
    required this.image,
    this.size = 64,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) : super(
    offset: offset,
    opacity: opacity,
    rotation: rotation,
    scale: scale,
  );
}
/// Attributes used by [ImageLayer]
class TietuLayerData extends BaseLayerData {
  ImageItem image;
  double size;

  TietuLayerData({
    Key? key,
    required this.image,
    this.size = 64,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) : super(
    offset: offset,
    opacity: opacity,
    rotation: rotation,
    scale: scale,
  );
}

/// Attributes used by [TextLayer]
class TextLayerData extends BaseLayerData {
  String text;
  double size;
  Color color, background;
  int backgroundOpacity;
  TextAlign align;

  TextLayerData({
    required this.text,
    this.size = 64,
    this.color = white,
    this.background = Colors.transparent,
    this.backgroundOpacity = 1,
    this.align = TextAlign.left,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) : super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
        );
}

/// Attributes used by [BackgroundBlurLayer]
class BackgroundBlurLayerData extends BaseLayerData {
  Color color;
  double radius;

  BackgroundBlurLayerData({
    required this.color,
    required this.radius,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) : super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
        );
}
