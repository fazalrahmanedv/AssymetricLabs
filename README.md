# Infinity Quiz

## Overview

Infinity Quiz is a simple yet engaging quiz application developed for iOS, adhering to best practices in iOS development. The app follows the MVVM design pattern and utilizes Swift, SwiftUI, and CoreData. The goal is to provide a clean, responsive user interface that supports various screen sizes while integrating haptics, bookmarking, and sharing features.

## App Features

### Home Screen

- **Design:** Simple and clean layout.
- **Primary Button:** `Start Test`
  - Navigates to the first question of the quiz.
- **Secondary Button:** `Bookmark`
  - Allows users to solve only bookmarked questions.
- **Choose Country:**
  - Fetch and display a list of countries using a public API.

### Test Screen

- Displays quiz instructions.
- fetching quiz data and manipulatig to get relevant error free quiz data
- Navigates to  question screen.
#### Question Sub-Screen

- Displays one multiple-choice question at a time.
- Users will habe a specific time to finish a questions duration is defined  by custom ML model.
- Provides four answer options.
- Shows a timer bar indicating the remaining time.
- Upon selecting an answer:
  - Navigates automatically to the Answer Explanation Screen.
- Every 5 questions, Displays A summary screen with score details

#### Answer Explanation Sub-Screen

- Displays whether the selected answer was correct or incorrect.
- Provides a brief explanation for the answer.

### Score Screen

- Displays the user's performance, including total correct and incorrect answers.
- Allows users to retake the quiz or review bookmarked questions.

## Technical Specifications

### Navigation

- Uses `NavigationStack` in SwiftUI for screen transitions.

### Responsive UI

- Designed with SwiftUI to support different screen sizes and orientations.
- Follows Apple’s Human Interface Guidelines for accessibility and consistency.

### Data Management

- Efficiently loads questions using a structured data model.
- Uses CoreData to store bookmarks and manage local data.
- Implements state management using `ObservableObject` and `@State`.

### Bookmark and Share Features

- Bookmarks questions in CoreData and updates the UI in real-time.

### Clean Architecture (MVVM)

- Implements the MVVM pattern for a clear separation of concerns.
- Business logic is managed in ViewModels, while SwiftUI views handle rendering.

## API Endpoint

- **Endpoint:** `https://6789df4ddd587da7ac27e4c2.mockapi.io/api/v1/mcq/content`
- **Parameters:**
  - `questionType` and `contentType` determine the data type received in `question` and `contentData` parameters.
- **Types:**
  - `text` – Plain text
  - `htmlText` – HTML text (use WebView or rich text rendering in SwiftUI)
  - `image` – Image URL

### Sample Response

```json
{
  "id": "1",
  "question": "What is the capital of France?",
  "contentType": "text",
  "contentData": "Paris",
  "options": ["Paris", "London", "Berlin", "Madrid"],
  "correctAnswer": "Paris",
  "explanation": "Paris is the capital of France."
}
```
Minimum Deployment Target: iOS 14 and above.

Orientation Support: Portrait and landscape.

Localization: English.

Architecture: Modular.

Third-Party Libraries: None.

<img width="581" alt="Screenshot 2025-03-07 at 11 34 12 PM" src="https://github.com/user-attachments/assets/e1e96989-1e47-4c6b-a9d5-789d973e7c7e" /><img width="581" alt="Screenshot 2025-03-07 at 11 34 12 PM" src="https://github.com/user-attachments/assets/155c0500-0423-4ffc-b5e2-06d08a7cf516" /><img width="581" alt="Screenshot 2025-03-07 at 11 40 51 PM" src="https://github.com/user-attachments/assets/c6a9258e-e484-46be-9d72-27ffa50d77fe" /><img width="581" alt="Screenshot 2025-03-07 at 11 41 00 PM" src="https://github.com/user-attachments/assets/32304194-6124-4b1e-b0ed-850410617b51" /><img width="581" alt="Screenshot 2025-03-07 at 11 41 07 PM" src="https://github.com/user-attachments/assets/2297f99c-045b-4eac-8cf9-aa72aeb3cfa1" /><img width="581" alt="Screenshot 2025-03-07 at 11 41 11 PM" src="https://github.com/user-attachments/assets/5dadcbaf-941d-4fd8-a8bd-cf844d4efb82" /><img width="581" alt="Screenshot 2025-03-07 at 11 41 22 PM" src="https://github.com/user-attachments/assets/564181c1-969e-41a8-8d7d-b47a994ba6b3" /><img width="581" alt="Screenshot 2025-03-07 at 11 41 26 PM" src="https://github.com/user-attachments/assets/bc8ef40f-4a87-4e0f-a524-f412e341bf4d" /><img width="581" alt="Screenshot 2025-03-07 at 11 43 17 PM" src="https://github.com/user-attachments/assets/3910565e-aeb8-408f-ae90-bf4091f371d2" /><img width="581" alt="Screenshot 2025-03-07 at 11 44 09 PM" src="https://github.com/user-attachments/assets/83507429-e412-4b2f-b663-ecd1d7cc43a3" />
