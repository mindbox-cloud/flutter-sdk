//
//  Constants.swift
//  mindbox_ios
//
//  Created by Silantyev Nikolay on 26.04.2023.
//

import Foundation

enum Constants {
    static let pluginChannelName = "mindbox.cloud/flutter-sdk";

    /// Matches `embeddedBlockViewType` in `mindbox_platform_interface`: the Dart widget asks for the
    /// platform view by this name, so the two spellings cannot drift apart.
    static let embeddedBlockViewType = "mindbox.cloud/flutter-sdk/embedded_block";
}
