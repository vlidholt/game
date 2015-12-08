part of game;

class PersistantGameState {
  int coins = 200;

  int powerupLevel(PowerUpType type) {
    return 1;
  }

  int currentStartingLevel = 0;
  int maxStartingLevel = 0;

  int _lastScore = 0;

  int get lastScore => _lastScore;

  set lastScore(int lastScore) {
    _lastScore = lastScore;
    if (lastScore > weeklyBestScore)
      weeklyBestScore = lastScore;
  }

  int weeklyBestScore = 0;
}
