import java.io.*;
import java.nio.channels.*;

class SingleInstance {
  String lockFileName;
  FileLock lock;
  FileChannel channel;
  File file;

  SingleInstance(String lockFileName) {
    this.lockFileName = lockFileName;
  }

  boolean init() {
    try {
      file = new File(lockFileName);
      channel = new RandomAccessFile(file, "rw").getChannel();
      lock = channel.tryLock();
      if (lock == null) {
        channel.close();
        showCMDerror(Error.INSTANCE_ALREADY_RUNNING, "", true);
        return false;
      }
      file.deleteOnExit();
      return true;
    } 
    catch (Exception e) {
      showCMDerror(Error.INSTANCE_ALREADY_RUNNING, e.getMessage(), true);
      return false;
    }
  }

  void release() {
    try {
      if (lock != null) lock.release();
      if (channel != null) channel.close();
    } 
    catch (IOException ignored) {}
  }
}
