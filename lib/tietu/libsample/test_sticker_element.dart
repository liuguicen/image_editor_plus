import 'package:flutter/material.dart';

import '../decoration_element.dart';

class StickerElement extends DecorationElement {
  StickerElement(double mOriginWidth, double mOriginHeight)
      : super(mOriginWidth, mOriginHeight);

  @override
  Widget initWidget() {
    return Image(
      image: NetworkImage(
          'https://img2.baidu.com/it/u=3062813899,1142128231&fm=253&fmt=auto&app=138&f=JPEG?w=479&h=500'),
      width: mOriginWidth,
      height: mOriginHeight,
      fit: BoxFit.cover,
    );
  }
}