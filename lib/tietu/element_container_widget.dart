import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'rotate_scale_gesture_recognizer.dart';

import 'ws_element.dart';

enum BaseActionMode {
  MOVE,
  SELECT,
  SELECTED_CLICK_OR_MOVE,
  SINGLE_TAP_BLANK_SCREEN,
  DOUBLE_FINGER_SCALE_AND_ROTATE,
}

class ElementContainerWidget extends StatefulWidget {
  final ElementContainerWidgetState elementContainerWidgetState;

  ElementContainerWidget(this.elementContainerWidgetState);

  @override
  State<StatefulWidget> createState() {
    return elementContainerWidgetState;
  }
}
/// 结构 请看 [https://juejin.cn/post/6844903870271848462]
/// ![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2019/6/18/16b69231961beeeb~tplv-t2oaga2asx-zoom-in-crop-mark:3024:0:0:0.awebp)
///
/// 主要是两个类
/// 这个是容器类，
/// 1、处理各种手势事件，这里的手势包括单指和双指，不能写在子wgt里面，必须写在这里面，因为事件可能发生在空白区域
/// 2、添加和删除一些子 Widget。这里的子 Widget 用于绘制各种元素。
/// 3.提供一些 api 让外部能操控元素。
/// 4.提供一个 listener，让外部能够监听内部的各种流程。
///
/// 然后就是里面的视图内容 wgt类，
/// 2.有了绘制容器，我们需要向绘制容器里面添加 Widget。
/// 而 Widget 在用户操作的过程中需要有各种数据，其内部有下面这些东西：
///
/// 1.各种用户操作过程中需要的数据例如：scale、rotate、x、y等等。
/// 2.有一些方法能够通过数据来更新 Widget。
/// 3.提供一些 api 让 容器 能更新 WE 里面的数据 。
///
///
/// 然后 由 容器 和 子wgt 就能继续继承出各种各样的扩展控件。
///
class ElementContainerWidgetState extends State<ElementContainerWidget> {
  static const String TAG = "ElementContainerWidgetState";
  final GlobalKey globalKey = GlobalKey();
  List<WsElement> mElementList = []; // 元素列表
  Set<ElementActionListener> mElementActionListenerSet = {}; // 监听列表
  WsElement? mSelectedWg; // 当前选中的 元素
  BaseActionMode mMode = BaseActionMode.SELECTED_CLICK_OR_MOVE; // 当前手势所处的模式
  Rect? mEditRect; // 当前 widget 的区域
  Offset? mOffset; // 当前 widget 与屏幕左上角位置偏移
  bool mIsNeedAutoUnSelect = true; // 是否需要自动取消选中
  int mAutoUnSelectDuration = 2000; // 自动取消选中的时间，默认 2000 毫秒，

  @override
  initState() {
    super.initState();

    print("initState rect:$mEditRect");
  }

  @override
  Widget build(BuildContext context) {
    // RawGestureDetector主要用于开发自己的手势识别器。
    // GestureDetector，一个不太灵活但简单得多的小部件，可以做同样的事情。
    // GestureRecognitzer，可扩展以创建自定义手势识别器的类。
    RawGestureDetector? gestureDetectorTwo = GestureDetector(
      child: GestureDetector(
        // 一样也是通过stack放置多个视图
        child: Stack(
            alignment: AlignmentDirectional.center,
            key: globalKey,
            children: mElementList
                .map((e) {
                  return e.buildTransform();
                })
                .toList()
                .reversed
                .toList()),
        onPanUpdate: onMove,
        behavior: HitTestBehavior.opaque,
      ),
    ).build(context) as RawGestureDetector?;
    gestureDetectorTwo?.gestures[RotateScaleGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<RotateScaleGestureRecognizer>(
      () => RotateScaleGestureRecognizer(debugOwner: this),
      (RotateScaleGestureRecognizer instance) {
        instance
          ..onStart = onDoubleFingerScaleAndRotateStart
          ..onUpdate = onDoubleFingerScaleAndRotateProcess
          ..onEnd = onDoubleFingerScaleAndRotateEnd;
      },
    );
    return Listener(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: double.infinity,
          minWidth: double.infinity,
        ),
        child: gestureDetectorTwo,
      ),
      behavior: HitTestBehavior.opaque,
      onPointerDown: onDown,
      onPointerUp: onUp,
    );
  }

  /// 点击逻辑 获取点击位置，根据位置获取点击到的wedgit
  /// 如果点击选中的，那么在判断是否点击到按钮
  /// 如果点击到没选中的，那么就选中该widget
  onDown(PointerDownEvent event) {
    cancelAutoUnSelect();
    final x = getRelativeX(event.position.dx),
        y = getRelativeY(event.position.dy);
    mMode = BaseActionMode.SELECTED_CLICK_OR_MOVE;
    WsElement? clickedElement = findElementByPosition(x, y);

    print(
        "$TAG onDown |||||||||| x:$x,y:$y,clickedElement:$clickedElement,mSelectedElement:$mSelectedWg");
    if (mSelectedWg != null) {
      if (isSameElement(clickedElement, mSelectedWg)) {
        bool result = downSelectTapOtherAction(event);
        if (result) {
          print("$TAG onDown other action");
          return;
        }
        if (mSelectedWg!.isInWholeDecoration(x, y)) {
          mMode = BaseActionMode.SELECTED_CLICK_OR_MOVE;
          print("$TAG onDown SELECTED_CLICK_OR_MOVE");
          return;
        }
        print("$TAG onDown error not action");
      } else {
        if (clickedElement == null) {
          mMode = BaseActionMode.SINGLE_TAP_BLANK_SCREEN;
          print("$TAG onDown SINGLE_TAP_BLANK_SCREEN");
        } else {
          mMode = BaseActionMode.SELECT;
          unSelectElement();
          selectElement(clickedElement);
          update();
          print("$TAG onDown unSelect old element, select new element");
        }
      }
    } else {
      if (clickedElement != null) {
        mMode = BaseActionMode.SELECT;
        selectElement(clickedElement);
        update();
        print("$TAG onDown select new element");
      } else {
        mMode = BaseActionMode.SINGLE_TAP_BLANK_SCREEN;
        print("$TAG onDown SINGLE_TAP_BLANK_SCREEN");
      }
    }
  }

  onMove(DragUpdateDetails dragUpdateDetails) {
    List<DragUpdateDetails> dragUpdateDetailList = [dragUpdateDetails];
    if (scrollSelectTapOtherAction(dragUpdateDetailList)) {
      return;
    } else {
      if (mMode == BaseActionMode.SELECTED_CLICK_OR_MOVE ||
          mMode == BaseActionMode.SELECT ||
          mMode == BaseActionMode.MOVE) {
        if (mMode == BaseActionMode.SELECTED_CLICK_OR_MOVE ||
            mMode == BaseActionMode.SELECT) {
          onSingleFingerMoveStart(dragUpdateDetailList[0]);
        } else {
          onSingleFingerMoveProcess(dragUpdateDetailList[0]);
        }
        update();
        mMode = BaseActionMode.MOVE;
      }
    }
  }

  onSingleFingerMoveStart(DragUpdateDetails d) {
    mSelectedWg!.onSingleFingerMoveStart();
    update();
    callListener((elementActionListener) {
      elementActionListener.onSingleFingerMoveStart(mSelectedWg!);
    });
  }

  onSingleFingerMoveProcess(DragUpdateDetails d) {
    mSelectedWg!.onSingleFingerMoveProcess(d);
    update();
    callListener((elementActionListener) {
      elementActionListener.onSingleFingerMoveProcess(mSelectedWg!);
    });
  }

  onSingleFingerMoveEnd() {
    mSelectedWg!.onSingleFingerMoveEnd();
    update();
    callListener((elementActionListener) {
      elementActionListener.onSingleFingerMoveEnd(mSelectedWg!);
    });
  }

  onDoubleFingerScaleAndRotateStart(RotateScaleStartDetails s) {
    mSelectedWg!.onDoubleFingerScaleAndRotateStart(s);
    update();
    callListener((elementActionListener) {
      elementActionListener.onDoubleFingerScaleAndRotateStart(mSelectedWg!);
    });
  }

  onDoubleFingerScaleAndRotateProcess(RotateScaleUpdateDetails s) {
    mSelectedWg!.onDoubleFingerScaleAndRotateProcess(s);
    update();
    callListener((elementActionListener) {
      elementActionListener
          .onDoubleFingerScaleAndRotateProcess(mSelectedWg!);
    });
  }

  onDoubleFingerScaleAndRotateEnd(RotateScaleEndDetails s) {
    mSelectedWg!.onDoubleFingerScaleAndRotateEnd(s);
    update();
    autoUnSelect();
    callListener((elementActionListener) {
      elementActionListener.onDoubleFingerScaleRotateEnd(mSelectedWg!);
    });
  }

  onUp(PointerUpEvent event) {
    autoUnSelect();
    print("$TAG singleFingerUp |||||||||| position:${event.position}");
    if (!upSelectTapOtherAction(event)) {
      switch (mMode) {
        case BaseActionMode.SELECTED_CLICK_OR_MOVE:
          selectedClick(event);
          update();
          return;
        case BaseActionMode.SINGLE_TAP_BLANK_SCREEN:
          onClickBlank(event);
          return;
        case BaseActionMode.MOVE:
          onSingleFingerMoveEnd();
          return;
        default:
          print("$TAG singleFingerUp other action");
      }
    }
  }

  /// 添加一个元素，如果元素已经存在，那么就会添加失败
  /// [wsElement] 被添加的元素
  bool addElement(WsElement wsElement) {
    if (mEditRect == null || mEditRect?.width == 0 || mEditRect?.height == 0) {
      mEditRect = Rect.fromLTRB(0, 0, globalKey.currentContext!.size!.width,
          globalKey.currentContext!.size!.height);
      RenderBox renderBox = globalKey.currentContext!.findRenderObject() as RenderBox;
      mOffset = renderBox.localToGlobal(Offset.zero);
      print("addElement init mEditRect:$mEditRect, offset:$mOffset");
    }
    if (wsElement == null) {
      print("$TAG addElement element is null");
      return false;
    }

    if (mElementList.contains(wsElement)) {
      print("$TAG addElement element is added");
      return false;
    }

    for (int i = 0; i < mElementList.length; i++) {
      WsElement nowElement = mElementList[i];
      nowElement.mZIndex++;
    }
    wsElement.mZIndex = 0;
    wsElement.mEditRect = mEditRect!;
    wsElement.mOffset = mOffset!;
    if (mElementList.length == 0) {
      mElementList.add(wsElement);
    } else {
      mElementList.insert(0, wsElement);
    }
    wsElement.add();
    callListener((elementActionListener) {
      elementActionListener.onAdd(mSelectedWg!);
    });
    autoUnSelect();
    return true;
  }

  /// 删除一个元素，只能删除当前最顶层的元素
  /// [wsElement] 被删除的元素
  bool deleteElement([WsElement? wsElement]) {
    if (wsElement == null) {
      if (mElementList.length <= 0) {
        return false;
      }
      wsElement = mElementList.first;
    }

    if (mElementList.first != wsElement) {
      print("$TAG deleteElement element is not in top");
      return false;
    }

    mElementList.remove(wsElement);
    for (int i = 0; i < mElementList.length; i++) {
      WsElement nowElement = mElementList[i];
      nowElement.mZIndex--;
    }
    wsElement.delete();
    callListener((elementActionListener) {
      elementActionListener.onDelete(mSelectedWg!);
    });
    return true;
  }

  /// 更新界面
  update() {
    setState(() {
      if (mSelectedWg != null) {
        mSelectedWg!.update();
      }
    });
  }

  /// 选中一个元素，如果需要选中的元素没有被添加到 container 中则选中失败
  /// [wsElement] 被选中的元素
  bool selectElement(WsElement wsElement) {
    print("$TAG selectElement |||||||||| element:$wsElement");
    if (wsElement == null) {
      print("$TAG selectElement element is null");
      return false;
    }

    if (!mElementList.contains(wsElement)) {
      print("$TAG selectElement element was not added");
      return false;
    }

    for (int i = 0; i < mElementList.length; i++) {
      WsElement nowElement = mElementList[i];
      if (!identical(nowElement, wsElement) &&
          wsElement.mZIndex > nowElement.mZIndex) {
        nowElement.mZIndex++;
      }
    }
    mElementList.remove(wsElement);
    wsElement.select();
    if (mElementList.length == 0) {
      mElementList.add(wsElement);
    } else {
      mElementList.insert(0, wsElement);
    }
    mSelectedWg = wsElement;
    callListener((elementActionListener) {
      elementActionListener.onSelect(mSelectedWg!);
    });
    return true;
  }

  /// 取消选中当前元素
  bool unSelectElement() {
    print("$TAG unSelectElement |||||||||| mSelectedElement:$mSelectedWg");
    if (mSelectedWg == null) {
      print("$TAG unSelectElement unSelect element is null");
      return false;
    }

    if (!mElementList.contains(mSelectedWg)) {
      print("$TAG unSelectElement unSelect elemnt not in container");
      return false;
    }

    mSelectedWg!.unSelect();
    mSelectedWg = null;
    callListener((elementActionListener) {
      elementActionListener.onUnSelect(mSelectedWg!);
    });
    return true;
  }

  /// 根据位置找到 元素
  /// [x] container widget 中的坐标
  /// [y] container widget 中的坐标
  WsElement? findElementByPosition(double x, double y) {
    WsElement? realFoundedElement;
    for (int i = mElementList.length - 1; i >= 0; i--) {
      WsElement nowElement = mElementList[i];
      if (nowElement.isInWholeDecoration(x, y)) {
        realFoundedElement = nowElement;
      }
    }
    print(
        "$TAG findElementByPosition |||||||||| realFoundedElement:$realFoundedElement,x:$x,y:$y");
    return realFoundedElement;
  }

  /// 选中之后再次点击选中的元素
  selectedClick(PointerUpEvent event) {
    callListener((elementActionListener) {
      elementActionListener.onSelectedClick(mSelectedWg!);
    });
  }

  /// 点击空白区域
  onClickBlank(PointerUpEvent event) {
    callListener((elementActionListener) {
      elementActionListener.onSingleTapBlankScreen(mSelectedWg!);
    });
  }

  /// 按下了已经选中的元素，如果子类中有操作的话可以给它，优先级最高
  bool downSelectTapOtherAction(PointerDownEvent event) {
    return false;
  }

  /// 滑动已经选中的元素，如果子类中有操作的话可以给它，优先级最高
  bool scrollSelectTapOtherAction(List<DragUpdateDetails> d) {
    return false;
  }

  /// 抬起已经选中的元素，如果子类中有操作的话可以给它，优先级最高
  bool upSelectTapOtherAction(PointerUpEvent event) {
    return false;
  }

  double getRelativeX(double screenX) {
    if (mOffset == null) {
      return screenX;
    }
    return screenX - mOffset!.dx;
  }

  double getRelativeY(double screenY) {
    if (mOffset == null) {
      return screenY;
    }
    return screenY - mOffset!.dy;
  }

  StreamSubscription? autoUnSelectFuture;

  /// 一定的时间之后自动取消当前元素的选中
  autoUnSelect() {
    if (mIsNeedAutoUnSelect) {
      cancelAutoUnSelect();
      autoUnSelectFuture =
          Future.delayed(Duration(milliseconds: mAutoUnSelectDuration))
              .asStream()
              .listen((a) {
        unSelectElement();
        update();
        print("autoUnSelect unselect");
      });
      print("autoUnSelect");
    }
  }

  /// 取消自动取消选中
  cancelAutoUnSelect() {
    print("cancelAutoUnSelect");
    if (mIsNeedAutoUnSelect && autoUnSelectFuture != null) {
      autoUnSelectFuture?.cancel();
      autoUnSelectFuture = null;
      print("cancelAutoUnSelect cancel");
    }
  }

  /// 是否需要自动取消选中
  setNeedAutoUnSelect(bool needAutoUnSelect) {
    mIsNeedAutoUnSelect = needAutoUnSelect;
  }

  /// 添加一个监听器
  void addElementActionListener(ElementActionListener elementActionListener) {
    if (elementActionListener == null) {
      return;
    }
    mElementActionListenerSet.add(elementActionListener);
  }

  /// 移除一个监听器
  void removeElementActionListener(
      ElementActionListener elementActionListener) {
    mElementActionListenerSet.remove(elementActionListener);
  }

  void callListener(
      Consumer<ElementActionListener> decorationActionListenerConsumer) {
    mElementActionListenerSet.map((elementActionListener) {
      decorationActionListenerConsumer(elementActionListener);
    });
  }
}

typedef EndRun = void Function();

typedef Consumer<T> = void Function(T t);

abstract class ElementActionListener {
  /// 增加了一个元素之后的回调
  void onAdd(WsElement element);

  /// 删除了一个元素之后的回调
  void onDelete(WsElement element);

  /// 选中了一个元素之后再次点击该元素触发的事件
  void onSelectedClick(WsElement element);

  /// 选中了元素之后，对元素单指移动开始的回调
  void onSingleFingerMoveStart(WsElement element);

  /// 选中了元素之后，对元素单指移动过程的回调
  void onSingleFingerMoveProcess(WsElement element);

  /// 一次 单指移动操作结束的回调
  void onSingleFingerMoveEnd(WsElement element);

  /// 选中了元素之后，对元素双指旋转缩放开始的回调
  void onDoubleFingerScaleAndRotateStart(WsElement element);

  /// 选中了元素之后，对元素双指旋转缩放过程的回调
  void onDoubleFingerScaleAndRotateProcess(WsElement element);

  /// 一次 双指旋转、缩放 操作结束的回调
  void onDoubleFingerScaleRotateEnd(WsElement element);

  /// 选中元素
  void onSelect(WsElement element);

  /// 取消选中元素
  void onUnSelect(WsElement element);

  // 点击空白区域
  void onSingleTapBlankScreen(WsElement element);
}

class DefaultElementActionListener implements ElementActionListener {
  @override
  void onAdd(WsElement element) {}

  @override
  void onDelete(WsElement element) {}

  @override
  void onSelectedClick(WsElement element) {}

  @override
  void onSingleFingerMoveStart(WsElement element) {}

  @override
  void onSingleFingerMoveProcess(WsElement element) {}

  @override
  void onSelect(WsElement element) {}

  @override
  void onUnSelect(WsElement element) {}

  @override
  void onSingleFingerMoveEnd(WsElement element) {}

  @override
  void onDoubleFingerScaleAndRotateStart(WsElement element) {}

  @override
  void onDoubleFingerScaleAndRotateProcess(WsElement element) {}

  @override
  void onDoubleFingerScaleRotateEnd(WsElement element) {}

  @override
  void onSingleTapBlankScreen(WsElement element) {}
}
