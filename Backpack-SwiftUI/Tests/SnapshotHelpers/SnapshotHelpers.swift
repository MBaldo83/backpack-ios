/*
 * Backpack - Skyscanner's Design System
 *
 * Copyright 2018 Skyscanner Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import SwiftUI
import XCTest
import SnapshotTesting

func assertSnapshot<V: View>(
    _ view: V,
    modes: [UIUserInterfaceStyle] = [.light, .dark],
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    let identifier: (UIUserInterfaceStyle) -> String = { mode in mode == .dark ? "dark-mode" : "light-mode" }
    modes.forEach { mode in
        let vc = UIHostingController(rootView: view)
        let styleTrait = UITraitCollection(userInterfaceStyle: mode)
        isRecording = false
        assertSnapshot(matching: vc, as: .image(traits: styleTrait), named:identifier(mode), file: file, testName: testName, line:line)
    }
}