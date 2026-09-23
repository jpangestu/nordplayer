# Testing Fakes & Test Doubles

This directory houses reusable test fakes, mocks, and fixtures for Nordplayer unit and widget tests, adhering to Flutter's recommended application testing architecture (as demonstrated in the Compass case study).

## Guidelines
- Define fakes that implement abstract interfaces from package:nordplayer/data/repositories/ and package:nordplayer/data/services/.
- Use in-memory state in fakes to make unit and widget tests deterministic and fast without platform dependencies.
