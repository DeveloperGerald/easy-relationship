import SwiftUI
import EasyRelationshipCore

struct GraphView: View {
    @StateObject private var store: GraphStore

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0

    @State private var dragMode: DragMode? = nil

    private enum DragMode: Equatable {
        case pan
        case node(nodeId: String, startNodePosition: CGPoint, startWorldPoint: CGPoint)
    }

    init(store: GraphStore) {
        self._store = StateObject(wrappedValue: store)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let highlightedNodes = store.highlightedNodeIds()
                    let highlightedEdges = store.highlightedEdgeIds()

                    var occupiedLabelRects: [CGRect] = []

                    for edge in store.edges {
                        guard let p1 = store.positions[edge.fromId], let p2 = store.positions[edge.toId] else { continue }
                        let a = worldToScreen(p1, center: center)
                        let b = worldToScreen(p2, center: center)
                        let isHighlighted = highlightedEdges.contains(edge.id)

                        let baseEdgeColor = colorForRelationTypeId(edge.relationTypeId)
                        let edgeColor = isHighlighted ? Color.orange : baseEdgeColor.opacity(0.55)

                        var path = Path()
                        path.move(to: a)
                        path.addLine(to: b)

                        context.stroke(
                            path,
                            with: .color(edgeColor),
                            lineWidth: isHighlighted ? 3 : 1
                        )

                        let labelPoint = edgeLabelPoint(from: a, to: b, seed: edge.id, occupied: &occupiedLabelRects)
                        let edgeLabel = Text(edge.label)
                            .font(.caption2)
                            .foregroundColor(.white)
                        let resolvedEdgeLabel = context.resolve(edgeLabel)
                        let labelSize = resolvedEdgeLabel.measure(in: CGSize(width: 160, height: 40))
                        let labelRect = CGRect(
                            x: labelPoint.x - labelSize.width / 2 - 6,
                            y: labelPoint.y - labelSize.height / 2 - 4,
                            width: labelSize.width + 12,
                            height: labelSize.height + 8
                        )

                        occupiedLabelRects.append(labelRect)

                        context.fill(
                            Path(roundedRect: labelRect, cornerRadius: 6),
                            with: .color(Color.black.opacity(isHighlighted ? 0.55 : 0.35))
                        )
                        context.draw(resolvedEdgeLabel, at: CGPoint(x: labelRect.midX, y: labelRect.midY), anchor: .center)

                        if edge.directional {
                            drawArrowHead(context: &context, from: a, to: b, color: edgeColor)
                        }
                    }

                    for node in store.nodes {
                        guard let p = store.positions[node.id] else { continue }
                        let sp = worldToScreen(p, center: center)

                        let isSelected = store.selectedNodeId == node.id
                        let isHighlighted = highlightedNodes.contains(node.id)

                        let paddingX: CGFloat = 12
                        let paddingY: CGFloat = 8
                        let approxCharWidth: CGFloat = 7.5
                        let width = min(max(CGFloat(node.name.count) * approxCharWidth + paddingX * 2, 70), 180)
                        let height: CGFloat = max(18 + paddingY * 2, 34)
                        let rect = CGRect(x: sp.x - width / 2, y: sp.y - height / 2, width: width, height: height)

                        let fillColor: Color = isSelected ? .orange : (isHighlighted ? .blue : .blue.opacity(0.7))
                        context.fill(Path(roundedRect: rect, cornerRadius: 10), with: .color(fillColor))
                        let isLocked = store.isLocked(nodeId: node.id)
                        context.stroke(
                            Path(roundedRect: rect, cornerRadius: 10),
                            with: .color(isLocked ? .yellow.opacity(0.95) : .white.opacity(0.85)),
                            lineWidth: isLocked ? 2 : 1
                        )

                        let nodeLabel = Text(node.name)
                            .font(.caption)
                            .foregroundColor(.white)
                        let resolvedNodeLabel = context.resolve(nodeLabel)
                        context.draw(resolvedNodeLabel, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)

                        if isLocked {
                            let lockLabel = Text(Image(systemName: "lock.fill"))
                                .font(.caption2)
                                .foregroundColor(.white)
                            let resolvedLock = context.resolve(lockLabel)
                            context.draw(
                                resolvedLock,
                                at: CGPoint(x: rect.maxX - 10, y: rect.minY + 10),
                                anchor: .center
                            )
                        }
                    }
                }
                .contentShape(Rectangle())
                .highPriorityGesture(dragGesture(center: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)))
                .simultaneousGesture(magnificationGesture)
                .onTapGesture { location in
                    let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    let world = screenToWorld(location, center: center)
                    store.selectNearestNode(worldPoint: world, maxDistance: 30 / max(scale, 0.5))
                }
                .onAppear {
                    store.reload()
                }
                .onDisappear {
                    store.persistLayout()
                }

                if !store.lastErrorMessage.isEmpty {
                    VStack {
                        Text("加载失败：\(store.lastErrorMessage)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("关系图")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("重排") {
                    store.recomputeLayout()
                    resetTransform()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetTransform()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }

            if let selectedId = store.selectedNodeId {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.toggleLock(nodeId: selectedId)
                    } label: {
                        Image(systemName: store.isLocked(nodeId: selectedId) ? "lock.fill" : "lock.open")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        centerOnSelected()
                    } label: {
                        Image(systemName: "scope")
                    }
                }
            }
        }
        .searchable(text: $store.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索人物")
        .searchSuggestions {
            ForEach(store.suggestions()) { node in
                Text(node.name)
                    .searchCompletion(node.name)
            }
        }
        .onSubmit(of: .search) {
            store.focusFirstMatch()
            resetTransform()
        }
    }

    private func dragGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if dragMode == nil {
                    let startWorld = screenToWorld(value.startLocation, center: center)
                    let maxPickDistance = 40 / max(scale, 0.5)
                    if let nodeId = store.nearestNodeId(worldPoint: startWorld, maxDistance: maxPickDistance),
                       let startNodePosition = store.positions[nodeId] {
                        store.selectedNodeId = nodeId
                        dragMode = .node(nodeId: nodeId, startNodePosition: startNodePosition, startWorldPoint: startWorld)
                    } else {
                        dragMode = .pan
                    }
                }

                switch dragMode {
                case .pan:
                    offset = CGSize(width: lastDragOffset.width + value.translation.width, height: lastDragOffset.height + value.translation.height)

                case .node(let nodeId, let startNodePosition, let startWorldPoint):
                    let currentWorld = screenToWorld(value.location, center: center)
                    let delta = CGPoint(x: currentWorld.x - startWorldPoint.x, y: currentWorld.y - startWorldPoint.y)
                    let newPosition = CGPoint(x: startNodePosition.x + delta.x, y: startNodePosition.y + delta.y)
                    store.updateNodePosition(nodeId: nodeId, worldPosition: newPosition)

                case .none:
                    break
                }
            }
            .onEnded { _ in
                if case .pan = dragMode {
                    lastDragOffset = offset
                }

                if case .node = dragMode {
                    store.persistLayout()
                }
                dragMode = nil
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastMagnification
                scale = (scale * delta).clamped(to: 0.35 ... 3.5)
                lastMagnification = value
            }
            .onEnded { _ in
                lastMagnification = 1.0
            }
    }

    private func resetTransform() {
        scale = 1.0
        offset = .zero
        lastDragOffset = .zero
        lastMagnification = 1.0
    }

    private func centerOnSelected() {
        guard let selectedId = store.selectedNodeId, let world = store.positions[selectedId] else {
            return
        }
        scale = 1.0
        offset = CGSize(width: -world.x * scale, height: -world.y * scale)
        lastDragOffset = offset
        lastMagnification = 1.0
    }

    private func worldToScreen(_ point: CGPoint, center: CGPoint) -> CGPoint {
        CGPoint(
            x: center.x + offset.width + point.x * scale,
            y: center.y + offset.height + point.y * scale
        )
    }

    private func screenToWorld(_ point: CGPoint, center: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - center.x - offset.width) / scale,
            y: (point.y - center.y - offset.height) / scale
        )
    }

    private func drawArrowHead(context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let len = max(hypot(dx, dy), 0.0001)
        let ux = dx / len
        let uy = dy / len

        let arrowSize: CGFloat = 10
        let back = CGPoint(x: to.x - ux * 18, y: to.y - uy * 18)
        let left = CGPoint(x: back.x + (-uy) * arrowSize, y: back.y + ux * arrowSize)
        let right = CGPoint(x: back.x - (-uy) * arrowSize, y: back.y - ux * arrowSize)

        var path = Path()
        path.move(to: to)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    private func edgeLabelPoint(from a: CGPoint, to b: CGPoint, seed: String, occupied: inout [CGRect]) -> CGPoint {
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = max(hypot(dx, dy), 0.0001)
        let nx = -dy / len
        let ny = dx / len
        let h = stableHash(seed)
        let baseSign: CGFloat = (h % 2 == 0) ? 1 : -1
        let baseStep = Int(h % 3)

        let candidates: [CGFloat] = [
            10 + CGFloat(baseStep) * 6,
            22 + CGFloat(baseStep) * 8,
            34 + CGFloat(baseStep) * 10,
            46 + CGFloat(baseStep) * 12,
            58 + CGFloat(baseStep) * 14
        ]

        for distance in candidates {
            for sign in [baseSign, -baseSign] {
                let point = CGPoint(x: mid.x + nx * distance * sign, y: mid.y + ny * distance * sign)
                let probe = CGRect(x: point.x - 50, y: point.y - 14, width: 100, height: 28)
                if !occupied.contains(where: { $0.intersects(probe) }) {
                    return point
                }
            }
        }

        let fallbackDistance = candidates.last ?? 40
        return CGPoint(x: mid.x + nx * fallbackDistance * baseSign, y: mid.y + ny * fallbackDistance * baseSign)
    }

    private func colorForRelationTypeId(_ id: String) -> Color {
        let h = stableHash(id)
        let hue = Double(h % 360) / 360.0
        return Color(hue: hue, saturation: 0.70, brightness: 0.85)
    }

    private func stableHash(_ value: String) -> Int {
        var result: UInt64 = 14695981039346656037
        for byte in value.utf8 {
            result ^= UInt64(byte)
            result &*= 1099511628211
        }
        return Int(result % UInt64(Int.max))
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
