

import SwiftUI
import Foundation


// Serializable color representation
struct SerializableColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(color: Color) {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
        #else
        // Fallback for other platforms
        self.red = 0.5
        self.green = 0.5
        self.blue = 0.5
        self.alpha = 1.0
        #endif
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    // Predefined colors
    static let red = SerializableColor(color: .red)
    static let blue = SerializableColor(color: .blue)
    static let green = SerializableColor(color: .green)
    static let yellow = SerializableColor(color: .yellow)
    static let purple = SerializableColor(color: .purple)
    static let orange = SerializableColor(color: .orange)
    static let pink = SerializableColor(color: .pink)
    static let teal = SerializableColor(color: .teal)
    static let mint = SerializableColor(color: .mint)
    static let cyan = SerializableColor(color: .cyan)
    static let brown = SerializableColor(color: .brown)
    static let gray = SerializableColor(color: .gray)
}

struct GameColor: Identifiable, Codable, Hashable {
    let id: UUID
    let serializableColor: SerializableColor
    let name: String
    
    // Computed property for SwiftUI Color
    var color: Color {
        serializableColor.color
    }
    
    init(id: UUID = UUID(), color: Color, name: String) {
        self.id = id
        self.serializableColor = SerializableColor(color: color)
        self.name = name
    }
    
    // Predefined colors
    static let red = GameColor(color: .red, name: "Red")
    static let blue = GameColor(color: .blue, name: "Blue")
    static let green = GameColor(color: .green, name: "Green")
    static let yellow = GameColor(color: .yellow, name: "Yellow")
    static let purple = GameColor(color: .purple, name: "Purple")
    static let orange = GameColor(color: .orange, name: "Orange")
    static let pink = GameColor(color: .pink, name: "Pink")
    static let teal = GameColor(color: .teal, name: "Teal")
    static let mint = GameColor(color: .mint, name: "Mint")
    static let cyan = GameColor(color: .cyan, name: "Cyan")
    static let brown = GameColor(color: .brown, name: "Brown")
    static let gray = GameColor(color: .gray, name: "Gray")
}

struct GameLevel: Identifiable, Codable {
    let id: UUID
    let name: String
    let difficulty: Difficulty
    let targetColors: [GameColor]
    let maxTaps: Int
    let gridSize: Int
    let initialGrid: [[Int]]
    
    init(id: UUID = UUID(), name: String, difficulty: Difficulty, targetColors: [GameColor], maxTaps: Int, gridSize: Int, initialGrid: [[Int]]) {
        self.id = id
        self.name = name
        self.difficulty = difficulty
        self.targetColors = targetColors
        self.maxTaps = maxTaps
        self.gridSize = gridSize
        self.initialGrid = initialGrid
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }
}

struct Score: Identifiable, Codable {
    let id: UUID
    let levelName: String
    let score: Int
    let date: Date
    let tapsUsed: Int
    let completionPercent: Double
    let difficulty: Difficulty
    
    init(id: UUID = UUID(), levelName: String, score: Int, date: Date, tapsUsed: Int, completionPercent: Double, difficulty: Difficulty) {
        self.id = id
        self.levelName = levelName
        self.score = score
        self.date = date
        self.tapsUsed = tapsUsed
        self.completionPercent = completionPercent
        self.difficulty = difficulty
    }
}

struct UserStats: Codable {
    var totalGamesPlayed: Int = 0
    var completedLevels: Int = 0
    var totalScore: Int = 0
    var bestScore: Int = 0
    var averageCompletion: Double = 0
    var perfectGames: Int = 0
    var easyLevelsCompleted: Int = 0
    var mediumLevelsCompleted: Int = 0
    var hardLevelsCompleted: Int = 0
    var totalPlayTime: Int = 0
    var averageTapsUsed: Double = 0
    var currentStreak: Int = 0
    var lastPlayedDate: Date?
    
    var totalLevels: Int {
        return 6 // Based on our default levels
    }
    
    var completionPercentage: Double {
        return Double(completedLevels) / Double(totalLevels) * 100
    }
    
    var averageScore: Int {
        return totalGamesPlayed > 0 ? totalScore / totalGamesPlayed : 0
    }
    
    var successRate: Double {
        return totalGamesPlayed > 0 ? Double(perfectGames) / Double(totalGamesPlayed) * 100 : 0
    }
}

class GameData: ObservableObject {
    @Published var scores: [Score] = []
    @Published var levels: [GameLevel] = []
    @Published var userStats = UserStats()
    
    init() {
        loadScores()
        loadLevels()
        calculateStats()
    }
    
    func addScore(_ score: Score) {
        scores.append(score)
        saveScores()
        calculateStats()
        updateStreak()
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        if let lastPlayed = userStats.lastPlayedDate {
            if calendar.isDateInYesterday(lastPlayed) {
                userStats.currentStreak += 1
            } else if !calendar.isDateInToday(lastPlayed) {
                userStats.currentStreak = 1
            }
        } else {
            userStats.currentStreak = 1
        }
        
        userStats.lastPlayedDate = today
        saveScores()
    }
    
    private func saveScores() {
        if let encoded = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encoded, forKey: "colorBleedScores")
        }
        if let statsEncoded = try? JSONEncoder().encode(userStats) {
            UserDefaults.standard.set(statsEncoded, forKey: "colorBleedStats")
        }
    }
    
    private func loadScores() {
        if let data = UserDefaults.standard.data(forKey: "colorBleedScores"),
           let decoded = try? JSONDecoder().decode([Score].self, from: data) {
            scores = decoded
        }
        
        if let statsData = UserDefaults.standard.data(forKey: "colorBleedStats"),
           let statsDecoded = try? JSONDecoder().decode(UserStats.self, from: statsData) {
            userStats = statsDecoded
        }
    }
    
    private func loadLevels() {
        if levels.isEmpty {
            levels = GameData.createDefaultLevels()
        }
    }
    
    func calculateStats() {
        userStats.totalGamesPlayed = scores.count
        userStats.completedLevels = Set(scores.map { $0.levelName }).count
        userStats.totalScore = scores.reduce(0) { $0 + $1.score }
        userStats.bestScore = scores.map { $0.score }.max() ?? 0
        userStats.averageCompletion = scores.isEmpty ? 0 : scores.reduce(0) { $0 + $1.completionPercent } / Double(scores.count)
        userStats.perfectGames = scores.filter { $0.completionPercent >= 95 }.count
        userStats.averageTapsUsed = scores.isEmpty ? 0 : Double(scores.reduce(0) { $0 + $1.tapsUsed }) / Double(scores.count)
        
        // Calculate level completion by difficulty
        let easyLevels = levels.filter { $0.difficulty == .easy }
        let mediumLevels = levels.filter { $0.difficulty == .medium }
        let hardLevels = levels.filter { $0.difficulty == .hard }
        
        userStats.easyLevelsCompleted = Set(scores.filter { score in
            easyLevels.contains { $0.name == score.levelName }
        }.map { $0.levelName }).count
        
        userStats.mediumLevelsCompleted = Set(scores.filter { score in
            mediumLevels.contains { $0.name == score.levelName }
        }.map { $0.levelName }).count
        
        userStats.hardLevelsCompleted = Set(scores.filter { score in
            hardLevels.contains { $0.name == score.levelName }
        }.map { $0.levelName }).count
        
        saveScores()
    }
    
    func getRecentPerformance() -> [Double] {
        let recentScores = scores.suffix(5)
        return recentScores.map { Double($0.completionPercent) }
    }
    
    func getLevelStats(levelName: String) -> (plays: Int, bestScore: Int, avgCompletion: Double) {
        let levelScores = scores.filter { $0.levelName == levelName }
        let plays = levelScores.count
        let bestScore = levelScores.map { $0.score }.max() ?? 0
        let avgCompletion = levelScores.isEmpty ? 0 : levelScores.reduce(0) { $0 + $1.completionPercent } / Double(levelScores.count)
        
        return (plays, bestScore, avgCompletion)
    }
    
    static func createDefaultLevels() -> [GameLevel] {
        return [
            GameLevel(
                name: "Simple Shapes",
                difficulty: .easy,
                targetColors: [.red, .blue, .green],
                maxTaps: 10,
                gridSize: 6,
                initialGrid: Array(repeating: Array(repeating: 0, count: 6), count: 6)
            ),
            GameLevel(
                name: "Nature Scene",
                difficulty: .easy,
                targetColors: [.green, .yellow, .brown],
                maxTaps: 15,
                gridSize: 8,
                initialGrid: Array(repeating: Array(repeating: 0, count: 8), count: 8)
            ),
            GameLevel(
                name: "Cityscape",
                difficulty: .medium,
                targetColors: [.blue, .gray, .orange, .yellow],
                maxTaps: 20,
                gridSize: 10,
                initialGrid: Array(repeating: Array(repeating: 0, count: 10), count: 10)
            ),
            GameLevel(
                name: "Abstract Art",
                difficulty: .medium,
                targetColors: [.purple, .pink, .teal, .orange],
                maxTaps: 25,
                gridSize: 12,
                initialGrid: Array(repeating: Array(repeating: 0, count: 12), count: 12)
            ),
            GameLevel(
                name: "Complex Pattern",
                difficulty: .hard,
                targetColors: [.red, .green, .blue, .yellow, .purple],
                maxTaps: 30,
                gridSize: 15,
                initialGrid: Array(repeating: Array(repeating: 0, count: 15), count: 15)
            ),
            GameLevel(
                name: "Masterpiece",
                difficulty: .hard,
                targetColors: [.purple, .orange, .cyan, .mint, .pink, .teal],
                maxTaps: 35,
                gridSize: 18,
                initialGrid: Array(repeating: Array(repeating: 0, count: 18), count: 18)
            )
        ]
    }
}

class ToastManager: ObservableObject {
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .info
    
    enum ToastType {
        case success, error, info, warning
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    func show(message: String, type: ToastType = .info) {
        toastMessage = message
        toastType = type
        showToast = true
    }
}

struct SplashScreen: View {
    @State private var isActive = false
    @State private var scale = 0.7
    @State private var opacity = 0.0
    @State private var rotation = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue, Color.pink]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Animated Logo
                    ZStack {
                  
                        Image("box")
                            .resizable()
                            .frame(width: 100,height:100)
                        
                        
                    }
                    
                    VStack(spacing: 15) {
                        Text("ColorfulBleedy")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        Text("Bleed the Color")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .italic()
                    }
                    
                    // Loading dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .scaleEffect(scale)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: scale
                                )
                        }
                    }
                }
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var toastManager = ToastManager()
    @StateObject private var gameData = GameData()
    @State private var showPauseMenu = false
    @State private var currentGameView: AnyView?
    @State private var isShowingGame = false
    @State private var currentView: AppView = .dashboard
    
    enum AppView {
        case dashboard, play, scores, howToPlay
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.9), Color.pink.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main Content
            Group {
                switch currentView {
                case .dashboard:
                    DashboardView(
                        gameData: gameData,
                        onPlaySelected: { currentView = .play },
                        onScoresSelected: { currentView = .scores },
                        onHowToPlaySelected: { currentView = .howToPlay }
                    )
                    .transition(.opacity)
                    .padding(.top,20)
                    
                case .play:
                    LevelSelectionView(
                        onBack: { currentView = .dashboard },
                        onLevelSelected: startGame
                    )
                    .transition(.move(edge: .trailing))
                    
                case .scores:
                    ScoreboardView(onBack: { currentView = .dashboard })
                        .transition(.move(edge: .trailing))
                    
                case .howToPlay:
                    HowToPlayView(onBack: { currentView = .dashboard })
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentView)
            
            if isShowingGame {
                currentGameView?
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
            
            // Toast Message
            if toastManager.showToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: toastManager.toastType.icon)
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        Text(toastManager.toastMessage)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(toastManager.toastType.color)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: toastManager.showToast)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            toastManager.showToast = false
                        }
                    }
                }
            }
            
            // Pause Menu
            if showPauseMenu {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(2)
                
                VStack(spacing: 25) {
                    Text("Game Paused")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Button("Resume") {
                        withAnimation(.spring()) {
                            showPauseMenu = false
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Main Menu") {
                        withAnimation(.spring()) {
                            showPauseMenu = false
                            isShowingGame = false
                            currentView = .dashboard
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                )
                .padding(40)
                .transition(.scale.combined(with: .opacity))
                .zIndex(3)
            }
        }
        .environmentObject(toastManager)
        .environmentObject(gameData)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowingGame)
        .overlay(
            Group {
                if isShowingGame && !showPauseMenu {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    showPauseMenu.toggle()
                                }
                            }) {
                                Image(systemName: "pause.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.purple).padding(-8))
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .padding(.top, 10)
                            .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
        )
    }
    
    private func startGame(level: GameLevel) {
        let gameView = GameView(level: level, onGameEnd: { score in
            withAnimation(.spring()) {
                isShowingGame = false
                currentView = .dashboard
            }
            if let score = score {
                gameData.addScore(score)
                toastManager.show(message: "Level Complete! Score: \(score.score)", type: .success)
            }
        })
        
        currentGameView = AnyView(gameView)
        
        withAnimation(.spring()) {
            isShowingGame = true
        }
    }
}

// NEW IMPROVED DASHBOARD VIEW
struct DashboardView: View {
    @ObservedObject var gameData: GameData
    let onPlaySelected: () -> Void
    let onScoresSelected: () -> Void
    let onHowToPlaySelected: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header with Profile
                HeaderView(stats: gameData.userStats)
                
                // Quick Actions
                QuickActionsView(
                    onPlaySelected: onPlaySelected,
                    onScoresSelected: onScoresSelected,
                    onHowToPlaySelected: onHowToPlaySelected
                )
                
                // Progress Overview
                ProgressOverview(stats: gameData.userStats)
                
                // Performance Metrics
                PerformanceMetrics(stats: gameData.userStats)
                
                // Recent Activity
                if !gameData.scores.isEmpty {
                    RecentActivityView(scores: Array(gameData.scores.suffix(3)))
                }
                
                Spacer(minLength: 30)
            }
            .padding(.horizontal)
        }
    }
}

struct HeaderView: View {
    let stats: UserStats
    
    private var playerLevel: Int {
        return min(stats.totalGamesPlayed / 5 + 1, 10)
    }
    
    private var progressToNextLevel: Double {
        return Double(stats.totalGamesPlayed % 5) / 5.0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                // Player Avatar
                ZStack {
                
                    
                    Image("box")
                        .resizable()
                        .frame(width: 100,height:100)
                    
                    
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Play Color Bleed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("Lv. \(playerLevel)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(stats.currentStreak) days")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Spacer()
                
                // Total Score
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(stats.totalScore)")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.yellow)
                    
                    Text("Total Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Level Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to Level \(playerLevel + 1)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(Int(progressToNextLevel * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                ProgressView(value: progressToNextLevel, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct QuickActionsView: View {
    let onPlaySelected: () -> Void
    let onScoresSelected: () -> Void
    let onHowToPlaySelected: () -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
            ActionButton(
                title: "Play",
                subtitle: "Start Game",
                icon: "play.circle.fill",
                color: .green,
                action: onPlaySelected
            )
            
            ActionButton(
                title: "Scores",
                subtitle: "Leaderboard",
                icon: "chart.bar.fill",
                color: .blue,
                action: onScoresSelected
            )
            
            ActionButton(
                title: "How to Play",
                subtitle: "Learn",
                icon: "info.circle.fill",
                color: .orange,
                action: onHowToPlaySelected
            )
        }
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ProgressOverview: View {
    let stats: UserStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Game Progress Overview")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ProgressCard(
                    title: "Level Completion",
                    value: "\(stats.completedLevels)/\(stats.totalLevels)",
                    progress: stats.completionPercentage / 100,
                    color: .purple,
                    icon: "checkmark.circle.fill"
                )
                
                ProgressCard(
                    title: "Perfect Games",
                    value: "\(stats.perfectGames)",
                    progress: Double(stats.perfectGames) / Double(max(stats.totalGamesPlayed, 1)),
                    color: .yellow,
                    icon: "star.fill"
                )
                
                ProgressCard(
                    title: "Games Played",
                    value: "\(stats.totalGamesPlayed)",
                    progress: min(Double(stats.totalGamesPlayed) / 50.0, 1.0),
                    color: .blue,
                    icon: "gamecontroller.fill"
                )
                
                ProgressCard(
                    title: "Success Rate",
                    value: "\(Int(stats.successRate))%",
                    progress: stats.successRate / 100,
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct ProgressCard: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 1.2, anchor: .center)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}


struct PerformanceMetrics: View {
    let stats: UserStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Game Performance Metrics")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Best Score",
                    value: "\(stats.bestScore)",
                    icon: "trophy.fill",
                    color: .yellow,
                    isSystemImage: true
                )
                
                MetricCard(
                    title: "Avg Score",
                    value: "\(stats.averageScore)",
                    icon: "number.circle.fill",
                    color: .blue,
                    isSystemImage: true
                )
                
                MetricCard(
                    title: "Avg Completion",
                    value: "\(Int(stats.averageCompletion))%",
                    icon: "percent",
                    color: .green,
                    isSystemImage: true
                )
                
                MetricCard(
                    title: "Avg Taps",
                    value: "\(Int(stats.averageTapsUsed))",
                    icon: "hand.tap.fill",
                    color: .orange,
                    isSystemImage: true
                )
                
                MetricCard(
                    title: "Easy Levels",
                    value: "\(stats.easyLevelsCompleted)/2",
                    icon: "🟢",
                    color: .green,
                    isSystemImage: false
                )
                
                MetricCard(
                    title: "Hard Levels",
                    value: "\(stats.hardLevelsCompleted)/2",
                    icon: "🔴",
                    color: .red,
                    isSystemImage: false
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isSystemImage: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            if isSystemImage {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            } else {
                Text(icon)
                    .font(.system(size: 20))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}



struct RecentActivityView: View {
    let scores: [Score]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Game Plays")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                ForEach(scores) { score in
                    RecentActivityRow(score: score)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct RecentActivityRow: View {
    let score: Score
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: score.date, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "paintbrush.fill")
                .font(.caption)
                .foregroundColor(score.difficulty.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(score.levelName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(score.completionPercent, specifier: "%.1f")% • \(score.tapsUsed) taps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score.score)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yellow)
                
                Text(timeAgo)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

// Enhanced Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: .purple.opacity(0.5), radius: configuration.isPressed ? 5 : 10, x: 0, y: configuration.isPressed ? 2 : 5)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.purple)
            .font(.headline)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Color.white)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


// Updated LevelSelectionView with back button
struct LevelSelectionView: View {
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var gameData: GameData
    let onBack: () -> Void
    let onLevelSelected: (GameLevel) -> Void
    
    var body: some View {
        VStack {
            // Custom Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                }
                
                Spacer()
                
                Text("Select Level")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Invisible spacer for balance
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if gameData.levels.isEmpty {
                Spacer()
                ProgressView("Loading Levels...")
                    .scaleEffect(1.2)
                    .foregroundColor(.white)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(gameData.levels) { level in
                            LevelCard(
                                level: level,
                                bestScore: bestScore(for: level.name),
                                onSelect: { onLevelSelected(level) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    private func bestScore(for levelName: String) -> Int? {
        gameData.scores
            .filter { $0.levelName == levelName }
            .map { $0.score }
            .max()
    }
}


// Updated ScoreboardView with modern card design
struct ScoreboardView: View {
    @EnvironmentObject var gameData: GameData
    @State private var selectedFilter = "All Levels"
    @State private var selectedTimeFilter = "All Time"
    let onBack: () -> Void
    
    var filteredScores: [Score] {
        var scores = gameData.scores
        
        // Filter by level
        if selectedFilter != "All Levels" {
            scores = scores.filter { $0.levelName == selectedFilter }
        }
        
        // Filter by time
        if selectedTimeFilter != "All Time" {
            let calendar = Calendar.current
            let now = Date()
            
            switch selectedTimeFilter {
            case "Today":
                scores = scores.filter { calendar.isDateInToday($0.date) }
            case "This Week":
                scores = scores.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
            case "This Month":
                scores = scores.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            default:
                break
            }
        }
        
        return scores.sorted { $0.score > $1.score }
    }
    
    var levels: [String] {
        Array(Set(gameData.scores.map { $0.levelName })).sorted()
    }
    
    var timeFilters = ["All Time", "Today", "This Week", "This Month"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                Text("Scoreboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Invisible spacer for balance
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.clear)
                .padding(.horizontal, 16)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            if gameData.scores.isEmpty {
                EmptyScoreboardView()
            } else {
                VStack(spacing: 16) {
                    // Stats Summary
                    ScoreboardStatsView(scores: filteredScores)
                    
                    // Filters
                    VStack(spacing: 12) {
                        // Level Filter
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Level Filter")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(
                                        title: "All Levels",
                                        isSelected: selectedFilter == "All Levels",
                                        action: { selectedFilter = "All Levels" }
                                    )
                                    
                                    ForEach(levels, id: \.self) { level in
                                        FilterChip(
                                            title: level,
                                            isSelected: selectedFilter == level,
                                            action: { selectedFilter = level }
                                        )
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                        
                        // Time Filter
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time Period")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(timeFilters, id: \.self) { filter in
                                        FilterChip(
                                            title: filter,
                                            isSelected: selectedTimeFilter == filter,
                                            action: { selectedTimeFilter = filter }
                                        )
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Scores List
                    if filteredScores.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No Scores Found")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Try changing your filters to see more results")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filteredScores.enumerated()), id: \.element.id) { index, score in
                                    ScoreCard(score: score, rank: index + 1)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9), Color.pink.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

// Scoreboard Stats Summary
struct ScoreboardStatsView: View {
    let scores: [Score]
    
    private var totalGames: Int {
        scores.count
    }
    
    private var averageScore: Int {
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0) { $0 + $1.score } / scores.count
    }
    
    private var bestScore: Int {
        scores.map { $0.score }.max() ?? 0
    }
    
    private var perfectGames: Int {
        scores.filter { $0.completionPercent >= 95 }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                StatPill(
                    title: "Total Games",
                    value: "\(totalGames)",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
                
                StatPill(
                    title: "Best Score",
                    value: "\(bestScore)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatPill(
                    title: "Avg Score",
                    value: "\(averageScore)",
                    icon: "chart.bar.fill",
                    color: .green
                )
                
                StatPill(
                    title: "Perfect",
                    value: "\(perfectGames)",
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Updated Score Card Design
struct ScoreCard: View {
    let score: Score
    let rank: Int
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: score.date, relativeTo: Date())
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                if rank <= 3 {
                    Text(rankIcon)
                        .font(.system(size: 20))
                } else {
                    Text("\(rank)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(score.levelName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Difficulty Badge
                    Text(score.difficulty.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(score.difficulty.color.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("\(score.tapsUsed) taps")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "percent")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(Int(score.completionPercent))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Score with stars
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(score.score)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                HStack(spacing: 2) {
                    ForEach(0..<starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var starCount: Int {
        switch score.score {
        case 2000...: return 5
        case 1500..<2000: return 4
        case 1000..<1500: return 3
        case 500..<1000: return 2
        case 100..<500: return 1
        default: return 0
        }
    }
}

// Updated Empty Scoreboard View
struct EmptyScoreboardView: View {
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "trophy.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Scores Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Play some levels to see your scores here!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Your achievements will appear here after you complete levels")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxHeight: .infinity)
    }
}



// Updated HowToPlayView with back button
struct HowToPlayView: View {
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            // Custom Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                }
                
                Spacer()
                
                Text("How to Play")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Invisible spacer for balance
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {

                    GameplaySection()
                    ScoringSection()
                    TipsSection()
                }
                .padding()
                .padding(.top, 10)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

struct LevelCard: View {
    let level: GameLevel
    let bestScore: Int?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Level Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [level.difficulty.color.opacity(0.3), level.difficulty.color.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 120)
                    
                    // Color palette preview
                    HStack(spacing: 4) {
                        ForEach(level.targetColors.prefix(4)) { gameColor in
                            Circle()
                                .fill(gameColor.color)
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        }
                    }
                    
                    // Grid pattern overlay
                    GridPatternView(gridSize: level.gridSize, opacity: 0.3)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(level.difficulty.color, lineWidth: 3)
                )
                
                VStack(spacing: 8) {
                    Text(level.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text(level.difficulty.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(level.difficulty.color.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        Text("\(level.maxTaps) taps")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let bestScore = bestScore {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("Best: \(bestScore)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        HStack {
                            Image(systemName: "play.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("New Level")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct GridPatternView: View {
    let gridSize: Int
    let opacity: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let cellSize = geometry.size.width / CGFloat(gridSize)
                
                // Vertical lines
                for i in 0...gridSize {
                    let x = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                for i in 0...gridSize {
                    let y = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(opacity), lineWidth: 0.5)
        }
    }
}

struct ScoreRow: View {
    let score: Score
    let rank: Int
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 45, height: 45)
                
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(score.levelName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("\(score.tapsUsed) taps")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 4, height: 4)
                    
                    Text("\(Int(score.completionPercent))% complete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 4, height: 4)
                    
                    Text(score.date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(score.score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                HStack(spacing: 2) {
                    ForEach(0..<starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var starCount: Int {
        switch score.score {
        case 2000...: return 5
        case 1500..<2000: return 4
        case 1000..<1500: return 3
        case 500..<1000: return 2
        case 100..<500: return 1
        default: return 0
        }
    }
}

struct GameplaySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Gameplay")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            InstructionStep(
                number: 1,
                icon: "circle.lefthalf.filled",
                title: "Start with Grayscale",
                description: "Each level begins as a black and white grid waiting for your colorful touch. The goal is to colorize at least 95% of the grid."
            )
            
            InstructionStep(
                number: 2,
                icon: "hand.tap",
                title: "Select & Tap",
                description: "Choose a color from your palette and tap on empty gray cells. Each tap consumes one of your limited moves."
            )
            
            InstructionStep(
                number: 3,
                icon: "paintpalette",
                title: "Watch Colors Bleed",
                description: "When you tap a cell, the color 'bleeds' outward, coloring adjacent cells automatically. Plan your taps strategically!"
            )
            
            InstructionStep(
                number: 4,
                icon: "target",
                title: "Complete the Level",
                description: "Use your color palette wisely to cover the entire grid before running out of taps. Mix colors efficiently for maximum coverage."
            )
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct ScoringSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Scoring System")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            ScoringRule(
                icon: "checkmark.circle.fill",
                color: .green,
                title: "Base Completion",
                points: "+1000 points"
            )
            
            ScoringRule(
                icon: "hand.tap",
                color: .blue,
                title: "Taps Remaining",
                points: "+50 per unused tap"
            )
            
            ScoringRule(
                icon: "percent",
                color: .orange,
                title: "Completion Bonus",
                points: "+10 per % complete"
            )
            
            ScoringRule(
                icon: "clock.fill",
                color: .purple,
                title: "Speed Bonus",
                points: "+1 per second saved"
            )
            
            ScoringRule(
                icon: "star.fill",
                color: .yellow,
                title: "Perfect Bonus",
                points: "+500 for 100% completion"
            )
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pro Tips")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            TipItem(
                icon: "lightbulb.fill",
                color: .yellow,
                tip: "Start from the center and work outward - colors bleed in all directions!"
            )
            
            TipItem(
                icon: "lightbulb.fill",
                color: .yellow,
                tip: "Plan your color sequence - some colors might blend better in certain areas"
            )
            
            TipItem(
                icon: "lightbulb.fill",
                color: .yellow,
                tip: "Use contrasting colors for different sections to maximize visual coverage"
            )
            
            TipItem(
                icon: "lightbulb.fill",
                color: .yellow,
                tip: "Save your taps for strategic positions - each tap affects multiple cells"
            )
            
            TipItem(
                icon: "lightbulb.fill",
                color: .yellow,
                tip: "Watch the completion percentage and adjust your strategy accordingly"
            )
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct InstructionStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.purple)
                        .font(.body)
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }
}

struct ScoringRule: View {
    let icon: String
    let color: Color
    let title: String
    let points: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 32)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(points)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct TipItem: View {
    let icon: String
    let color: Color
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
            
            Text(tip)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }
}

// GameView needs to be updated to include difficulty in Score
struct GameView: View {
    let level: GameLevel
    let onGameEnd: (Score?) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var gameData: GameData
    
    @State private var grid: [[Int]]
    @State private var selectedColorIndex = 0
    @State private var tapsUsed = 0
    @State private var score = 0
    @State private var gameTime = 0
    @State private var isGameActive = true
    @State private var showGameOver = false
    @State private var completionPercent = 0.0
    @State private var timer: Timer?
    
    init(level: GameLevel, onGameEnd: @escaping (Score?) -> Void) {
        self.level = level
        self.onGameEnd = onGameEnd
        self._grid = State(initialValue: level.initialGrid)
    }
    
    var body: some View {
        
        ZStack {
            // Game background
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
            VStack(spacing: 20) {
                // Header with stats
                GameHeader(
                    level: level,
                    score: score,
                    tapsUsed: tapsUsed,
                    maxTaps: level.maxTaps,
                    time: gameTime,
                    completionPercent: completionPercent
                )
                .padding(.top,30)
                // Game grid
                GameGrid(
                    grid: grid,
                    colors: level.targetColors,
                    onCellTapped: handleCellTap
                )
                
                // Color palette
                ColorPalette(
                    colors: level.targetColors,
                    selectedIndex: selectedColorIndex,
                    onColorSelected: { index in
                        selectedColorIndex = index
                    }
                )
                
                // Game controls
                GameControls(
                    onReload: reloadGame,
                    onExit: { onGameEnd(nil) }
                )
            }
         
            .padding()
            .disabled(!isGameActive || showGameOver)
            
        }
            
            // Game Over Modal
            if showGameOver {
                GameOverModal(
                    score: score,
                    level: level,
                    tapsUsed: tapsUsed,
                    completionPercent: completionPercent,
                    onMenu: { onGameEnd(nil) },
                    onPlayAgain: reloadGame
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startTimer()
            updateCompletionPercent()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func handleCellTap(row: Int, col: Int) {
        guard isGameActive, !showGameOver else { return }
        guard tapsUsed < level.maxTaps else {
            toastManager.show(message: "No more taps left!", type: .warning)
            endGame()
            return
        }
        
        if grid[row][col] == 0 {
            // Apply color bleed effect
            applyColorBleed(from: row, col: col, colorIndex: selectedColorIndex + 1)
            tapsUsed += 1
            updateCompletionPercent()
            checkGameCompletion()
        } else {
            toastManager.show(message: "Already colored! Try empty space.", type: .info)
        }
    }
    
    private func applyColorBleed(from startRow: Int, col startCol: Int, colorIndex: Int) {
        var visited = Array(repeating: Array(repeating: false, count: level.gridSize), count: level.gridSize)
        var queue = [(startRow, startCol)]
        let bleedDistance = 2 // How far the color bleeds
        
        visited[startRow][startCol] = true
        
        while !queue.isEmpty {
            let (row, col) = queue.removeFirst()
            grid[row][col] = colorIndex
            
            // Check adjacent cells
            for (dr, dc) in [(0,1), (1,0), (0,-1), (-1,0)] {
                let newRow = row + dr
                let newCol = col + dc
                
                if newRow >= 0 && newRow < level.gridSize && newCol >= 0 && newCol < level.gridSize &&
                    !visited[newRow][newCol] && abs(newRow - startRow) <= bleedDistance && abs(newCol - startCol) <= bleedDistance {
                    visited[newRow][newCol] = true
                    queue.append((newRow, newCol))
                }
            }
        }
    }
    
    private func updateCompletionPercent() {
        let totalCells = level.gridSize * level.gridSize
        let coloredCells = grid.flatMap { $0 }.filter { $0 > 0 }.count
        completionPercent = Double(coloredCells) / Double(totalCells) * 100
    }
    
    private func checkGameCompletion() {
        if completionPercent >= 95.0 {
            calculateFinalScore()
            endGame()
            toastManager.show(message: "Perfect! Level Complete!", type: .success)
        } else if tapsUsed >= level.maxTaps {
            calculateFinalScore()
            endGame()
            toastManager.show(message: "Out of taps! Game Over.", type: .warning)
        }
    }
    
    private func calculateFinalScore() {
        let baseScore = 1000
        let tapBonus = (level.maxTaps - tapsUsed) * 50
        let completionBonus = Int(completionPercent * 10)
        let timeBonus = max(0, 300 - gameTime) // Bonus for faster completion
        let perfectBonus = completionPercent >= 100 ? 500 : 0
        
        score = baseScore + tapBonus + completionBonus + timeBonus + perfectBonus
    }
    
    private func endGame() {
        isGameActive = false
        timer?.invalidate()
        
        let finalScore = Score(
            levelName: level.name,
            score: score,
            date: Date(),
            tapsUsed: tapsUsed,
            completionPercent: completionPercent,
            difficulty: level.difficulty
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showGameOver = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            onGameEnd(finalScore)
        }
    }
    
    private func reloadGame() {
        grid = level.initialGrid
        tapsUsed = 0
        score = 0
        gameTime = 0
        completionPercent = 0.0
        selectedColorIndex = 0
        isGameActive = true
        showGameOver = false
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isGameActive && !showGameOver {
                gameTime += 1
            }
        }
    }
}

struct GameHeader: View {
    let level: GameLevel
    let score: Int
    let tapsUsed: Int
    let maxTaps: Int
    let time: Int
    let completionPercent: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(level.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(level.difficulty.rawValue) • \(level.gridSize)x\(level.gridSize)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            HStack(spacing: 20) {
                StatItem(icon: "hand.tap", value: "\(tapsUsed)/\(maxTaps)", color: .blue)
                StatItem(icon: "clock", value: "\(time)s", color: .green)
                StatItem(icon: "percent", value: "\(Int(completionPercent))%", color: .orange)
            }
            
            // Progress bar
            ProgressView(value: completionPercent, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(15)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

struct GameGrid: View {
    let grid: [[Int]]
    let colors: [GameColor]
    let onCellTapped: (Int, Int) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / CGFloat(grid.count)
            
            ZStack {
                // Grid background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                
                // Cells
                ForEach(0..<grid.count, id: \.self) { row in
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        let colorIndex = grid[row][col]
                        let color = colorIndex > 0 ? colors[colorIndex - 1].color : Color.gray.opacity(0.3)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                            .frame(width: cellSize - 2, height: cellSize - 2)
                            .position(
                                x: CGFloat(col) * cellSize + cellSize / 2,
                                y: CGFloat(row) * cellSize + cellSize / 2
                            )
                            .onTapGesture {
                                onCellTapped(row, col)
                            }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(2)
    }
}

struct ColorPalette: View {
    let colors: [GameColor]
    let selectedIndex: Int
    let onColorSelected: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, gameColor in
                Button(action: {
                    onColorSelected(index)
                }) {
                    ZStack {
                        Circle()
                            .fill(gameColor.color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedIndex == index ? 4 : 2)
                            )
                            .shadow(color: gameColor.color.opacity(0.5), radius: selectedIndex == index ? 8 : 4)
                        
                        if selectedIndex == index {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2)
                        }
                    }
                }
                .scaleEffect(selectedIndex == index ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedIndex)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(25)
    }
}

struct GameControls: View {
    let onReload: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button("Reload") {
                onReload()
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button("Exit") {
                onExit()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

struct GameOverModal: View {
    let score: Int
    let level: GameLevel
    let tapsUsed: Int
    let completionPercent: Double
    let onMenu: () -> Void
    let onPlayAgain: () -> Void
    
    var body: some View {
        Color.black.opacity(0.9)
            .ignoresSafeArea()
            .transition(.opacity)
        
        VStack(spacing: 25) {
            Text(completionPercent >= 95 ? "Level Complete! 🎉" : "Game Over")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                Text("Final Score")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(score)")
                    .font(.system(size: 60, weight: .black))
                    .foregroundColor(.yellow)
                    .shadow(color: .black, radius: 5)
            }
            
            VStack(spacing: 12) {
                StatRow(label: "Level:", value: level.name)
                StatRow(label: "Taps Used:", value: "\(tapsUsed)/\(level.maxTaps)")
                StatRow(label: "Completion:", value: "\(Int(completionPercent))%")
                StatRow(label: "Performance:", value: performanceRating)
            }
            
            HStack(spacing: 15) {
                Button("Main Menu") {
                    onMenu()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Play Again") {
                    onPlayAgain()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(30)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .padding(40)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var performanceRating: String {
        switch completionPercent {
        case 95...100: return "Perfect! 🌟"
        case 80..<95: return "Great! 👍"
        case 60..<80: return "Good 👏"
        default: return "Keep Trying 💪"
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .font(.body)
    }
}
