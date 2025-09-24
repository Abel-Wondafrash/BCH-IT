import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

class SystemTray_ {
  SystemTray tray;
  TrayIcon trayIcon;

  SystemTray_ (String iconPath) {
    if (SystemTray.isSupported()) {
      tray = SystemTray.getSystemTray();

      if (iconPath != null && new File (iconPath).exists ()) {
        Image image = new ImageIcon(iconPath).getImage();
        trayIcon = new TrayIcon(image, APP_NAME);
        trayIcon.setImageAutoSize(true);
      }

      // Create popup menu
      PopupMenu menu = new PopupMenu();

      // Exit item
      MenuItem exitItem = new MenuItem("Exit Parcel");
      exitItem.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent e) {
          tray.remove(trayIcon);
          exit();
        }
      }
      );
      menu.add(exitItem);

      trayIcon.setPopupMenu(menu);

      try {
        tray.add(trayIcon);
      } 
      catch (AWTException e) {
        println("TrayIcon could not be added.");
        cLogger.log ("TrayIcon could not be added.");
      }
    } else {
      println("System tray not supported!");
      cLogger.log ("System tray not supported!");
    }
  }

  void draw() {
  }
}
