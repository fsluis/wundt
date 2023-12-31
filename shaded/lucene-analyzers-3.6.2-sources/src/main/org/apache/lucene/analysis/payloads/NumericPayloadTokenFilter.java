package org.apache.lucene3.analysis.payloads;
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


import org.apache.lucene3.analysis.TokenFilter;
import org.apache.lucene3.analysis.TokenStream;
import org.apache.lucene3.analysis.tokenattributes.PayloadAttribute;
import org.apache.lucene3.analysis.tokenattributes.TypeAttribute;
import org.apache.lucene3.index.Payload;

import java.io.IOException;


/**
 * Assigns a payload to a token based on the {@link org.apache.lucene3.analysis.Token#type()}
 *
 **/
public class NumericPayloadTokenFilter extends TokenFilter {

  private String typeMatch;
  private Payload thePayload;

  private final PayloadAttribute payloadAtt = addAttribute(PayloadAttribute.class);
  private final TypeAttribute typeAtt = addAttribute(TypeAttribute.class);

  public NumericPayloadTokenFilter(TokenStream input, float payload, String typeMatch) {
    super(input);
    //Need to encode the payload
    thePayload = new Payload(PayloadHelper.encodeFloat(payload));
    this.typeMatch = typeMatch;
  }

  @Override
  public final boolean incrementToken() throws IOException {
    if (input.incrementToken()) {
      if (typeAtt.type().equals(typeMatch))
        payloadAtt.setPayload(thePayload);
      return true;
    } else {
      return false;
    }
  }
}
