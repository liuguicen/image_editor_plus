import 'package:flutter/material.dart';
import 'package:image_editor_plus/data/layer.dart';

import '../tietu/element_container_widget.dart';
import '../tietu/libsample/test_sticker_element.dart';
import '../tietu/rule_line_element_container_widget.dart';

/// Image layer that can be used to add overlay images and drawings
class TietuLayer extends StatefulWidget {
  final TietuLayerData layerData;
  final VoidCallback? onUpdate;

  const TietuLayer({
    Key? key,
    required this.layerData,
    this.onUpdate,
  }) : super(key: key);

  @override
  _TietuLayerState createState() => _TietuLayerState();
}

class _TietuLayerState extends State<TietuLayer> {


  @override
  Widget build(BuildContext context) {
    RuleLineElementContainerState decorationElementContainerWidgetState = RuleLineElementContainerState();
    return Stack(
      alignment: AlignmentDirectional.topStart,
      children: <Widget>[
        DecoratedBox(
          decoration: const BoxDecoration(
              color: Colors.grey
          ),
          // P图的Widget 页面
          child: ElementContainerWidget(
              decorationElementContainerWidgetState),
        ),
        Positioned(
          left: 0,
          top: 50,
          child: RaisedButton(
            child: Text("add"),
            onPressed: () {
              StickerElement stickerElement = StickerElement(100, 100);
              decorationElementContainerWidgetState
                  .addSelectAndUpdateElement(
                  stickerElement);
            },
          ),
        ),
        Positioned(
          left: 100,
          top: 50,
          child: RaisedButton(
            child: Text("delete"),
            onPressed: () {
              decorationElementContainerWidgetState
                  .unSelectDeleteAndUpdateTopElement();
            },
          ),
        ),
      ],
    );
  }
}
