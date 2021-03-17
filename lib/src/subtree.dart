import 'package:meta/meta.dart';

import 'export.dart';

class _PageWithPosition {
  final AppPage customPage;
  final int position;

  _PageWithPosition({@required this.customPage, @required this.position})
      : assert(customPage != null && position != null && position >= 0);

  @override
  String toString() =>
      "AppPage{route: ${customPage.route.template}, position: $position}";
}

class _SubTree {
  final _PageWithPosition root;
  final List<_PageWithPosition> children;

  _SubTree({this.root, this.children});

  @override
  String toString() => "SubTree(root: $root, children: $children)";

  int get startPosition => root.position;
  int get endPosition => children.isNotEmpty ? children.last.position : startPosition;

  void reset() => children.clear();

  List<AppPage> toPagesView() {
    return [
      root.customPage,
      ...children.map((e) => e.customPage),
    ];
  }
}

extension PageList on List<AppPage> {
  _SubTree getVisibleSubTree() {
    final subTrees = getSubTrees();
    return subTrees.isNotEmpty ? subTrees.last : null;
  }

  List<AppPage> subTreeMovedDown(AppRoute route, {bool reset = false}) {
    final subTree = getSubTrees().find(route);
    if (subTree != null && subTree.endPosition != length - 1) {
      final newRoutes = List.of(this)
        ..removeRange(subTree.startPosition, subTree.endPosition + 1);
      if (reset) {
        subTree.reset();
      }
      return newRoutes..addAll(subTree.toPagesView());
    } else {
      return this;
    }
  }

  List<AppPage> removeSubTree(AppRoute route) {
    final subTree = getSubTrees().find(route);
    if (subTree != null) {
      final newRoutes = List.of(this)
        ..removeRange(subTree.startPosition, subTree.endPosition + 1);
      return newRoutes;
    } else {
      return this;
    }
  }

  List<_SubTree> getSubTrees() {
    final List<MapEntry<_PageWithPosition, List<_PageWithPosition>>> treesEntries = [];
    asMap().entries.forEach((entry) {
      final index = entry.key;
      final page = entry.value;
      if (page.route.isSubRoot) {
        treesEntries.add(MapEntry(
          _PageWithPosition(
            customPage: page,
            position: index,
          ),
          [],
        ));
      } else if (!page.route.isSubRoot) {
        if (treesEntries.isNotEmpty && treesEntries.last != null) {
          treesEntries.last.value.add(
            _PageWithPosition(
              customPage: page,
              position: index,
            ),
          );
        } else {
          return;
        }
      }
    });
    return treesEntries.map((e) {
      return _SubTree(
        root: e.key,
        children: e.value,
      );
    }).toList();
  }
}

extension SubTreeList on List<_SubTree> {
  _SubTree find(AppRoute route) {
    return singleWhere(
      (e) => e.root.customPage.route == route,
      orElse: () => null,
    );
  }
}
