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
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.AddExpression;
import hu.bme.mit.gamma.expression.model.ArithmeticExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanExpression;
import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeTypeDefinition;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ModExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.QuantifierExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression;
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression;
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition;

public class ExpressionTypeDeterminator {
	// Singleton
	public static final ExpressionTypeDeterminator INSTANCE = new ExpressionTypeDeterminator();
	protected ExpressionTypeDeterminator() {}
	//
	protected final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	
	/**
	 * Collector of extension methods.
	 */
	public ExpressionType getType(Expression expression) {
		if (expression instanceof BooleanLiteralExpression) {
			return getType((BooleanLiteralExpression) expression);
		}
		if (expression instanceof IntegerLiteralExpression) {
			return getType((IntegerLiteralExpression) expression);
		}
		if (expression instanceof RationalLiteralExpression) {
			return getType((RationalLiteralExpression) expression);
		}
		if (expression instanceof DecimalLiteralExpression) {
			return getType((DecimalLiteralExpression) expression);
		}
		if (expression instanceof EnumerationLiteralExpression) {
			return getType((EnumerationLiteralExpression) expression);
		}
		if (expression instanceof IntegerRangeLiteralExpression) {
			return getType((IntegerRangeLiteralExpression) expression);
		}
		if (expression instanceof RecordLiteralExpression) {
			return getType((RecordLiteralExpression) expression);
		}
		if (expression instanceof ArrayLiteralExpression) {
			return getType((ArrayLiteralExpression) expression);
		}
		if (expression instanceof DirectReferenceExpression) {
			return getType((DirectReferenceExpression) expression);
		}
		if (expression instanceof ElseExpression) {
			return getType((ElseExpression) expression);
		}
		if (expression instanceof BooleanExpression) {
			return getType((BooleanExpression) expression);
		}
		if (expression instanceof PredicateExpression) {
			return getType((PredicateExpression) expression);
		}
		if (expression instanceof QuantifierExpression) {
			return getType((QuantifierExpression) expression);
		}
		if (expression instanceof UnaryPlusExpression) {
			return getArithmeticUnaryType((UnaryPlusExpression) expression);
		}
		if (expression instanceof UnaryMinusExpression) {
			return getArithmeticUnaryType((UnaryMinusExpression) expression);
		}
		if (expression instanceof SubtractExpression) {
			return getArithmeticBinaryType((SubtractExpression) expression);
		}
		if (expression instanceof DivideExpression) {
			return getArithmeticBinaryType((DivideExpression) expression);
		}
		if (expression instanceof ModExpression) {
			return getArithmeticBinaryIntegerType((ModExpression) expression);
		}
		if (expression instanceof DivExpression) {
			return getArithmeticBinaryIntegerType((DivExpression) expression);
		}
		if (expression instanceof AddExpression) {
			return getArithmeticMultiaryType((AddExpression) expression);
		}
		if (expression instanceof MultiplyExpression) {
			return getArithmeticMultiaryType((MultiplyExpression) expression);
		}
		if (expression instanceof ArrayAccessExpression) {
			int depth = 0;
			List<FieldDeclaration> fields = new ArrayList<FieldDeclaration>();
			ReferenceExpression ref = (ArrayAccessExpression) expression;
			TypeDefinition type;
			while (true) {
				if (ref instanceof ArrayAccessExpression) {
					depth++;
					ref = (ReferenceExpression)((ArrayAccessExpression)ref).getOperand();
				} else if (ref instanceof RecordAccessExpression) {
					RecordAccessExpression recordAccessExpression = (RecordAccessExpression) ref;
					fields.add(0, recordAccessExpression.getFieldReference().getFieldDeclaration());
					ref = (ReferenceExpression) recordAccessExpression.getOperand();
				} else if (ref instanceof DirectReferenceExpression) {
					type = expressionUtil.findTypeDefinitionOfType(((DirectReferenceExpression)ref).getDeclaration().getType());
					break;
				} else {
					throw new IllegalArgumentException("Array access expression contains forbidden elements: " + ref.getClass());
				}
			}
			while (depth >= 0 || !fields.isEmpty()) {
				if (type instanceof ArrayTypeDefinition) {
					type = expressionUtil.findTypeDefinitionOfType(((ArrayTypeDefinition)type).getElementType());
					depth--;
				} else if (type instanceof RecordTypeDefinition) {
					type = expressionUtil.findTypeDefinitionOfType(((RecordTypeDefinition)type).getFieldDeclarations().stream().filter(e -> e.equals(fields.remove(0))).findFirst().get().getType());
				} else {
					throw new IllegalArgumentException("Type contains forbidden elements: " + type.getClass());
				}
			}
			return transform(expressionUtil.findTypeDefinitionOfType(type));
		}
		if (expression instanceof FunctionAccessExpression) {
			return transform(expressionUtil.getDeclaration(((FunctionAccessExpression) expression)).getType());
			// What if it goes through a type reference / declaration?
		}
		if (expression instanceof RecordAccessExpression) {
			RecordAccessExpression recordAccessExpression = (RecordAccessExpression) expression;
			return getType(recordAccessExpression.getFieldReference());
		}
		if (expression instanceof SelectExpression) {
			SelectExpression selectExpression = (SelectExpression) expression;
			Declaration declaration = expressionUtil.getAccessedDeclaration(selectExpression);
			TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(declaration);
			if (typeDefinition instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
				return transform(arrayTypeDefinition.getElementType());
			}
			else if (typeDefinition instanceof IntegerRangeTypeDefinition) {
				return ExpressionType.INTEGER;
			}
			else if (typeDefinition instanceof EnumerationTypeDefinition) {
				return ExpressionType.ENUMERATION;
			}
			else {
				throw new IllegalArgumentException("The type of the operand  of the select expression is not an enumerable type: " + expressionUtil.getDeclaration(selectExpression));
			}
		}
		if (expression instanceof IfThenElseExpression) {
			return getType(((IfThenElseExpression) expression).getThen());
		}
		if (expression instanceof OpaqueExpression) {
			return ExpressionType.VOID;
		}
		if (expression == null) {
			return ExpressionType.VOID;
		}
		// EventParameterReferences: they are contained in StatechartModelPackage (they cannot be imported)
		Optional<EObject> parameter = getParameter(expression);
		if (parameter.isPresent()) {
			ParameterDeclaration parameterDeclaration = (ParameterDeclaration) parameter.get();
			Type declarationType = parameterDeclaration.getType();
			return transform(declarationType);
		}
		return ExpressionType.UNKNOWN;
	}

	protected Optional<EObject> getParameter(Expression expression) {
		return expression.eCrossReferences().stream().filter(it -> it instanceof ParameterDeclaration).findFirst();
	}
	
	// Extension methods
	
	// Literals
	
	private ExpressionType getType(BooleanLiteralExpression expression) {
		return ExpressionType.BOOLEAN;
	}
	
	private ExpressionType getType(IntegerLiteralExpression expression) {
		return ExpressionType.INTEGER;
	}
	
	private ExpressionType getType(RationalLiteralExpression expression) {
		return ExpressionType.RATIONAL;
	}
	
	private ExpressionType getType(DecimalLiteralExpression expression) {
		return ExpressionType.DECIMAL;
	}
	
	private ExpressionType getType(EnumerationLiteralExpression expression) {
		return ExpressionType.ENUMERATION;
	}
	
	private ExpressionType getType(IntegerRangeLiteralExpression expression) {
		return ExpressionType.INTEGER_RANGE;
	}
	
	private ExpressionType getType(RecordLiteralExpression expression) {
		return ExpressionType.RECORD;
	}
	
	private ExpressionType getType(ArrayLiteralExpression expression) {
		return ExpressionType.ARRAY;
	}
	
	// References
	
	private ExpressionType getType(DirectReferenceExpression expression) {
		Type declarationType = expression.getDeclaration().getType();
		return transform(declarationType);
	}
	
	// Else
	
	private ExpressionType getType(ElseExpression expression) {
		return ExpressionType.BOOLEAN;
	}
	
	// Boolean
	
	private ExpressionType getType(BooleanExpression expression) {
		return ExpressionType.BOOLEAN;
	}
	
	// Predicate
	
	private ExpressionType getType(PredicateExpression expression) {
		return ExpressionType.BOOLEAN;
	}
	
	// Quantifier
	
	private ExpressionType getType(QuantifierExpression expression) {
		return ExpressionType.BOOLEAN;
	}
	
	// Arithmetics
	
	private ExpressionType getArithmeticType(Collection<ExpressionType> collection) {
		// Wrong types, not suitable for arithmetic operations
		if (collection.stream().anyMatch(it -> !isNumber(it))) {
//			throw new IllegalArgumentException("Type is not suitable for arithmetic operations: " + collection);
			return ExpressionType.ERROR;
		}
		// All types are numbers
		if (collection.stream().anyMatch(it -> it == ExpressionType.DECIMAL)) {
			return ExpressionType.DECIMAL;
		}
		if (collection.stream().anyMatch(it -> it == ExpressionType.RATIONAL)) {
			return ExpressionType.RATIONAL;
		}
		return ExpressionType.INTEGER;
		
	}
	
	// Unary
	
	/**
	 * Unary plus and minus.
	 */
	private <T extends ArithmeticExpression & UnaryExpression> ExpressionType getArithmeticUnaryType(T expression) {
		ExpressionType type = getType(expression.getOperand());
		if (isNumber(type)) {
			return type;
		}
		throw new IllegalArgumentException("Type is not suitable type for expression: " + type + System.lineSeparator() + expression);
	}
	
	// Binary
	
	/**
	 * Subtract and divide.
	 */
	private <T extends ArithmeticExpression & BinaryExpression> ExpressionType getArithmeticBinaryType(T expression) {
		List<ExpressionType> types = new ArrayList<ExpressionType>();
		types.add(getType(expression.getLeftOperand()));
		types.add(getType(expression.getRightOperand()));		
		return getArithmeticType(types);
	}
	
	/**
	 * Modulo and div.
	 */
	private <T extends ArithmeticExpression & BinaryExpression> ExpressionType getArithmeticBinaryIntegerType(T expression) {
		ExpressionType type = getArithmeticBinaryType(expression);
		if (type == ExpressionType.INTEGER) {
			return type;
		}
		throw new IllegalArgumentException("Type is not suitable type for expression: " + type + System.lineSeparator() + expression);
	}
	
	// Multiary
	
	/**
	 * Add and multiply.
	 */
	private <T extends ArithmeticExpression & MultiaryExpression> ExpressionType getArithmeticMultiaryType(T expression) {
		Collection<ExpressionType> types = expression.getOperands().stream()
				.map(it -> getType(it)).collect(Collectors.toSet());
		return getArithmeticType(types);
	}
	
	// Easy determination of boolean and number types
	
	public boolean isBoolean(Expression	expression) {
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			Type declarationType = declaration.getType();
			return transform(declarationType) == ExpressionType.BOOLEAN;
		} else if (expression instanceof AccessExpression) {
			Declaration declaration = expressionUtil.getDeclaration(expression);
			Type declarationType = declaration.getType();
			return transform(declarationType) == ExpressionType.BOOLEAN;
		}
		return expression instanceof BooleanExpression || expression instanceof PredicateExpression ||
			expression instanceof ElseExpression;
	}
	
	private boolean isInteger(ExpressionType type) {
		return type == ExpressionType.INTEGER;
	}
	
	public boolean isInteger(Expression expression) {
		return isInteger(getType(expression));
	}
	
	private boolean isNumber(ExpressionType type) {
		return type == ExpressionType.INTEGER ||
				type == ExpressionType.DECIMAL ||
				type == ExpressionType.RATIONAL;
	}
	
	public boolean isNumber(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			Type declarationType = declaration.getType();
			return isNumber(transform(declarationType));
		} else {
			return isNumber(getType(expression));
		}
	}
	
	// Transform type
	
	public ExpressionType transform(Type type) {
		if (type == null) {
			// During editing the type of the reference expression can be null
			return ExpressionType.ERROR;
		} 
		if(type instanceof VoidTypeDefinition) {
			return ExpressionType.VOID;
		}
		if (type instanceof BooleanTypeDefinition) {
			return ExpressionType.BOOLEAN;
		}
		if (type instanceof IntegerTypeDefinition) {
			return ExpressionType.INTEGER;
		}
		if (type instanceof RationalTypeDefinition) {
			return ExpressionType.RATIONAL;
		}
		if (type instanceof DecimalTypeDefinition) {
			return ExpressionType.DECIMAL;
		}
		if (type instanceof EnumerationTypeDefinition) {
			return ExpressionType.ENUMERATION;
		}
		if (type instanceof ArrayTypeDefinition) {
			return ExpressionType.ARRAY;
		}
		if (type instanceof IntegerRangeTypeDefinition) {
			return ExpressionType.INTEGER_RANGE;
		}
		if (type instanceof RecordTypeDefinition) {
			return ExpressionType.RECORD;
		}
		if (type instanceof TypeReference) {
			TypeReference reference = (TypeReference) type;
			TypeDeclaration declaration = reference.getReference();
			Type declaredType = declaration.getType();
			return transform(declaredType);
		}
		throw new IllegalArgumentException("Not known type: " + type);
	}
	
	// Type equal (in the case of complex types, only shallow comparison)
	
	public boolean equals(Type type, ExpressionType expressionType) {
		return type instanceof BooleanTypeDefinition && expressionType == ExpressionType.BOOLEAN ||
			type instanceof IntegerTypeDefinition && expressionType == ExpressionType.INTEGER ||
			type instanceof RationalTypeDefinition && expressionType == ExpressionType.RATIONAL ||
			type instanceof DecimalTypeDefinition && expressionType == ExpressionType.DECIMAL ||
			type instanceof EnumerationTypeDefinition && expressionType == ExpressionType.ENUMERATION ||
			type instanceof ArrayTypeDefinition  && expressionType == ExpressionType.ARRAY ||
			type instanceof IntegerRangeTypeDefinition && expressionType == ExpressionType.INTEGER_RANGE ||
			type instanceof RecordTypeDefinition && expressionType == ExpressionType.RECORD ||
			type instanceof VoidTypeDefinition && expressionType == ExpressionType.VOID ||
			type instanceof TypeReference && equals(((TypeReference) type).getReference().getType(), expressionType);
	}
	
	public EnumerationTypeDefinition getEnumerationType(Type type) {
		EnumerationTypeDefinition enumType = null;
		if (type instanceof EnumerationTypeDefinition) {
			enumType = (EnumerationTypeDefinition) type;
		}
		else if (type instanceof TypeReference){
			final TypeReference typeReference = (TypeReference) type;
			final Type referencedType = typeReference.getReference().getType();
			if (referencedType instanceof EnumerationTypeDefinition) {
				enumType = (EnumerationTypeDefinition) referencedType;
			}
		}
		return enumType;
	}
	
	public EnumerationTypeDefinition getEnumerationType(Expression expression) {
		if (expression instanceof EnumerationLiteralExpression) {
			EnumerationLiteralExpression literal = (EnumerationLiteralExpression) expression;
			return (EnumerationTypeDefinition) literal.getReference().eContainer();
		}
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression reference = (DirectReferenceExpression) expression;
			Type type = reference.getDeclaration().getType();
			return getEnumerationType(type);
		}
		Optional<EObject> parameter = getParameter(expression);
		if (parameter.isPresent()) {
			ParameterDeclaration parameterDeclaration = (ParameterDeclaration) parameter.get();
			Type type = parameterDeclaration.getType();
			return getEnumerationType(type);
		}
		throw new IllegalArgumentException("Not known expression: " + expression);
	}
	
}
