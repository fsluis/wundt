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

package org.apache.lucene33.analysis;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.util.Set;

import org.apache.lucene33.analysis.CharArraySet;
import org.apache.lucene33.analysis.ReusableAnalyzerBase;
import org.apache.lucene33.analysis.WordlistLoader;
import org.apache.lucene33.util.IOUtils;
import org.apache.lucene33.util.Version;

/**
 * Base class for Analyzers that need to make use of stopword sets. 
 * 
 */
public abstract class StopwordAnalyzerBase extends ReusableAnalyzerBase {

  /**
   * An immutable stopword set
   */
  protected final CharArraySet stopwords;

  protected final Version matchVersion;

  /**
   * Returns the analyzer's stopword set or an empty set if the analyzer has no
   * stopwords
   * 
   * @return the analyzer's stopword set or an empty set if the analyzer has no
   *         stopwords
   */
  public Set<?> getStopwordSet() {
    return stopwords;
  }

  /**
   * Creates a new instance initialized with the given stopword set
   * 
   * @param version
   *          the Lucene version for cross version compatibility
   * @param stopwords
   *          the analyzer's stopword set
   */
  protected StopwordAnalyzerBase(final Version version, final Set<?> stopwords) {
    matchVersion = version;
    // analyzers should use char array set for stopwords!
    this.stopwords = stopwords == null ? CharArraySet.EMPTY_SET : CharArraySet
        .unmodifiableSet(CharArraySet.copy(version, stopwords));
  }

  /**
   * Creates a new Analyzer with an empty stopword set
   * 
   * @param version
   *          the Lucene version for cross version compatibility
   */
  protected StopwordAnalyzerBase(final Version version) {
    this(version, null);
  }

  /**
   * Creates a CharArraySet from a file resource associated with a class. (See
   * {@link Class#getResourceAsStream(String)}).
   * 
   * @param ignoreCase
   *          <code>true</code> if the set should ignore the case of the
   *          stopwords, otherwise <code>false</code>
   * @param aClass
   *          a class that is associated with the given stopwordResource
   * @param resource
   *          name of the resource file associated with the given class
   * @param comment
   *          comment string to ignore in the stopword file
   * @return a CharArraySet containing the distinct stopwords from the given
   *         file
   * @throws IOException
   *           if loading the stopwords throws an {@link IOException}
   */
  protected static CharArraySet loadStopwordSet(final boolean ignoreCase,
      final Class<? extends ReusableAnalyzerBase> aClass, final String resource,
      final String comment) throws IOException {
    Reader reader = null;
    try {
      reader = IOUtils.getDecodingReader(aClass.getResourceAsStream(resource), IOUtils.CHARSET_UTF_8);
      return WordlistLoader.getWordSet(reader, comment, new CharArraySet(Version.LUCENE_31, 16, ignoreCase));
    } finally {
      IOUtils.close(reader);
    }
    
  }
  
  /**
   * Creates a CharArraySet from a file.
   * 
   * @param stopwords
   *          the stopwords file to load
   * 
   * @param matchVersion
   *          the Lucene version for cross version compatibility
   * @return a CharArraySet containing the distinct stopwords from the given
   *         file
   * @throws IOException
   *           if loading the stopwords throws an {@link IOException}
   */
  protected static CharArraySet loadStopwordSet(File stopwords,
      Version matchVersion) throws IOException {
    Reader reader = null;
    try {
      reader = IOUtils.getDecodingReader(stopwords, IOUtils.CHARSET_UTF_8);
      return WordlistLoader.getWordSet(reader, matchVersion);
    } finally {
      IOUtils.close(reader);
    }
  }
  
  /**
   * Creates a CharArraySet from a file.
   * 
   * @param stopwords
   *          the stopwords reader to load
   * 
   * @param matchVersion
   *          the Lucene version for cross version compatibility
   * @return a CharArraySet containing the distinct stopwords from the given
   *         reader
   * @throws IOException
   *           if loading the stopwords throws an {@link IOException}
   */
  protected static CharArraySet loadStopwordSet(Reader stopwords,
      Version matchVersion) throws IOException {
    try {
      return WordlistLoader.getWordSet(stopwords, matchVersion);
    } finally {
      IOUtils.close(stopwords);
    }
  }
}
