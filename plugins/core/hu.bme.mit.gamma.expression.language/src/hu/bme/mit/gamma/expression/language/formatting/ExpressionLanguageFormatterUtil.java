/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.language.formatting;

import org.eclipse.xtext.Keyword;
import org.eclipse.xtext.formatting.impl.FormattingConfig;
import org.eclipse.xtext.service.AbstractElementFinder.AbstractGrammarElementFinder;
import org.eclipse.xtext.util.Pair;

public class ExpressionLanguageFormatterUtil {

	public void format(FormattingConfig c, AbstractGrammarElementFinder f) {
		setBrackets(c, f);
		setParantheses(c, f);
		setDots(c, f);
		setExclamationMarks(c, f);
		setCommas(c, f);
		setSemicolons(c, f);
		setDoubleColons(c, f);
	}

	public void setDoubleColons(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword dot : f.findKeywords("::")) {
			c.setNoSpace().after(dot);
		}
	}

	public void setCommas(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword comma : f.findKeywords(",")) {
			c.setNoSpace().before(comma);
		}
	}
	
	public void setSemicolons(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword comma : f.findKeywords(";")) {
			c.setNoSpace().before(comma);
		}
	}

	public void setExclamationMarks(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword exclamationMark : f.findKeywords("!")) {
			c.setNoSpace().after(exclamationMark);
		}
	}

	public void setDots(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Keyword dot : f.findKeywords(".")) {
			c.setNoSpace().around(dot);
		}
	}

	public void setParantheses(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Pair<Keyword, Keyword> p : f.findKeywordPairs("(", ")")) {
			c.setNoSpace().after(p.getFirst());
			c.setNoSpace().before(p.getSecond());
		}
	}

	public void setBrackets(FormattingConfig c, AbstractGrammarElementFinder f) {
		for (Pair<Keyword, Keyword> pair : f.findKeywordPairs("{", "}")) {
			c.setIndentation(pair.getFirst(), pair.getSecond());
			c.setLinewrap(1).after(pair.getFirst());
			c.setLinewrap(1).before(pair.getSecond());
			c.setLinewrap(1).after(pair.getSecond());
		}
	}

}
