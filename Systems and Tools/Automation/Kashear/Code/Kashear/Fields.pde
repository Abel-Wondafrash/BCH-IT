import java.util.List;
import java.util.Collections;
import java.util.Comparator;

enum Direction {
  RIGHT, DOWN
}

class FieldTypes {
  List <FieldInfo> editables;
  List <FieldInfo> selectables;
  List <FieldInfo> selfs;

  FieldTypes (List <FieldInfo> fieldInfos) {
    this.editables = new ArrayList <FieldInfo> ();
    this.selectables = new ArrayList <FieldInfo> ();
    this.selfs = new ArrayList <FieldInfo> ();

    classify (fieldInfos);
  }

  void classify (List <FieldInfo> fieldInfos) {
    for (FieldInfo f : fieldInfos) {
      if (f.isEditable ()) editables.add (f);
      if (f.isSelectable ()) selectables.add (f);
      selfs.add (f);
    }
  }
  // Field Info Getters
  FieldInfo getEditableInfo (int index) {
    if (index < 0 || editables.isEmpty() || index + 1 > editables.size ()) return null;
    return editables.get (index);
  }
  FieldInfo getSelectableInfo (int index) {
    if (index < 0 || selectables.isEmpty() || index + 1 > selectables.size ()) return null;
    return selectables.get (index);
  }
  FieldInfo getSelfInfo (int index) {
    if (index < 0 || selfs.isEmpty() || index + 1 > selfs.size ()) return null;
    return selfs.get (index);
  }

  // Field Getters
  Field getEditable (int index) {
    FieldInfo editable = getEditableInfo (index);
    if (editable == null) return null;
    return new Field (editable);
  }
  Field getSelectable (int index) {
    FieldInfo selectable = getSelectableInfo (index);
    if (selectable == null) return null;
    return new Field (selectable);
  }
  Field getSelf (int index) {
    FieldInfo self = getSelfInfo (index);
    if (self == null) return null;
    return new Field (self);
  }
}

class Fields {
  String winTitle;
  String labels [];
  Map <String, List <FieldInfo>> labeledFields;
  Map <String, List <FieldInfo>> downFields;
  Map <String, List <FieldInfo>> selfFields;

  Fields (String winTitle, String [] labels) {
    this.winTitle = winTitle;
    this.labels = labels;
  }

  void update () {
    List <FieldInfo> winFields = getWindowFieldsDetailed(Windows.mainTitle);
    labeledFields = matchLabelsToFieldsR (winFields, labels); // Right
    downFields = matchLabelsToFieldsD (winFields, labels); // Down
    selfFields = matchLabelsToFieldsS (winFields, labels); // Self
  }

  FieldTypes get (String label) {
    if (label == null || !labeledFields.containsKey (label)) return null;
    return new FieldTypes (labeledFields.get (label));
  }
  FieldTypes getD (String label) {
    if (label == null || !downFields.containsKey (label)) return null;
    return new FieldTypes (downFields.get (label));
  }
  FieldTypes getSelf(String label) {
    if (label == null || !selfFields.containsKey (label)) return null;
    return new FieldTypes (selfFields.get (label));
  }

  Map<String, List<FieldInfo>> matchLabelsToFieldsR(List<FieldInfo> allFields, String [] labelsToMatch) {
    Map<String, List<FieldInfo>> labelToFields = new HashMap<String, List<FieldInfo>>();
    List<FieldInfo> inputs = new ArrayList<FieldInfo>();

    Map<String, FieldInfo> knownLabels = new HashMap<String, FieldInfo>();
    for (FieldInfo field : allFields) {
      if (field.getText() != null) {
        for (String label : labelsToMatch) {
          if (label.equals(field.getText().trim())) {
            knownLabels.put(label, field);
          }
        }
      }
      inputs.add(field);
    }

    for (String label : labelsToMatch) {
      FieldInfo labelField = knownLabels.get(label);
      if (labelField == null) continue;

      List<FieldInfo> matches = new ArrayList<FieldInfo>();

      for (FieldInfo input : inputs) {
        int dx = input.getX() - labelField.getX();
        int dy = Math.abs(input.getY() - labelField.getY());

        if (dx > 0 && dx < 500 && dy < 5) {
          matches.add(input);
        }
      }

      // Sort left to right
      Collections.sort(matches, new Comparator<FieldInfo>() {
        public int compare(FieldInfo a, FieldInfo b) {
          return Integer.compare(a.getX(), b.getX());
        }
      }
      );

      if (!matches.isEmpty()) labelToFields.put(label, matches);
    }

    return labelToFields;
  }

  Map<String, List<FieldInfo>> matchLabelsToFieldsD (List<FieldInfo> allFields, String [] labelsToMatch) {
    Map<String, List<FieldInfo>> labelToFields = new HashMap<String, List<FieldInfo>>();
    List<FieldInfo> inputs = new ArrayList<FieldInfo>();

    Map<String, FieldInfo> knownLabels = new HashMap<String, FieldInfo>();
    for (FieldInfo field : allFields) {
      if (field.getText() != null) {
        for (String label : labelsToMatch) {
          if (label.equals(field.getText().trim())) {
            knownLabels.put(label, field);
          }
        }
      }
      inputs.add(field);
    }

    for (String label : labelsToMatch) {
      FieldInfo labelField = knownLabels.get(label);
      if (labelField == null) continue;

      List<FieldInfo> matches = new ArrayList<FieldInfo>();

      for (FieldInfo input : inputs) {
        int dy = input.getY() - (labelField.getY() + labelField.getH ());
        int dx = input.getX() - (labelField.getX() + labelField.getW ());

        if (dy > 0 && dy < 500 && dx > -60 && dx < 0) matches.add(input);
      }

      // Sort left to right
      Collections.sort(matches, new Comparator<FieldInfo>() {
        public int compare(FieldInfo a, FieldInfo b) {
          return Integer.compare(a.getY(), b.getY());
        }
      }
      );

      if (!matches.isEmpty()) labelToFields.put(label, matches);
    }

    return labelToFields;
  }

  Map<String, List<FieldInfo>> matchLabelsToFieldsS(List<FieldInfo> allFields, String[] labelsToMatch) {
    Map<String, List<FieldInfo>> selfFields = new HashMap<String, List<FieldInfo>>();

    for (int i = 0; i < labelsToMatch.length; i++) {
      String label = labelsToMatch[i];
      List<FieldInfo> matches = new ArrayList<FieldInfo>();

      for (int j = 0; j < allFields.size(); j++) {
        FieldInfo field = allFields.get(j);

        if (field == null) continue;

        String text = field.getText();
        if (text == null || text.trim().isEmpty()) continue;
        if (field.isEditable()) continue;
        if (label.equals(text.trim())) matches.add(field);
      }

      // Sort top to bottom (optional)
      Collections.sort(matches, new Comparator<FieldInfo>() {
        public int compare(FieldInfo a, FieldInfo b) {
          return Integer.compare(a.getY(), b.getY());
        }
      }
      );

      if (!matches.isEmpty()) selfFields.put(label, matches);
    }

    return selfFields;
  }
}

static class Field {
  private FieldInfo fInfo;

  Field (FieldInfo fieldInfo) {
    this.fInfo = fieldInfo;
  }

  int getX () {
    return fInfo.getX ();
  }
  int getY () {
    return fInfo.getY ();
  }
  int getW () {
    return fInfo.getW ();
  }
  int getH () {
    return fInfo.getH ();
  }

  String getClassName () {
    return fInfo.getClassName ();
  }
  String getClassNN () {
    return fInfo.getClassNN ();
  }

  public WinDef.HWND getHwnd() {
    return fInfo.getHwnd ();
  }

  void setContent (String content) {
    if (content == null) return;
    Memory memory = new Memory((content.length() + 1) * 2); // *2 because it's wide char (UTF-16)
    memory.setWideString(0, content);

    WinDef.LPARAM lparam = new WinDef.LPARAM(Pointer.nativeValue(memory));

    User32.INSTANCE.SendMessage(
      getHwnd(), 
      WinMessages.WM_SETTEXT, 
      new WinDef.WPARAM(0), 
      lparam
      );
  }
  String getContent() {
    int bufferSize = 512; // max characters expected
    Memory buffer = new Memory(bufferSize * 2); // wide char buffer (UTF-16)

    WinDef.LPARAM lparam = new WinDef.LPARAM(Pointer.nativeValue(buffer));

    User32.INSTANCE.SendMessage(
      getHwnd(), 
      WinMessages.WM_GETTEXT, 
      new WinDef.WPARAM(bufferSize), // number of characters (including null terminator)
      lparam
      );

    return buffer.getWideString(0);
  }

  void clickButton() {
    User32.INSTANCE.SendMessage(getHwnd(), WinMessages.BM_CLICK, new WinDef.WPARAM(0), new WinDef.LPARAM(0));
  }
  void click() {
    WinDef.HWND hwnd = getHwnd();

    // Simulate mouse down
    User32.INSTANCE.PostMessage(hwnd, WinMessages.WM_LBUTTONDOWN, new WinDef.WPARAM(1), new WinDef.LPARAM(0));
    // Simulate mouse up
    User32.INSTANCE.PostMessage(hwnd, WinMessages.WM_LBUTTONUP, new WinDef.WPARAM(0), new WinDef.LPARAM(0));
  }
}
