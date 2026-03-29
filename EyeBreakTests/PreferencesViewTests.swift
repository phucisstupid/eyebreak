import AppKit
import SwiftUI
import XCTest

@testable import EyeBreak

@MainActor
final class PreferencesViewTests: XCTestCase {
    func test_prefersNativeFormSpacingAndWindowFootprint() throws {
        let hostingView = makeHostingView()

        hostingView.frame = CGRect(origin: .zero, size: PreferencesView.nativeWindowSize)
        hostingView.layoutSubtreeIfNeeded()

        let fittingSize = hostingView.fittingSize

        XCTAssertGreaterThanOrEqual(fittingSize.width, PreferencesView.nativeWindowSize.width)
        XCTAssertGreaterThanOrEqual(fittingSize.height, PreferencesView.nativeWindowSize.height)
    }

    func test_rendersCompactNumericFieldWidth() throws {
        let hostingView = makeHostingView()

        hostingView.frame = CGRect(origin: .zero, size: PreferencesView.nativeWindowSize)
        hostingView.layoutSubtreeIfNeeded()

        let numericField = try XCTUnwrap(
            allSubviews(of: NSTextField.self, in: hostingView)
                .first { !$0.stringValue.isEmpty }
        )

        XCTAssertGreaterThan(numericField.frame.width, 0)
        XCTAssertLessThanOrEqual(numericField.frame.width, PreferencesView.numericFieldWidth)
    }

    func test_launchAtLoginToggleUsesTheSavePathAndLaunchAtLoginChangeCallback() {
        var savedSettings: [AppSettings] = []
        var launchAtLoginValues: [Bool] = []
        let view = PreferencesView(
            settings: .default,
            onSave: { savedSettings.append($0) },
            onLaunchAtLoginChange: { enabled in
                launchAtLoginValues.append(enabled)
                return nil
            }
        )

        view.launchAtLoginBinding.wrappedValue = true

        XCTAssertEqual(savedSettings.count, 1)
        XCTAssertEqual(savedSettings.first?.launchAtLogin, true)
        XCTAssertEqual(launchAtLoginValues, [true])
    }

    func test_integerFieldParserNormalizesInputWithinConfiguredRange() {
        let parser = PreferencesIntegerFieldParser(range: 1...120)

        XCTAssertEqual(parser.normalizedText(from: " 15 ", fallback: 20), "15")
        XCTAssertEqual(parser.normalizedText(from: "0", fallback: 20), "1")
        XCTAssertEqual(parser.normalizedText(from: "999", fallback: 20), "120")
        XCTAssertEqual(parser.normalizedText(from: "abc", fallback: 20), "20")
    }

    private func makeHostingView() -> NSHostingView<PreferencesView> {
        NSHostingView(
            rootView: PreferencesView(
                settings: .default,
                onSave: { _ in },
                onLaunchAtLoginChange: { _ in nil }
            )
        )
    }

    private func allSubviews<T: NSView>(of type: T.Type, in view: NSView) -> [T] {
        var results: [T] = []

        for subview in view.subviews {
            if let typedSubview = subview as? T {
                results.append(typedSubview)
            }

            results.append(contentsOf: allSubviews(of: type, in: subview))
        }

        return results
    }
}
