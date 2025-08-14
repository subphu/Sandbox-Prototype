//
//  RenderContext.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/21.
//

import Metal
import MetalKit
import simd

struct RenderRecord {
    var renderPassDesc: MTLRenderPassDescriptor!
    var commands: [(Int, (MTLRenderCommandEncoder) -> Void)]
    func execute(_ encoder: MTLRenderCommandEncoder) {
        commands.sorted { $0.0 < $1.0 }.forEach { (_, command) in command(encoder) }
    }
}

class RenderContext {
    private var records: [RenderPassId: RenderRecord] = [:]
    private var globalExecute: (MTLRenderCommandEncoder) -> Void = { _ in }
    
    init() {}
    
    func setGlobalCommand(_ command: @escaping (MTLRenderCommandEncoder) -> Void) {
        self.globalExecute = command
    }
    
    func addRenderpassDesc(to id: RenderPassId, descriptor: MTLRenderPassDescriptor) {
        records[id] = RenderRecord(renderPassDesc: descriptor, commands: [])
    }
    
    func addCommand(to id: RenderPassId, priority: Int, command: @escaping (MTLRenderCommandEncoder) -> Void) {
        guard records[id] != nil else { return }
        records[id]!.commands.append((priority, command))
    }
    
    func executeRecords() {
        let commander = Render.shared.commander!
        let sortedRecirds = records.sorted { $0.key.rawValue < $1.key.rawValue }
        for (key, record) in sortedRecirds {
            guard record.commands.count > 0 else { continue }
            guard let encoder = commander.makeRenderCommandEncoder(descriptor: record.renderPassDesc) else { continue }
            
            globalExecute(encoder)
            encoder.pushDebugGroup("RenderPass: \(key)")
            encoder.label = String(describing: key)
            encoder.setCullMode(.back)
            encoder.setFrontFacing(.counterClockwise)
            record.execute(encoder)
            encoder.popDebugGroup()
            encoder.endEncoding()
        }
    }
    
    func prepareFrame() {
        records = [:]
    }
}
