package ru.myx.distro.prepare;

import java.util.TreeSet;

public class OptionList extends TreeSet<OptionListItem> {

    private static final long serialVersionUID = 4464004437970547444L;

    public OptionList() {
    }

    @Override
    public boolean add(final OptionListItem item) {
	final OptionListItem existing = this.floor(item);
	if (existing == null || !existing.getName().equals(item.getName())) {
	    return super.add(item);
	}
	return existing.keys.addAll(item.keys);
    }

    @Override
    public String toString() {
	if (this.isEmpty()) {
	    return "";
	}

	final StringBuilder builder = new StringBuilder();
	for (final OptionListItem item : this) {
	    if (builder.length() > 0) {
		builder.append(' ');
	    }
	    builder.append(item);
	}
	return builder.toString();
    }
}
