import java.io.File;
import java.io.FilenameFilter;
import java.nio.file.Path;
import java.util.Set;
import java.util.concurrent.*;

class FileWatcher implements Runnable {
  private final BlockingQueue<Path> pathQueue;
  private final Set<String> seenFiles; // track processed files
  private final String targetDirPathStr;
  private long startDirModifiedTime; // track dir last modified at startup

  private final int pollIntervalMs = 2000; // poll every 2s

  FileWatcher(String targetDirPathStr) {
    this.targetDirPathStr = targetDirPathStr;
    this.pathQueue = new LinkedBlockingQueue<Path>();
    this.seenFiles = ConcurrentHashMap.newKeySet();
    this.startDirModifiedTime = 0;
  }

  boolean init() {
    File targetDir = new File(targetDirPathStr);
    if (!targetDir.exists() || !targetDir.isDirectory()) {
      System.err.println("Could not find target directory: " + targetDirPathStr);
      showCMDerror(Error.MISSING_TARGET_DIR, "Could not find XML listening directory");
      return false;
    }

    // Save the directory last modified timestamp at startup
    startDirModifiedTime = targetDir.lastModified();
    return true;
  }

  void start() {
    Thread t = new Thread(this, "FileWatcherThread");
    t.setDaemon(true); // not to block JVM shutdown
    t.start();
  }

  public void run() {
    while (true) {
      try {
        pollDirectory();
        Thread.sleep(pollIntervalMs);
      } 
      catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        break;
      } 
      catch (Exception e) {
        System.err.println("Error polling directory: " + e);
        cLogger.log("Error occurred while polling directory " + e);
      }
    }
  }

  private void pollDirectory() {
    File dir = new File(targetDirPathStr);

    File[] files = dir.listFiles(new FilenameFilter() {
      public boolean accept(File d, String name) {
        return name.toLowerCase().endsWith(".xml");
      }
    }
    );

    if (files == null) return; // directory not accessible

    for (File file : files) {
      String absPath = file.getAbsolutePath();

      // Only process files created/modified after watcher started
      if (seenFiles.contains(absPath) || file.lastModified() <= startDirModifiedTime) continue;

      if (waitForCompleteWrite(file)) {
        pathQueue.add(file.toPath());
        seenFiles.add(absPath);
      }
    }
  }

  private boolean waitForCompleteWrite(File f) {
    if (!f.exists()) return false;

    final int timeoutMs = 5000; // 5s max wait
    final int delayMs = 200;
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
    cLogger.log("Timeout waiting for complete write: " + f.getAbsolutePath());
    return false;
  }

  boolean isEmpty() {
    return pathQueue.isEmpty();
  }

  BlockingQueue<Path> getPathQueue() {
    return pathQueue;
  }
}
