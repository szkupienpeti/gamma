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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.List
import java.util.Set
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*
import hu.bme.mit.gamma.xsts.transformation.util.XstsNamings
import hu.bme.mit.gamma.theta.trace.model.XstsTrace
import hu.bme.mit.gamma.theta.trace.model.XstsState

class TraceBackAnnotator {
	
	protected final XstsTrace cex
	protected final ThetaQueryGenerator thetaQueryGenerator
	
	protected final Package gammaPackage
	protected final Component component
	protected final Expression schedulingConstraint
	
	protected final boolean sortTrace
	// Directives info
	protected boolean splitted = false
	protected boolean noenv = false
	// Auxiliary objects
	protected final extension TraceModelFactory trFact = TraceModelFactory.eINSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(Package gammaPackage, XstsTrace cex) {
		this(gammaPackage, cex, true)
	}
	
	new(Package gammaPackage, XstsTrace cex, boolean sortTrace) {
		this(gammaPackage, cex, sortTrace, null)
	}
	
	new(Package gammaPackage, XstsTrace cex, List<String> directives) {
		this(gammaPackage, cex, true, directives)
	}
	
	new(Package gammaPackage, XstsTrace cex, boolean sortTrace, List<String> directives) {
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.components.head
		this.thetaQueryGenerator = new ThetaQueryGenerator(gammaPackage)
		this.cex = cex
		this.sortTrace = sortTrace
		val schedulingConstraintAnnotation = gammaPackage.annotations
			.filter(SchedulingConstraintAnnotation).head
		if (schedulingConstraintAnnotation !== null) {
			this.schedulingConstraint = schedulingConstraintAnnotation.schedulingConstraint
		}
		else {
			this.schedulingConstraint = null
		}
		// Directives
		for (directive : directives) {
			switch (directive) {
				case directive.startsWith(XstsNamings.SPLIT_DIRECTIVE): {
					splitted = true
				}
				case directive.startsWith(XstsNamings.NOENV_DIRECTIVE): {
					noenv = true
				}
				default: {
					logger.log(Level.WARNING, "Unhandled directive: " + directive)
				}
			}
		}
	}
	
	def synchronized ExecutionTrace execute() {
		// Creating the trace component
		val trace = createExecutionTrace => [
			it.component = this.component
			it.import = this.gammaPackage
			it.name = this.component.name + "Trace"
		]
		val topComponentArguments = gammaPackage.topComponentArguments
		// Note that the top component does not contain parameter declarations anymore due to the preprocessing
		checkState(topComponentArguments.size == component.parameterDeclarations.size, 
			"The number of top component arguments and top component parameters are not equal: " +
				topComponentArguments.size + " - " + component.parameterDeclarations.size)
		logger.log(Level.INFO, "The number of top component arguments is " + topComponentArguments.size)
		trace.arguments += topComponentArguments.map[it.clone]
		var Step step// = createStep
		//trace.steps += step
		// Sets for raised in and out events and activated states
		val raisedOutEvents = newHashSet
		val raisedInEvents = newHashSet
		val activatedStates = newHashSet
		// Parsing
		var BackAnnotatorState backAnnotatorState
		
		for (sequence : cex.sequences) {
			System.out.println(">>>XstsStateSequence")
			// Skipping the first state
			var states = sequence.states.subList(1, sequence.states.length)
			// Removing unreal states
			states.removeUnrealStates
			
			// Frist step
			// Creating a new step
			step = createStep
			trace.steps += step
			step.actions += createReset
			System.out.println("* Reset added")
			
			// Parsing
			backAnnotatorState = BackAnnotatorState.STATE_CHECK
			for (xStsState : states) {
				System.out.println(backAnnotatorState.name)
				if (backAnnotatorState == BackAnnotatorState.ENVIRONMENT_CHECK) {
					// Creating a new step (every Gamma step is built from two XstsStates (last_env, last_internal)
					step = createStep
					trace.steps += step
					// Add static delay every turn
					if (schedulingConstraint !== null) {
						step.addTimeElapse(schedulingConstraint)
					}
				}
				///
				for (valuation : xStsState.state.valuations) {
					val id = valuation.name
					val value = valuation.value
					System.out.println('''(«id» «value»)''')
					switch (backAnnotatorState) {
						case STATE_CHECK: {
							val potentialStateString = '''«id» == «value»'''
							if (thetaQueryGenerator.isSourceState(potentialStateString)) {
//								System.out.println('''* «id» is source state''')
								val instanceState = thetaQueryGenerator.getSourceState(potentialStateString)
								val controlState = instanceState.key
								val instance = instanceState.value
								step.addInstanceState(instance, controlState)
								activatedStates += controlState
							}
							else if (thetaQueryGenerator.isSourceVariable(id)) {
//								System.out.println('''* «id» is source var''')
								val instanceVariable = thetaQueryGenerator.getSourceVariable(id)
								val instance = instanceVariable.value
								val variable = instanceVariable.key
								// Getting fields and indexes regardless of primitive or complex types
								// In the case of primitive types, these hierarchies will be empty
								val field = thetaQueryGenerator.getSourceVariableFieldHierarchy(id)
								val indexPairs = value.parseArray
								//
								for (indexPair : indexPairs) {
									val index = indexPair.key
									val parsedValue = indexPair.value
									step.addInstanceVariableState(instance, variable, field, index, parsedValue)
								}
							}
							else if (thetaQueryGenerator.isSourceOutEvent(id)) {
								System.out.println('''* «id» is out event''')
								val systemOutEvent = thetaQueryGenerator.getSourceOutEvent(id)
								if (value.equals("true")) {
									System.out.println('''** «id» out event value is true''')
									val event = systemOutEvent.get(0) as Event
									val port = systemOutEvent.get(1) as Port
									val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
									step.addOutEvent(systemPort, event)
									// Denoting that this event has been actually
									raisedOutEvents += new Pair(systemPort, event)
								}
							}
							else if (thetaQueryGenerator.isSourceOutEventParamater(id)) {
//								System.out.println('''* «id» is out event param''')
								val systemOutEvent = thetaQueryGenerator.getSourceOutEventParamater(id)
								val event = systemOutEvent.get(0) as Event
								val port = systemOutEvent.get(1) as Port
								val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
								val parameter = systemOutEvent.get(2) as ParameterDeclaration
								// Getting fields and indexes regardless of primitive or complex types
								val field = thetaQueryGenerator.getSourceOutEventParamaterFieldHierarchy(id)
								val indexPairs = value.parseArray
								//
								for (indexPair : indexPairs) {
									val index = indexPair.key
									val parsedValue = indexPair.value
									step.addOutEventWithStringParameter(systemPort, event, parameter, field, index, parsedValue)
								}
							}
						}
						case ENVIRONMENT_CHECK: {
							if (thetaQueryGenerator.isSourceInEvent(id)) {
								System.out.println('''* «id» is source event''')
								val systemInEvent = thetaQueryGenerator.getSourceInEvent(id)
								if (value.equals("true")) {
									System.out.println('''** «id» source event value is true''')
									val event = systemInEvent.get(0) as Event
									val port = systemInEvent.get(1) as Port
									val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
									step.addInEvent(systemPort, event)
									// Denoting that this event has been actually
									raisedInEvents += new Pair(systemPort, event)
								}
							}
							else if (thetaQueryGenerator.isSourceInEventParamater(id)) {
//								System.out.println('''* «id» is source event param''')
								val systemInEvent = thetaQueryGenerator.getSourceInEventParamater(id)
								val event = systemInEvent.get(0) as Event
								val port = systemInEvent.get(1) as Port
								val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
								val parameter = systemInEvent.get(2) as ParameterDeclaration
								// Getting fields and indexes regardless of primitive or complex types
								val field = thetaQueryGenerator.getSourceInEventParamaterFieldHierarchy(id)
								val indexPairs = value.parseArray
								//
								for (indexPair : indexPairs) {
									val index = indexPair.key
									val parsedValue = indexPair.value
									step.addInEventWithParameter(systemPort, event, parameter, field, index, parsedValue)
								}
							}
						}
						default:
							throw new IllegalArgumentException("Not known state: " + backAnnotatorState)
					}
				}
				// Post-process
				switch (backAnnotatorState) {
					case STATE_CHECK: {
						step.checkStates(raisedOutEvents, activatedStates)
						// Setting the state
						backAnnotatorState = BackAnnotatorState.ENVIRONMENT_CHECK
					}
					case ENVIRONMENT_CHECK: {
						step.checkInEvents(raisedInEvents)
						// Add schedule
						step.addComponentScheduling
						// Setting the state
						backAnnotatorState = BackAnnotatorState.STATE_CHECK
						System.out.println()
					}
					default:
						throw new IllegalArgumentException("Not know state: " + backAnnotatorState)
				}
			}
		}
		// Checking the last state (in events must NOT be deleted here though)
		//step.checkStates(raisedOutEvents, activatedStates) //???
		// Sorting if needed
		if (sortTrace) {
			trace.sortInstanceStates
		}
		System.out.println("***END***")
		return trace
	}
	
	protected def void checkStates(Step step, Set<Pair<Port, Event>> raisedOutEvents,
			Set<State> activatedStates) {
		val raiseEventActs = step.outEvents
		for (raiseEventAct : raiseEventActs) {
			if (!raisedOutEvents.contains(new Pair(raiseEventAct.port, raiseEventAct.event))) {
				EcoreUtil.delete(raiseEventAct)
			}
		}
		val instanceStates = step.instanceStateConfigurations
		for (instanceState : instanceStates) {
			// A state is active if all of its ancestor states are active
			val ancestorStates = instanceState.state.ancestors
			if (!activatedStates.containsAll(ancestorStates)) {
				EcoreUtil.delete(instanceState)
			}
		}
		raisedOutEvents.clear
		activatedStates.clear
	}
	
	protected def void checkInEvents(Step step, Set<Pair<Port, Event>> raisedInEvents) {
		val raiseEventActs = step.actions.filter(RaiseEventAct).toList
		for (raiseEventAct : raiseEventActs) {
			if (!raisedInEvents.contains(new Pair(raiseEventAct.port, raiseEventAct.event))) {
				EcoreUtil.delete(raiseEventAct)
			}
		}
		raisedInEvents.clear
	}
	
	protected def List<Pair<IndexHierarchy, String>> parseArray(String value) {
		// (array (0 10) (1 11) (default 0))
		val values = newArrayList
		if (value.isArray) {
			val unwrapped = thetaQueryGenerator.unwrap(value).substring("array ".length) // (0 10) (default 0)
			val splits = unwrapped.parseAlongParentheses // 0 10, default array
			for (split : splits) {
				val splitPair = split.split(" ") // 0, 10
				val index = splitPair.get(0) // 0
				if (!index.equals("default")) { // Not parsing default values
					val parsedIndex = Integer.parseInt(index) // 0
					val storedValue = splitPair.get(1) // 10
					val parsedValues = storedValue.parseArray
					for (parsedValue : parsedValues) {
						val indexHierarchy = parsedValue.key
						indexHierarchy.prepend(parsedIndex) // So the "parent index" will be retrieved earlier
						val stringValue = parsedValue.value
						values += indexHierarchy -> stringValue
					}
				}
			}
			return values
		}
		else {
			return #[new IndexHierarchy -> value]
		}
	}
	
	protected def parseAlongParentheses(String line) {
		val result = newArrayList
		var unclosedParanthesisCount = 0
		var firstParanthesisIndex = 0
		for (var i = 0; i < line.length; i++) {
			val character = line.charAt(i).toString
			if (character == "(") {
				unclosedParanthesisCount++
				if (unclosedParanthesisCount == 1) {
					firstParanthesisIndex = i
				}
			}
			else if (character == ")") {
				unclosedParanthesisCount--
				if (unclosedParanthesisCount == 0) {
					result += line.substring(firstParanthesisIndex + 1, i)
				}
			}
		}
		return result
	}
	
	protected def boolean isArray(String value) {
		return value.startsWith("(array ")
	}
	
	protected def void removeUnrealStates(List<XstsState> states) {
		if (splitted) {
			states.removeIf[s |
				s.state.valuations.filter[v |
					v.name.equals(XstsNamings.PC_VAR_NAME) && !v.value.equals("0")
				].size > 0
			]
		}
		if (noenv) {
			states.removeIf[s |
				s.annotations.contains("last_env")
			]
		}
	}
	
	enum BackAnnotatorState {STATE_CHECK, ENVIRONMENT_CHECK}
	
}