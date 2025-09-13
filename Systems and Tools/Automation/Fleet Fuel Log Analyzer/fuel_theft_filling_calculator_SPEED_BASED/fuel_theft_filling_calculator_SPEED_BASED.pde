String inputPath = "c:/users/abel wondafrash/desktop/16660-history-apr11-apr22.csv";
String outputPath = "c:/users/abel wondafrash/desktop/16660-records-apr11-apr22_SPD.csv";
import java.text.SimpleDateFormat;
import java.util.Date;

int MINUS_FROM = -60 * 5;
int PLUS_FROM = 60 * 1;
int MINUS_TO = -60 * 1;
int PLUS_TO = 60 * 1;
float FUEL_DIFF_THRESHOLD = 3.0;
int MIN_VALID_SAMPLES = 5;
int MIN_STOP_DURATION_VALID = 60 * 10;
int MIN_STOP_DURATION_FILLING = 60 * 3;
int MAX_STOP_DURATION_FILLING = 60 * 60;
int MIN_STOP_DURATION_THEFT = 60 * 5;

Table telemetry;
Table stops;
SimpleDateFormat dateFormat = new SimpleDateFormat("dd-MM-yyyy HH:mm:ss");

void setup() {
  telemetry = loadTable(inputPath, "header");
  stops = new Table();
  stops.addColumn("Stop Duration");
  stops.addColumn("From Location (lat, lng)");
  stops.addColumn("From Time");
  stops.addColumn("To Location (lat, lng)");
  stops.addColumn("To Time");
  stops.addColumn("Fuel Before (Ltr)");
  stops.addColumn("Fuel After (Ltr)");
  stops.addColumn("Fuel Diff (Ltr)");
  stops.addColumn("Remark");
  stops.addColumn("From-To Distance (km)");

  boolean isStopped = false;
  String fromTime = "";
  float fromLat = 0.0, fromLng = 0.0;
  String lastRunStartTime = null;

  for (int i = 0; i < telemetry.getRowCount(); i++) {
    TableRow row = telemetry.getRow(i);
    String currentTime = row.getString("Time");
    String speedStr = row.getString("Speed");

    float speed = speedStr.equals("0 kph") ? 0 : parseFloat(speedStr.replace(" kph", ""));

    if (speed > 0 && !isStopped && lastRunStartTime == null) {
      lastRunStartTime = currentTime;
    }

    if (speed == 0 && !isStopped) {
      isStopped = true;
      fromTime = currentTime;
      fromLat = row.getFloat("Latitude");
      fromLng = row.getFloat("Longitude");
    } else if (speed > 0 && isStopped) {
      isStopped = false;

      long durationSeconds = calculateDuration(fromTime, currentTime);
      if (durationSeconds < MIN_STOP_DURATION_VALID) {
        lastRunStartTime = currentTime;
        continue;
      }

      float fuelFrom = getAverageFuel(fromTime, MINUS_FROM, PLUS_FROM, i);
      float fuelTo = getAverageFuel(currentTime, MINUS_TO, PLUS_TO, i);
      float fuelDiff = (fuelFrom != -1 && fuelTo != -1) ? fuelTo - fuelFrom : 0;

      String remark = "";
      if (fuelFrom != -1 && fuelTo != -1) {
        if (fuelDiff > FUEL_DIFF_THRESHOLD && durationSeconds >= MIN_STOP_DURATION_FILLING && durationSeconds <= MAX_STOP_DURATION_FILLING) {
          remark = "Filling";
        } else if (fuelDiff < -FUEL_DIFF_THRESHOLD && durationSeconds >= MIN_STOP_DURATION_THEFT) {
          remark = "Theft";
        }
      }

      if (!remark.equals("Filling") && !remark.equals("Theft")) {
        continue;
      }

      float toLat = row.getFloat("Latitude");
      float toLng = row.getFloat("Longitude");
      float distanceKm = calculateDistance(fromLat, fromLng, toLat, toLng);

      TableRow newRow = stops.addRow();
      newRow.setString("Stop Duration", formatDuration(durationSeconds));
      newRow.setString("From Time", fromTime);
      newRow.setString("To Time", currentTime);
      newRow.setString("From Location (lat, lng)", fromLat + ", " + fromLng);
      newRow.setString("To Location (lat, lng)", toLat + ", " + toLng);
      newRow.setString("Fuel Before (Ltr)", fuelFrom == -1 ? "N/A" : nf(fuelFrom, 0, 2));
      newRow.setString("Fuel After (Ltr)", fuelTo == -1 ? "N/A" : nf(fuelTo, 0, 2));
      newRow.setString("Fuel Diff (Ltr)", nf(fuelDiff, 0, 2));
      newRow.setString("Remark", remark);
      newRow.setString("From-To Distance (km)", nf(distanceKm, 0, 2));

      lastRunStartTime = currentTime;
    }
  }

  saveTable(stops, outputPath);
  println("Stop events saved to stops.csv");
  exit();
}

long calculateDuration(String from, String to) {
  try {
    Date startDate = dateFormat.parse(from);
    Date endDate = dateFormat.parse(to);
    long duration = (endDate.getTime() - startDate.getTime()) / 1000;
    return duration >= 0 ? duration : 0;
  } catch (Exception e) {
    return 0;
  }
}

String formatDuration(long seconds) {
  if (seconds <= 0) return "0m";
  long hours = seconds / 3600;
  long minutes = (seconds % 3600) / 60;
  return hours > 0 ? hours + "hr " + minutes + "m" : minutes + "m";
}

float getAverageFuel(String referenceTime, long windowStart, long windowEnd, int refIndex) {
  try {
    Date refDate = dateFormat.parse(referenceTime);
    long refTimeMs = refDate.getTime();
    float sum = 0;
    int count = 0;

    for (int i = max(0, refIndex - 100); i < min(telemetry.getRowCount(), refIndex + 100); i++) {
      TableRow row = telemetry.getRow(i);
      String timeStr = row.getString("Time");
      String fuelStr = row.getString("Fuel In Tank");

      Date rowDate = dateFormat.parse(timeStr);
      long rowTimeMs = rowDate.getTime();
      long timeDiff = (rowTimeMs - refTimeMs) / 1000;

      if (timeDiff >= windowStart && timeDiff <= windowEnd && !fuelStr.equals("-")) {
        try {
          float fuel = Float.parseFloat(fuelStr.replace(" Ltr", ""));
          sum += fuel;
          count++;
        } catch (NumberFormatException e) {}
      }
    }

    return count >= MIN_VALID_SAMPLES ? sum / count : -1;
  } catch (Exception e) {
    return -1;
  }
}

float calculateDistance(float lat1, float lon1, float lat2, float lon2) {
  float R = 6371; // Earth radius in km
  float dLat = radians(lat2 - lat1);
  float dLon = radians(lon2 - lon1);
  float a = sin(dLat / 2) * sin(dLat / 2) +
            cos(radians(lat1)) * cos(radians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
  float c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}
