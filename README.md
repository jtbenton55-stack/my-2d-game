# Untitled Heist RPG - Birthday Gift Game

## 🎮 **Game Overview**
A top-down 2D action RPG/heist roguelite created as a birthday gift. Features 5 unique missions, friend progression system (Hades-inspired), and Scheme Cards (Balatro-inspired).

## 🎭 **Genre & Tone**
Top-down action RPG with Hades-style meta-loop structure. Each heist is a compact run with stealth, combat, light puzzles, and an objective.

**Tone:** Stylish, playful, romantic noir crime thriller. Think Hades meets Ocean's Eleven meets cozy crime drama.

## 📁 **Project Location**
`/home/node/.openclaw/workspace/games/my-2d-game/`

## 🚀 **How to Open & Play**
1. **Open Godot 4.x** (version 4.2 or later)
2. **Click "Import"** or "Open"
3. **Navigate to:** `/home/node/.openclaw/workspace/games/my-2d-game/`
4. **Select `project.godot`**
5. **Click Play (F5)** or export to your platform

## 🎮 **Controls**

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD | Left Stick |
| Dodge | Space | B/Circle |
| Attack | Left Click | A/Cross |
| Interact | E | Y/Triangle |
| Stealth | Shift | L2 |
| Pause | Escape | Start |

## 🎯 **Game Features**

### **✅ COMPLETE SYSTEMS:**
- **5 Unique Missions** with different gameplay styles
- **16 Scheme Cards** (8 MVP + 8 stretch) with effects
- **Friend Progression System** - Help friends, they help you back
- **Save/Load System** with 3 slots
- **Collectible System** - Polaroids, trinkets, stationery
- **Dialogue System** with portraits and branching
- **3 Enemy Types** - Guard, Goon, Bruiser
- **2 Puzzle Types** - Music sequence, Screenwriting multiple choice
- **Car Chase Mission** - Different gameplay style

### **🎮 Mission List:**
1. **Taco Bell Drop** - Help Louis recover his delivery bag (goons, sniff trail)
2. **Velvet Paw Jazz Club** - Steal blackmail ledger (music puzzle, Bruiser enemy)
3. **The Rewrite Room** - Recover screenplay documents (screenwriting puzzle)
4. **Fast Family Getaway** - Help Dom escape (car chase sequence)
5. **Sterling Tower Heist** - Final boss, friend-favor system

### **🃏 Scheme Cards (16 total):**
- **MVP Cards (8):** Bentley's Dental Boy, Fish Treat Focus, Jake's Resident Orders, Louis Delivery Route, Mere's Legal Eyes, Yordano Bass Drop, Stationery Queen, Dom's Getaway Keys
- **Stretch Cards (8):** Persian Tea Focus, JC's London Contact, Bryce's Swiss Timing, Clorox Wipe Protocol, Two Letters Away, Diamond a Year, Polaroid Proof, Violet's Counterpunch

## 🛠️ **Technical Details**

### **Godot Version:** 4.x

### **Project Structure:**
```
games/my-2d-game/
├── project.godot              # Main project file
├── scenes/                   # All game scenes
│   ├── TitleScreen.tscn      # Entry point
│   ├── hideout/              # Hideout hub
│   ├── missions/             # All 5 mission scenes
│   ├── ui/                   # UI scenes
│   └── characters/           # Character scenes
├── src/                      # Source code
│   ├── autoload/            # Singletons (GameState, SaveManager, etc.)
│   ├── missions/            # Mission scripts (5 missions)
│   ├── inventory/           # Card system
│   ├── collectibles/        # Collectible system
│   ├── dialogue/            # Dialogue system
│   ├── enemies/             # Enemy scripts
│   ├── levels/              # Level base classes
│   ├── player/              # Player controller
│   ├── ui/                  # UI scripts
│   └── utils/               # Utilities
└── assets/                  # Placeholder assets
```

### **Key Autoloads:**
- `GameState` - Player progression, missions, cards, friend favors
- `SaveManager` - JSON save/load system
- `CardManager` - Scheme Card management
- `DialogueManager` - Dialogue system
- `EventBus` - Signal hub for decoupled communication
- `CollectibleManager` - Collectible tracking

## 🧪 **Testing Instructions**

### **Basic Test:**
1. Start New Game from Title Screen
2. Go to Hideout → Mission Board
3. Select Mission 1 (Taco Bell Drop)
4. Draft 3 Scheme Cards
5. Complete mission → See rewards
6. Return to Hideout → Save game
7. Repeat with other missions

### **Advanced Test:**
1. Complete Missions 1-4 to help all friends
2. Play Mission 5 (Sterling Tower Heist)
3. Verify friend-favor bypasses work:
   - Louis: Delivery entrance bypass
   - Mere: Legal department keycard
   - Yordano: Camera distraction
   - Dom: Getaway vehicle
   - Jake: Elevator override
4. Defeat Victor Sterling (final boss)

## 🎨 **Art & Audio Status**
- **Visuals:** Placeholder polygons/icons throughout
- **Audio:** Framework exists, needs assets
- **Dialogue:** System complete, needs JSON content files

## ⚠️ **Known Issues**
1. **Placeholder art** - All visuals are simple polygons/icons
2. **Missing audio** - AudioManager exists but no sound files
3. **Dialogue content** - System works but needs JSON files
4. **Balance tuning** - Difficulty/rewards need playtesting

## 🚀 **Next Steps for Polish**

### **Priority 1 (Content):**
1. Create dialogue JSON files for 14+ characters
2. Add actual artwork (replace placeholders)
3. Add sound effects and music

### **Priority 2 (Polish):**
1. Balance mission difficulty
2. Tune card effects
3. Add particle effects
4. Improve UI/UX

### **Priority 3 (Features):**
1. Add more collectibles
2. Implement Bentley ability system
3. Add more Scheme Cards
4. Create additional missions

## 📊 **Development Stats**
- **Development Time:** ~2.5 hours (swarm AI agents)
- **Lines of Code:** ~3,300+ across mission scripts
- **Files Created:** 30+ GDScript, 10+ scenes
- **Agents Used:** brain, minimax, game, hands, glm
- **Completion Date:** 2026-04-27

## 🎂 **Birthday Gift Context**
This game was created as a **birthday gift for Jake's fiancée** who loves:
- Balatro (card mechanics inspiration)
- Hades (failure progression inspiration)
- Roguelike replayability
- Action movies and anime
- Her Shiba Inu (Bentley in-game)

## 📞 **Support & Contact**
- **OpenClaw Project:** `/home/node/.openclaw/workspace/`
- **Game Docs:** `/home/node/.openclaw/workspace/docs/`
- **Progress Reports:** `SWARM_PROGRESS_*.md` files

## 📚 **Design Docs**
- `docs/game-design/CREATIVE_DIRECTION.md` - Vision, tone, pillars
- `docs/game-design/TECHNICAL_ARCHITECTURE.md` - Systems, data flow, milestones
- `docs/CHANGELOG.md` - Development progress and changes

---

**Enjoy the game! Happy birthday!** 🎂🎮

*Created with ❤️ by the OpenClaw AI swarm (brain, minimax, game, hands, glm)*