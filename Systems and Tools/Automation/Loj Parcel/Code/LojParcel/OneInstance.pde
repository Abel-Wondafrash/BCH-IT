import java.io.*;
import java.nio.channels.*;
import javax.swing.JOptionPane;

public class OneInstance {
  private FileLock lock;
  private FileChannel channel;
  private File file;

  public boolean acquire(String lockFileName) {
    try {
      file = new File(lockFileName);
      channel = new RandomAccessFile(file, "rw").getChannel();
      lock = channel.tryLock();
      if (lock == null) {
        channel.close();
        return false;
      }
      file.deleteOnExit();
      return true;
    } 
    catch (Exception e) {
      return false;
    }
  }

  public void release() {
    try {
      if (lock != null) lock.release();
      if (channel != null) channel.close();
    } 
    catch (IOException ignored) {
    }
  }

  void showAlreadyRunningMessage() {
    JOptionPane.showMessageDialog(
      null, 
      "Another instance of the application is already running!", 
      "Another Instance Already Running", 
      JOptionPane.WARNING_MESSAGE
      );
  }
}
