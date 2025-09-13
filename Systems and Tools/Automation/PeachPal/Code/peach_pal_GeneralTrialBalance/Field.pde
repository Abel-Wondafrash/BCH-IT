import java.util.List;

class Fields {
  Field CUSTOMER = new Field (178, 215, 241, 20);
  Field REMARK = new Field (1147, 191, 197, 20);
  Field CUSTOMER_CONTAINER = new Field (179, 236, 510, 16);
  Field ARTICLE = new Field (130, 282, 283, 20);
  Field QUANTITY = new Field (1147, 243, 197, 20);
  Field PRICE = new Field (1147, 267, 197, 20);
  Field REMOVE = new Field (133, 412, 75, 21);
  
  List <Field> fields;
  
  Fields () {
    fields = new ArrayList <Field> ();
    
    fields.add (CUSTOMER);
    fields.add (CUSTOMER_CONTAINER);
    fields.add (ARTICLE);
    fields.add (REMARK);
    fields.add (QUANTITY);
    fields.add (PRICE);
  }
}

static class Field {
  private int originalX, originalY;
  private int x, y;
  private int w, h;

  Field (int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    
    originalX = x;
    originalY = y;
  }

  int getX () {
    return x;
  }
  int getY () {
    return y;
  }
  int getW () {
    return w;
  }
  int getH () {
    return h;
  }
  
  void updateRelative (int x, int y) {
    this.x = originalX + x;
    this.y = originalY + y;
  }
}
