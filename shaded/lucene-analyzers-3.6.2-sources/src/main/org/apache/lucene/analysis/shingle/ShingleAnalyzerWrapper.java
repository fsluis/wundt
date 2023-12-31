package org.apache.lucene3.analysis.shingle;

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

import org.apache.lucene3.analysis.Analyzer;
import org.apache.lucene3.analysis.TokenStream;
import org.apache.lucene3.analysis.standard.StandardAnalyzer;
import org.apache.lucene3.util.Version;

/**
 * A ShingleAnalyzerWrapper wraps a {@link ShingleFilter} around another {@link Analyzer}.
 * <p>
 * A shingle is another name for a token based n-gram.
 * </p>
 */
public final class ShingleAnalyzerWrapper extends Analyzer {

  private final Analyzer defaultAnalyzer;
  private int maxShingleSize = ShingleFilter.DEFAULT_MAX_SHINGLE_SIZE;
  private int minShingleSize = ShingleFilter.DEFAULT_MIN_SHINGLE_SIZE;
  private String tokenSeparator = ShingleFilter.TOKEN_SEPARATOR;
  private boolean outputUnigrams = true;
  private boolean outputUnigramsIfNoShingles = false;

  public ShingleAnalyzerWrapper(Analyzer defaultAnalyzer) {
    this(defaultAnalyzer, ShingleFilter.DEFAULT_MAX_SHINGLE_SIZE);
  }

  public ShingleAnalyzerWrapper(Analyzer defaultAnalyzer, int maxShingleSize) {
    this(defaultAnalyzer, ShingleFilter.DEFAULT_MIN_SHINGLE_SIZE, maxShingleSize);
  }

  public ShingleAnalyzerWrapper(Analyzer defaultAnalyzer, int minShingleSize, int maxShingleSize) {
    this(defaultAnalyzer, minShingleSize, maxShingleSize, ShingleFilter.TOKEN_SEPARATOR, true, false);
  }

  /**
   * Creates a new ShingleAnalyzerWrapper
   *
   * @param defaultAnalyzer Analyzer whose TokenStream is to be filtered
   * @param minShingleSize Min shingle (token ngram) size
   * @param maxShingleSize Max shingle size
   * @param tokenSeparator Used to separate input stream tokens in output shingles
   * @param outputUnigrams Whether or not the filter shall pass the original
   *        tokens to the output stream
   * @param outputUnigramsIfNoShingles Overrides the behavior of outputUnigrams==false for those
   *        times when no shingles are available (because there are fewer than
   *        minShingleSize tokens in the input stream)?
   *        Note that if outputUnigrams==true, then unigrams are always output,
   *        regardless of whether any shingles are available.
   */
  public ShingleAnalyzerWrapper(
      Analyzer defaultAnalyzer,
      int minShingleSize,
      int maxShingleSize,
      String tokenSeparator,
      boolean outputUnigrams,
      boolean outputUnigramsIfNoShingles) {
    this.defaultAnalyzer = defaultAnalyzer;

    if (maxShingleSize < 2) {
      throw new IllegalArgumentException("Max shingle size must be >= 2");
    }
    this.maxShingleSize = maxShingleSize;

    if (minShingleSize < 2) {
      throw new IllegalArgumentException("Min shingle size must be >= 2");
    }
    if (minShingleSize > maxShingleSize) {
      throw new IllegalArgumentException
        ("Min shingle size must be <= max shingle size");
    }
    this.minShingleSize = minShingleSize;

    this.tokenSeparator = (tokenSeparator == null ? "" : tokenSeparator);
    this.outputUnigrams = outputUnigrams;
    this.outputUnigramsIfNoShingles = outputUnigramsIfNoShingles;
  }

  /**
   * Wraps {@link StandardAnalyzer}. 
   */
  public ShingleAnalyzerWrapper(Version matchVersion) {
    this(matchVersion, ShingleFilter.DEFAULT_MIN_SHINGLE_SIZE, ShingleFilter.DEFAULT_MAX_SHINGLE_SIZE);
  }

  /**
   * Wraps {@link StandardAnalyzer}. 
   */
  public ShingleAnalyzerWrapper(Version matchVersion, int minShingleSize, int maxShingleSize) {
    this(new StandardAnalyzer(matchVersion), minShingleSize, maxShingleSize);
  }

  /**
   * The max shingle (token ngram) size
   * 
   * @return The max shingle (token ngram) size
   */
  public int getMaxShingleSize() {
    return maxShingleSize;
  }

  /**
   * Set the maximum size of output shingles (default: 2)
   *
   * @param maxShingleSize max shingle size
   * @deprecated Setting maxShingleSize after Analyzer instantiation prevents reuse.
   *             Confgure maxShingleSize during construction.
   */
  @Deprecated
  public void setMaxShingleSize(int maxShingleSize) {
    if (maxShingleSize < 2) {
      throw new IllegalArgumentException("Max shingle size must be >= 2");
    }
    this.maxShingleSize = maxShingleSize;
  }

  /**
   * The min shingle (token ngram) size
   * 
   * @return The min shingle (token ngram) size
   */
  public int getMinShingleSize() {
    return minShingleSize;
  }

  /**
   * <p>Set the min shingle size (default: 2).
   * <p>This method requires that the passed in minShingleSize is not greater
   * than maxShingleSize, so make sure that maxShingleSize is set before
   * calling this method.
   *
   * @param minShingleSize min size of output shingles
   * @deprecated Setting minShingleSize after Analyzer instantiation prevents reuse.
   *             Confgure minShingleSize during construction.
   */
  @Deprecated
  public void setMinShingleSize(int minShingleSize) {
    if (minShingleSize < 2) {
      throw new IllegalArgumentException("Min shingle size must be >= 2");
    }
    if (minShingleSize > maxShingleSize) {
      throw new IllegalArgumentException
        ("Min shingle size must be <= max shingle size");
    }
    this.minShingleSize = minShingleSize;
  }

  public String getTokenSeparator() {
    return tokenSeparator;
  }

  /**
   * Sets the string to use when joining adjacent tokens to form a shingle
   * @param tokenSeparator used to separate input stream tokens in output shingles
   * @deprecated Setting tokenSeparator after Analyzer instantiation prevents reuse.
   *             Confgure tokenSeparator during construction.
   */
  @Deprecated
  public void setTokenSeparator(String tokenSeparator) {
    this.tokenSeparator = (tokenSeparator == null ? "" : tokenSeparator);
  }
  
  public boolean isOutputUnigrams() {
    return outputUnigrams;
  }

  /**
   * Shall the filter pass the original tokens (the "unigrams") to the output
   * stream?
   * 
   * @param outputUnigrams Whether or not the filter shall pass the original
   *        tokens to the output stream
   * @deprecated Setting outputUnigrams after Analyzer instantiation prevents reuse.
   *             Confgure outputUnigrams during construction.
   */
  @Deprecated
  public void setOutputUnigrams(boolean outputUnigrams) {
    this.outputUnigrams = outputUnigrams;
  }
  
  public boolean isOutputUnigramsIfNoShingles() {
    return outputUnigramsIfNoShingles;
  }
  
  /**
   * <p>Shall we override the behavior of outputUnigrams==false for those
   * times when no shingles are available (because there are fewer than
   * minShingleSize tokens in the input stream)? (default: false.)
   * <p>Note that if outputUnigrams==true, then unigrams are always output,
   * regardless of whether any shingles are available.
   *
   * @param outputUnigramsIfNoShingles Whether or not to output a single
   *  unigram when no shingles are available.
   * @deprecated Setting outputUnigramsIfNoShingles after Analyzer instantiation prevents reuse.
   *             Confgure outputUnigramsIfNoShingles during construction.
   */
  @Deprecated
  public void setOutputUnigramsIfNoShingles(boolean outputUnigramsIfNoShingles) {
    this.outputUnigramsIfNoShingles = outputUnigramsIfNoShingles;
  }

  @Override
  public TokenStream tokenStream(String fieldName, Reader reader) {
    TokenStream wrapped;
    try {
      wrapped = defaultAnalyzer.reusableTokenStream(fieldName, reader);
    } catch (IOException e) {
      wrapped = defaultAnalyzer.tokenStream(fieldName, reader);
    }
    ShingleFilter filter = new ShingleFilter(wrapped, minShingleSize, maxShingleSize);
    filter.setMinShingleSize(minShingleSize);
    filter.setMaxShingleSize(maxShingleSize);
    filter.setTokenSeparator(tokenSeparator);
    filter.setOutputUnigrams(outputUnigrams);
    filter.setOutputUnigramsIfNoShingles(outputUnigramsIfNoShingles);
    return filter;
  }
  
  private class SavedStreams {
    TokenStream wrapped;
    ShingleFilter shingle;
  }
  
  @Override
  public TokenStream reusableTokenStream(String fieldName, Reader reader) throws IOException {
    SavedStreams streams = (SavedStreams) getPreviousTokenStream();
    if (streams == null) {
      streams = new SavedStreams();
      streams.wrapped = defaultAnalyzer.reusableTokenStream(fieldName, reader);
      streams.shingle = new ShingleFilter(streams.wrapped);
      setPreviousTokenStream(streams);
    } else {
      TokenStream result = defaultAnalyzer.reusableTokenStream(fieldName, reader);
      if (result != streams.wrapped) {
        /* the wrapped analyzer did not, create a new shingle around the new one */
        streams.wrapped = result;
        streams.shingle = new ShingleFilter(streams.wrapped);
      }
    }
    streams.shingle.setMaxShingleSize(maxShingleSize);
    streams.shingle.setMinShingleSize(minShingleSize);
    streams.shingle.setTokenSeparator(tokenSeparator);
    streams.shingle.setOutputUnigrams(outputUnigrams);
    streams.shingle.setOutputUnigramsIfNoShingles(outputUnigramsIfNoShingles);
    return streams.shingle;
  }
}
