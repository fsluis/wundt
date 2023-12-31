package org.apache.lucene3.analysis.ga;

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

import java.io.IOException;
import java.io.Reader;
import java.util.Arrays;

import org.apache.lucene3.analysis.Analyzer;
import org.apache.lucene3.analysis.StopFilter;
import org.apache.lucene3.analysis.fr.ElisionFilter;
import org.apache.lucene3.analysis.KeywordMarkerFilter;
import org.apache.lucene3.analysis.TokenStream;
import org.apache.lucene3.analysis.Tokenizer;
import org.apache.lucene3.analysis.snowball.SnowballFilter;
import org.apache.lucene3.analysis.standard.StandardFilter;
import org.apache.lucene3.analysis.standard.StandardTokenizer;
import org.apache.lucene3.analysis.CharArraySet;
import org.apache.lucene3.analysis.StopwordAnalyzerBase;
import org.apache.lucene3.util.Version;
import org.tartarus.snowball3.ext.IrishStemmer;

/**
 * {@link Analyzer} for Irish.
 */
public final class IrishAnalyzer extends StopwordAnalyzerBase {
  private final CharArraySet stemExclusionSet;
  
  /** File containing default Irish stopwords. */
  public final static String DEFAULT_STOPWORD_FILE = "stopwords.txt";
  
  private static final CharArraySet DEFAULT_ARTICLES = CharArraySet.unmodifiableSet(
      new CharArraySet(Version.LUCENE_CURRENT, 
          Arrays.asList(
              "d", "m", "b"
          ), true));
  
  /**
   * When StandardTokenizer splits t‑athair into {t, athair}, we don't
   * want to cause a position increment, otherwise there will be problems
   * with phrase queries versus tAthair (which would not have a gap).
   */
  private static final CharArraySet HYPHENATIONS = CharArraySet.unmodifiableSet(
      new CharArraySet(Version.LUCENE_CURRENT,
          Arrays.asList(
              "h", "n", "t"
          ), true));
  
  /**
   * Returns an unmodifiable instance of the default stop words set.
   * @return default stop words set.
   */
  public static CharArraySet getDefaultStopSet(){
    return DefaultSetHolder.DEFAULT_STOP_SET;
  }
  
  /**
   * Atomically loads the DEFAULT_STOP_SET in a lazy fashion once the outer class 
   * accesses the static final set the first time.;
   */
  private static class DefaultSetHolder {
    static final CharArraySet DEFAULT_STOP_SET;

    static {
      try {
        DEFAULT_STOP_SET = loadStopwordSet(false, 
            IrishAnalyzer.class, DEFAULT_STOPWORD_FILE, "#");
      } catch (IOException ex) {
        // default set should always be present as it is part of the
        // distribution (JAR)
        throw new RuntimeException("Unable to load default stopword set");
      }
    }
  }

  /**
   * Builds an analyzer with the default stop words: {@link #DEFAULT_STOPWORD_FILE}.
   */
  public IrishAnalyzer(Version matchVersion) {
    this(matchVersion, DefaultSetHolder.DEFAULT_STOP_SET);
  }
  
  /**
   * Builds an analyzer with the given stop words.
   * 
   * @param matchVersion lucene compatibility version
   * @param stopwords a stopword set
   */
  public IrishAnalyzer(Version matchVersion, CharArraySet stopwords) {
    this(matchVersion, stopwords, CharArraySet.EMPTY_SET);
  }

  /**
   * Builds an analyzer with the given stop words. If a non-empty stem exclusion set is
   * provided this analyzer will add a {@link KeywordMarkerFilter} before
   * stemming.
   * 
   * @param matchVersion lucene compatibility version
   * @param stopwords a stopword set
   * @param stemExclusionSet a set of terms not to be stemmed
   */
  public IrishAnalyzer(Version matchVersion, CharArraySet stopwords, CharArraySet stemExclusionSet) {
    super(matchVersion, stopwords);
    this.stemExclusionSet = CharArraySet.unmodifiableSet(CharArraySet.copy(
        matchVersion, stemExclusionSet));
  }

  /**
   * Creates a
   * {@link org.apache.lucene3.analysis.ReusableAnalyzerBase.TokenStreamComponents}
   * which tokenizes all the text in the provided {@link Reader}.
   * 
   * @return A
   *         {@link org.apache.lucene3.analysis.ReusableAnalyzerBase.TokenStreamComponents}
   *         built from an {@link StandardTokenizer} filtered with
   *         {@link StandardFilter}, {@link IrishLowerCaseFilter}, {@link StopFilter}
   *         , {@link KeywordMarkerFilter} if a stem exclusion set is
   *         provided and {@link SnowballFilter}.
   */
  @Override
  protected TokenStreamComponents createComponents(String fieldName,
      Reader reader) {
    final Tokenizer source = new StandardTokenizer(matchVersion, reader);
    TokenStream result = new StandardFilter(matchVersion, source);
    StopFilter s = new StopFilter(matchVersion, result, HYPHENATIONS);
    s.setEnablePositionIncrements(false);
    result = s;
    result = new ElisionFilter(matchVersion, result, DEFAULT_ARTICLES);
    result = new IrishLowerCaseFilter(result);
    result = new StopFilter(matchVersion, result, stopwords);
    if(!stemExclusionSet.isEmpty())
      result = new KeywordMarkerFilter(result, stemExclusionSet);
    result = new SnowballFilter(result, new IrishStemmer());
    return new TokenStreamComponents(source, result);
  }
}
