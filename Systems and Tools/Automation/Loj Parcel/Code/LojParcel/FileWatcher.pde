import java.io.File;
import java.io.FilenameFilter;
import java.nio.file.Path;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

class FileWatcher implements Runnable {
  private final BlockingQueue<Path> pathQueue;
  private final String targetDirPathStr;
  private long lastPollTime; // track last poll timestamp

  private final int pollIntervalMs = 2000; // poll every 2s

  FileWatcher(String targetDirPathStr) {
    this.targetDirPathStr = targetDirPathStr;
    this.pathQueue = new LinkedBlockingQueue<Path>();
    this.lastPollTime = 0;
  }

  boolean init() {
    File targetDir = new File(targetDirPathStr);
    if (!targetDir.exists() || !targetDir.isDirectory()) {
      System.err.println("Could not find target directory: " + targetDirPathStr);
      showCMDerror(Error.MISSING_TARGET_DIR, "Could not find XML listening directory");
      return false;
    }

    // Initialize lastPollTime to directory last modified at startup
    lastPollTime = targetDir.lastModified();
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
    });

    if (files == null) return; // directory not accessible

    long newestFileTime = lastPollTime;

    for (File file : files) {
      long fileTime = file.lastModified();
      if (fileTime <= lastPollTime) continue; // ignore old files

      if (waitForCompleteWrite(file)) {
        pathQueue.add(file.toPath());
      }

      if (fileTime > newestFileTime) {
        newestFileTime = fileTime; // track newest file timestamp
      }
    }

    lastPollTime = newestFileTime; // update for next poll
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
        String currentChecksum = checksum.get(f.getAbsolutePath());
        if (currentChecksum != null && currentChecksum.equals(lastChecksum)) {
          stableCount++;
          if (stableCount >= 2) return true;
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
