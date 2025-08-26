# e-Disha

A cross-platform Flutter application for digital public services, featuring modern UI/UX, OTP authentication, dashboard analytics, and modular architecture.

---

## 🚀 Features
- Modern, professional dashboard with analytics cards
- OTP-based authentication
- Theming (light/dark mode)
- Modular, maintainable code structure
- Placeholder for map integration
- Ready for backend API integration

---

## 🛠️ Setup Instructions
1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd e-Disha/edisha
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Run the app:**
   ```sh
   flutter run
   ```
   - To run on a specific emulator/device, use `flutter devices` and `flutter run -d <device-id>`

---

## 🤝 Contribution Guidelines
- Fork the repository and create a feature branch.
- Write clear, concise commit messages.
- Follow the existing code style and naming conventions.
- Add doc comments to all public classes and methods.
- Test your changes before submitting a pull request.

---

## 🔌 Integrating Backend APIs (Future Guidance)
This app is designed to be API-ready. To connect to backend APIs **without changing the UI or breaking the app**:

1. **Create/Update Service Classes:**
   - Add your API logic in `lib/services/` (e.g., `api_service.dart`).
   - Use methods like `Future<Data> fetchData()` for network calls.
   - Use the `http` package or `dio` for REST APIs.

2. **Use Providers for State Management:**
   - Inject your service into providers in `lib/providers/`.
   - Update provider logic to call service methods and notify listeners.

3. **Keep UI Decoupled:**
   - UI widgets (in `lib/screens/`) should only interact with providers, not directly with services or APIs.
   - This ensures you can swap out mock/demo data for real API data with minimal changes.

4. **Error Handling:**
   - Handle errors in services/providers and show user-friendly messages in the UI.

5. **Testing:**
   - Use mock services for testing UI without hitting real APIs.

**Example:**
```dart
// lib/services/api_service.dart
class ApiService {
  Future<List<Item>> fetchItems() async {
    // TODO: Implement API call using http/dio
    // return parsed response
  }
}

// lib/providers/item_provider.dart
class ItemProvider extends ChangeNotifier {
  final ApiService apiService;
  List<Item> items = [];
  ItemProvider(this.apiService);

  Future<void> loadItems() async {
    items = await apiService.fetchItems();
    notifyListeners();
  }
}
```

**You can add your API endpoints and logic in the service layer, update providers, and the UI will automatically reflect the new data.**

---

## 📄 License
[MIT](LICENSE)
