#!/usr/bin/env node
// Render a scene JSON as a hand-drawn diagram with rough.js, in the dark
// Excalidraw style. Write the picture as an SVG, and the same scene as an
// Excalidraw file.
//
// Usage: rex-diagram-render.cjs SCENE.json OUT.svg OUT.excalidraw
//
// ROUGH_JS is the path of the CommonJS bundle of rough.js. The SVG uses the
// font family Excalifont. A bad scene prints one line on stderr and exits 1.
"use strict";
const fs = require("fs");

const SHAPES = ["rect", "ellipse", "diamond"];
const TYPES = [...SHAPES, "text", "arrow", "line"];
const BG = "#121212";
const MARGIN = 40;
const FONT = 20;
const ARROW_FONT = 16;
const CHAR_W = 0.56; // average glyph width of Excalifont, in em
const LINE_H = 1.25;
const GAP = 6; // space between the end of an arrow and the edge of a shape
const TOP_PAD = 10; // space above a label with labelPos "top"

// Excalidraw palette: stroke and fill per name. The SVG uses the dark
// colors. The Excalidraw file stores the light colors, because Excalidraw
// makes them dark when it shows the dark theme.
const palette = {
  light: {
    black: ["#1e1e1e", "#e9ecef"],
    red: ["#e03131", "#ffc9c9"],
    green: ["#2f9e44", "#b2f2bb"],
    blue: ["#1971c2", "#a5d8ff"],
    yellow: ["#f08c00", "#ffec99"],
    violet: ["#6741d9", "#d0bfff"],
    gray: ["#868e96", "#e9ecef"],
  },
  dark: {
    black: ["#e3e3e8", "#343a40"],
    red: ["#ff8383", "#5c1f1f"],
    green: ["#3ab95e", "#1c4027"],
    blue: ["#56a2e8", "#154163"],
    yellow: ["#f5a43a", "#5b4613"],
    violet: ["#a28af5", "#3a2a6b"],
    gray: ["#adb5bd", "#2c3034"],
  },
};

function color(theme, name) {
  return palette[theme][name] || palette[theme].black;
}

function fail(msg) {
  throw new Error(msg);
}

function describe(el, i) {
  return `element ${i} (${el.type}${el.id != null ? ` "${el.id}"` : ""})`;
}

function textSize(text, size) {
  const lines = String(text).split("\n");
  const w = Math.max(...lines.map((l) => l.length)) * size * CHAR_W;
  return { w, h: lines.length * size * LINE_H, lines };
}

function center(s) {
  return [s.x + s.w / 2, s.y + s.h / 2];
}

// Boundary point of a shape in the direction of (tx, ty).
function edge(s, tx, ty) {
  const [cx, cy] = center(s);
  const dx = tx - cx,
    dy = ty - cy;
  if (dx === 0 && dy === 0) return [cx, cy];
  const a = s.w / 2 + GAP,
    b = s.h / 2 + GAP;
  let t;
  if (s.type === "ellipse") t = 1 / Math.sqrt((dx * dx) / (a * a) + (dy * dy) / (b * b));
  else if (s.type === "diamond") t = 1 / (Math.abs(dx) / a + Math.abs(dy) / b);
  else t = Math.min(a / Math.abs(dx || 1e-9), b / Math.abs(dy || 1e-9));
  return [cx + dx * t, cy + dy * t];
}

// Check the scene, give each element its size and position, and shift all
// elements so that the bounding box starts at the margin.
function layout(scene) {
  const els = scene.elements;
  if (!Array.isArray(els)) fail('the scene has no "elements" array');
  const byId = {};
  els.forEach((el, i) => {
    if (!TYPES.includes(el.type)) fail(`${describe(el, i)}: unknown type, use one of ${TYPES.join(", ")}`);
    el.key = el.id != null ? String(el.id) : `el${i}`;
    if (SHAPES.includes(el.type)) {
      el.size = el.fontSize || FONT;
      el.ts = el.label ? textSize(el.label, el.size) : null;
      const ts = el.ts || { w: 0, h: 0 };
      const k = el.type === "rect" ? 1 : 1.5;
      el.w = el.w || Math.max(120, ts.w * k + 40);
      el.h = el.h || Math.max(60, ts.h * k + 30);
      if (el.id != null) byId[el.id] = el;
    } else if (el.type === "text") {
      el.size = el.fontSize || FONT;
      el.ts = textSize(el.text ?? "", el.size);
    }
  });

  for (const [i, el] of els.entries()) {
    if (el.type !== "arrow" && el.type !== "line") continue;
    for (const end of ["from", "to"]) {
      if (el[end] != null && !byId[el[end]]) fail(`${describe(el, i)}: "${end}" names an unknown shape id "${el[end]}"`);
    }
    const pts = (el.points || []).map((p) => [...p]);
    if ((el.from != null) + pts.length + (el.to != null) < 2) {
      fail(`${describe(el, i)}: needs two points or more, from "from", "points", and "to"`);
    }
    if (el.from != null) pts.unshift(edge(byId[el.from], ...(pts[0] || center(byId[el.to]))));
    if (el.to != null) pts.push(edge(byId[el.to], ...pts[pts.length - 1]));
    el.pts = pts;
    if (el.label) {
      const m = Math.floor((pts.length - 1) / 2);
      el.mid = [(pts[m][0] + pts[m + 1][0]) / 2, (pts[m][1] + pts[m + 1][1]) / 2];
      el.size = el.fontSize || ARROW_FONT;
      el.ts = textSize(el.label, el.size);
    }
  }

  const boxes = [];
  for (const el of els) {
    if (SHAPES.includes(el.type)) boxes.push([el.x, el.y, el.x + el.w, el.y + el.h]);
    else if (el.type === "text") {
      const [x0] = textBox(el);
      boxes.push([x0, el.y - el.ts.h / 2, x0 + el.ts.w, el.y + el.ts.h / 2]);
    } else {
      for (const [x, y] of el.pts) boxes.push([x, y, x, y]);
      if (el.mid) {
        const [mx, my] = el.mid;
        boxes.push([mx - el.ts.w / 2 - 4, my - el.ts.h / 2, mx + el.ts.w / 2 + 4, my + el.ts.h / 2]);
      }
    }
  }
  const minX = Math.min(...boxes.map((b) => b[0])),
    minY = Math.min(...boxes.map((b) => b[1])),
    maxX = Math.max(...boxes.map((b) => b[2])),
    maxY = Math.max(...boxes.map((b) => b[3]));
  const dx = MARGIN - minX,
    dy = MARGIN - minY;
  for (const el of els) {
    if (el.pts) {
      el.pts = el.pts.map(([x, y]) => [x + dx, y + dy]);
      if (el.mid) el.mid = [el.mid[0] + dx, el.mid[1] + dy];
    } else {
      el.x += dx;
      el.y += dy;
    }
  }
  return { els, width: maxX - minX + 2 * MARGIN, height: maxY - minY + 2 * MARGIN };
}

// The left edge of a text element and its SVG text-anchor.
function textBox(el) {
  const align = el.align || "start";
  const x0 = align === "middle" ? el.x - el.ts.w / 2 : align === "end" ? el.x - el.ts.w : el.x;
  return [x0, align];
}

// The center of the label of a shape.
function labelCenter(el) {
  const [cx, cy] = center(el);
  return el.type === "rect" && el.labelPos === "top" ? [cx, el.y + TOP_PAD + el.ts.h / 2] : [cx, cy];
}

function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function svgText(x, y, ts, size, fill, anchor = "middle") {
  const top = y - ((ts.lines.length - 1) * size * LINE_H) / 2;
  return ts.lines
    .map(
      (l, i) =>
        `<text x="${x}" y="${top + i * size * LINE_H}" font-family="Excalifont" font-size="${size}" fill="${fill}" text-anchor="${anchor}" dominant-baseline="central">${esc(l)}</text>`,
    )
    .join("");
}

function svg({ els, width, height }) {
  const rough = require(process.env.ROUGH_JS);
  const gen = rough.generator();
  let seed = 1;
  const out = [];

  const opts = (el) => {
    const [stroke, fill] = color("dark", el.color);
    return {
      seed: seed++,
      stroke,
      strokeWidth: 2,
      roughness: 1,
      fill: el.fill === true ? fill : undefined,
      fillStyle: el.fillStyle || "hachure",
      hachureGap: 8,
      fillWeight: 1,
      bowing: 1,
    };
  };

  // The outline of a dashed element gets a dash. Its fill does not.
  const paths = (drawable, dashed) =>
    gen
      .toPaths(drawable)
      .map(
        (p, i) =>
          `<path d="${p.d}" stroke="${p.stroke}" stroke-width="${p.strokeWidth}" fill="${p.fill || "none"}"${
            dashed && drawable.sets[i].type === "path" ? ' stroke-dasharray="12 8"' : ""
          }/>`,
      )
      .join("");

  for (const el of els) {
    if (!SHAPES.includes(el.type)) continue;
    const o = opts(el);
    let d;
    if (el.type === "rect") d = gen.rectangle(el.x, el.y, el.w, el.h, o);
    else if (el.type === "ellipse") d = gen.ellipse(el.x + el.w / 2, el.y + el.h / 2, el.w, el.h, o);
    else {
      const [cx, cy] = center(el);
      d = gen.polygon(
        [
          [cx, el.y],
          [el.x + el.w, cy],
          [cx, el.y + el.h],
          [el.x, cy],
        ],
        o,
      );
    }
    out.push(paths(d, el.dashed));
    if (el.ts) out.push(svgText(...labelCenter(el), el.ts, el.size, o.stroke));
  }

  for (const el of els) {
    if (!el.pts) continue;
    const pts = el.pts;
    const o = opts(el);
    o.fill = undefined;
    out.push(paths(pts.length > 2 ? gen.curve(pts, o) : gen.line(...pts[0], ...pts[1], o), el.dashed));
    const heads = el.type === "arrow" ? (el.both ? [0, 1] : [1]) : [];
    for (const h of heads) {
      const [ex, ey] = h ? pts[pts.length - 1] : pts[0];
      const [px, py] = h ? pts[pts.length - 2] : pts[1];
      const ang = Math.atan2(ey - py, ex - px);
      const L = 16,
        A = 0.45;
      for (const s of [-1, 1]) {
        out.push(
          paths(gen.line(ex, ey, ex - L * Math.cos(ang + s * A), ey - L * Math.sin(ang + s * A), { ...o, seed: seed++ })),
        );
      }
    }
    if (el.mid) {
      const [mx, my] = el.mid;
      out.push(`<rect x="${mx - el.ts.w / 2 - 4}" y="${my - el.ts.h / 2}" width="${el.ts.w + 8}" height="${el.ts.h}" fill="${BG}"/>`);
      out.push(svgText(mx, my, el.ts, el.size, o.stroke));
    }
  }

  for (const el of els) {
    if (el.type !== "text") continue;
    out.push(svgText(el.x, el.y, el.ts, el.size, color("dark", el.color)[0], textBox(el)[1]));
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" stroke-linecap="round" stroke-linejoin="round"><rect width="100%" height="100%" fill="${BG}"/>${out.join("")}</svg>\n`;
}

function excalidraw({ els }) {
  let n = 0;
  const rand = () => (++n * 2654435761) % 2147483647;
  const base = (el, type, x, y, width, height, extra) => ({
    id: extra.id || el.key,
    type,
    x,
    y,
    width,
    height,
    angle: 0,
    strokeColor: color("light", el.color)[0],
    backgroundColor: el.fill === true && SHAPES.includes(el.type) ? color("light", el.color)[1] : "transparent",
    fillStyle: el.fillStyle || "hachure",
    strokeWidth: 2,
    strokeStyle: el.dashed ? "dashed" : "solid",
    roughness: 1,
    opacity: 100,
    groupIds: [],
    frameId: null,
    roundness: null,
    seed: rand(),
    version: 1,
    versionNonce: rand(),
    isDeleted: false,
    boundElements: null,
    updated: 1,
    link: null,
    locked: false,
    ...extra,
  });
  const text = (el, id, str, size, cx, cy, ts, align, extra) =>
    base(el, "text", cx - ts.w / 2, cy - ts.h / 2, ts.w, ts.h, {
      id,
      strokeStyle: "solid",
      backgroundColor: "transparent",
      text: str,
      originalText: str,
      fontSize: size,
      fontFamily: 5,
      textAlign: align,
      verticalAlign: "middle",
      containerId: null,
      autoResize: true,
      lineHeight: LINE_H,
      ...extra,
    });

  const out = [];
  const bound = {};
  const bind = (key, ref) => (bound[key] = bound[key] || []).push(ref);
  for (const el of els) {
    if (el.pts && el.type === "arrow") {
      if (el.from != null) bind(String(el.from), { id: el.key, type: "arrow" });
      if (el.to != null) bind(String(el.to), { id: el.key, type: "arrow" });
    }
    if (el.ts && el.type !== "text") bind(el.key, { id: `${el.key}-label`, type: "text" });
  }

  for (const el of els) {
    if (SHAPES.includes(el.type)) {
      const type = el.type === "rect" ? "rectangle" : el.type;
      out.push(base(el, type, el.x, el.y, el.w, el.h, { boundElements: bound[el.key] || null }));
      if (el.ts) {
        const top = el.type === "rect" && el.labelPos === "top";
        out.push(
          text(el, `${el.key}-label`, el.label, el.size, ...labelCenter(el), el.ts, "center", {
            containerId: el.key,
            verticalAlign: top ? "top" : "middle",
          }),
        );
      }
    } else if (el.type === "text") {
      const [x0, align] = textBox(el);
      const textAlign = { start: "left", middle: "center", end: "right" }[align] || "left";
      out.push(text(el, el.key, String(el.text ?? ""), el.size, x0 + el.ts.w / 2, el.y, el.ts, textAlign, {}));
    } else {
      const [x0, y0] = el.pts[0];
      const points = el.pts.map(([x, y]) => [x - x0, y - y0]);
      const xs = points.map((p) => p[0]),
        ys = points.map((p) => p[1]);
      const binding = (id) => (el.type === "arrow" && id != null ? { elementId: String(id), focus: 0, gap: GAP, fixedPoint: null } : null);
      out.push(
        base(el, el.type, x0, y0, Math.max(...xs) - Math.min(...xs), Math.max(...ys) - Math.min(...ys), {
          roundness: points.length > 2 ? { type: 2 } : null,
          boundElements: bound[el.key] || null,
          points,
          lastCommittedPoint: null,
          startBinding: binding(el.from),
          endBinding: binding(el.to),
          startArrowhead: el.type === "arrow" && el.both ? "arrow" : null,
          endArrowhead: el.type === "arrow" ? "arrow" : null,
          elbowed: false,
        }),
      );
      if (el.ts) {
        out.push(
          text(el, `${el.key}-label`, el.label, el.size, ...el.mid, el.ts, "center", {
            containerId: el.key,
          }),
        );
      }
    }
  }

  return {
    type: "excalidraw",
    version: 2,
    source: "rex-diagram",
    elements: out,
    appState: { viewBackgroundColor: "#ffffff", theme: "dark" },
    files: {},
  };
}

function main() {
  const [, , inPath, svgPath, exPath] = process.argv;
  if (!exPath) fail("usage: rex-diagram-render.cjs SCENE.json OUT.svg OUT.excalidraw");
  const scene = JSON.parse(fs.readFileSync(inPath, "utf8"));
  const laid = layout(scene);
  fs.writeFileSync(svgPath, svg(laid));
  fs.writeFileSync(exPath, JSON.stringify(excalidraw(laid), null, 2) + "\n");
}

try {
  main();
} catch (e) {
  process.stderr.write(`rex-diagram: ${e.message}\n`);
  process.exit(1);
}
