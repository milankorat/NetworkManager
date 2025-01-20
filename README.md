# NetworkManager Package

A Swift package for making network requests using URLSession with support for GET, POST, and form-data requests. This package supports both async/await and completion handler patterns.

## Features

- Support for GET, POST, PUT, DELETE HTTP methods.
- Async/Await and Completion Handler support.
- Handles JSON and form-data requests.
- Prints detailed logs for requests and responses.
- Error handling with descriptive error messages.

## Installation

Add the following line to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "", from: "1.0.0")
]
```

## Usage

### 1. Async/Await Example

```swift
import NetworkManager

let networkManager = NetworkManager()

Task {
    do {
        let result: YourDecodableModel = try await networkManager.makeRequest(
            url: "https://api.example.com/data",
            method: .get
        )
        print("Success: \(result)")
    } catch {
        print("Error: \(error)")
    }
}
```

### 2. Completion Handler Example

```swift
import NetworkManager

let networkManager = NetworkManager()

networkManager.makeRequest(
    url: "https://api.example.com/data",
    method: .get,
    completion: { (result: Result<YourDecodableModel, NetworkError>) in
        switch result {
        case .success(let data):
            print("Success: \(data)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
)
```

### 3. POST Request with JSON Parameters

```swift
let parameters = ["key": "value"]

Task {
    do {
        let result: YourDecodableModel = try await networkManager.makeRequest(
            url: "https://api.example.com/post",
            method: .post,
            parameters: parameters
        )
        print("Success: \(result)")
    } catch {
        print("Error: \(error)")
    }
}
```

### 4. POST Form Data Example

```swift
let parameters = ["key": "value"]

networkManager.postFormData(
    url: "https://api.example.com/form",
    parameters: parameters
) { result in
    switch result {
    case .success(let data):
        print("Success: \(String(data: data, encoding: .utf8) ?? "")")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Error Handling

The `NetworkManager` uses a custom `NetworkError` enum to provide detailed error messages:

```swift
public enum NetworkError: Error {
    case invalidURL
    case httpError(Int)
    case decodingError
    case noData
    case unknown
}
```

## License

This package is licensed under the MIT License.
