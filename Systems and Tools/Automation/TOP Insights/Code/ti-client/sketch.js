let isConnected = false;
let nodes;
let cards;
let gauge;
let oeeSegments;
let timeline;

let scaleW = 1;
let scaleH = 1;
let textScale = 1;
let minMargin = 20;
let minWinWidth = 360.0;
let minWinHeight = 612.0;
let winMargin;

let nodesData;
let codenames = ["BLW", "LBL", "PKR", "PLT"];
let availabilityLabels = [
  "Runtime",
  "Availability Loss",
  "Unplanned Stop T",
  "Planned Stop T",
];
let performanceLabels = [
  "Net Runtime",
  "Performance Loss",
  "Slow Cycles",
  "Small Stops",
];
let qualityLabels = [
  "Fully Productive T",
  "Quality Loss",
  "Good Count",
  "Reject Count",
];
let selectedNodeIndex = 0;

function setup() {
  createCanvas(windowWidth, windowHeight); // Create a canvas that fills the entire window
  windowResized();

  nodes = new Nodes();
  cards = new Map();
  for (var label of nodes.labels) {
    var card = new Card();
    card.setHeader("-");
    card.setLabel(label);
    cards.set(label, card);
  }
  cards.get("BLW").setActive(); // TODO: Set first card active from class

  oeeSegments = new SegmentedControl(["AVA", "PRF", "QUA"]);
  timeline = new Timeline("Timeline");

  gauge = new SolidGauge(oeeSegments.getSelectedOption());
  gauge.setColors(Colors.GAUGE_COLORS);
  gauge.addLabels(availabilityLabels);
  gauge.addLabels(performanceLabels);
  gauge.addLabels(qualityLabels);
  gauge.setLabels(oeeSegments.getSelectedIndex());

  fetchData(); // Fetch data once on setup
  setInterval(fetchData, 3000); // Fetch data every x second
}

function draw() {
  background(Colors.BACKGROUND);

  let posY = winMargin;
  noStroke();
  textFont("Euclid Square", 20 * textScale);
  textStyle(NORMAL);
  fill(Colors.HEADER_TEXT);
  textAlign(LEFT, TOP);
  text("TOP Insights", winMargin, posY);
  textAlign(RIGHT, TOP);
  text("LIVE", windowWidth - winMargin, posY);

  posY += 20 * textScale + 6; // 6 Padding

  textFont("Euclid Square", 14 * textScale);
  textStyle(NORMAL);
  fill(Colors.SUBHEADER_TEXT);
  textAlign(LEFT, TOP);
  let subheaderText =
    nodes.getSite() + " • " + nodes.getLine() + " [" + nodes.getProduct() + "]";
  text(subheaderText.length < 7 ? "" : subheaderText, winMargin, posY);
  textAlign(RIGHT, TOP);
  text(nodes.getDatestamp(), windowWidth - winMargin, posY);

  posY += 14 * textScale + winMargin;
  let cardW = new Card().getWidth();
  let cardH = new Card().getHeight();
  let posX = winMargin;
  let gapX = (width - winMargin * 2 - cardW * cards.size) / (cards.size - 1);
  for (let card of cards.values()) {
    card.draw(posX, posY);
    posX += gapX + cardW;
  }

  posY += cardH + winMargin + gauge.getWeight();
  gauge.draw(width / 2, posY);

  posY += gauge.getTotalHeight() + winMargin;
  oeeSegments.draw(posY);

  posY += oeeSegments.getHeight() + winMargin * 0.5;
  timeline.draw(winMargin, posY);
}

function windowResized() {
  resizeCanvas(windowWidth, windowHeight); // Resize the canvas when the window is resized
  winMargin = max(minMargin, min(windowHeight, windowWidth) * 0.05);
  scaleW = max(windowWidth, minWinWidth) / minWinWidth;
  scaleH = max(windowHeight, minWinHeight) / minWinHeight;
  textScale = max(windowWidth, minWinWidth) / minWinWidth;
}

function mouseReleased() {
  if (oeeSegments.getHovered() !== null) {
    oeeSegments.mouseReleased();
  }

  timeline.mouseReleased();

  let index = 0;
  for (var label of nodes.labels) {
    let card = cards.get(label);
    if (card.isHovered()) {
      for (var label of nodes.labels) cards.get(label).setInactive();
      card.setActive();
      selectedNodeIndex = index;
      break;
    }

    index++;
  }

  // Update components after interaction
  assignNodesdata();
}

function fetchData() {
  isConnected = false;
  // fetch("https://devoted-gentle-monarch.ngrok-free.app/data")
  fetch("http://localhost:3000/data")
    .then((response) => {
      if (!response.ok) throw new Error("Network response was not ok");
      return response.json(); // Convert response to JSON
    })
    .then((jsonData) => {
      if (jsonData) {
        updateNodesData(jsonData);
        print (jsonData)
        assignNodesdata();
      }
    })
    .catch((err) => {
      console.error("Error fetching data:", err);
    });

  isConnected = true;
}

function updateNodesData(data) {
  if (!data) return;
  nodes.setNodesData(data);
  nodes.setData(data);
}

function assignNodesdata() {
  assignCardsData();
  assignGaugeData();
  assignTimelineData();
}

function rectHovered(x, y, w, h, ori = CORNER) {
  if (ori === CENTER) {
    x -= w / 2;
    y -= h / 2;
  }
  return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
}

function toIntPercentage(val) {
  val = val * 100;
  val = constrain(val, 0, 100);
  return round(val);
}

function assignCardsData() {
  for (var label of nodes.labels) {
    let node = nodes.get(label);
    if (node === undefined) continue;

    let card = cards.get(label);
    card.setHeader(toIntPercentage(node.getOEE()) + "%"); // OEE Percentage
    card.setState(node.getState()); // For badge
  }
}
function assignGaugeData() {
  let selectedNode = nodes.get(codenames[selectedNodeIndex]);
  if (selectedNode === undefined) return;

  gauge.setTitle(oeeSegments.getSelectedOption());
  gauge.setLabelsByIndex(oeeSegments.getSelectedIndex());
  let headers = [
    toIntPercentage(selectedNode.getAvailability()),
    toIntPercentage(selectedNode.getPerformance()),
    toIntPercentage(selectedNode.getQuality()),
  ];
  gauge.setHeader(headers[oeeSegments.getSelectedIndex()] + "%");
  let values = [
    [
      selectedNode.getRuntime(),
      selectedNode.getAvailabilityLoss(),
      selectedNode.getUnplannedStops(),
      selectedNode.getPlannedStops(),
    ],
    [
      selectedNode.getNetRuntime(),
      selectedNode.getPerformanceLoss(),
      selectedNode.getSlowCycles(),
      selectedNode.getSmallStops(),
    ],
    [
      selectedNode.getFullyProductiveTime(),
      selectedNode.getQualityLoss(),
      selectedNode.getGoods(),
      selectedNode.getRejects(),
    ],
  ];
  gauge.setValuesArray(values[oeeSegments.getSelectedIndex()]);
}
function assignTimelineData() {
  let node = nodes.get(codenames[selectedNodeIndex]);
  if (node === undefined) return;

  let t_data = node.getTimeline();
  if (t_data === undefined) return;

  timeline.clear();
  for (let i = 0; i < t_data.length; i++) {
    timeline.add(parseFloat(t_data[i].f), t_data[i].s);
  }
}
