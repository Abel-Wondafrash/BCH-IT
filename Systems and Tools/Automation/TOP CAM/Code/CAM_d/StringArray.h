class StringArray {
    String* data;
    int size;

  public:
    StringArray() {
      data = nullptr;
      size = 0;
    }

    void append(String newElement) {
      String* newData = new String[size + 1];  // Allocate new array
      for (int i = 0; i < size; i++)
        newData[i] = data[i];  // Copy old data

      newData[size] = newElement;  // Add new element
      delete[] data;               // Free old array
      data = newData;              // Point to new array
      size++;
    }
    void clear() {
      delete[] data;  // Free the memory used by the array
      data = nullptr; // Reset pointer to null
      size = 0;       // Reset the size to 0
    }

    String get(int index) {
      if (index < size) return data[index];
      return "";
    }

    int getSize () {
      return size;
    }

    boolean isEmpty () {
      return size == 0;
    }
    boolean contains(String searchElement) {
      for (int i = 0; i < size; i++)
        if (data[i].equals (searchElement)) return true;
      return false;
    }

    ~StringArray() {
      delete[] data;
    }
};
