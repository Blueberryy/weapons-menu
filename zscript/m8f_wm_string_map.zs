class m8f_wm_StringMap
{

  private Array<string> keys;
  private Array<string> values;

  void print()
  {
    uint size = values.size();
    Console.Printf("Size: %d", size);
    for (int i = 0; i < size; ++i)
      {
        Console.Printf("%s: %s", keys[i], values[i]);
      }
  }

  void push(string key, string value)
  {
    // array is sorted
    uint size = values.size();
    uint i    = 0;
    for (; i < size && keys[i] < key; ++i);
    keys.insert(i, key);
    values.insert(i, value);
  }

  string get(string key)
  {
    // binary search
    int size = values.size();
    int L    = 0;
    int R    = size - 1;

    while (L <= R)
      {
        int m = (L + R) / 2;
        string current = keys[m];
        if      (current <  key) { L = m + 1; }
        else if (current >  key) { R = m - 1; }
        else if (current == key) { return values[m]; }
      }
    return "";
  }

} // class m8f_wm_StringMap