import java.nio.file.*;
import java.util.concurrent.*;
import java.io.File;

class FileWatcher implements Runnable {
  BlockingQueue<Path> pathQueue;
  WatchService watchService;

  private String targetDirPathStr;

  private FileWatcher (String targetDirPathStr) {
    this.targetDirPathStr = targetDirPathStr;
  }

  private boolean init () {
    pathQueue = new LinkedBlockingQueue<Path>();
    try {
      Path targetDir = Paths.get(targetDirPathStr);
      if (!targetDir.toFile().exists()) {
        System.err.println ("Could not find target directory: " + targetDirPathStr);
        showCMDerror (Error.MISSING_TARGET_DIR, "Could not find XML listening directory");
        return false;
      }

      watchService = FileSystems.getDefault().newWatchService();
      targetDir.register(watchService, StandardWatchEventKinds.ENTRY_CREATE);
      return true;
    } 
    catch (Exception e) {
      e.printStackTrace();
      cLogger.log ("Error initializing File Watcher " + e);
      println ("Error initializing File Watcher", e);
      return false;
    }
  }

  private void start() {
    Thread t = new Thread(this, "FileWatcherThread");
    t.setDaemon(true); // Not to block JVM shutdown
    t.start();
  }

  void run () {
    while (true) {
      try {
        watchDirectory();
      }
      catch (Exception e) {
        println ("Error watching directory:", e);
        cLogger.log ("Error occurred while watching directory " + e);
      }
    }
  }

  private void watchDirectory() throws Exception {
    WatchKey key = watchService.take();
    for (WatchEvent<?> event : key.pollEvents()) {
      if (event.kind() != StandardWatchEventKinds.ENTRY_CREATE) continue;

      Path dir = (Path) key.watchable();
      Path newPath = dir.resolve((Path) event.context());
      if (pathQueue.contains(newPath)
        || !newPath.toString().toLowerCase().endsWith(".xml")
        || !waitForCompleteWrite(newPath.toFile())) continue;

      pathQueue.add(newPath);
    }
    key.reset();
  }

  private boolean waitForCompleteWrite(File f) {
    if (!f.exists()) return false;

    final int timeoutMs = 5_000; // 5s max wait
    final int delayMs = 500;
    long start = System.currentTimeMillis();

    long lastSize = -1;
    String lastChecksum = null;
    int stableCount = 0;

    while (System.currentTimeMillis() - start < timeoutMs) {
      long size = f.length();

      if (size == lastSize) {
        // Size stable, check checksum
        String currentChecksum = checksum.get(f.getAbsolutePath());
        if (currentChecksum != null && currentChecksum.equals(lastChecksum)) {
          stableCount++;
          if (stableCount >= 2) return true; // require 2 consistent rounds
        } else {
          lastChecksum = currentChecksum;
          stableCount = 0;
        }
      } else {
        stableCount = 0;
      }

      lastSize = size;
      try { 
        Thread.sleep(delayMs);
      }
      catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        return false;
      }
    }

    System.err.println("Timeout waiting for complete write: " + f.getAbsolutePath());
    cLogger.log ("Timeout waiting for complete write: " + f.getAbsolutePath());
    return false;
  }

  boolean isEmpty () {
    return pathQueue.isEmpty ();
  }
  BlockingQueue <Path> getPathQueue () {
    return pathQueue;
  }
}
