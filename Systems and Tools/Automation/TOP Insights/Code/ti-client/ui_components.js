class Colors {
  static BACKGROUND = "#292B4D";
  static PRIMARY_TEXT = "#FFFFFF";
  static SECONDARY_TEXT = "#9495A6";
  static HEADER_TEXT = "#FFFFFF";
  static SUBHEADER_TEXT = "#999EC9";
  // State
  static ERROR = "#E62941";
  static NORMAL = "#098F3B";
  static WARNING = "#FD8724";
  static BADGE_CONTAINER = "#FFFFFF";
  // Gauge
  static SECONDARY = "#353766";
  static GAUGE_COLORS = ["#0B8DE2", "#E62941", "#FD8724", "#FFCB00"];
  // Segmented Control
  static CONTAINER_PRIMARY = "#1E1F35";
  static CONTAINER_SECONDARY = "#353766";
  static CONTAINER_TERTIARY = "#4D508F";
}

class Card {
  static badgeBackgroundSize = 12;
  static badgeSize = 8;

  constructor(width, height, header = "-", label = "---") {
    this.x = 0;
    this.y = 0;
    this.cornerRadius = 10;
    this.header = header;
    this.label = label;
    this.state = new State();
    this.setSize(width, height);
    this.setFillColor();
    this.setActive(false);
  }
  setHeader(header) {
    this.header = header;
  }
  setLabel(label) {
    this.label = label;
  }
  setFillColor(fillActive = `#0B8DE2`, fillInactive = `#353766`) {
    this.fillActive = fillActive;
    this.fillInactive = fillInactive;
  }
  setActive(active = true) {
    this.active = active;
  }
  setInactive() {
    this.active = false;
  }
  setSize(width = 72, height = 82) {
    this.width = width;
    this.height = height;
  }
  setState(state) {
    this.state = state;
  }

  getHeight() {
    return this.height * scaleH;
  }
  getWidth() {
    return this.width * scaleW;
  }
  getLabel() {
    return this.label;
  }

  draw(x, y) {
    this.x = x;
    this.y = y;
    noStroke();
    fill(this.active ? this.fillActive : this.fillInactive);
    if (this.isHovered() && mouseIsPressed) fill(Colors.CONTAINER_TERTIARY);
    rectMode(CORNER);
    rect(x, y, this.getWidth(), this.getHeight(), this.cornerRadius);

    textFont("Euclid Square");
    fill(Colors.PRIMARY_TEXT);
    textAlign(CENTER, CENTER);
    textStyle(BOLD);
    textSize(20 * textScale);
    text(this.header, x + this.getWidth() / 2, y + this.getHeight() * 0.407);
    textStyle(NORMAL);
    textSize(13 * textScale);
    text(this.label, x + this.getWidth() / 2, y + this.getHeight() * 0.667);

    // Badge: Background
    ellipseMode(CENTER);
    fill(Colors.BADGE_CONTAINER);
    circle(
      x + this.getWidth() / 2,
      y + this.getHeight(),
      Card.badgeBackgroundSize
    );
    // Badge: Foreground
    // console.log(this.state.getState());
    fill(this.state.getColor());
    circle(x + this.getWidth() / 2, y + this.getHeight(), Card.badgeSize);
  }

  isHovered() {
    return rectHovered(this.x, this.y, this.getWidth(), this.getHeight());
  }
}

class SegmentedControl {
  constructor(options = ["SEG"], marginless = false) {
    this.options = options;
    this.selectedIndex = 0;

    this.x = 0;
    this.y = 0;
    this.setWidthVal = (width - winMargin * 2) / scaleW;
    this.thumbH = 30;
    this.marginless = marginless;
    this.margin = marginless ? 0 : 5;
    this.cornerRadius = 3;
    this.setTextSizeVal = 13;

    this.setThumbSize(
      (this.setWidthVal - (this.length() + 1) * this.margin) / this.length(),
      this.thumbH
    );
  }

  setThumbSize(thumbW, thumbH) {
    this.thumbW = thumbW;
    this.thumbH = thumbH;
    this.setWidth(thumbW * this.length() + this.margin * (this.length() + 1));
  }
  setWidth(setWidthVal) {
    this.setWidthVal = setWidthVal;
  }
  setTextSize(setTextSizeVal) {
    this.setTextSizeVal = setTextSizeVal;
  }

  getWidth() {
    return this.setWidthVal * scaleW;
  }
  getHeight() {
    return this.getThumbH() + this.getMargin() * 2;
  }
  getMargin() {
    return this.margin * scaleH;
  }
  getThumbW() {
    return this.thumbW * scaleW;
  }
  getThumbH() {
    return this.thumbH * scaleH;
  }
  getThumbX(index) {
    return index * this.getThumbW() + (index + 1) * this.getMargin();
  }
  getTextSize() {
    return this.setTextSizeVal * textScale;
  }
  getSelectedIndex() {
    return this.selectedIndex;
  }
  getSelectedOption() {
    return this.options[this.selectedIndex];
  }

  length() {
    return this.options.length;
  }

  draw(y, x = null) {
    if (x === null) x = (width - this.getWidth()) * 0.5;

    this.x = x;
    this.y = y;

    this.thumbW =
      (this.getWidth() - (this.length() + 1) * this.getMargin()) /
      this.length();
    this.thumbW = this.thumbW / scaleW;

    noStroke();
    rectMode(CORNER);

    // Container
    fill(Colors.CONTAINER_PRIMARY);
    rect(x, y, this.getWidth(), this.getHeight(), this.cornerRadius);

    // Thumb
    for (let i = 0; i < this.length(); i++) {
      let isSelected = i === this.selectedIndex;
      let thumbX = x + this.getThumbX(i);
      let thumbY = y + this.getMargin();
      let hovered = rectHovered(
        thumbX,
        thumbY,
        this.getThumbW(),
        this.getThumbH()
      );
      fill(isSelected ? Colors.CONTAINER_SECONDARY : color(0, 0));
      if (hovered && mouseIsPressed) fill(Colors.CONTAINER_TERTIARY);
      rect(
        thumbX,
        thumbY,
        this.getThumbW(),
        this.getThumbH(),
        this.cornerRadius
      );

      // Thumb Text
      textFont("Euclid Square", this.getTextSize());
      textAlign(CENTER, CENTER);
      textStyle(NORMAL);
      if (isSelected) fill(Colors.PRIMARY_TEXT);
      else fill(Colors.SUBHEADER_TEXT);
      text(
        this.options[i],
        x + this.getThumbX(i) + this.getThumbW() * 0.5,
        thumbY + this.getThumbH() * 0.5
      );
    }
  }

  getHovered() {
    if (!rectHovered(this.x, this.y, this.getWidth(), this.getHeight()))
      return null;

    for (let i = 0; i < this.length(); i++) {
      let thumbX = this.x + this.getThumbX(i);
      let thumbY = this.y + this.getMargin();
      let hovered = rectHovered(
        thumbX,
        thumbY,
        this.getThumbW(),
        this.getThumbH()
      );
      if (hovered) return i;
    }

    return null;
  }

  mouseReleased() {
    let hoveredIndex = this.getHovered();
    if (hoveredIndex !== null) this.selectedIndex = hoveredIndex;
  }
}

class Timeline {
  constructor(title) {
    this.width = 320;
    this.height = 85;
    this.margin = 10;

    this.title = title;
    this.cornerRadius = 10;
    // "1h", "6h", "12h",
    this.segments = new SegmentedControl(["24h"], true);
    this.segments.setThumbSize(40, 22);
    this.segments.setTextSize(12);
    this.segments.selectedIndex = 0;

    this.chromogram = new Chromogram();
    // this.chromogram.setWidth(this.getWidth() - winMargin * 2);
    this.chromogram.setStartLabel("12:00 AM");
    this.chromogram.setCurrentLabel("");
    this.chromogram.setEndLabel("11:59 PM");
  }

  add(length, stateName) {
    this.chromogram.add(length, stateName);   
  }
  clear() {
    this.chromogram.clear();
  }

  getWidth() {
    return width - winMargin * 2;
  }
  getHeight() {
    return this.height * scaleH;
  }
  getMargin() {
    return this.margin * scaleH;
  }
  getTitleSize() {
    return 17 * textScale;
  }

  draw(x, y) {
    noStroke();
    rectMode(CORNER);

    // Container
    fill(Colors.CONTAINER_PRIMARY);
    rect(x, y, this.getWidth(), this.getHeight(), this.cornerRadius);

    // Container Title
    textFont("Euclid Square", this.getTitleSize());
    fill(Colors.PRIMARY_TEXT);
    textAlign(LEFT, TOP);
    textStyle(NORMAL);
    text(this.title, x + this.getMargin(), y + this.getMargin());

    this.segments.draw(
      y + this.getMargin(),
      x + this.getWidth() - this.segments.getWidth() - this.getMargin()
    );

    this.chromogram.draw(
      x + this.getMargin(),
      y + this.getMargin() + this.segments.getHeight() + this.getMargin()
    );
  }

  mouseReleased() {
    this.segments.mouseReleased();
  }
}

class Chromogram {
  constructor(width = 300, height = 8, gapLabel = 7) {
    this.width = width;
    this.height = height;
    this.gapLabel = gapLabel;
    this.labelSize = 12;

    this.pStates = new PStates();

    this.startLabel = "DAWN";
    this.endLabel = "DUSK";
    this.currentLabel = "NOW";
  }

  clear() {
    this.pStates.clear();
  }
  add(length, stateName) {
    this.pStates.add(length, new State(stateName));
  }

  setWidth(width) {
    this.width = width;
  }
  setStartLabel(startLabel) {
    this.startLabel = startLabel;
  }
  setEndLabel(endLabel) {
    this.endLabel = endLabel;
  }
  setCurrentLabel(currentLabel) {
    this.currentLabel = currentLabel;
  }

  getWidth() {
    return this.width * scaleW;
  }
  getHeight() {
    return this.height * scaleH;
  }
  getGapLabel() {
    return this.gapLabel * scaleH;
  }
  getLabelSize() {
    return this.labelSize * textScale;
  }

  draw(x, y) {
    noStroke();

    // Rail
    fill(Colors.CONTAINER_SECONDARY);
    rect(x, y, this.getWidth(), this.getHeight());

    // Segments
    let segX = x;
    for (let i = 0; i < this.pStates.size(); i++) {
      let totalW = segX - x;
      if (totalW > this.getWidth()) break;

      let length = this.pStates.getLength(i);
      let state = this.pStates.getState(i);
      let segW = length * this.getWidth();

      fill(state.getColorLight());
      // Remove overflow
      rect(segX, y, min(segW, this.getWidth() - totalW), this.getHeight());

      segX += segW;
    }

    // Labels
    textFont("Euclid Square", this.getLabelSize());
    fill(Colors.SECONDARY_TEXT);
    textStyle(NORMAL);
    textAlign(LEFT, TOP);
    text(this.startLabel, x, y + this.getHeight() + this.getGapLabel());
    textAlign(CENTER, TOP);
    text(
      this.currentLabel,
      x + this.getWidth() * 0.5,
      y + this.getHeight() + this.getGapLabel()
    );
    textAlign(RIGHT, TOP);
    text(
      this.endLabel,
      x + this.getWidth(),
      y + this.getHeight() + this.getGapLabel()
    );
  }
}

class State {
  static UNKNOWN = "UNK";
  static NORMAL = "NRM";
  static SLOW = "SLW";
  static SMALL_STOP = "SST";
  static DOWN = "DWN";
  static allStates = [
    State.UNKNOWN,
    State.NORMAL,
    State.SLOW,
    State.SMALL_STOP,
    State.DOWN,
  ];

  constructor(state = State.UNKNOWN) {
    if (!State.isValid(state)) return;

    this.state = state;

    this.colors = new Map();
    this.colors.set(State.UNKNOWN, Colors.BACKGROUND);
    this.colors.set(State.NORMAL, Colors.NORMAL);
    this.colors.set(State.SLOW, Colors.NORMAL);
    this.colors.set(State.SMALL_STOP, Colors.WARNING);
    this.colors.set(State.DOWN, Colors.ERROR);

    this.lightColors = new Map();
    this.lightColors.set(State.UNKNOWN, Colors.BACKGROUND);
    this.lightColors.set(State.NORMAL, "#75A865");
    this.lightColors.set(State.SLOW, "#75A865");
    this.lightColors.set(State.SMALL_STOP, "#F1AE3B");
    this.lightColors.set(State.DOWN, "#D44353");
  }

  setUnknown() {
    this.state = State.UNKNOWN;
  }
  setNormal() {
    this.state = State.NORMAL;
  }
  setSmallStop() {
    this.state = State.SMALL_STOP;
  }
  setDown() {
    this.state = State.DOWN;
  }
  set(state) {
    if (State.isValid(state)) this.state = state;
    else this.state = State.UNKNOWN;
  }

  isUnknown() {
    return this.state === State.UNKNOWN;
  }
  isNormal() {
    return this.state === State.NORMAL;
  }
  isSmallStop() {
    return this.state === State.SMALL_STOP;
  }
  isDown() {
    return this.state === State.DOWN;
  }
  static isValid(state) {
    return this.allStates.includes(state);
  }

  getState() {
    return this.state;
  }
  getColor() {
    return this.colors.get(this.state);
  }
  getColorLight() {
    return this.lightColors.get(this.state);
  }
}

class PStates {
  constructor() {
    this.lengths = [];
    this.states = [];
    this.prevState = null;
  }

  clear() {
    this.lengths = [];
    this.states = [];
    this.prevState = null;
  }

  add(length, state) {
    if (this.prevState !== null && this.prevState.state === state.state) {
      let prevIndex = this.size() - 1;
      let prevLength = this.getLength(prevIndex);

      this.setLength(prevIndex, prevLength + length);
      return;
    }

    this.lengths.push(length);
    this.states.push(state);
    this.prevState = state;
  }

  setLength(index, length) {
    if (index < 0 || index + 1 > this.size()) return null;
    this.lengths[index] = length;
  }

  getLength(index) {
    if (index < 0 || index + 1 > this.size()) return null;
    return this.lengths[index];
  }
  getState(index) {
    if (index < 0 || index + 1 > this.size()) return null;
    return this.states[index];
  }

  size() {
    return this.lengths.length;
  }
}

class SolidGauge {
  static animationFactor = 0.1;
  constructor(title) {
    this.diameter = 155;
    this.totalHeight = this.diameter;
    this.weight = 8;
    this.gap = 4;
    this.header = "-";
    this.title = title;
    this.colors = [];
    this.values = [];
    this.nowVals = [];
    this.labels = new Map();
    this.labelsSet = [];
  }

  setHeader(header) {
    this.header = header;
  }
  setTitle(title) {
    this.title = title;
  }
  setColors(colors) {
    this.colors = colors;
    this.values = new Array(colors.length).fill(0);
    this.nowVals = new Array(colors.length).fill(0);
    for (let color of colors) {
      let label = new Label();
      label.setMarkerColor(color);
      this.labels.set(color, label);
    }
  }
  setValuesArray(values) {
    for (let i = 0; i < this.values.length; i++) {
      let label = nfc(values[i][1]).length === 0 ? "" : "x" + nfc(values[i][1]);
      this.setPrimaryValue(i, nfc(values[i][0]));
      this.setSecondaryValue(i, toIntPercentage(values[i][2]) + "%");
      this.setSecondaryLabel(i, label);
      this.values[i] = values[i][2];
    }
  }
  setPrimaryValue(index, value) {
    if (index >= 0 && index + 1 <= this.values.length)
      this.getLabel(index).setPrimaryValue(value);
  }
  setSecondaryValue(index, value) {
    if (index >= 0 && index + 1 <= this.values.length)
      this.getLabel(index).setSecondaryValue(value);
  }
  setPrimaryLabel(index, primaryLabel) {
    if (index >= 0 && index + 1 <= this.labels.size)
      this.getLabel(index).setPrimaryLabel(primaryLabel);
  }
  setSecondaryLabel(index, secondaryLabel) {
    if (index >= 0 && index + 1 <= this.labels.size)
      this.getLabel(index).setSecondaryLabel(secondaryLabel);
  }
  setLabels(index, primaryLabel, secondaryLabel) {
    if (index >= 0 && index + 1 <= this.labels.size) {
      let label = this.getLabel(index);
      label.setPrimaryLabel(index, primaryLabel);
      label.setSecondaryLabel(index, secondaryLabel);
    }
  }
  addLabels(labels) {
    this.labelsSet.push(labels);
  }
  setLabelsByIndex(index) {
    if (index + 1 > this.labelsSet.length) return;
    if (this.labelsSet[index].length === 0) return;

    for (let i = 0; i < this.colors.length; i++)
      this.setPrimaryLabel(i, this.labelsSet[index][i]);
  }

  getLabel(index) {
    if (index < 0 || index + 1 > this.labels.size) return null;
    let color = this.colors[index];
    let label = this.labels.get(color);
    return label;
  }
  getWeight() {
    return this.weight * scaleH;
  }
  getDiameter() {
    return this.diameter * scaleH;
  }
  getGap() {
    return this.gap * scaleH;
  }
  getTotalHeight() {
    return this.totalHeight;
  }

  draw(x, setY) {
    let y = setY + gauge.getDiameter() * 0.5;

    textFont("Euclid Square");
    fill(Colors.PRIMARY_TEXT);
    textAlign(CENTER, CENTER);
    textStyle(BOLD);
    textSize(18 * textScale);
    text(this.header, x, y);
    textStyle(NORMAL);
    textSize(10 * textScale);
    text(this.title, x, y + 18 * textScale); // 6 padding

    noFill();
    strokeWeight(this.getWeight());
    strokeCap(ROUND);

    let dia = this.getDiameter();
    for (let i = 0; i < this.colors.length; i++) {
      let color = this.colors[i];
      let p = max(this.values[i], 0.001); // Percentage
      let animationUpdateRequired = abs(this.nowVals[i] - p) > 0.01;
      if (animationUpdateRequired)
        this.nowVals[i] = lerp(this.nowVals[i], p, SolidGauge.animationFactor);
      this.nowVals[i] = max(this.nowVals[i], 0.001);

      stroke(Colors.SECONDARY);
      arc(x, y, dia, dia, 0, TWO_PI); // Rail
      stroke(color);
      arc(x, y, dia, dia, -HALF_PI, -HALF_PI + TWO_PI * this.nowVals[i]);

      dia -= this.getGap() + this.getWeight() * 3;
    }

    // Labels
    let labelGapX = 12 * textScale;
    let labelGapY = 12 * textScale;
    let labelH = new Label().getHeight();
    let posY = y + this.getDiameter() * 0.5 + winMargin + gauge.getWeight();

    this.getLabel(0).draw(winMargin, posY);
    this.getLabel(1).draw(width * 0.5 + labelGapX * 0.5, posY);
    posY += labelGapY + labelH;
    this.getLabel(2).draw(winMargin, posY);
    this.getLabel(3).draw(width * 0.5 + labelGapX * 0.5, posY);
    posY += labelH;

    this.totalHeight = posY - setY;
  }
}

class Label {
  constructor() {
    this.width = 155;
    this.height = 32;
    this.markerColor = Colors.PRIMARY_TEXT;
    this.markerDiameter = 8;
    this.markerGap = 10;

    this.primary = "P";
    this.secondary = "S";
    this.primaryLabel = "";
    this.secondaryLabel = "";
  }

  setMarkerColor(markerColor) {
    this.markerColor = markerColor;
  }
  setPrimaryLabel(primaryLabel) {
    this.primaryLabel = primaryLabel;
  }
  setSecondaryLabel(secondaryLabel) {
    this.secondaryLabel = secondaryLabel;
  }
  setPrimaryValue(primary) {
    this.primary = primary;
  }
  setSecondaryValue(secondary) {
    this.secondary = secondary;
  }

  getWidth() {
    return this.width * scaleW;
  }
  getHeight() {
    return this.height * textScale;
  }
  getMarkerD() {
    return this.markerDiameter * scaleH;
  }
  getMarkerGap() {
    return this.markerGap * textScale;
  }

  draw(x, y) {
    // Marker
    noStroke();
    fill(this.markerColor);
    ellipseMode(CENTER);
    circle(
      x + this.getMarkerD() * 0.5,
      y + this.getHeight() * 0.5,
      this.getMarkerD()
    );

    textFont("Euclid Square", 16 * textScale);
    textStyle(NORMAL);
    // Values: Primary
    fill(Colors.PRIMARY_TEXT);
    textAlign(LEFT, TOP);
    text(this.primary, x + this.getMarkerD() + this.getMarkerGap(), y);
    // Values: Secondary
    fill(Colors.SECONDARY_TEXT);
    textAlign(RIGHT, TOP);
    text(this.secondary, x + this.getWidth(), y);

    textFont("Euclid Square", 10 * textScale);
    textStyle(NORMAL);
    fill(Colors.SUBHEADER_TEXT);
    // Labels: Primary
    textAlign(LEFT, BOTTOM);
    text(
      this.primaryLabel,
      x + this.getMarkerD() + this.getMarkerGap(),
      y + this.getHeight()
    );
    // Labels: Secondary
    textAlign(RIGHT, BOTTOM);
    text(this.secondaryLabel, x + this.getWidth(), y + this.getHeight());
  }
}
