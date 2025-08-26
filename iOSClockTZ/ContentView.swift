//
//  ContentView.swift
//  iOSClockTZ
//
//  Created by Masahiko Funaki on 2025/08/26.
//

import SwiftUI
import Combine

final class ClockViewModel: ObservableObject {
    @Published var now: Date = Date()
    @Published var timezoneDisplayName: String = ClockViewModel.computeTimezoneDisplayName()

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 毎秒タイマーで現在時刻を更新
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.now = Date()
            }
            .store(in: &cancellables)

        // タイムゾーンやロケールが外部で変更されたら表示名を更新
        let tzDidChange = NotificationCenter.default
            .publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)
        let localeDidChange = NotificationCenter.default
            .publisher(for: NSLocale.currentLocaleDidChangeNotification)

        tzDidChange
            .merge(with: localeDidChange)
            .sink { [weak self] _ in
                self?.timezoneDisplayName = ClockViewModel.computeTimezoneDisplayName()
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    /// 例: "Japan Standard Time" → "Japan"
    static func computeTimezoneDisplayName(
        locale: Locale = Locale(identifier: "en_US")
    ) -> String {
        let tz = TimeZone.current
        if let name = tz.localizedName(for: .generic, locale: locale) ??
                      tz.localizedName(for: .standard, locale: locale) {
            // よくある "Xxx Standard Time" / "Xxx Time" を短縮
            return name
                .replacingOccurrences(of: " Standard Time", with: "")
                .replacingOccurrences(of: " Time", with: "")
        }
        // 取得できなければ識別子（Asia/Tokyo など）を表示
        return tz.identifier
    }

    static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX") // 24時間固定のため
        df.dateFormat = "HH:mm:ss"                    // 24h HH:MM:SS
        return df
    }()
}

struct ContentView: View {
    @StateObject private var vm = ClockViewModel()

    var body: some View {
        VStack(spacing: 12) {
            // 中央に現在時刻（24時間制、毎秒更新）
            Text(ClockViewModel.timeFormatter.string(from: vm.now))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .accessibilityIdentifier("timeLabel")

            // その下にタイムゾーン（例: Timezone: Japan）
            Text("Timezone: \(vm.timezoneDisplayName)")
                .font(.title3)
                .accessibilityIdentifier("timezoneLabel")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
