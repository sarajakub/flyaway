# FlyAway - Healing Journey App

A mindful iOS app for emotional healing and personal growth. Write or vocalize thoughts, send them into the ether, or hold onto them. Connect with others on their healing journey.

<div align="center">
  <img width="240" height="524" alt="create-thought-020525" src="https://github.com/user-attachments/assets/da0a210b-3702-4cb4-90d7-31e4c4111b82">
  <br>
  <sub>Thought Creation Page</sub>
</div>

## Features

### 🌟 Core Features
- **Thought Creation**: Write or vocalize your thoughts
- **Send to Ether**: Release thoughts immediately into the void
- **Temporary Storage**: Keep thoughts for a set period (1, 7, 30, or 90 days)
- **Permanent Storage**: Save thoughts indefinitely
- **Public/Private**: Control visibility of your thoughts

### 👥 Community
- **Public Feed**: Browse public thoughts from others
- **Save Thoughts**: Bookmark thoughts that resonate with you
- **Follow Journeys**: Follow others' healing paths
- **Categories**: Breakup, Grief, Anxiety, Healing, Gratitude, Reflection

### 🧘 Mindfulness Resources
- **Meditation**: Guided meditations for healing
- **Breathwork**: Breathing exercises for anxiety and stress
- **Journaling**: Prompts and guidance
- **Affirmations**: Positive affirmations for healing

## Tech Stack

- **SwiftUI**: Modern declarative UI framework
- **Firebase**: Backend services
  - Authentication: User management
  - Firestore: Database
  - Storage: Audio files
- **AVFoundation**: Audio recording and playback

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- CocoaPods
- Firebase account

### Installation

1. Clone the repository
```bash
cd flyaway
```

2. Install dependencies
```bash
pod install
```

3. Open the workspace
```bash
open FlyAway.xcworkspace
```

4. Configure Firebase
   - Create a new Firebase project at https://console.firebase.google.com
   - Add an iOS app to your Firebase project
   - Download `GoogleService-Info.plist`
   - Add the file to your Xcode project

5. Build and run the app

## Project Structure

```
FlyAway/
├── Models/
│   ├── Thought.swift
│   ├── User.swift
│   └── MindfulnessResource.swift
├── Services/
│   ├── AuthenticationManager.swift
│   └── ThoughtManager.swift
├── Views/
│   ├── Authentication/
│   │   └── AuthenticationView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ThoughtCard.swift
│   ├── Create/
│   │   └── CreateThoughtView.swift
│   ├── Community/
│   │   └── CommunityView.swift
│   ├── Mindfulness/
│   │   ├── MindfulnessView.swift
│   │   └── MindfulnessDetailView.swift
│   └── Profile/
│       └── ProfileView.swift
├── FlyAwayApp.swift
└── ContentView.swift
```

## Usage

### Creating a Thought
1. Tap the "Create" tab
2. Write your thought or use voice input
3. Select a category
4. Choose visibility (public/private)
5. Decide to send to ether or keep for a duration
6. Release your thought

### Browsing Community
1. Navigate to "Community" tab
2. Filter by category
3. Search for specific topics
4. Save thoughts that resonate with you

### Mindfulness Practice
1. Go to "Mindfulness" tab
2. Choose a resource type
3. Select a practice
4. Follow the guided session

## Future Enhancements

- [ ] Voice recording and playback
- [ ] Push notifications for thought expiration
- [ ] Analytics and insights dashboard
- [ ] Custom meditation creation
- [ ] Chat/messaging between users
- [ ] Badges and achievements
- [ ] Dark mode optimization
- [ ] Offline mode support
- [ ] Export thoughts as PDF/journal

## Contributing

This is a personal project, but suggestions and feedback are welcome!

## License

Private - All rights reserved

## Privacy

FlyAway takes privacy seriously. Thoughts marked as "Send to Ether" are automatically deleted and cannot be recovered. Public thoughts are visible to all users. Private thoughts are only visible to you.

## Support

For support or questions, please contact the developer.

---

Built with ❤️ for healing and growth
