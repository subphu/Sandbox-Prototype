//
//  Render.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/21.
//

final class Render {
    private init() {}
    static private(set) var shared: Renderer!
    static func set(_ renderer: Renderer) {
        Render.shared = renderer
    }
}
