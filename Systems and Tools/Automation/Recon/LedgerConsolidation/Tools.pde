LinkedHashMap <String, Entries> getOrganizedEntries (String partners [], String amounts [], String [] references) {
  LinkedHashMap <String, Entries> entriesMap = new LinkedHashMap <String, Entries> ();
  for (int i = 0; i < partners.length; i ++) {
    String partnerName = partners [i];
    String amount = amounts [i];
    String ref = references [i];

    if (partnerName.contains ("-")) partnerName = partnerName.substring (0, partnerName.indexOf ("-")).trim ();

    if (!entriesMap.containsKey(partnerName)) entriesMap.put (partnerName, new Entries ());
    entriesMap.get (partnerName).add (partnerName, new Entry (amount, ref));
  }

  return entriesMap;
}

import org.apache.commons.text.similarity.LevenshteinDistance;

FloatDict getBM(String key, java.util.Set<String> keys) {
  FloatDict bm = new FloatDict();
  LevenshteinDistance distance = new LevenshteinDistance();

  for (String each : keys) {
    // --- Levenshtein similarity ---
    int d = distance.apply(key, each);
    int maxLen = Math.max(key.length(), each.length());
    float levenshteinScore = (maxLen == 0) ? 1.0f : 1.0f - ((float) d / (float) maxLen);

    // --- Jaccard similarity (word-based) ---
    float jaccardScore = jaccardSimilarity(key, each);

    // --- N-Gram similarity (trigrams) ---
    float ngramScore = ngramSimilarity(key, each, 3);

    // --- Weighted hybrid ---
    float similarity = (levenshteinScore * 0.3f) + (jaccardScore * 0.4f) + (ngramScore * 0.3f);

    bm.set(each, similarity);
  }

  // Sort best matches (highest similarity first)
  bm.sortValuesReverse();

  return bm;
}

// --- Jaccard similarity (word-level) ---
float jaccardSimilarity(String s1, String s2) {
  String[] w1 = s1.toLowerCase().split("\\s+");
  String[] w2 = s2.toLowerCase().split("\\s+");

  java.util.Set<String> set1 = new java.util.HashSet<String>(java.util.Arrays.asList(w1));
  java.util.Set<String> set2 = new java.util.HashSet<String>(java.util.Arrays.asList(w2));

  java.util.Set<String> intersection = new java.util.HashSet<String>(set1);
  intersection.retainAll(set2);

  java.util.Set<String> union = new java.util.HashSet<String>(set1);
  union.addAll(set2);

  return union.isEmpty() ? 0f : (float) intersection.size() / (float) union.size();
}

// --- N-Gram similarity ---
float ngramSimilarity(String s1, String s2, int n) {
  java.util.Set<String> set1 = new java.util.HashSet<String>();
  java.util.Set<String> set2 = new java.util.HashSet<String>();

  String a = s1.toLowerCase().replaceAll("[^a-z0-9]", "");
  String b = s2.toLowerCase().replaceAll("[^a-z0-9]", "");

  for (int i = 0; i <= a.length() - n; i++) {
    set1.add(a.substring(i, i+n));
  }
  for (int i = 0; i <= b.length() - n; i++) {
    set2.add(b.substring(i, i+n));
  }

  java.util.Set<String> intersection = new java.util.HashSet<String>(set1);
  intersection.retainAll(set2);

  java.util.Set<String> union = new java.util.HashSet<String>(set1);
  union.addAll(set2);

  return union.isEmpty() ? 0f : (float) intersection.size() / (float) union.size();
}
