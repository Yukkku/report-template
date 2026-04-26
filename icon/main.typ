#let icon(size, background: white, foreground: black) = {
  let poly = (
    (0, -20),
    (10, -10),
    (10, 10),
    (2, 18),
    (2, -2),
    (9, -9),
    (9, 9),
    (-9, -9),
    (0, -18),
    (0, 20),
    (-10, 10),
    (-10, -10),
  )
  square(size: size, stroke: none, fill: background, place(dx: 50%, dy: 50%, polygon(
    stroke: none,
    fill: foreground,
    fill-rule: "even-odd",
    ..poly.map(((x, y)) => (x * size * calc.sqrt(3) / 50, y * size / 50)),
  )))
};
