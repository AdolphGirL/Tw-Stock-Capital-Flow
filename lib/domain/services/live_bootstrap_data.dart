import 'package:flutter/foundation.dart';
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';

/// 全域可監聽的「目前最新」bootstrap 計算結果持有者。
///
/// 背景：MainCategoryPage / SubCategoryPage / 成分股清單這條鑽入導覽鏈路是透過
/// Navigator.push 建立的獨立路由，資料以建構子參數傳入，只在第一次建立時取值一次；
/// 之後即使根層（BootstrapApp）因為背景同步、手動刷新拿到新資料而 setState，這幾層
/// 已經被 push 出去的頁面並不會自動重新取得新資料——它們脫離了 IndexedStack 的
/// rebuild 循環，會一直停留在使用者進入當下的靜態快照，這正是「日期顯示已更新，
/// 但個股明細數字依然是舊的」這個問題的根因。
///
/// main.dart 每次拿到新的計算結果時，除了 setState 更新自己的畫面，也會同步寫入
/// 這個全域 notifier；MainCategoryPage / SubCategoryPage 改用 ValueListenableBuilder
/// 訂閱它，依照 market + 板塊名稱動態查找當下最新的資料，而不是持有寫死的物件參照，
/// 讓即使頁面已經在導覽堆疊上，資料一旦更新也會立即反映在畫面。
class LiveBootstrapData {
  LiveBootstrapData._();

  static final ValueNotifier<AppBootstrapResult?> notifier =
      ValueNotifier<AppBootstrapResult?>(null);
}
