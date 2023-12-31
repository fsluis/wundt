package org.apache.lucene3.analysis.hi;

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
import java.util.Set;

import org.apache.lucene3.analysis.LowerCaseFilter;
import org.apache.lucene3.analysis.CharArraySet;
import org.apache.lucene3.analysis.KeywordMarkerFilter;
import org.apache.lucene3.analysis.StopFilter;
import org.apache.lucene3.analysis.StopwordAnalyzerBase;
import org.apache.lucene3.analysis.standard.StandardTokenizer;
import org.apache.lucene3.analysis.TokenStream;
import org.apache.lucene3.analysis.Tokenizer;
import org.apache.lucene3.analysis.in.IndicNormalizationFilter;
import org.apache.lucene3.analysis.in.IndicTokenizer;
import org.apache.lucene3.util.Version;

/**
 * Analyzer for Hindi.
 * <p>
 * <a name="version"/>
 * <p>You must specify the required {@link Version}
 * compatibility when creating HindiAnalyzer:
 * <ul>
 *   <li> As of 3.6, StandardTokenizer is used for tokenization
 * </ul>
 */
public final class HindiAnalyzer extends StopwordAnalyzerBase {
  private final Set<?> stemExclusionSet;
  
  /**
   * File containing default Hindi stopwords.
   * 
   * Default stopword list is from http://members.unine.ch/jacques.savoy/clef/index.html
   * The stopword list is BSD-Licensed.
   */
  public final static String DEFAULT_STOPWORD_FILE = "stopwords.txt";
  private static final String STOPWORDS_COMMENT = "#";
  
  /**
   * Returns an unmodifiable instance of the default stop-words set.
   * @return an unmodifiable instance of the default stop-words set.
   */
  public static Set<?> getDefaultStopSet(){
    return DefaultSetHolder.DEFAULT_STOP_SET;
  }
  
  /**
   * Atomically loads the DEFAULT_STOP_SET in a lazy fashion once the outer class 
   * accesses the static final set the first time.;
   */
  private static class DefaultSetHolder {
    static final Set<?> DEFAULT_STOP_SET;

    static {
      try {
        DEFAULT_STOP_SET = loadStopwordSet(false, HindiAnalyzer.class, DEFAULT_STOPWORD_FILE, STOPWORDS_COMMENT);
      } catch (IOException ex) {
        // default set should always be present as it is part of the
        // distribution (JAR)
        throw new RuntimeException("Unable to load default stopword set");
      }
    }
  }
  
  /**
   * Builds an analyzer with the given stop words
   * 
   * @param version lucene compatibility version
   * @param stopwords a stopword set
   * @param stemExclusionSet a stemming exclusion set
   */
  public HindiAnalyzer(Version version, Set<?> stopwords, Set<?> stemExclusionSet) {
    super(version, stopwords);
    this.stemExclusionSet = CharArraySet.unmodifiableSet(
        CharArraySet.copy(matchVersion, stemExclusionSet));
  }
  
  /**
   * Builds an analyzer with the given stop words 
   * 
   * @param version lucene compatibility version
   * @param stopwords a stopword set
   */
  public HindiAnalyzer(Version version, Set<?> stopwords) {
    this(version, stopwords, CharArraySet.EMPTY_SET);
  }
  
  /**
   * Builds an analyzer with the default stop words:
   * {@link #DEFAULT_STOPWORD_FILE}.
   */
  public HindiAnalyzer(Version version) {
    this(version, DefaultSetHolder.DEFAULT_STOP_SET);
  }

  /**
   * Creates
   * {@link org.apache.lucene3.analysis.ReusableAnalyzerBase.TokenStreamComponents}
   * used to tokenize all the text in the provided {@link Reader}.
   * 
   * @return {@link org.apache.lucene3.analysis.ReusableAnalyzerBase.TokenStreamComponents}
   *         built from a {@link StandardTokenizer} filtered with
   *         {@link LowerCaseFilter}, {@link IndicNormalizationFilter},
   *         {@link HindiNormalizationFilter}, {@link KeywordMarkerFilter}
   *         if a stem exclusion set is provided, {@link HindiStemFilter}, and
   *         Hindi Stop words
   */
  @Override
  protected TokenStreamComponents createComponents(String fieldName,
      Reader reader) {
    final Tokenizer source;
    if (matchVersion.onOrAfter(Version.LUCENE_36)) {
      source = new StandardTokenizer(matchVersion, reader);
    } else {
      source = new IndicTokenizer(matchVersion, reader);
    }
    TokenStream result = new LowerCaseFilter(matchVersion, source);
    if (!stemExclusionSet.isEmpty())
      result = new KeywordMarkerFilter(result, stemExclusionSet);
    result = new IndicNormalizationFilter(result);
    result = new HindiNormalizationFilter(result);
    result = new StopFilter(matchVersion, result, stopwords);
    result = new HindiStemFilter(result);
    return new TokenStreamComponents(source, result);
  }
}
