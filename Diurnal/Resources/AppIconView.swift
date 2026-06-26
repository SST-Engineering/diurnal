import SwiftUI

// MARK: - Diurnal App Icon — Sundial on Amber
//
// Usage: Run the app, find AppIconPreview in the canvas,
// screenshot at 1024×1024 and drag the PNG into
// Assets.xcassets → AppIcon.

struct AppIconView: View {

    var size: CGFloat = 1024

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width
            let h = sz.height
            let cx = w * 0.500
            let cy = h * 0.560

            // ─────────────────────────────────────────
            // 1.  BACKGROUND — rich amber-gold gradient
            //     Saturated warm gold so it pops in the dock
            //     alongside blue/green/red neighbours.
            // ─────────────────────────────────────────
            let bgRect = CGRect(origin: .zero, size: sz)

            // Base: deep amber
            ctx.fill(Path(bgRect), with: .color(Color(red: 0.820, green: 0.540, blue: 0.080)))

            // Radial highlight: brighter centre (warm sunlight)
            ctx.fill(Path(bgRect), with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.980, green: 0.780, blue: 0.220).opacity(0.72), location: 0.0),
                    .init(color: Color.clear,                                                 location: 0.68),
                ]),
                center: CGPoint(x: w * 0.48, y: h * 0.38),
                startRadius: 0,
                endRadius: w * 0.62
            ))

            // Edge vignette: deeper burnt-orange corners
            ctx.fill(Path(bgRect), with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color.clear,                                                   location: 0.48),
                    .init(color: Color(red: 0.45, green: 0.20, blue: 0.00).opacity(0.52),       location: 1.0),
                ]),
                center: CGPoint(x: w * 0.5, y: h * 0.5),
                startRadius: w * 0.30,
                endRadius: w * 0.82
            ))

            // ─────────────────────────────────────────
            // 2.  OUTER BORDER — dark brown ink frame
            // ─────────────────────────────────────────
            let inset  = w * 0.026
            let border = Path(bgRect.insetBy(dx: inset, dy: inset))
            ctx.stroke(border,
                       with: .color(Color(red: 0.20, green: 0.09, blue: 0.01).opacity(0.75)),
                       lineWidth: w * 0.028)

            // ─────────────────────────────────────────
            // 3.  SUNDIAL PLATE — dark stone ellipse
            // ─────────────────────────────────────────
            let rx = w * 0.340
            let ry = h * 0.158
            let plateRect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)

            // Shadow
            ctx.fill(Path(ellipseIn: plateRect.offsetBy(dx: w * 0.020, dy: h * 0.026)),
                     with: .color(Color(red: 0.18, green: 0.07, blue: 0.00).opacity(0.42)))

            // Plate body — warm dark stone, high contrast against amber bg
            ctx.fill(Path(ellipseIn: plateRect), with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.295, green: 0.195, blue: 0.085),
                    Color(red: 0.200, green: 0.130, blue: 0.050),
                ]),
                startPoint: CGPoint(x: cx, y: cy - ry),
                endPoint:   CGPoint(x: cx, y: cy + ry)
            ))

            // Plate rim — warm gold stroke so it reads on the amber background
            ctx.stroke(Path(ellipseIn: plateRect),
                       with: .color(Color(red: 0.92, green: 0.72, blue: 0.20).opacity(0.70)),
                       lineWidth: w * 0.013)

            // ─────────────────────────────────────────
            // 4.  HOUR RAYS — 7 gold rays on dark plate
            // ─────────────────────────────────────────
            let footX = cx
            let footY = cy + ry * 0.10

            let totalLines = 7
            let arcDeg     = 140.0
            let arcStart   = -90.0 - arcDeg / 2
            let arcEnd     = -90.0 + arcDeg / 2
            let rayGold    = Color(red: 0.96, green: 0.80, blue: 0.28).opacity(0.90)

            for i in 0..<totalLines {
                let t        = Double(i) / Double(totalLines - 1)
                let angleDeg = arcStart + t * (arcEnd - arcStart)
                let angleRad = angleDeg * .pi / 180.0
                let ex       = footX + CGFloat(cos(angleRad)) * rx * 0.82
                let ey       = footY + CGFloat(sin(angleRad)) * ry * 0.82

                // Ray
                var ray = Path()
                ray.move(to: CGPoint(x: footX, y: footY))
                ray.addLine(to: CGPoint(x: ex, y: ey))
                ctx.stroke(ray, with: .color(rayGold), lineWidth: w * 0.007)

                // Tick at end
                let perp    = Double(angleRad) + .pi / 2
                let tickLen = w * 0.032
                var tick = Path()
                tick.move(to: CGPoint(x: ex + CGFloat(cos(perp)) * tickLen * 0.5,
                                      y: ey + CGFloat(sin(perp)) * tickLen * 0.5))
                tick.addLine(to: CGPoint(x: ex - CGFloat(cos(perp)) * tickLen * 0.5,
                                         y: ey - CGFloat(sin(perp)) * tickLen * 0.5))
                ctx.stroke(tick, with: .color(rayGold), lineWidth: w * 0.009)
            }

            // ─────────────────────────────────────────
            // 5.  GNOMON — bright gold fin, wide and bold
            // ─────────────────────────────────────────
            let gnomonTip   = CGPoint(x: cx, y: h * 0.148)
            let gnomonLeft  = CGPoint(x: footX - w * 0.042, y: footY)
            let gnomonRight = CGPoint(x: footX + w * 0.042, y: footY)

            // Gnomon shadow on the plate
            var gShadow = Path()
            gShadow.move(to:    CGPoint(x: gnomonTip.x   + w * 0.022, y: gnomonTip.y   + h * 0.026))
            gShadow.addLine(to: CGPoint(x: gnomonLeft.x  + w * 0.022, y: gnomonLeft.y  + h * 0.026))
            gShadow.addLine(to: CGPoint(x: gnomonRight.x + w * 0.022, y: gnomonRight.y + h * 0.026))
            gShadow.closeSubpath()
            ctx.fill(gShadow, with: .color(Color(red: 0.12, green: 0.05, blue: 0.00).opacity(0.38)))

            // Gnomon body — bright gold gradient
            var gnomon = Path()
            gnomon.move(to: gnomonTip)
            gnomon.addLine(to: gnomonLeft)
            gnomon.addLine(to: gnomonRight)
            gnomon.closeSubpath()
            ctx.fill(gnomon, with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.98, green: 0.84, blue: 0.32),
                    Color(red: 0.82, green: 0.60, blue: 0.10),
                ]),
                startPoint: gnomonLeft,
                endPoint:   gnomonRight
            ))
            ctx.stroke(gnomon,
                       with: .color(Color(red: 0.18, green: 0.08, blue: 0.00).opacity(0.88)),
                       lineWidth: w * 0.007)

            // ─────────────────────────────────────────
            // 6.  CAST SHADOW — dark line at ~10 o'clock
            // ─────────────────────────────────────────
            let shadowRad = (-90.0 - 30.0) * .pi / 180.0
            var castShadow = Path()
            castShadow.move(to: gnomonTip)
            castShadow.addLine(to: CGPoint(
                x: footX + CGFloat(cos(shadowRad)) * rx * 0.74,
                y: footY + CGFloat(sin(shadowRad)) * ry * 0.74
            ))
            ctx.stroke(castShadow,
                       with: .color(Color(red: 0.12, green: 0.05, blue: 0.00).opacity(0.72)),
                       lineWidth: w * 0.011)

            // ─────────────────────────────────────────
            // 7.  PIVOT DOT — gold ring on dark plate
            // ─────────────────────────────────────────
            let pr = w * 0.036
            var pivot = Path()
            pivot.addEllipse(in: CGRect(x: footX - pr, y: footY - pr, width: pr * 2, height: pr * 2))
            ctx.fill(pivot, with: .color(Color(red: 0.96, green: 0.78, blue: 0.22)))

            let pr2 = pr * 0.44
            var pivotInner = Path()
            pivotInner.addEllipse(in: CGRect(x: footX - pr2, y: footY - pr2, width: pr2 * 2, height: pr2 * 2))
            ctx.fill(pivotInner, with: .color(Color(red: 0.20, green: 0.10, blue: 0.02)))

        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Icon 512pt") {
    AppIconView(size: 512)
        .clipShape(RoundedRectangle(cornerRadius: 512 * 0.225))
        .shadow(radius: 24)
        .padding(40)
        .background(Color.gray.opacity(0.15))
}

#Preview("Icon small (dock)") {
    HStack(spacing: 20) {
        ForEach([128, 64, 32], id: \.self) { s in
            AppIconView(size: CGFloat(s))
                .clipShape(RoundedRectangle(cornerRadius: CGFloat(s) * 0.225))
                .shadow(radius: 4)
        }
    }
    .padding(40)
    .background(Color.gray.opacity(0.15))
}

#Preview("Dock context") {
    // Simulates sitting next to Word (blue) and Excel (green)
    HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color(red: 0.18, green: 0.45, blue: 0.90))
            .frame(width: 96, height: 96)
        AppIconView(size: 96)
            .clipShape(RoundedRectangle(cornerRadius: 96 * 0.225))
        RoundedRectangle(cornerRadius: 22)
            .fill(Color(red: 0.20, green: 0.68, blue: 0.30))
            .frame(width: 96, height: 96)
    }
    .padding(24)
    .background(Color(white: 0.18))
}
