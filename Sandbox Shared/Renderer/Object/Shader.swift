//
//  Shader.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/13.
//


import Metal
import MetalKit
import simd

class Shader {
    private let library: MTLLibrary
    private var customLibrary: MTLLibrary?
    
    private var vs: MTLFunction!
    private var fs: MTLFunction!
        
    init() {
        self.library = Render.shared.library
    }
    
    convenience init(vsName: String, fsName: String) {
        self.init()
        setShader(vsName: vsName, fsName: fsName)
    }
    
    convenience init(screenShaderName: String) {
        self.init()
        setShader(vsName: "vs_screen", fsName: screenShaderName)
    }
    
    convenience init(source: String) {
        self.init()
        createCustomLibrary(source: source)
    }
        
    func createCustomLibrary(source: String) {
        let options = MTLCompileOptions()
        do {
            customLibrary = try Render.shared.device.makeLibrary(source: source, options: options)
        } catch {
            print("Error::Unable to compile MTLibrary. Error info: \(error)")
        }
    }
    
    func getVS() -> MTLFunction { return vs }
    func getFS() -> MTLFunction { return fs }
    
    func setVS(_ vsName: String) { vs = library.makeFunction(name: vsName) }
    func setFS(_ fsName: String) { fs = library.makeFunction(name: fsName) }
    func setShader(vsName: String, fsName: String) { setFS(fsName); setVS(vsName) }
    
    func setupCustomFS(_ fsName: String) { fs = customLibrary?.makeFunction(name: fsName) }
    func setupCustomVS(_ vsName: String) { vs = customLibrary?.makeFunction(name: vsName) }
    func setupCustomShader(vsName: String, fsName: String) { setupCustomFS(fsName); setupCustomVS(vsName) }

    
}
