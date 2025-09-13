let _UNKNOWN = "UNK";
let _NORMAL = "NRM";
let _SLOW = "SLW";
let _SMALL_STOP = "SST";
let _STOP = "DWN";

class Node {
  constructor(codename = "CNM") {
    this.codename = codename;

    // Overviews
    this.availability = 0;
    this.performance = 0;
    this.quality = 0;
    this.oee = 0;
    this.state = new State();
    this.timeline = [];
    // Availability
    this.runtime = "";
    this.runtimeCount = 0;
    this.runtimePercentage = 0;
    this.availablityLoss = "";
    this.availabilityLossCounts = 0;
    this.availabilityLossPercentage = 0;
    this.unplannedStops = "";
    this.unplannedStopsCounts = 0;
    this.unplannedStopsPercentage = 0;
    this.plannedStops = "";
    this.plannedStopsCounts = 0;
    this.plannedStopsPercentage = 0;
    // Performance
    this.netRuntime = "";
    this.netRuntimeCounts = 0;
    this.netRuntimePercentage = 0;
    this.performanceLoss = "";
    this.performanceLossCounts = 0;
    this.performanceLossPercentage = 0;
    this.slowCycles = "";
    this.slowCyclesCounts = 0;
    this.slowCyclesPercentage = 0;
    this.smallStops = "";
    this.smallStopsCounts = 0;
    this.smallStopsPercentage = 0;
    // Quality
    this.fullyProductiveTime = "";
    this.fullyProductiveTimeCounts = 0;
    this.fullyProductiveTimePercentage = 0;
    this.qualityLoss = "";
    this.qualityLossCounts = 0;
    this.qualityLossPercentage = 0;
    this.goods = "";
    this.goodsCounts = 0;
    this.goodsPercentage = 0;
    this.rejects = "";
    this.rejectsCounts = 0;
    this.rejectsPercentage = 0;
  }

  // SET: Node Data
  setData(data) {
    // Setting Fetched Data: Overviews
    const overviews = data.overviews ?? {};
    this.setAvailability(overviews.ava);
    this.setPerformance(overviews.prf);
    this.setQuality(overviews.qua);
    this.setOEE(overviews.oee);
    this.setState(overviews.lst); // lst: last state

    // Setting Fetched Data: Timeline
    const timeline = data.timeline;
    this.setTimeline(timeline.timeline_data);

    // Setting Fetched Data: Availability
    const detailsAva = data.details_ava ?? {};
    this.setRuntime(
      detailsAva.runtime ?? "",
      detailsAva.runtime_c ?? "",
      detailsAva.runtime_p ?? ""
    );
    this.setAvailabilityLoss(
      detailsAva.ava_loss ?? "",
      detailsAva.ava_loss_c ?? "",
      detailsAva.ava_loss_p ?? ""
    );
    this.setUnplannedStops(
      detailsAva.unp_stop ?? "",
      detailsAva.unp_stop_c ?? "",
      detailsAva.unp_stop_p ?? ""
    );
    this.setPlannedStops(
      detailsAva.pln_stop ?? "",
      detailsAva.pln_stop_c ?? "",
      detailsAva.pln_stop_p ?? ""
    );

    // Obtaining Data: Performance
    const detailsPrf = data.details_prf ?? {};
    this.setNetRuntime(
      detailsPrf.net_runtime ?? "",
      detailsPrf.net_runtime_c ?? "",
      detailsPrf.net_runtime_p ?? ""
    );
    this.setPerformanceLoss(
      detailsPrf.prf_loss ?? "",
      detailsPrf.prf_loss_c ?? "",
      detailsPrf.prf_loss_p ?? ""
    );
    this.setSlowCycles(
      detailsPrf.slow_cycles ?? "",
      detailsPrf.slow_cycles_c ?? "",
      detailsPrf.slow_cycles_p ?? ""
    );
    this.setSmallStops(
      detailsPrf.small_stops ?? "",
      detailsPrf.small_stops_c ?? "",
      detailsPrf.small_stops_p ?? ""
    );

    // Obtaining Data: Quality
    const detailsQua = data.details_qua ?? {};
    this.setFullyProductiveTime(
      detailsQua.fully_productive_time ?? "",
      detailsQua.fully_productive_time_c ?? "",
      detailsQua.fully_productive_time_p ?? ""
    );
    this.setQualityLoss(
      detailsQua.qua_loss ?? "",
      detailsQua.qua_loss_c ?? "",
      detailsQua.qua_loss_p ?? ""
    );
    this.setGoods(detailsQua.good_c ?? "", "", detailsQua.good_p ?? "");
    this.setRejects(detailsQua.reject_c ?? "", "", detailsQua.reject_p ?? "");
  }

  // SET: Overviews
  setAvailability(availability) {
    this.availability = availability;
  }
  setPerformance(performance) {
    this.performance = performance;
  }
  setQuality(quality) {
    this.quality = quality;
  }
  setOEE(oee) {
    this.oee = oee;
  }
  setState(state) {
    this.state.set(state);
  }
  // SET: Timeline
  setTimeline(timeline) {
    this.timeline = timeline;
  }
  // SET: Availability Details
  setRuntime(runtime, runtimeCount, runtimePercentage) {
    this.runtime = runtime;
    this.runtimeCount = runtimeCount;
    this.runtimePercentage = runtimePercentage;
  }
  setAvailabilityLoss(
    availabilityLoss,
    availabilityLossCounts,
    availabilityLossPercentage
  ) {
    this.availablityLoss = availabilityLoss;
    this.availabilityLossCounts = availabilityLossCounts;
    this.availabilityLossPercentage = availabilityLossPercentage;
  }
  setUnplannedStops(
    unplannedStops,
    unplannedStopsCounts,
    unplannedStopsPercentage
  ) {
    this.unplannedStops = unplannedStops;
    this.unplannedStopsCounts = unplannedStopsCounts;
    this.unplannedStopsPercentage = unplannedStopsPercentage;
  }
  setPlannedStops(plannedStops, plannedStopsCounts, plannedStopsPercentage) {
    this.plannedStops = plannedStops;
    this.plannedStopsCounts = plannedStopsCounts;
    this.plannedStopsPercentage = plannedStopsPercentage;
  }
  // SET: Performance Details
  setNetRuntime(netRuntime, netRuntimeCounts, netRuntimePercentage) {
    this.netRuntime = netRuntime;
    this.netRuntimeCounts = netRuntimeCounts;
    this.netRuntimePercentage = netRuntimePercentage;
  }
  setPerformanceLoss(
    performanceLoss,
    performanceLossCounts,
    performanceLossPercentage
  ) {
    this.performanceLoss = performanceLoss;
    this.performanceLossCounts = performanceLossCounts;
    this.performanceLossPercentage = performanceLossPercentage;
  }
  setSlowCycles(slowCycles, slowCyclesCounts, slowCyclesPercentage) {
    this.slowCycles = slowCycles;
    this.slowCyclesCounts = slowCyclesCounts;
    this.slowCyclesPercentage = slowCyclesPercentage;
  }
  setSmallStops(smallStops, smallStopsCounts, smallStopsPercentage) {
    this.smallStops = smallStops;
    this.smallStopsCounts = smallStopsCounts;
    this.smallStopsPercentage = smallStopsPercentage;
  }
  // SET: Quality Details
  setFullyProductiveTime(
    fullyProductiveTime,
    fullyProductiveTimeCounts,
    fullyProductiveTimePercentage
  ) {
    this.fullyProductiveTime = fullyProductiveTime;
    this.fullyProductiveTimeCounts = fullyProductiveTimeCounts;
    this.fullyProductiveTimePercentage = fullyProductiveTimePercentage;
  }
  setQualityLoss(qualityLoss, qualityLossCounts, qualityLossPercentage) {
    this.qualityLoss = qualityLoss;
    this.qualityLossCounts = qualityLossCounts;
    this.qualityLossPercentage = qualityLossPercentage;
  }
  setGoods(goods, goodsCounts, goodsPercentage) {
    this.goods = goods;
    this.goodsCounts = goodsCounts;
    this.goodsPercentage = goodsPercentage;
  }
  setRejects(rejects, rejectsCounts, rejectsPercentage) {
    this.rejects = rejects;
    this.rejectsCounts = rejectsCounts;
    this.rejectsPercentage = rejectsPercentage;
  }

  getCodename() {
    return this.codename;
  }

  // GET: Overviews
  getAvailability() {
    return this.availability;
  }
  getPerformance() {
    return this.performance;
  }
  getQuality() {
    return this.quality;
  }
  getOEE() {
    return this.oee;
  }
  getState() {
    return this.state;
  }
  // GET: Timeline
  getTimeline() {
    return this.timeline;
  }
  // GET: Availability Details
  getRuntime() {
    return [this.runtime, this.runtimeCount, this.runtimePercentage];
  }
  getAvailabilityLoss() {
    return [
      this.availablityLoss,
      this.availabilityLossCounts,
      this.availabilityLossPercentage,
    ];
  }
  getUnplannedStops() {
    return [
      this.unplannedStops,
      this.unplannedStopsCounts,
      this.unplannedStopsPercentage,
    ];
  }
  getPlannedStops() {
    return [
      this.plannedStops,
      this.plannedStopsCounts,
      this.plannedStopsPercentage,
    ];
  }
  // GET: Performance Details
  getNetRuntime() {
    return [this.netRuntime, this.netRuntimeCounts, this.netRuntimePercentage];
  }
  getPerformanceLoss() {
    return [
      this.performanceLoss,
      this.performanceLossCounts,
      this.performanceLossPercentage,
    ];
  }
  getSlowCycles() {
    return [this.slowCycles, this.slowCyclesCounts, this.slowCyclesPercentage];
  }
  getSmallStops() {
    return [this.smallStops, this.smallStopsCounts, this.smallStopsPercentage];
  }
  // GET: Quality Details
  getFullyProductiveTime() {
    return [
      this.fullyProductiveTime,
      this.fullyProductiveTimeCounts,
      this.fullyProductiveTimePercentage,
    ];
  }
  getQualityLoss() {
    return [
      this.qualityLoss,
      this.qualityLossCounts,
      this.qualityLossPercentage,
    ];
  }
  getGoods() {
    return [this.goods, this.goodsCounts, this.goodsPercentage];
  }
  getRejects() {
    return [this.rejects, this.rejectsCounts, this.rejectsPercentage];
  }
}

class Nodes {
  constructor(jsonData = null) {
    this.jsonData = jsonData;
    this.map = new Map();
    this.labels = codenames;

    // Plant Data
    this.datestamp = "";
    this.site = "";
    this.product = "";
    this.line = "";
  }

  setNodesData(data) {
    if (data === null) return;

    if (data && typeof data === "object") {
      this.map.clear();
      for (const [name, values] of Object.entries(data)) {
        if (!this.labels.includes(name)) continue;

        let node = new Node(name);
        this.map.set(name, node);
      }
    }
  }
  // SET: Plant Data
  setDatestamp(datestamp) {
    this.datestamp = datestamp;
  }
  setSite(site) {
    this.site = site;
  }
  setProduct(product) {
    this.product = product;
  }
  setLine(line) {
    this.line = line;
  }

  size() {
    return this.map.size;
  }
  contains(name) {
    return this.map.has(name);
  }
  get(name) {
    return this.map.get(name);
  }

  // GET: Plant Data
  getDatestamp(datestamp) {
    return this.datestamp;
  }
  getSite(site) {
    return this.site;
  }
  getProduct(product) {
    return this.product;
  }
  getLine(line) {
    return this.line;
  }

  // SET: Node Data
  setData(data) {
    // Set Fetched Data: Plant Data
    const plantData = data["plant_data"] ?? {};
    this.setDatestamp(plantData.datestamp ?? "");
    this.setSite(plantData.site ?? "");
    this.setProduct(plantData.product ?? "");
    this.setLine(plantData.line ?? "");

    for (let label of this.labels) {
      let node = this.get(label);
      let nodeData = data[label];

      if (nodeData === undefined || nodeData.length === 0) continue;
      node.setData(nodeData);
    }
  }
}
