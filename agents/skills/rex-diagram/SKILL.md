---
name: rex-diagram
description: Draw a hand-drawn diagram in the Excalidraw style and show it in
  a Rex pane beside the agent. Use when the user asks you to draw, sketch, or
  diagram something, or to explain something visually, for example "draw me
  a diagram of this", "sketch the flow", or "show me how this works in a
  picture". Do not use it on your own. Do not offer a diagram when the user
  did not ask for one.
compatibility: Needs Rex with kitty graphics (REX_BLOCK set, rex in
  REX_BIN_DIR or on PATH) and the rex-diagram command.
---

# Draw a diagram in Rex

This skill draws a diagram from a scene file. A scene file is a JSON file
that lists the boxes, arrows, and texts of the picture. The `rex-diagram`
command makes a PNG in the dark Excalidraw style, and shows it in a pane on
the right of your Rex pane. It also writes a `.excalidraw` file. The user
can open that file on excalidraw.com and edit the diagram.

There is one diagram pane for each agent pane. A new diagram replaces the
picture in the same pane. If the user closed the pane, the next diagram
opens a new one. The keyboard focus stays on your pane.

## When to use it

Use this skill only when the user asks for a picture. For example:

- "Draw me a diagram of this."
- "Sketch the request flow."
- "Explain it visually."

Do not draw a diagram on your own. Do not offer one.

## Procedure

1. Plan the picture: the boxes, the arrows, and their labels. Keep it to
   about 12 shapes or fewer. Use a flow from left to right, or from top to
   bottom.
2. Write the scene JSON to a file in your scratchpad or temp directory.
   Name it after the topic, for example `auth-flow.json`.
3. Run `rex-diagram render FILE`. Read the PNG. Fix overlaps, labels that
   do not fit, and arrows that cross shapes. Render again until the picture
   is clean.
4. Run `rex-diagram show FILE`.
5. In the chat, write a short explanation (a few sentences) that walks
   through the diagram. Do not repeat the full answer. Give the paths of
   the PNG and the `.excalidraw` file.

To change a diagram, edit the same scene file and run `show` again. The
same pane shows the new picture.

## Output and exit status

`render` and `show` write `NAME.png` and `NAME.excalidraw` next to
`NAME.json`. They print the two paths, one on each line.

- `0`: Done.
- `1`: The scene is bad. The message on stderr names the element. Fix the
  scene and run the command again.
- `3`: `show` is not in a Rex pane. The render is done. Give the user the
  two paths, and tell them that the PNG is the diagram.

## Scene format

A scene is an object with an `elements` array. The renderer draws the
shapes first, then the arrows and lines, then the free texts. Shapes are
drawn in the order of the array. The canvas fits all elements with a margin
of 40 px, so you can use any coordinates. The picture is always dark.

### Shapes: `rect`, `ellipse`, `diamond`

| Field | Meaning |
| --- | --- |
| `id` | A name. Arrows use it in `from` and `to`. |
| `x`, `y` | The top-left corner, in px. |
| `w`, `h` | Optional. The size, in px. If you do not give them, the size comes from the label (at least 120 x 60). |
| `label` | Optional. The text in the shape. Use `\n` for a new line. |
| `labelPos` | `rect` only. `"top"` puts the label at the top inside edge. Use it for a container box around other shapes. |
| `color` | `black` (default, light gray on dark), `red`, `green`, `blue`, `yellow`, `violet`, or `gray`. |
| `fill` | `true` fills the shape with the color. Default `false`. |
| `fillStyle` | `hachure` (default), `cross-hatch`, or `solid`. |
| `dashed` | `true` draws a dashed outline. |
| `fontSize` | The label size. Default 20. |

### Arrows and lines: `arrow`, `line`

| Field | Meaning |
| --- | --- |
| `from`, `to` | Optional. The `id` of a shape. The end binds to the edge of that shape. |
| `points` | Optional. Bend points, as `[[x, y], ...]`, between `from` and `to`. |
| `label` | Optional. The text on the middle segment. |
| `both` | `arrow` only. `true` draws a head at both ends. |
| `color`, `dashed`, `fontSize` | As for shapes. The label size default is 16. |

An arrow needs two points or more. `from`, each item of `points`, and `to`
each give one point. A `line` has no heads.

### Text: `text`

| Field | Meaning |
| --- | --- |
| `x`, `y` | The anchor. `y` is the vertical center of the text. |
| `text` | The text. Use `\n` for a new line. |
| `align` | `start` (default, `x` is the left edge), `middle`, or `end`. |
| `color`, `fontSize` | As for shapes. The size default is 20. |

### Example

```json
{
  "elements": [
    { "type": "text", "x": 0, "y": 0, "text": "Login flow", "fontSize": 28 },
    { "id": "backend", "type": "rect", "x": 260, "y": 60, "w": 460, "h": 160, "label": "Backend", "labelPos": "top", "color": "gray", "dashed": true },
    { "id": "user", "type": "ellipse", "x": 0, "y": 110, "label": "User", "color": "green", "fill": true },
    { "id": "api", "type": "rect", "x": 300, "y": 120, "label": "API", "color": "blue", "fill": true },
    { "id": "db", "type": "rect", "x": 520, "y": 120, "label": "Sessions DB", "color": "yellow", "fill": true },
    { "id": "valid", "type": "diamond", "x": 290, "y": 280, "label": "valid?", "color": "violet" },
    { "id": "err", "type": "rect", "x": 520, "y": 290, "label": "401 error", "color": "red", "fill": true, "fillStyle": "solid" },
    { "type": "arrow", "from": "user", "to": "api", "label": "POST /login" },
    { "type": "arrow", "from": "api", "to": "db", "label": "check", "both": true },
    { "type": "arrow", "from": "api", "to": "valid" },
    { "type": "arrow", "from": "valid", "to": "err", "label": "no", "color": "red" },
    { "type": "arrow", "from": "valid", "points": [[60, 320]], "to": "user", "label": "yes: token", "color": "green" },
    { "type": "text", "x": 520, "y": 390, "text": "A token expires after one hour.", "color": "gray", "fontSize": 16 }
  ]
}
```

## Layout tips

- Put the shapes on a grid of columns about 220 px apart and rows about
  140 px apart. Then the arrows have space for their labels.
- Do not give `w` and `h` for normal shapes. The size comes from the label.
  Give them for a container.
- Put a container (`labelPos: "top"`) first in the array, so that it is
  drawn below the shapes in it. Leave space between its edge and the arrows
  that cross it.
- If an arrow crosses a shape, add a bend point in `points` to route it
  around the shape.
- Use color for meaning, and keep it the same in one diagram. For example:
  blue for services, yellow for data, green for the user, red for errors,
  and gray for notes and containers.
- Keep labels short: one to three words. Use a free `text` for a longer
  note.
