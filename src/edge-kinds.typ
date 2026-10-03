#import "utils.typ"
#import "deps.typ": cetz

#let EDGE_KINDS = (
  line: (
    draw: (_, vertices) => cetz.draw.line(..vertices)
  ),
  cetz: (),
  arc: (
    required: ("bend",),
    optional: (:),
    n-vertices: 2,
    draw: ((bend,), (a, b)) => {
      let perp-dist = if type(bend) == angle {
        let sin-bend = calc.sin(bend)
        if calc.abs(sin-bend) < 1e-3 { return cetz.draw.line(a, b) }
        let half-chord-len = cetz.vector.dist(a, b) / 2
        half-chord-len * (1 - calc.cos(bend)) / sin-bend
      } else {
        bend
      }
      let midpoint = (a: (a, 50%, b), b: a, number: perp-dist, angle: -90deg)
      cetz.draw.merge-path(cetz.draw.arc-through(a, midpoint, b))
    },
  ),
  bezier-cubic: (
    required: ("from", "to"),
    optional: (:),
    n-vertices: 2,
    validate-args: (ctx, (from, to)) => {
      let as-coord(x) = if type(x) == angle { (x, 1) } else { x }
      (from: as-coord(from), to: as-coord(to))
    },
    draw: ((from, to), (a, b)) => {
      cetz.draw.bezier(a, b, (rel: from, to: a), (rel: to, to: b))
    },
  ),
  bezier-from: (
    required: ("from",),
    optional: (:),
    n-vertices: 2,
    validate-args: (ctx, (from,)) => {
      let as-coord(x) = if type(x) == angle { (x, 1) } else { x }
      (from: as-coord(from))
    },
    draw: ((from,), (a, b)) => {
      cetz.draw.bezier(a, b, (rel: from, to: a))
    },
  ),
  bezier-to: (
    required: ("to",),
    optional: (:),
    n-vertices: 2,
    validate-args: (ctx, (to,)) => {
      let as-coord(x) = if type(x) == angle { (x, 1) } else { x }
      (to: as-coord(to))
    },
    draw: ((to,), (a, b)) => {
      cetz.draw.bezier(a, b, (rel: to, to: b))
    },
  ),
  bezier-through: (
    required: ("through",),
    optional: (:),
    n-vertices: 2,
    draw: ((through,), (a, b)) => {
      cetz.draw.bezier-through(a, through, b)
    },
  ),
  loop: (
    required: ("loop",),
    optional: (size: 1.5em),
    n-vertices: 1,
    validate-args: (ctx, (loop, size)) => {
      (
        loop: utils.thing-to-angle(loop),
        size: cetz.util.resolve-number(ctx, size)/2,
      )
    },
    pre-snapping-adjust: (edge, snap-objects) => {
      let bounds = cetz.process.aabb.aabb(cetz.path-util.bounds(snap-objects.first().first().segments))
      let diag = cetz.vector.dist(bounds.high, bounds.low)
      let R = diag*0.354 // 1/(2√2)
      let (loop: θ, size: l) = edge.shape.args
      let d = calc.sqrt(R*R + l*l) - l
      let shift = cetz.vector.scale((calc.cos(θ), calc.sin(θ)), d)
      edge.vertices = edge.vertices.map(pt => cetz.vector.add(pt, shift))
      return edge
    },
    draw: ((loop, size), (a, ..)) => {
      cetz.draw.arc(a, radius: size, start: loop + 180deg, delta: -360deg)
    },
  ),
  bow: (
    required: ("bow",),
    optional: (size: 2em, angle: 60deg),
    n-vertices: 1,
    validate-args: (ctx, (bow, size, angle)) => {
      (
        bow: utils.thing-to-angle(bow),
        size: cetz.util.resolve-number(ctx, size),
        angle: angle,
      )
    },
    draw: ((bow, size, angle), (a, _)) => {
      let c1 = (to: a, rel: (bow + angle/2, size*1.7))
      let c2 = (to: a, rel: (bow - angle/2, size*1.7))
      cetz.draw.bezier(a, a, c1, c2)
    }
  ),
  corner: (
    required: ("corner",),
    optional: (:),
    draw: ((corner,), (a, b)) => {
      if corner == "|-" {
        cetz.draw.line(a, (a, "|-", b), b)
      } else if corner == "-|" {
        cetz.draw.line(a, (a, "-|", b), b)
      } else if corner == "-|-" {
        let mid = (a, 50%, b)
        cetz.draw.line(a, (a, "-|", mid), (mid, "|-", b), b)
      } else if corner == "|-|" {
        let mid = (a, 50%, b)
        cetz.draw.line(a, (a, "|-", mid), (mid, "-|", b), b)
      } else {
        utils.error("edge shape `corner` accepts one of #..0; got #1", ("-|", "|-", "-|-", "|-|"), repr(corner))
      }
    },
  ),
)
