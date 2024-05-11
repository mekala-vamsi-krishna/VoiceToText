//
//  ScanData.swift
//  VoiceToText
//
//  Created by Mekala Vamsi Krishna on 2/13/24.
//

import Foundation

struct ScanData:Identifiable {
    var id = UUID()
    let content:String
    
    init(content:String) {
        self.content = content
    }
}
