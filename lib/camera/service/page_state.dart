import 'dart:math';

import 'package:flutter/foundation.dart';

class PageState with ChangeNotifier {
  PageState(this._pageCount);

  int _pageCount;
  int pageIndex = -1;

  bool incrementPageCount(int dir) {
    if (dir == 0 || _pageCount + dir < 0) {
      return false;
    }

    final needPageAdjust = isOnLastPage && dir < 0;
    _pageCount += dir;
    if (needPageAdjust) {
      incrementPageIndex(dir);
    } else {
      notifyListeners();
    }

    return true;
  }

  bool setPageCount(int newPageCount) {
    _pageCount = max(newPageCount, 0);

    final boundPageIndex = min(max(pageIndex, 0), _pageCount - 1);
    if (boundPageIndex != pageIndex) {
      setPageIndex(boundPageIndex);
    } else {
      notifyListeners();
    }

    return true;
  }

  bool incrementPageIndex(int dir) {
    if (dir == 0 || isOnFirstPage && dir < 0 || isOnLastPage && dir > 0) {
      return false;
    }

    pageIndex += dir;
    notifyListeners();

    return true;
  }

  bool setPageIndex(int newPageIndex) {
    final boundPageIndex = min(max(newPageIndex, 0), _pageCount - 1);
    if (boundPageIndex == pageIndex) {
      return false;
    }

    pageIndex = newPageIndex;
    notifyListeners();
    return true;
  }

  int get pageCount => _pageCount;
  int get currentPage => pageIndex;
  bool get isOnFirstPage => pageIndex == 0;
  bool get isOnLastPage => pageIndex == _pageCount - 1;
}
