package org.dthume.maven.gource;

import java.io.Writer;

import org.apache.maven.scm.command.changelog.ChangeLogSet;

public interface ChangeLogWriter {
    void write(final ChangeLogSet changes, final Writer writer);
}
