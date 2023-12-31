package org.apache.lucene33.analysis;

/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.BufferedReader;
import java.io.IOException;
import java.io.Reader;

import org.apache.lucene33.util.IOUtils;
import org.apache.lucene33.util.Version;

/**
 * Loader for text files that represent a list of stopwords.
 * 
 * @see IOUtils to obtain {@link Reader} instances
 * @lucene.internal
 */
public class WordlistLoader {
  
  private static final int INITITAL_CAPACITY = 16;
  
  /**
   * Reads lines from a Reader and adds every line as an entry to a CharArraySet (omitting
   * leading and trailing whitespace). Every line of the Reader should contain only
   * one word. The words need to be in lowercase if you make use of an
   * Analyzer which uses LowerCaseFilter (like StandardAnalyzer).
   *
   * @param reader Reader containing the wordlist
   * @param result the {@link CharArraySet} to fill with the readers words
   * @return the given {@link CharArraySet} with the reader's words
   */
  public static CharArraySet getWordSet(Reader reader, CharArraySet result) throws IOException {
    BufferedReader br = null;
    try {
      br = getBufferedReader(reader);
      String word = null;
      while ((word = br.readLine()) != null) {
        result.add(word.trim());
      }
    }
    finally {
      IOUtils.close(br);
    }
    return result;
  }
  
  /**
   * Reads lines from a Reader and adds every line as an entry to a CharArraySet (omitting
   * leading and trailing whitespace). Every line of the Reader should contain only
   * one word. The words need to be in lowercase if you make use of an
   * Analyzer which uses LowerCaseFilter (like StandardAnalyzer).
   *
   * @param reader Reader containing the wordlist
   * @param matchVersion the Lucene {@link Version}
   * @return A {@link CharArraySet} with the reader's words
   */
  public static CharArraySet getWordSet(Reader reader, Version matchVersion) throws IOException {
    return getWordSet(reader, new CharArraySet(matchVersion, INITITAL_CAPACITY, false));
  }

  /**
   * Reads lines from a Reader and adds every non-comment line as an entry to a CharArraySet (omitting
   * leading and trailing whitespace). Every line of the Reader should contain only
   * one word. The words need to be in lowercase if you make use of an
   * Analyzer which uses LowerCaseFilter (like StandardAnalyzer).
   *
   * @param reader Reader containing the wordlist
   * @param comment The string representing a comment.
   * @param matchVersion the Lucene {@link Version}
   * @return A CharArraySet with the reader's words
   */
  public static CharArraySet getWordSet(Reader reader, String comment, Version matchVersion) throws IOException {
    return getWordSet(reader, comment, new CharArraySet(matchVersion, INITITAL_CAPACITY, false));
  }

  /**
   * Reads lines from a Reader and adds every non-comment line as an entry to a CharArraySet (omitting
   * leading and trailing whitespace). Every line of the Reader should contain only
   * one word. The words need to be in lowercase if you make use of an
   * Analyzer which uses LowerCaseFilter (like StandardAnalyzer).
   *
   * @param reader Reader containing the wordlist
   * @param comment The string representing a comment.
   * @param result the {@link CharArraySet} to fill with the readers words
   * @return the given {@link CharArraySet} with the reader's words
   */
  public static CharArraySet getWordSet(Reader reader, String comment, CharArraySet result) throws IOException {
    BufferedReader br = null;
    try {
      br = getBufferedReader(reader);
      String word = null;
      while ((word = br.readLine()) != null) {
        if (word.startsWith(comment) == false){
          result.add(word.trim());
        }
      }
    }
    finally {
      IOUtils.close(br);
    }
    return result;
  }

  
  /**
   * Reads stopwords from a stopword list in Snowball format.
   * <p>
   * The snowball format is the following:
   * <ul>
   * <li>Lines may contain multiple words separated by whitespace.
   * <li>The comment character is the vertical line (&#124;).
   * <li>Lines may contain trailing comments.
   * </ul>
   * </p>
   * 
   * @param reader Reader containing a Snowball stopword list
   * @param result the {@link CharArraySet} to fill with the readers words
   * @return the given {@link CharArraySet} with the reader's words
   */
  public static CharArraySet getSnowballWordSet(Reader reader, CharArraySet result)
      throws IOException {
    BufferedReader br = null;
    try {
      br = getBufferedReader(reader);
      String line = null;
      while ((line = br.readLine()) != null) {
        int comment = line.indexOf('|');
        if (comment >= 0) line = line.substring(0, comment);
        String words[] = line.split("\\s+");
        for (int i = 0; i < words.length; i++)
          if (words[i].length() > 0) result.add(words[i]);
      }
    } finally {
      IOUtils.close(br);
    }
    return result;
  }
  
  /**
   * Reads stopwords from a stopword list in Snowball format.
   * <p>
   * The snowball format is the following:
   * <ul>
   * <li>Lines may contain multiple words separated by whitespace.
   * <li>The comment character is the vertical line (&#124;).
   * <li>Lines may contain trailing comments.
   * </ul>
   * </p>
   * 
   * @param reader Reader containing a Snowball stopword list
   * @param matchVersion the Lucene {@link Version}
   * @return A {@link CharArraySet} with the reader's words
   */
  public static CharArraySet getSnowballWordSet(Reader reader, Version matchVersion) throws IOException {
    return getSnowballWordSet(reader, new CharArraySet(matchVersion, INITITAL_CAPACITY, false));
  }


  /**
   * Reads a stem dictionary. Each line contains:
   * <pre>word<b>\t</b>stem</pre>
   * (i.e. two tab separated words)
   *
   * @return stem dictionary that overrules the stemming algorithm
   * @throws IOException 
   */
  public static CharArrayMap<String> getStemDict(Reader reader, CharArrayMap<String> result) throws IOException {
    BufferedReader br = null;
    try {
      br = getBufferedReader(reader);
      String line;
      while ((line = br.readLine()) != null) {
        String[] wordstem = line.split("\t", 2);
        result.put(wordstem[0], wordstem[1]);
      }
    } finally {
      IOUtils.close(br);
    }
    return result;
  }
  
  private static BufferedReader getBufferedReader(Reader reader) {
    return (reader instanceof BufferedReader) ? (BufferedReader) reader
        : new BufferedReader(reader);
  }
  
}
