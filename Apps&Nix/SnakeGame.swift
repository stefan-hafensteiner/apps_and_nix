import SwiftUI

struct SnakeGame: View {
    // Spielzustand
    @State private var snakePositions: [CGPoint] = [CGPoint(x: 140, y: 200)]
    @State private var direction: Direction = .right
    @State private var foodPosition: CGPoint = CGPoint(x: 180, y: 200)
    @State private var gameOver: Bool = false
    @State private var timer: Timer? = nil
    @State private var isPaused: Bool = false
    
    // Punkte und Highscore
    @State private var score: Int = 0
    @State private var highScore: Int = UserDefaults.standard.integer(forKey: "HighScore")
    @State private var highScorePlayer: String = UserDefaults.standard.string(forKey: "HighScorePlayer") ?? "-"
    @State private var isNewHighScore: Bool = false
    @State private var playerName: String = ""
    
    enum Direction {
        case up, down, left, right
    }
    
    // Rastergröße
    let gridSize: CGFloat = 20
    
    // Rahmen- und Grenzlinienbreite
    let borderWidth: CGFloat = 4
    let boundaryWidth: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Punkteanzeige und Highscore
                HStack {
                    VStack(alignment: .leading) {
                        Text("Punkte: \(score)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Highscore: \(highScore) \(highScorePlayer)")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                }
                .padding([.leading, .top], 20)
                
                // Pause und Neustart Buttons oberhalb des Spielfelds
                HStack {
                    Button(action: {
                        togglePause()
                    }) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Button(action: {
                        restartGame()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                Spacer()
                
                ZStack {
                    // Schwarzer Hintergrund
                    Color.black

                    
                    // Weiße Grenzlinie innerhalb des weißen Rahmens
                    Rectangle()
                        .stroke(Color.white, lineWidth: boundaryWidth)
                        .frame(width: min(geometry.size.width, geometry.size.height) - 40 - 2 * borderWidth,
                               height: min(geometry.size.width, geometry.size.height) - 40 - 2 * borderWidth)
                        .position(x: (min(geometry.size.width, geometry.size.height) - 40) / 2,
                                  y: (min(geometry.size.width, geometry.size.height) - 40) / 2)
                    
                    // Schlange und Essen
                    ForEach(snakePositions, id: \.self) { position in
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: gridSize, height: gridSize)
                            .position(position)
                    }
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: gridSize, height: gridSize)
                        .position(foodPosition)
                    
                    // Game Over Meldung
                    if gameOver {
                        VStack {
                            Text("Game Over")
                                .font(.custom("Courier", size: 40))
                                .foregroundColor(.green)
                            
                            Text("Punkte: \(score)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if score >= highScore {
                                VStack {
                                    Text("Neuer Highscore!")
                                        .font(.headline)
                                        .foregroundColor(.yellow)
                                    
                                    TextField("Dein Name", text: $playerName, onCommit: {
                                        saveHighScore()
                                    })
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding()
                                    
                                    Button(action: {
                                        saveHighScore()
                                    }) {
                                        Text("Speichern")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(5)
                                    }
                                }
                                .padding()
                            } else {
                                Text("Highscore: \(highScore) \(highScorePlayer)")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .frame(width: min(geometry.size.width, geometry.size.height) - 40,
                               height: min(geometry.size.width, geometry.size.height) - 40)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if isPaused { return }
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            
                            if abs(horizontal) > abs(vertical) {
                                if horizontal > 0 && direction != .left {
                                    direction = .right
                                } else if horizontal < 0 && direction != .right {
                                    direction = .left
                                }
                            } else {
                                if vertical > 0 && direction != .up {
                                    direction = .down
                                } else if vertical < 0 && direction != .down {
                                    direction = .up
                                }
                            }
                        }
                )
                .padding()
                
                // Platz für die Item-Bar
                Spacer()
                    .frame(height: 100) // Anpassbare Höhe für die Item-Bar
            }
            .onAppear(perform: startGame)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    func startGame() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            if !isPaused && !gameOver {
                moveSnake()
                checkCollision()
            }
        }
    }
    
    func moveSnake() {
        guard let head = snakePositions.first else { return }
        var newHead = head
        
        switch direction {
        case .up:
            newHead.y -= gridSize
        case .down:
            newHead.y += gridSize
        case .left:
            newHead.x -= gridSize
        case .right:
            newHead.x += gridSize
        }
        
        // Hinzufügen des neuen Kopfes
        snakePositions.insert(newHead, at: 0)
        
        if isOnFood(newHead) {
            generateFood()
            score += 1
            if score > highScore {
                highScore = score
                isNewHighScore = true
                // Entferne das Stoppen des Spiels beim Erreichen eines neuen Highscores
                // timer?.invalidate()
            }
            // Kein Entfernen des letzten Elements, um die Schlange zu verlängern
        } else {
            snakePositions.removeLast()
        }
    }
    
    func isOnFood(_ position: CGPoint) -> Bool {
        let snakeX = Int(position.x / gridSize)
        let snakeY = Int(position.y / gridSize)
        let foodX = Int(foodPosition.x / gridSize)
        let foodY = Int(foodPosition.y / gridSize)
        return snakeX == foodX && snakeY == foodY
    }
    
    func checkCollision() {
        guard let head = snakePositions.first else { return }
        
        // Berechnungen zur Spielfeldbegrenzung
        let gameSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 40
        let minX = borderWidth + boundaryWidth + gridSize / 2
        let maxX = gameSize - borderWidth - boundaryWidth - gridSize / 2
        let minY = borderWidth + boundaryWidth + gridSize / 2
        let maxY = gameSize - borderWidth - boundaryWidth - gridSize / 2
        
        // Wandkollision
        if head.x < minX || head.x > maxX ||
            head.y < minY || head.y > maxY {
            gameOver = true
            timer?.invalidate()
        }
        
        // Selbstkollision
        if snakePositions.dropFirst().contains(head) {
            gameOver = true
            timer?.invalidate()
        }
    }
    
    func generateFood() {
        let gameSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 40
        let minX = borderWidth + boundaryWidth + gridSize / 2
        let maxX = gameSize - borderWidth - boundaryWidth - gridSize / 2
        let minY = borderWidth + boundaryWidth + gridSize / 2
        let maxY = gameSize - borderWidth - boundaryWidth - gridSize / 2
        
        // Berechnung der minimalen und maximalen Rasterkoordinaten
        let minGridX = Int(ceil(minX / gridSize))
        let maxGridX = Int(floor(maxX / gridSize))
        let minGridY = Int(ceil(minY / gridSize))
        let maxGridY = Int(floor(maxY / gridSize))
        
        var newX: CGFloat
        var newY: CGFloat
        repeat {
            newX = CGFloat(Int.random(in: minGridX...maxGridX)) * gridSize
            newY = CGFloat(Int.random(in: minGridY...maxGridY)) * gridSize
        } while snakePositions.contains(CGPoint(x: newX, y: newY))
        
        foodPosition = CGPoint(x: newX, y: newY)
    }
    
    func togglePause() {
        isPaused.toggle()
    }
    
    func restartGame() {
        let gameSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 40
        snakePositions = [CGPoint(x: gameSize / 2, y: gameSize / 2)]
        direction = .right
        foodPosition = CGPoint(x: gameSize / 2 + gridSize * 2, y: gameSize / 2)
        gameOver = false
        isPaused = false
        score = 0
        isNewHighScore = false
        playerName = ""
        timer?.invalidate()
        startGame()
    }
    
    func saveHighScore() {
        if !playerName.isEmpty {
            UserDefaults.standard.set(highScore, forKey: "HighScore")
            UserDefaults.standard.set(playerName, forKey: "HighScorePlayer")
            highScorePlayer = playerName
            isNewHighScore = false
            playerName = ""
        }
    }
}

struct SnakeGame_Previews: PreviewProvider {
    static var previews: some View {
        SnakeGame()
    }
} 
