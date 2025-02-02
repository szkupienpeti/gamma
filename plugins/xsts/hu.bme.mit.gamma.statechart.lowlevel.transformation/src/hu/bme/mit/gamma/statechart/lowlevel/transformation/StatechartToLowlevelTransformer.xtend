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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.util.ActionUtil
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.lowlevel.model.Component
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.GuardEvaluation
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutAction
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

class StatechartToLowlevelTransformer {
	// Auxiliary objects
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionUtil actionUtil = ActionUtil.INSTANCE
	protected final extension EventAttributeTransformer eventAttributeTransformer = EventAttributeTransformer.INSTANCE
	protected final extension TypeTransformer typeTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension TriggerTransformer triggerTransformer
	protected final extension PseudoStateTransformer pseudoStateTransformer
	// Low-level statechart model factory
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace object for storing the mappings
	protected final Trace trace
	// Transformation parameters
	protected final boolean functionInlining = true
	protected final int maxRecursionDepth = 10
	protected final String assertionVariableName = "__assertionFailed"

	new() {
		this.trace = new Trace
		this.typeTransformer = new TypeTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace, this.functionInlining)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace, this.functionInlining,
			this.maxRecursionDepth, this.assertionVariableName)
		this.triggerTransformer = new TriggerTransformer(this.trace, this.functionInlining)
		this.pseudoStateTransformer = new PseudoStateTransformer(this.trace)
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package execute(Package _package) {
		return _package.transform
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition execute(StatechartDefinition statechart) {
		return statechart.transformComponent as hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Package transform(Package _package) {
		if (trace.isMapped(_package)) {
			// It is already transformed
			return trace.get(_package)
		}
		val lowlevelPackage = createPackage => [
			it.name = _package.name
		]
		trace.put(_package, lowlevelPackage) // Saving in trace
		// Transforming other type declarations in ExpressionTransformer during variable transformation
		// Not transforming imports as it is unnecessary (Traces.getLowlevelPackage would not work either)
		return lowlevelPackage
	}
	
	protected def List<VariableDeclaration> transformComponentParameter(ParameterDeclaration gammaParameter) {
		val lowlevelVariables = gammaParameter.transformValue
		// Traced in transformValue
		val lowlevelVariableNames = gammaParameter.componentParameterNames
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		return lowlevelVariables
	}

	protected def List<VariableDeclaration> transform(ConstantDeclaration gammaConstant) {
		val lowlevelVariables = gammaConstant.transformValue
		// Constant variable names do not really matter in terms of traceability
		return lowlevelVariables
	}
	
	protected def List<VariableDeclaration> transform(VariableDeclaration gammaVariable) {
		val lowlevelVariables = gammaVariable.transformValue
		// Traced in transformValue
		val lowlevelVariableNames = gammaVariable.names
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		return lowlevelVariables
	}
	
	protected def nameLowlevelVariables(List<VariableDeclaration> lowlevelVariables,
			List<String> lowlevelVariableNames) {
		checkState(lowlevelVariables.size == lowlevelVariableNames.size)
		val size = lowlevelVariables.size
		for (var i = 0; i < size; i++) {
			val lowlevelVariable = lowlevelVariables.get(i)
			val lowlevelVariableName = lowlevelVariableNames.get(i)
			lowlevelVariable.name = lowlevelVariableName
		}
	}

	/**
	 * Returns a list, as an INOUT declaration is mapped to an IN and an OUT declaration.
	 */
	protected def List<EventDeclaration> transform(
			hu.bme.mit.gamma.statechart.interface_.EventDeclaration declaration, Port gammaPort) {
		val gammaDirection = declaration.direction
		val realizationMode = gammaPort.interfaceRealization.realizationMode
		if (gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.PROVIDED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.REQUIRED) {
			// Event coming in
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventIn) // Tracing the Event
			return #[lowlevelEventIn]
		}
		else if	(gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.REQUIRED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.PROVIDED) {
			// Events going out
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventOut) // Tracing the Event
			return #[lowlevelEventOut]
		}
		else {
			// In-out events
			checkState(gammaDirection == EventDirection.INOUT)
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			return #[lowlevelEventIn, lowlevelEventOut]
		}
	}

	protected def EventDeclaration transform(Event gammaEvent, Port gammaPort, EventDirection direction) {
		checkState(direction == EventDirection.IN || direction == EventDirection.OUT)
		val lowlevelEvent = createEventDeclaration => [
			it.name = (direction == EventDirection.IN) ?
				gammaEvent.getInputName(gammaPort) : gammaEvent.getOutputName(gammaPort)
			it.persistency = gammaEvent.persistency.transform
			it.direction = direction.transform
			it.isRaised = createVariableDeclaration => [
				it.name = "isRaised"
				it.type = createBooleanTypeDefinition
			]
		]
		trace.put(gammaPort, gammaEvent, lowlevelEvent)
		// Transforming the parameters
		for (gammaParameter : gammaEvent.parameterDeclarations) {
			val lowlevelParameters = gammaParameter.transformValue
			val lowlevelVariableNames = (direction == EventDirection.IN) ?
				gammaParameter.getInNames(gammaPort) : 
				gammaParameter.getOutNames(gammaPort)
			lowlevelParameters.nameLowlevelVariables(lowlevelVariableNames)
			lowlevelEvent.parameters += lowlevelParameters
			if (lowlevelParameters.size == 1) {
				// TODO Is this tracing good?
				val lowlevelParameter = lowlevelParameters.head
				trace.put(gammaPort, gammaEvent, gammaParameter,
					lowlevelEvent.direction, lowlevelParameter)
			
			}
		}
		return lowlevelEvent
	}

	protected def VariableDeclaration transform(TimeoutDeclaration timeout) {
		val statechart = timeout.containingStatechart
		val transitions = statechart.transitions.filter[it.getAllContentsOfType(
			TimeoutEventReference).exists[it.timeout === timeout]]
		// We can optimize, if this timeout is used for triggering the transitions of only one state
		if (transitions.size == 1) {
			val transition = transitions.head
			val source = transition.sourceState
			if (source instanceof State) {
				// We can optimize, if this is an after N sec trigger (each timeout is set only once, hence the "== 1" if it is one)
				if (source.getAllContentsOfType(
						TimeoutAction).exists[it.timeoutDeclaration === timeout]) {
					// We can optimize, if all outgoing transitions use (potentially) only this timeout
					if (source.outgoingTransitions.map[it.getAllContentsOfType(
							TimeoutEventReference).toList].flatten.forall[it.timeout === timeout]) {
						val gammaParentRegion = source.parentRegion
						if (!trace.doesRegionHaveOptimizedTimeout(gammaParentRegion)) {
							val lowlevelTimeout = timeout.createTimeoutVariable
							trace.put(gammaParentRegion, lowlevelTimeout)
						}
						val lowlevelTimeout = trace.getTimeout(gammaParentRegion)
						trace.put(timeout, lowlevelTimeout) // If the above if is true, this is not necessary
						return lowlevelTimeout
					}
				}
			}
		}
		return timeout.createTimeoutVariable
	}
	
	protected def createTimeoutVariable(TimeoutDeclaration timeout) {
		val lowlevelTimeout = createVariableDeclaration => [
			it.name = getName(timeout)
			it.type = createIntegerTypeDefinition // Could be rational
			// Initial expression in EventReferenceTransformer
		]
		trace.put(timeout, lowlevelTimeout)
		return lowlevelTimeout
	}
	
	protected def dispatch Component transformComponent(hu.bme.mit.gamma.statechart.interface_.Component component) {
		throw new IllegalArgumentException("Not known component: " + component)
	}
	
	protected def dispatch Component transformComponent(StatechartDefinition statechart) {
		if (trace.isMapped(statechart)) {
			// It is already transformed
			return trace.get(statechart)
		}
		val lowlevelStatechart = createStatechartDefinition => [
			it.name = getName(statechart)
			it.schedulingOrder = statechart.schedulingOrder.transform
			it.guardEvaluation = statechart.guardEvaluation.transform
		]
		trace.put(statechart, lowlevelStatechart) // Saving in trace
		
		// Create assertion variable if not yet created
		if (!trace.isAssertionVariableMapped(assertionVariableName)) {
			var assertionVariable = createVariableDeclaration => [
				it.name = assertionVariableName
				it.type = createBooleanTypeDefinition
				it.expression = createFalseExpression
			]
			lowlevelStatechart.variableDeclarations += assertionVariable
			trace.put(assertionVariableName, assertionVariable)
		}
		// Constants
		val gammaPackage = statechart.containingPackage
		for (constantDeclaration : gammaPackage.constantDeclarations) {
			lowlevelStatechart.variableDeclarations += constantDeclaration.transform
		}
		// No parameter declarations mapping
		for (parameterDeclaration : statechart.parameterDeclarations) {
			val lowlevelParameterDeclaration = parameterDeclaration.transformComponentParameter
			lowlevelStatechart.variableDeclarations += lowlevelParameterDeclaration
			lowlevelStatechart.parameterDeclarations += lowlevelParameterDeclaration
		}
		for (variableDeclaration : statechart.variableDeclarations) {
			lowlevelStatechart.variableDeclarations += variableDeclaration.transform
		}
		for (timeoutDeclaration : statechart.timeoutDeclarations) {
			// Timeout declarations are transformed to integer variable declarations
			val lowlevelTimeoutDeclaration = timeoutDeclaration.transform
			lowlevelStatechart.variableDeclarations += lowlevelTimeoutDeclaration
			lowlevelStatechart.timeoutDeclarations += lowlevelTimeoutDeclaration
		}
		for (port : statechart.ports) {
			// Both in and out events are transformed to a boolean VarDecl with additional parameters
			for (eventDecl : port.allEventDeclarations) {
				lowlevelStatechart.eventDeclarations += eventDecl.transform(port)
			}
		}
		for (region : statechart.regions) {
			lowlevelStatechart.regions += region.transform
		}
		for (transition : statechart.transitions) {
			val lowlevelTransition = transition.transform
			lowlevelStatechart.transitions += lowlevelTransition
		}
		// Prioritizing transitions
		if (statechart.transitionPriority != TransitionPriority.OFF) {
			statechart.prioritizeTransitions
		}
		return lowlevelStatechart
	}

	protected def transform(SchedulingOrder order) {
		switch (order) {
			case SchedulingOrder.BOTTOM_UP: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder.BOTTOM_UP
			}
			case SchedulingOrder.TOP_DOWN: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder.TOP_DOWN
			}
			default: {
				throw new IllegalArgumentException("Not known scheduling order: " + order)
			}
		}
	}
	
	protected def transform(GuardEvaluation guardEvaluation) {
		switch (guardEvaluation) {
			case GuardEvaluation.ON_THE_FLY: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation.ON_THE_FLY
			}
			case GuardEvaluation.BEGINNING_OF_STEP: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation.BEGINNING_OF_STEP
			}
			default: {
				throw new IllegalArgumentException("Not known guard evaluation: " + guardEvaluation)
			}
		}
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Region transform(Region region) {
		val lowlevelRegion = createRegion => [
			it.name = region.regionName
		]
		trace.put(region, lowlevelRegion)
		// Transforming normal nodes
		for (stateNode : region.stateNodes.filter(State)) {
			lowlevelRegion.stateNodes += stateNode.transformNode
		}
		// Transforming abstract transition nodes
		for (pseudoState : region.stateNodes.filter(PseudoState)) {
			lowlevelRegion.stateNodes += pseudoState.transformPseudoState
		}
		return lowlevelRegion
	}
	
	protected def StateNode transformNode(State state) {
		val lowlevelState = createState => [
			it.name = state.stateName
		]
		trace.put(state, lowlevelState)
		// Transforming regions
		for (region : state.regions) {
			lowlevelState.regions += region.transform
		}
		// Entry and exit actions
		lowlevelState.entryAction = state.entryActions.transformActions
		lowlevelState.exitAction = state.exitActions.transformActions
		return lowlevelState
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Transition transform(Transition gammaTransition) {
		// Trivial simple transitions
		val gammaSource = gammaTransition.sourceState
		val gammaTarget = gammaTransition.targetState
		val lowlevelSource = if (gammaSource instanceof State) {
			trace.get(gammaSource)
		} else if (gammaSource instanceof PseudoState) {
			trace.get(gammaSource)
		}
		val lowlevelTarget = if (gammaTarget instanceof State) {
			trace.get(gammaTarget)
		} else if (gammaTarget instanceof PseudoState) {
			trace.get(gammaTarget)
		}
		val lowlevelTransition = createTransition => [
			it.source = lowlevelSource
			it.target = lowlevelTarget
		]
		trace.put(gammaTransition, lowlevelTransition) // Saving in trace
		// Important to trace the Gamma transition as the trigger transformer depends on it
		val lowlevelGuard = gammaTransition.transformTriggerAndGuard
		val lowlevelAction = gammaTransition.effects.transformActions
		lowlevelTransition => [
			it.guard = lowlevelGuard
			it.action = lowlevelAction
		]
		return lowlevelTransition
	}
	
	/**
	 * Can return null.
	 */
	protected def Expression transformTriggerAndGuard(Transition transition) {
		val lowlevelGuardList = newLinkedList
		val gammaTrigger = transition.trigger
		if (gammaTrigger !== null) {
			lowlevelGuardList += gammaTrigger.transformTrigger // Trigger guard
		}
		var guard = transition.guard
		if (guard !== null) {
			// Transforming else expressions
			if (guard instanceof ElseExpression) {
				trace.designateElseGuardedTransition(transition)
				var Expression transformedGuard
				val source = transition.sourceState
				val gammaOutgoingTransitions = source.outgoingTransitions
					.reject[it === transition]
				if (gammaOutgoingTransitions.empty) {
					transformedGuard = createTrueExpression
				}
				else {
					// Check if there are empty transitions...
					val gammaEmptyOutgoingTransitions = gammaOutgoingTransitions
							.filter[!it.hasTrigger && !it.hasGuard]
					checkState(gammaEmptyOutgoingTransitions.empty)
					transformedGuard = createAndExpression => [
						for (gammaOutgoingTransition : gammaOutgoingTransitions) {
							it.operands += createNotExpression => [
								val otherTrigger = gammaOutgoingTransition.trigger
								val otherGuard = gammaOutgoingTransition.guard
								it.operand = createAndExpression => [
									// By default, the transformTrigger returns false expression for null
									if (otherTrigger !== null) {
										it.operands += otherTrigger.transformTrigger
									}
									if (otherGuard !== null) {
										it.operands += otherGuard.transformExpression
									}
								]
							]
						}
					]
				}
				lowlevelGuardList += transformedGuard
			}
			else {
				lowlevelGuardList += guard.transformExpression
			}
		}
		// The expressions are in an AND relation
		return lowlevelGuardList.wrapIntoMultiaryExpression(createAndExpression)
	}
	
	protected def prioritizeTransitions(StatechartDefinition statechart) {
		for (node : statechart.allStateNodes
					.filter[it instanceof State || it instanceof ChoiceState]) {
			val gammaOutgoingTransitions = node.outgoingTransitions
					// Else expressions should not be cloned again
					.reject[trace.elseGuardedTransition.contains(it)]
			// Sorting, so the resulting guard expressions do not get too big
			val sortedGammaOutgoingTransitions = gammaOutgoingTransitions.sortBy[it.calculatePriority]
			for (gammaTransition : sortedGammaOutgoingTransitions) {
				val lowlevelTransition = trace.get(gammaTransition)
				val newGuardExpression = createAndExpression
				for (prioritizedTransition : gammaTransition.prioritizedTransitions) {
					newGuardExpression.operands += createNotExpression => [
						it.operand = prioritizedTransition.transformTriggerAndGuard // New expression
					]
				}
				// New guard
				if (!newGuardExpression.operands.empty) {
					lowlevelTransition.guard = newGuardExpression => [
						it.operands += lowlevelTransition.guard // No clone here
					]
				}
			}
		}
	}
	
}