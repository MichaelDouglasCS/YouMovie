# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

YouMovie is an iOS application that displays movies from The Movie Database (TMDb) API across three sections: Popular, Top Rated, and Upcoming. The app is built using the VIPER architecture pattern with a focus on testability and modular design.

**Tech Stack:** Swift 5.0+, iOS 12.0+, Xcode 11.4+

## Build and Development Commands

### Initial Setup

```bash
# Install CocoaPods dependencies (run from project root)
pod install

# Always open the workspace, not the xcodeproj
open YouMovie.xcworkspace
```

### Building and Testing

```bash
# Run tests from command line
xcodebuild -workspace YouMovie.xcworkspace \
  -scheme "YouMovie" \
  -destination "platform=iOS Simulator,name=iPhone 12 Pro Max,OS=14.5" \
  clean test | xcpretty

# Run SwiftLint
swiftlint

# Build from Xcode: Cmd+B
# Run tests from Xcode: Cmd+U
# Select scheme: YouMovie (Product > Scheme > YouMovie)
```

### Working with Tests

The project uses Quick (BDD framework) and Nimble (matcher library) for testing:

```bash
# Run specific test file in Xcode: Cmd+U with cursor in the file
# Test files are located in YouMovieTests/Modules/Movies/
```

## Architecture

### VIPER Pattern

The app follows the VIPER architecture with strict separation of concerns:

**V - View** (`*View.swift`)
- UIViewController subclasses extending `BaseViewController`
- Handles UI presentation and user interaction
- Conforms to `*PresenterOutputProtocol`
- Owns IBOutlets and lifecycle methods
- Example: `YouMovie/Sources/Modules/Movies/Movies/MoviesView.swift`

**I - Interactor** (`*Interactor.swift`)
- Contains business logic and data fetching
- Communicates with API through Requests layer
- Reports results to Presenter via output protocol
- Example: `YouMovie/Sources/Modules/Movies/Movies/MoviesInteractor.swift`

**P - Presenter** (`*Presenter.swift`)
- Mediates between View and Interactor
- Implements both input (from View) and output (from Interactor) protocols
- Manages presentation logic, state, and routing decisions
- Example: `YouMovie/Sources/Modules/Movies/Movies/MoviesPresenter.swift`

**E - Entity** (`*Entity.swift`)
- Data models using ObjectMapper for JSON deserialization
- All inherit from `BaseEntity` which implements Mappable protocol
- Located in `ModuleResources/Entities/` or per-module `Entities/` folder
- Example: `YouMovie/Sources/Modules/Movies/ModuleResources/Entities/MovieEntity.swift`

**R - Router/Wireframe** (`*Wireframe.swift`)
- Creates and wires all VIPER components together
- Handles navigation between modules
- Owns the instantiation logic for the entire module
- Example: `YouMovie/Sources/Modules/Movies/Movies/MoviesWireframe.swift`

### Protocol-Based Communication

Each module defines protocols in `*Protocols.swift`:
- `*WireframeProtocol` - Module instantiation and navigation
- `*PresenterInputProtocol` - View to Presenter communication
- `*PresenterOutputProtocol` - Presenter to View callbacks
- `*InteractorInputProtocol` - Presenter to Interactor requests
- `*InteractorOutputProtocol` - Interactor to Presenter results

This ensures loose coupling and enables comprehensive mocking for tests.

### Module Structure

Each feature module follows this structure:

```
ModuleName/
├── ModuleNameProtocols.swift
├── ModuleNameView.swift + .xib
├── ModuleNamePresenter.swift
├── ModuleNameInteractor.swift
├── ModuleNameWireframe.swift
├── Cells/
│   └── CustomCell.swift + .xib
├── Views/
│   └── CustomView.swift
└── Extras/
    ├── ModuleNameAPIRoutes.swift
    ├── ModuleNameMessagesUtil.swift
    └── ModuleNameRequests.swift
```

**Extras folder** contains:
- **APIRoutes** - Extension of global `APIRoutes` with module-specific endpoints
- **MessagesUtil** - Localized strings and error messages for the module
- **Requests** - API request handling with NetworkProvider injection

## Networking Layer

Location: `YouMovie/Sources/Network/`

### NetworkProvider

```swift
protocol NetworkProviderProtocol {
    func request(urlString: String,
                 method: HTTPMethod,
                 parameters: Parameters?,
                 encoding: ParameterEncoding,
                 headers: HTTPHeaders?,
                 success: @escaping RequestSuccess,
                 failure: @escaping RequestFailure)
}
```

The `NetworkProvider` wraps Alamofire and:
- Executes requests on background queue (`.background` QoS)
- Prints cURL commands for debugging
- Handles JSON response parsing
- Manages error detection (network vs internal errors)

### API Routes Pattern

API configuration is centralized in `APIRoutes.swift`:

```swift
struct APIRoutes {
    static let apiKey: String = "86edbafd587030693158039afb48e826"
    static let apiVersion: Int = 3
    static let apiBaseURL: String = "https://api.themoviedb.org/\(APIRoutes.apiVersion)"
}
```

Module-specific routes extend this in `Extras/*APIRoutes.swift`:

```swift
extension APIRoutes {
    struct Movies {
        static func fetchMovies(from section: MoviesSectionType, atPage page: Int) -> String
    }
}
```

### Requests Layer

Each module has a Requests class (in `Extras/`) that:
1. Injects `NetworkProviderProtocol` for testability
2. Constructs URLs using APIRoutes
3. Maps JSON to entities using ObjectMapper
4. Provides typed success/failure callbacks

Example pattern:
```swift
class MoviesRequests: MoviesRequestsProtocol {
    var provider: NetworkProviderProtocol = NetworkProvider()

    func fetchMovies(success: @escaping MoviesSuccess, failure: @escaping RequestFailure) {
        let urlString = APIRoutes.Movies.fetchMovies(...)
        provider.request(urlString: urlString, method: .get, success: { json in
            guard let entity = MoviesCategoryEntity(JSON: json) else {
                failure(RequestError.error(.internalError))
                return
            }
            success(entity)
        }, failure: failure)
    }
}
```

## Dependency Injection

### Wireframe-Based Constructor Injection

Wireframes create and wire all VIPER components:

```swift
private func setupView() -> MoviesView {
    let view = MoviesView(nibName: self.nibName, bundle: nil)
    let presenter = MoviesPresenter()
    let interactor = MoviesInteractor()

    presenter.wireframe = self
    presenter.view = view
    presenter.interactor = interactor

    view.presenter = presenter
    interactor.output = presenter

    return view
}
```

### Property Injection for Testability

External dependencies are injected as protocol properties:

```swift
class MoviesInteractor {
    var requests: MoviesRequestsProtocol = MoviesRequests()  // Replaceable with mock
    weak var output: MoviesInteractorOutputProtocol!
}
```

All protocol dependencies can be replaced with mocks in tests.

## Navigation & Routing

Navigation is owned by Wireframes, not Views:

**App Entry (AppDelegate):**
```swift
let moviesView = MoviesWireframe().instantiateView()
let navigationView = UINavigationController(rootViewController: moviesView)
window.rootViewController = navigationView
```

**Inter-Module Navigation:**
```swift
// In MoviesWireframe
func presentDetails(from movie: MovieEntity) {
    let movieDetailsView = MovieDetailsWireframe().instantiateView(with: movie)
    self.view.navigationController?.pushViewController(movieDetailsView, animated: true)
}
```

Flow: User Action → View → Presenter → Wireframe → New Module

## Testing Strategy

### Test Structure

Tests mirror source structure:
```
YouMovieTests/
└── Modules/
    └── Movies/
        ├── Movies/
        │   ├── MoviesPresenterSpec.swift
        │   ├── MoviesInteractorSpec.swift
        │   ├── MoviesViewSpec.swift
        │   ├── MoviesWireframeSpec.swift
        │   └── Extras/
        │       └── MoviesMocks.swift
        └── MovieDetails/
            └── ... (same pattern)
```

### Testing Tools

- **Quick** - BDD-style testing framework
- **Nimble** - Expressive matchers (`expect().to()`, `toEventually()`)
- **OHHTTPStubs** - HTTP request stubbing for network tests

### Mock Pattern

Each module has a `*Mocks.swift` file containing mock implementations for all protocols:

```swift
class MoviesPresenterMock: MoviesPresenterInputProtocol {
    var fetchMoviesCalled: Bool = false
    var didSelectMovieCalled: Bool = false
    // ... track method calls
}
```

### Writing Tests

Use Quick's BDD syntax:

```swift
class MoviesPresenterSpec: QuickSpec {
    override func spec() {
        var sut: MoviesPresenter!
        var view: MoviesViewMock!
        var interactor: MoviesInteractorMock!

        beforeEach {
            sut = MoviesPresenter()
            view = MoviesViewMock()
            interactor = MoviesInteractorMock()
            sut.view = view
            sut.interactor = interactor
        }

        context("When fetching movies") {
            it("Should call interactor") {
                sut.fetchMovies(from: .popular)
                expect(interactor.fetchMoviesCalled).to(beTrue())
            }
        }
    }
}
```

### HTTP Stubbing

For Interactor tests with real network calls:

```swift
stub(condition: isMethodGET() && isHost("api.themoviedb.org")) { _ in
    return HTTPStubsResponse(
        fileAtPath: OHPathForFile("MoviesJSON.json", type(of: self))!,
        statusCode: 200,
        headers: ["Content-Type": "application/json"]
    )
}

expect(output.fetchMoviesDidSucceedCalled).toEventually(beTrue(), timeout: 5.5)
```

## Code Style and Linting

SwiftLint configuration: `.swiftlint.yml`

Key rules:
- Type body length: 600 lines warning, 2000 error
- File length: 600 lines warning, 1200 error
- Function body length: 70 lines warning, 100 error
- Cyclomatic complexity: 25 warning, 40 error
- Function parameter count: 7 warning, 12 error
- Pods directory is excluded from linting

Many standard rules are disabled (see `.swiftlint.yml`) to accommodate the existing codebase style.

## Key Files and Locations

### Source Code
- **Modules:** `YouMovie/Sources/Modules/` - All feature modules
- **Network:** `YouMovie/Sources/Network/` - Networking layer
- **Shared:** `YouMovie/Sources/Shared/` - Reusable components
  - `Commons/` - Base classes (BaseViewController, BaseEntity, Instantiable)
  - `Components/` - UI components (CircularImageView, CardView, etc.)
  - `Extensions/` - UIKit and Foundation extensions
  - `Utils/` - Utilities (MessagesUtil, Connectivity)

### Tests
- **Test Specs:** `YouMovieTests/Modules/Movies/` - Test files matching source structure
- **Mocks:** Located in `Extras/` folders within test directories

### Configuration
- **Dependencies:** `Podfile` - CocoaPods dependencies
- **Workspace:** `YouMovie.xcworkspace/` - Main workspace (always use this)
- **Linting:** `.swiftlint.yml` - SwiftLint rules
- **CI:** `.travis.yml` - Travis CI configuration

## Adding a New Module

1. Create directory structure: `ModuleName/` with Extras, Cells, Views folders
2. Create all five VIPER components following naming convention
3. Define protocols in `ModuleNameProtocols.swift`
4. Create Requests class in `Extras/ModuleNameRequests.swift`
5. Extend APIRoutes in `Extras/ModuleNameAPIRoutes.swift`
6. Create entities in `ModuleResources/Entities/` or local `Entities/`
7. Wire components in Wireframe's `setupView()`
8. Create corresponding test files and mocks

## Common Patterns

### Pagination
Presenter manages pagination state:
- Page 1 replaces data
- Page > 1 appends data
- Check `shouldFetchNextPageMovies` computed property before loading more

### Search Filtering
Presenter holds both `movies` (all) and `filteredMovies`:
```swift
func searchMovie(byTitle title: String) {
    self.searchQuery = title.lowercased()
    // Filter logic
}
```

### Loading States
Use `isLoading` flag in Presenter to prevent concurrent requests

### Error Handling
`RequestError` enum distinguishes:
- `.networkError` - No internet connection
- `.internalError` - Server/parsing errors

Check connectivity via `Connectivity.isConnectedToInternet()`

### Entity Mapping
All entities inherit from `BaseEntity` and override `mapping(map:)`:
```swift
override func mapping(map: Map) {
    self.id <- map["id"]
    self.title <- map["title"]
}
```

For complex nested structures, use transform operations in mapping.

## Dependencies

Managed via CocoaPods (see `Podfile`):

**Production:**
- Alamofire ~5.2.2 - HTTP networking
- ObjectMapper ~3.4 - JSON to object mapping
- Kingfisher ~5.15.3 - Image downloading/caching
- BetterSegmentedControl ~1.2 - Custom segmented control
- XCDYouTubeKit - YouTube video playback

**Testing:**
- Quick - BDD testing framework
- Nimble - Matcher/expectation library
- OHHTTPStubs/Swift - HTTP stubbing
