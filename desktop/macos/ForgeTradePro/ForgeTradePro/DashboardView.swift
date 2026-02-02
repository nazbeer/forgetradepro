//
//  DashboardView.swift
//  ForgeTradePro
//
//  Created by Nasbeer Ahammed on 02/02/26.
//


import SwiftUI
import Combine

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Dashboard")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Picker("Symbol", selection: $vm.symbol) {
                    Text("BTCUSDT").tag("BTCUSDT")
                    Text("ETHUSDT").tag("ETHUSDT")
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            HStack(spacing: 12) {
                StatCard(title: "Balance", value: vm.balanceText)
                StatCard(title: "PnL", value: vm.pnlText, valueColor: vm.pnlColor)
                StatCard(title: "Max Risk", value: vm.maxRiskText)
                StatCard(title: "Trades", value: vm.tradesText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Realtime Price")
                    .font(.headline)

                CandleChart(candles: vm.candles)
                    .frame(height: 240)
                    .overlay(alignment: .topLeading) {
                        Text(vm.lastPriceText)
                            .font(.caption)
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(8)
                    }
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 12) {
                Button("Run Paper Trade") {
                    vm.runPaperTrade()
                }
                .keyboardShortcut(.return)

                Text(vm.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 900, minHeight: 600)
        .preferredColorScheme(.dark)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .onChange(of: vm.symbol) { _, _ in
            vm.refreshMarket()
        }
    }
}

final class DashboardViewModel: ObservableObject {
    @Published var symbol: String = "BTCUSDT"
    @Published var balance: Double = 0
    @Published var pnl: Double = 0
    @Published var maxRiskPct: Double = 0
    @Published var tradesCount: Int = 0
    @Published var candles: [Candle] = []
    @Published var status: String = ""

    private var timer: Timer?

    var balanceText: String { String(format: "$%.2f", balance) }
    var pnlText: String { String(format: "$%.2f", pnl) }
    var pnlColor: Color { pnl >= 0 ? .green : .red }
    var maxRiskText: String { String(format: "%.2f%%", maxRiskPct * 100) }
    var tradesText: String { "\(tradesCount)" }
    var lastPriceText: String {
        guard let last = candles.last else { return "Loading…" }
        return "\(symbol)  \(String(format: "%.2f", last.close))"
    }

    func start() {
        refreshAll()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshAll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refreshAll() {
        refreshAnalytics()
        refreshMarket()
    }

    func refreshAnalytics() {
        guard API.token != nil else {
            // Guest/offline mode: analytics requires auth.
            if status.isEmpty {
                status = "Guest mode: market only"
            }
            return
        }
        API.get("/analytics/summary") { [weak self] res in
            guard let self else { return }
            guard let json = res as? [String: Any] else {
                self.status = "Analytics: no response"
                return
            }

            self.balance = (json["balance"] as? Double) ?? self.balance
            self.pnl = (json["pnl"] as? Double) ?? self.pnl
            self.maxRiskPct = (json["max_risk_pct"] as? Double) ?? self.maxRiskPct
            self.tradesCount = (json["trades_count"] as? Int) ?? self.tradesCount
        }
    }

    func refreshMarket() {
        let path = "/market/candles/\(symbol)?interval=1m&limit=60"
        API.get(path) { [weak self] res in
            guard let self else { return }
            guard
                let json = res as? [String: Any],
                let points = json["points"] as? [[String: Any]]
            else {
                self.status = "Market: no response"
                return
            }

            let parsed: [Candle] = points.compactMap { Candle.from(json: $0) }
            if !parsed.isEmpty {
                self.candles = parsed
            }
        }
    }

    func runPaperTrade() {
        guard API.token != nil else {
            status = "Login required to trade"
            return
        }
        status = "Placing paper trade…"
        API.post("/trade/paper", body: nil) { [weak self] res in
            guard let self else { return }
            if let json = res as? [String: Any] {
                if let newBalance = json["balance"] as? Double {
                    self.balance = newBalance
                }
                self.status = "Trade placed"
            } else {
                self.status = "Trade failed"
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .foregroundStyle(valueColor)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct Candle: Identifiable {
    let id = UUID()
    let t: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double

    var isUp: Bool { close >= open }

    static func from(json: [String: Any]) -> Candle? {
        let t = json["t"] as? Int ?? (json["t"] as? Double).map(Int.init)
        guard let t else { return nil }

        // New format: open/high/low/close
        let open = json["open"] as? Double
        let high = json["high"] as? Double
        let low = json["low"] as? Double
        let close = json["close"] as? Double

        if let open, let high, let low, let close {
            return Candle(t: t, open: open, high: high, low: low, close: close)
        }

        // Fallback for older backend: close-only
        if let close = json["close"] as? Double {
            return Candle(t: t, open: close, high: close, low: close, close: close)
        }

        return nil
    }
}

struct CandleChart: View {
    let candles: [Candle]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minV = candles.map { $0.low }.min() ?? 0
            let maxV = candles.map { $0.high }.max() ?? 1
            let span = max(maxV - minV, 0.000001)

            func y(_ v: Double) -> CGFloat {
                let yn = (v - minV) / span
                return h * (1 - CGFloat(yn))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                // Subtle horizontal grid
                Path { path in
                    let lines = 4
                    for i in 0...lines {
                        let yy = h * CGFloat(i) / CGFloat(lines)
                        path.move(to: CGPoint(x: 10, y: yy))
                        path.addLine(to: CGPoint(x: w - 10, y: yy))
                    }
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 1)

                Canvas { ctx, size in
                    guard !candles.isEmpty else { return }

                    let count = candles.count
                    let step = (w - 20) / CGFloat(max(count, 1))
                    let bodyW = max(3, min(step * 0.65, 12))

                    for (i, c) in candles.enumerated() {
                        let cx = 10 + step * (CGFloat(i) + 0.5)
                        let openY = y(c.open)
                        let closeY = y(c.close)
                        let highY = y(c.high)
                        let lowY = y(c.low)

                        let color: Color = c.isUp ? .green : .red

                        // Wick
                        var wick = Path()
                        wick.move(to: CGPoint(x: cx, y: highY))
                        wick.addLine(to: CGPoint(x: cx, y: lowY))
                        ctx.stroke(wick, with: .color(color.opacity(0.9)), lineWidth: 1)

                        // Body
                        let top = min(openY, closeY)
                        let bottom = max(openY, closeY)
                        let bodyH = max(1.5, bottom - top)
                        let rect = CGRect(x: cx - bodyW / 2, y: top, width: bodyW, height: bodyH)

                        if bodyH <= 2 {
                            ctx.stroke(Path(roundedRect: rect, cornerRadius: 1), with: .color(color.opacity(0.95)), lineWidth: 2)
                        } else {
                            ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color.opacity(0.85)))
                        }
                    }
                }
            }
        }
    }
}
