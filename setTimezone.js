function mablJavaScriptStep(
  mablInputs,
  callback,
  tz = "Asia/Tokyo",      // ここを "Asia/Tokyo" 以外に変えてもOK（IANA TZ名）
  bundleId = ""           // 明示したい場合だけ設定。空なら自動取得
) {
  async function run() {
    const driver = await mabl.mobile.getDriver();

    // いま前面のアプリの bundleId を自動取得（明示されたらそれを使用）
    let bid = (bundleId || "").trim();
    if (!bid) {
      const info = await driver.executeScript("mobile: activeAppInfo", []);
      bid = info.bundleId;
      if (!bid) throw new Error("bundleId を取得できませんでした。");
    }

    // 一旦終了して…
    try {
      await driver.executeScript("mobile: terminateApp", [{ bundleId: bid }]);
    } catch (_) { /* 走っていなくても気にしない */ }

    // TZ 環境変数を付けて起動
    await driver.executeScript("mobile: launchApp", [{
      bundleId: bid,
      environment: { TZ: tz }   // ← これがポイント
    }]);

    return `Relaunched ${bid} with TZ=${tz}`;
  }

  run().then(msg => callback(msg)).catch(err => callback(String(err)));
}