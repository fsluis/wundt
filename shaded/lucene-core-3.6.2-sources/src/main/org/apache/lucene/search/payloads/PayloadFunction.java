package org.apache.lucene33.search.payloads;
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

import java.io.Serializable;
import org.apache.lucene33.search.Explanation;

/**
 * An abstract class that defines a way for Payload*Query instances to transform
 * the cumulative effects of payload scores for a document.
 * 
 * @see org.apache.lucene33.search.payloads.PayloadTermQuery for more information
 * 
 * @lucene.experimental This class and its derivations are experimental and subject to
 *               change
 * 
 **/
public abstract class PayloadFunction implements Serializable {

  /**
   * Calculate the score up to this point for this doc and field
   * @param docId The current doc
   * @param field The field
   * @param start The start position of the matching Span
   * @param end The end position of the matching Span
   * @param numPayloadsSeen The number of payloads seen so far
   * @param currentScore The current score so far
   * @param currentPayloadScore The score for the current payload
   * @return The new current Score
   *
   * @see org.apache.lucene33.search.spans.Spans
   */
  public abstract float currentScore(int docId, String field, int start, int end, int numPayloadsSeen, float currentScore, float currentPayloadScore);

  /**
   * Calculate the final score for all the payloads seen so far for this doc/field
   * @param docId The current doc
   * @param field The current field
   * @param numPayloadsSeen The total number of payloads seen on this document
   * @param payloadScore The raw score for those payloads
   * @return The final score for the payloads
   */
  public abstract float docScore(int docId, String field, int numPayloadsSeen, float payloadScore);
  
  public Explanation explain(int docId, int numPayloadsSeen, float payloadScore){
	  Explanation result = new Explanation();
	  result.setDescription("Unimpl Payload Function Explain");
	  result.setValue(1);
	  return result;
  };
  
  @Override
  public abstract int hashCode();
  
  @Override
  public abstract boolean equals(Object o);

}
