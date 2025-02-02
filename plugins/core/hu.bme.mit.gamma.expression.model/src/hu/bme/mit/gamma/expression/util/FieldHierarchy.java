package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.model.FieldDeclaration;

public class FieldHierarchy {

	private List<FieldDeclaration> fields = new ArrayList<FieldDeclaration>();
	
	public FieldHierarchy(FieldHierarchy fields) {
		this.fields.addAll(fields.getFields());
	}
	
	public FieldHierarchy(List<FieldDeclaration> fields) {
		this.fields.addAll(fields);
	}
	
	public FieldHierarchy(FieldDeclaration field) {
		this.fields.add(field);
	}
	
	public FieldHierarchy() {}
	
	public List<FieldDeclaration> getFields() {
		return fields;
	}
	
	public void prepend(FieldDeclaration field) {
		fields.add(0, field);
	}
	
	public void prepend(FieldHierarchy fieldHierarchy) {
		fields.addAll(0, fieldHierarchy.getFields());
	}
	
	public void add(FieldDeclaration field) {
		fields.add(field);
	}
	
	public void add(List<FieldDeclaration> fields) {
		fields.addAll(fields);
	}
	
	public void add(FieldHierarchy fieldHierarchy) {
		fields.addAll(fieldHierarchy.getFields());
	}
	
	public FieldDeclaration getLast() {
		int size = fields.size();
		return fields.get(size - 1);
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((fields == null) ? 0 : fields.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (obj == null) {
			return false;
		}
		if (getClass() != obj.getClass()) {
			return false;
		}
		FieldHierarchy other = (FieldHierarchy) obj;
		if (fields == null) {
			if (other.fields != null) {
				return false;
			}
		} else if (!fields.equals(other.fields)) {
			return false;
		}
		return true;
	}
	
}
