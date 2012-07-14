package org.dthume.maven.gource;

import static org.apache.commons.lang3.StringEscapeUtils.escapeXml;
import static org.apache.commons.lang3.StringUtils.isNotEmpty;

import java.io.PrintWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.apache.maven.scm.ChangeFile;
import org.apache.maven.scm.ChangeSet;
import org.apache.maven.scm.ScmFileStatus;
import org.apache.maven.scm.command.changelog.ChangeLogSet;
import org.codehaus.plexus.component.annotations.Component;

@Component(role=ChangeLogWriter.class)
public class DefaultChangeLogWriter implements ChangeLogWriter {
    public void write(final ChangeLogSet changes, final Writer out) {
        final List<ChangeSet> changeSets = preprocessChangeSet(changes);
        final PrintWriter writer = new PrintWriter(out);
        
        try {
            printChangeSets(writer, changeSets);
        } finally {
            writer.close();
        }
    }
    
    private List<ChangeSet> preprocessChangeSet(final ChangeLogSet changes) {
        final List<ChangeSet> changeSets =
                new ArrayList<ChangeSet>(changes.getChangeSets());
        java.util.Collections.sort(changeSets, new Comparator<ChangeSet>() {
            public int compare(final ChangeSet o1, final ChangeSet o2) {
                return o1.getDate().compareTo(o2.getDate());
            }
        });
        return changeSets;
    }
    
    private void printChangeSets(final PrintWriter writer,
            final List<ChangeSet> changeSets) {
        writer.println("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>");
        writer.println("<changelog>");
        for (final ChangeSet change : changeSets)
            printChange(writer, change);
        writer.println("</changelog>");
        writer.flush();
    }
    
    private void printChange(final PrintWriter writer, final ChangeSet change) {
        if (null == change.getDate())
            return;
        
        printIndent(writer, 1);
        
        writer.print("<entry ts=\"");
        writer.print(change.getDate().getTime() / 1000);
        writer.println("\">");
        
        printEl(writer, 2, "author", change.getAuthor());
        printEl(writer, 2, "msg", change.getComment());
        printEl(writer, 2, "revision", change.getRevision());
        printEl(writer, 2, "parent", change.getParentRevision());
        
        for (final String rev : change.getMergedRevisions())
            printEl(writer, 2, "merge", rev);
        
        for (final ChangeFile file : change.getFiles())
            printFile(writer, file);
        
        printIndent(writer, 1);
        writer.println("</entry>");
        writer.flush();
    }
    
    private void printFile(final PrintWriter writer, final ChangeFile file) {
        printIndent(writer, 2);
        writer.println("<file>");
        
        final ScmFileStatus action = file.getAction();
        if (null != action)
            printEl(writer, 3, "action", action.toString());
        
        printEl(writer, 3, "name", file.getName());
        printEl(writer, 3, "revision", file.getRevision());
        printEl(writer, 3, "old-name", file.getOriginalName());
        printEl(writer, 3, "old-revision", file.getOriginalRevision());
        printIndent(writer, 2);
        writer.println("</file>");
        writer.flush();
    }
    
    private void printIndent(final PrintWriter writer, final int indent) {
        for (int ii = 0; ii < indent; ii++)
            writer.print("\t");
    }
        
    private void printEl(final PrintWriter writer, final int indent,
            final String name, final String value) {
        if (isNotEmpty(value)) {
            printIndent(writer, indent);
            writer.print("<");
            writer.print(name);
            writer.print(">");
            writer.print(escapeXml(value));
            writer.print("</");
            writer.print(name);
            writer.println(">");
        }
    }
}
