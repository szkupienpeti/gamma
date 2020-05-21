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
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.contract.AdaptiveContractAnnotation
import hu.bme.mit.gamma.statechart.model.contract.StateContractAnnotation
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import java.io.File
import java.util.Collections
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelPreprocessor {
	
	protected val logger = Logger.getLogger("GammaLogger")
	protected extension StatechartUtil statechartUtil = new StatechartUtil
	
	def preprocess(Package gammaPackage, File containingFile) {
		val parentFolder = containingFile.parent
		val fileName = containingFile.name
		val fileNameExtensionless = fileName.substring(0, fileName.lastIndexOf("."))
		// Unfolding the given system
		val trace = new ModelUnfolder().unfold(gammaPackage)
		var _package = trace.package
		// If it is a single statechart, we wrap it
		val component = trace.topComponent
		if (component instanceof StatechartDefinition) {
			logger.log(Level.INFO, "Wrapping statechart " + component)
			_package.components.add(0, component.wrapSynchronousComponent)
		}
		// Saving the package, because VIATRA will NOT return matches if the models are not in the same ResourceSet
		val flattenedModelFileName = "." + fileNameExtensionless + ".gsm"
		val flattenedModelUri = URI.createFileURI(parentFolder + File.separator + flattenedModelFileName)
		normalSave(_package, flattenedModelUri)
		// Reading the model from disk as this is the easy way of reloading the necessary ResourceSet
		_package = flattenedModelUri.normalLoad as Package
		val resource = _package.eResource
		val resourceSet = resource.resourceSet
		// Optimizing - removing unfireable transitions
		val transitionOptimizer = new SystemReducer(resourceSet)
		transitionOptimizer.execute
		// Saving the Package of the unfolded model
		resource.save(Collections.EMPTY_MAP)
		return _package.components.head
	}
	
	def removeAnnotations(Component component) {
		// Removing annotations only from the models; they are saved on disk
		val newPackage = component.containingPackage
		EcoreUtil.getAllContents(newPackage, true)
			.filter(AdaptiveContractAnnotation).forEach[EcoreUtil.remove(it)]
		EcoreUtil.getAllContents(newPackage, true)
			.filter(StateContractAnnotation).forEach[EcoreUtil.remove(it)]
	}
	
	def getLogger() {
		return logger
	}
}
