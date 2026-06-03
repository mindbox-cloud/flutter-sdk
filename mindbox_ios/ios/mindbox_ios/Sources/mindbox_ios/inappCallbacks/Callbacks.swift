//
//  Callbacks.swift
//
//  Created by ENotniy on 21.09.2023.
//

import Flutter
import Mindbox


class URLClass: URLInappMessageDelegate {
}

class CopyClass: CopyInappMessageDelegate {
}

class EmptyClass: InAppMessagesDelegate {
}

class CompositeClass: CompositeInappMessageDelegate {
    var delegates: [InAppMessagesDelegate] = []
}
