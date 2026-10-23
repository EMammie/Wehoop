//
//  LogoGenerator.swift
//  Wehoop
//
//  Generate team logo placeholder images programmatically
//  This is a Swift alternative to the Python script
//

import SwiftUI
import UIKit

/// Generates placeholder team logos programmatically
struct LogoGenerator {
    
    struct TeamLogoData {
        let id: String
        let name: String
        let abbreviation: String
        let color: UIColor
    }
    
    static let teams: [TeamLogoData] = [
        TeamLogoData(id: "team-1", name: "Mist BC", abbreviation: "MST", color: UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0)),
        TeamLogoData(id: "team-2", name: "Lunar Owls BC", abbreviation: "LOW", color: UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0)),
        TeamLogoData(id: "team-3", name: "Rose BC", abbreviation: "RSE", color: UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1.0)),
        TeamLogoData(id: "team-4", name: "Vinyl BC", abbreviation: "VNL", color: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)),
        TeamLogoData(id: "team-5", name: "Phantom BC", abbreviation: "PHT", color: UIColor(red: 0.2, green: 0.15, blue: 0.3, alpha: 1.0)),
        TeamLogoData(id: "team-6", name: "Laces BC", abbreviation: "LAC", color: UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)),
        TeamLogoData(id: "team-7", name: "Breeze", abbreviation: "BRZ", color: UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)),
        TeamLogoData(id: "team-8", name: "Hive", abbreviation: "HVE", color: UIColor(red: 1.0, green: 0.84, blue: 0.2, alpha: 1.0)),
    ]
    
    /// Generate a circular logo with team color and abbreviation
    static func generateLogo(for team: TeamLogoData, size: CGFloat = 512) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 3.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw main circle
        context.setFillColor(team.color.cgColor)
        context.fillEllipse(in: rect)
        
        // Draw inner circle for depth
        let innerSize = size * 0.85
        let innerOffset = (size - innerSize) / 2
        let innerRect = CGRect(x: innerOffset, y: innerOffset, width: innerSize, height: innerSize)
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        team.color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lighterColor = UIColor(red: min(r + 0.08, 1.0), green: min(g + 0.08, 1.0), blue: min(b + 0.08, 1.0), alpha: 1.0)
        
        context.setFillColor(lighterColor.cgColor)
        context.fillEllipse(in: innerRect)
        
        // Draw text
        let text = team.abbreviation as NSString
        let fontSize = size * 0.35
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        
        let textColor: UIColor = (team.id == "team-6") ? .darkGray : .white
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size - textSize.width) / 2,
            y: (size - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /// Generate all team logos and save to documents directory
    static func generateAllLogos() -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let logosURL = documentsURL.appendingPathComponent("TeamLogos", isDirectory: true)
        
        // Create directory
        try? fileManager.createDirectory(at: logosURL, withIntermediateDirectories: true)
        
        print("🏀 Generating team logos...")
        print("   Location: \(logosURL.path)\n")
        
        for team in teams {
            if let image = generateLogo(for: team, size: 512),
               let pngData = image.pngData() {
                let filename = "logo-\(team.id).png"
                let fileURL = logosURL.appendingPathComponent(filename)
                
                do {
                    try pngData.write(to: fileURL)
                    print("✓ Created \(filename)")
                } catch {
                    print("✗ Failed to save \(filename): \(error)")
                }
            }
        }
        
        print("\n✅ Done! Logos saved to:")
        print("   \(logosURL.path)\n")
        print("📦 Next steps:")
        print("   1. Open Finder and navigate to the path above")
        print("   2. Select all 8 PNG files")
        print("   3. Drag them into Assets.xcassets in Xcode")
        print("   4. Verify names: logo-team-1, logo-team-2, etc.")
        print("   5. Build and run!\n")
        
        return logosURL
    }
}

/// SwiftUI view to generate logos with a button
struct LogoGeneratorView: View {
    @State private var logosGenerated = false
    @State private var outputPath: String = ""
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Team Logo Generator")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Generate placeholder logos for all 8 Unrivaled teams")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if !logosGenerated {
                Button(action: generateLogos) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "photo.on.rectangle.angled")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Logos")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isGenerating)
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Logos Generated!")
                        .font(.headline)
                    
                    Text("Saved to:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(outputPath)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button("Open in Files") {
                        if let url = URL(string: "shareddocuments://\(outputPath)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.subheadline)
                    
                    Button("Generate Again") {
                        logosGenerated = false
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Divider()
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Instructions:")
                    .font(.headline)
                
                instructionRow(number: 1, text: "Tap 'Generate Logos'")
                instructionRow(number: 2, text: "Open Files app and navigate to the path shown")
                instructionRow(number: 3, text: "Share/AirDrop files to your Mac")
                instructionRow(number: 4, text: "Drag PNG files into Xcode's Assets.xcassets")
                instructionRow(number: 5, text: "Build and run the app!")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
    
    private func generateLogos() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let url = LogoGenerator.generateAllLogos() {
                DispatchQueue.main.async {
                    outputPath = url.path
                    logosGenerated = true
                    isGenerating = false
                }
            } else {
                DispatchQueue.main.async {
                    isGenerating = false
                }
            }
        }
    }
}

#Preview {
    LogoGeneratorView()
}
